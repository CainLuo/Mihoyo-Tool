/**
 * ============================================================
 * GeetestDialog — Geetest 验证码弹窗组件（entry 层）
 * ============================================================
 *
 * 职责：
 *   展示 Geetest 验证码（v3 / v4 均支持），等待用户完成验证，
 *   通过 Promise 把验证结果回传给调用方。
 *
 * 技术方案：
 *   使用 HarmonyOS ArkUI 的 Web 组件加载一段内嵌 HTML，
 *   HTML 内通过 <script> 动态加载 Geetest 官方 JS SDK，
 *   验证完成后通过 registerJavaScriptProxy 把结果回传给 ArkTS。
 *
 *   选择此方案而非 Geetest HarmonyOS Native SDK 的原因：
 *     1. Native SDK 需要手动下载 .har 包，集成成本高
 *     2. JS SDK 与 TeyvatGuide 的实现思路一致，经过验证
 *     3. Web 组件方案更灵活，后续 Geetest 升级只需更新 JS URL
 *
 * 使用方式（在任意 ArkUI 页面/组件中）：
 *   import { showGeetestDialog } from '../components/GeetestDialog';
 *   import { GeetestService } from 'core';
 *
 *   // 1. 调用 core 层获取验证参数
 *   const createResult = await GeetestService.createVerification(cookie);
 *   // 2. 展示弹窗，等待用户完成验证
 *   const verifyInput = await showGeetestDialog(this.getUIContext(), createResult);
 *   if (!verifyInput) return; // 用户取消
 *   // 3. 提交验证结果换取新 challenge
 *   const newChallenge = await GeetestService.verifyVerification(verifyInput, cookie);
 *   // 4. 用新 challenge 重试业务请求
 *   await apiService.get(url, params, {
 *     extraHeaders: {
 *       'x-rpc-challenge': newChallenge,
 *       'x-rpc-validate':  verifyInput.geetest_validate,
 *       'x-rpc-seccode':   verifyInput.geetest_seccode,
 *     }
 *   });
 * ============================================================
 */

import { webview } from '@kit.ArkWeb';
import { UIContext, ComponentContent, promptAction, window } from '@kit.ArkUI';
import { BusinessError } from '@kit.BasicServicesKit';
import { GeetestCreateResult, GeetestVerifyInput } from 'core';

// ---- 生成内嵌 HTML 的工厂函数 ----

/**
 * 根据 Geetest 版本生成对应的内嵌 HTML 字符串
 *
 * v3：使用 initGeetest()，需要 gt + challenge 参数
 * v4：使用 initGeetest4()，需要 captchaId(gt) + riskType 参数
 *
 * HTML 内的 window.geetestBridge 对象会被 registerJavaScriptProxy 注入，
 * 验证完成后调用 window.geetestBridge.onSuccess(challenge, validate, seccode)
 * 验证取消后调用 window.geetestBridge.onCancel()
 *
 * @param createResult createVerification 返回的参数
 * @returns 完整 HTML 字符串（data URI 格式）
 */
function buildGeetestHtml(createResult: GeetestCreateResult): string {
  const isV3 = createResult.challenge !== undefined;
  const gt = createResult.gt;
  const challenge = createResult.challenge ?? '';
  const riskType = createResult.risk_type ?? 'slide';

  // Geetest JS SDK URL（来源：TeyvatGuide geetest.vue）
  const sdkUrl = isV3
    ? 'https://static.geetest.com/static/js/gt.0.4.9.js'
    : 'https://static.geetest.com/v4/gt4.js';

  // v3 初始化脚本（纯字符串拼接，避免模板字符串内 CSS/JS 关键字被 ArkTS 误判）
  const v3Script = isV3
    ? 'initGeetest({gt:"' + gt + '",challenge:"' + challenge + '",' +
      'offline:false,new_captcha:true,product:"popup",width:"100%",https:true},' +
      'function(o){o.appendTo("#geetest-box");' +
      'o.onReady(function(){document.getElementById("loading").style.display="none";});' +
      'o.onClose(function(){var v=o.getValidate();if(v){' +
      'window.geetestBridge.onSuccess(v.geetest_challenge,v.geetest_validate,v.geetest_seccode);}' +
      'else{window.geetestBridge.onCancel();}});});'
    : '';

  // v4 初始化脚本
  const v4Script = !isV3
    ? 'initGeetest4({captchaId:"' + gt + '",riskType:"' + riskType + '",' +
      'product:"popup",nextWidth:"100%",lang:"zho",https:true,protocol:"https"},' +
      'function(o){o.appendTo("#geetest-box");' +
      'o.onReady(function(){document.getElementById("loading").style.display="none";});' +
      'o.onClose(function(){window.geetestBridge.onCancel();});' +
      'o.onSuccess(function(){var v=o.getValidate();if(v){' +
      'window.geetestBridge.onSuccess(v.geetest_challenge,v.geetest_validate,v.geetest_seccode);}' +
      'else{window.geetestBridge.onCancel();}});});'
    : '';

  // 用字符串拼接构造 HTML，避免模板字符串内 CSS 属性被 ArkTS 误判为关键字
  const style = 'body{margin:0;padding:16px;background:transparent;display:flex;' +
    'flex-direction:column;align-items:center;}' +
    '#loading{color:#888;font-size:14px;margin-top:20px;}' +
    '#geetest-box{width:100%;}';

  const loadingText = '加载验证码中...';

  const html = '<!DOCTYPE html><html><head>' +
    '<meta charset="utf-8">' +
    '<meta name="viewport" content="width=device-width,initial-scale=1.0">' +
    '<style>' + style + '</style>' +
    '</head><body>' +
    '<div id="loading">' + loadingText + '</div>' +
    '<div id="geetest-box"></div>' +
    '<script src="' + sdkUrl + '"></script>' +
    '<script>window.onload=function(){' + v3Script + v4Script + '};</script>' +
    '</body></html>';

  // 使用 data URI 加载 HTML，避免跨域问题
  return 'data:text/html;charset=utf-8,' + encodeURIComponent(html);
}

// ---- JS Bridge 接口 ----
// registerJavaScriptProxy 要求注入的对象方法必须定义在一个 class 上

/**
 * 注入到 Web 页面的 JS Bridge 对象
 * HTML 内通过 window.geetestBridge.onSuccess(...) / window.geetestBridge.onCancel() 调用
 *
 * 注意：registerJavaScriptProxy 要求方法列表在注册时显式声明，
 * 且方法参数只支持基础类型（string / number / boolean）。
 */
class GeetestBridge {
  // resolve/reject 由外部在创建 Promise 时注入
  private resolveCallback: ((result: GeetestVerifyInput | null) => void) | null = null;

  setCallback(resolve: (result: GeetestVerifyInput | null) => void): void {
    this.resolveCallback = resolve;
  }

  /**
   * Geetest 验证成功回调（由 HTML 内 JS 调用）
   * @param challenge geetest_challenge
   * @param validate  geetest_validate
   * @param seccode   geetest_seccode
   */
  onSuccess(challenge: string, validate: string, seccode: string): void {
    if (this.resolveCallback) {
      const result: GeetestVerifyInput = {
        geetest_challenge: challenge,
        geetest_validate: validate,
        geetest_seccode: seccode,
      };
      this.resolveCallback(result);
      this.resolveCallback = null;
    }
  }

  /**
   * 用户取消验证回调（由 HTML 内 JS 调用）
   */
  onCancel(): void {
    if (this.resolveCallback) {
      this.resolveCallback(null);
      this.resolveCallback = null;
    }
  }
}

// ---- ArkUI 组件 ----

/**
 * GeetestDialog 卡片内容组件
 *
 * 只渲染卡片本身（标题栏 + Web），不包含全屏遮罩。
 * 遮罩由 openCustomDialog 的 maskColor 参数负责。
 * 通过 ComponentContent + openCustomDialog 方案调用。
 *
 * 自适应策略：
 *   - 外层容器 padding 16vp 留边距，卡片 constraintSize 限制最大宽度 400vp
 *   - Web 高度动态跟随窗口高度（55%），并限制 min/max，适配横屏/分屏/折叠屏
 *   - 注册 windowSizeChange 监听，形态切换时自动重算高度
 */
@Component
export struct GeetestDialog {
  /** createVerification 返回的参数，由调用方传入 */
  @Prop createResult: GeetestCreateResult = { gt: '' };
  /** 验证完成/取消的回调，由 showGeetestDialog 注入 */
  onResult: (result: GeetestVerifyInput | null) => void = () => {};

  // Web 组件高度，动态跟随窗口可用高度
  @State private webHeight: number = 360;

  private controller: webview.WebviewController = new webview.WebviewController();
  private bridge: GeetestBridge = new GeetestBridge();
  private win: window.Window | null = null;

  // 根据窗口高度（px）计算 Web 组件高度（vp），取 55% 并限制范围
  private calcWebHeight(windowHeightPx: number): number {
    const heightVp = px2vp(windowHeightPx) * 0.55;
    if (heightVp < 200) {
      return 200;
    }
    if (heightVp > 480) {
      return 480;
    }
    return heightVp;
  }

  aboutToAppear(): void {
    this.bridge.setCallback((result) => {
      this.onResult(result);
    });

    // 获取当前窗口，读取初始高度并注册尺寸变化监听
    try {
      const ctx = getContext(this);
      window.getLastWindow(ctx).then((win) => {
        this.win = win;
        const rect = win.getWindowProperties().windowRect;
        this.webHeight = this.calcWebHeight(rect.height);

        win.on('windowSizeChange', (size: window.Size) => {
          this.webHeight = this.calcWebHeight(size.height);
        });
      }).catch((e: BusinessError) => {
        console.warn('GeetestDialog getLastWindow failed: ' + e.message);
      });
    } catch (e) {
      console.warn('GeetestDialog window init failed: ' + (e as Error).message);
    }
  }

  aboutToDisappear(): void {
    // 取消窗口尺寸监听，防止内存泄漏
    if (this.win !== null) {
      try {
        this.win.off('windowSizeChange');
      } catch (e) {
        console.warn('GeetestDialog off windowSizeChange failed: ' + (e as Error).message);
      }
      this.win = null;
    }
  }

  build() {
    // 外层容器：左右 padding 16vp，撑满弹窗宽度
    Column() {
      // 卡片：限制最大宽度 400vp，小屏自动收缩，大屏居中
      Column() {
        // 标题栏
        Row() {
          Text('请完成安全验证')
            .fontSize(16)
            .fontColor('#333333')
            .fontWeight(FontWeight.Medium)
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })
            .layoutWeight(1)
          // 关闭按钮
          Text('✕')
            .fontSize(18)
            .fontColor('#666666')
            .padding(8)
            .onClick(() => {
              this.onResult(null);
            })
        }
        .width('100%')
        .padding({ left: 16, right: 8, top: 12, bottom: 12 })

        Divider().color('#EEEEEE')

        // Web 组件：高度动态跟随窗口，适配横屏/分屏/折叠屏
        Web({
          src: buildGeetestHtml(this.createResult),
          controller: this.controller
        })
          .width('100%')
          .height(this.webHeight)
          .javaScriptAccess(true)
          .domStorageAccess(true)
          .mixedMode(MixedMode.All)
          .onControllerAttached(() => {
            try {
              this.controller.registerJavaScriptProxy(
                this.bridge,
                'geetestBridge',
                ['onSuccess', 'onCancel']
              );
            } catch (e) {
              console.error('GeetestDialog registerJavaScriptProxy failed: ' + (e as Error).message);
            }
          })
          .onErrorReceive((event) => {
            console.error('GeetestDialog Web error: ' + event?.error?.getErrorInfo());
            this.onResult(null);
          })
      }
      .width('100%')
      .constraintSize({ minWidth: 280, maxWidth: 400 })
      .backgroundColor(Color.White)
      .borderRadius(12)
      .clip(true)
    }
    .width('100%')
    .padding({ left: 16, right: 16 })
  }
}

// ---- 全局调用入口 ----

/**
 * 内部用于传递参数给 @Builder 的数据容器
 * ArkTS 要求 wrapBuilder 的参数必须是单一对象
 */
class GeetestDialogParams {
  createResult: GeetestCreateResult;
  onResult: (result: GeetestVerifyInput | null) => void;

  constructor(
    createResult: GeetestCreateResult,
    onResult: (result: GeetestVerifyInput | null) => void
  ) {
    this.createResult = createResult;
    this.onResult = onResult;
  }
}

/**
 * 供 ComponentContent + openCustomDialog 使用的 @Builder 函数
 * 注意：@Builder 函数不能是 class 方法，必须是模块级函数
 */
@Builder
function buildGeetestDialogContent(params: GeetestDialogParams) {
  GeetestDialog({
    createResult: params.createResult,
    onResult: params.onResult,
  })
}

/**
 * 展示 Geetest 验证码弹窗，返回 Promise<GeetestVerifyInput | null>
 *
 * 使用 ComponentContent + openCustomDialog 方案（API 12+ 推荐）。
 * closeCustomDialog 传入 ComponentContent 实例，关闭后调用 dispose() 释放资源。
 *
 * @param uiContext 当前页面的 UIContext，通过 this.getUIContext() 获取
 * @param createResult GeetestService.createVerification() 返回的参数
 * @returns 用户完成验证后的结果，用户取消时返回 null
 */
export function showGeetestDialog(
  uiContext: UIContext,
  createResult: GeetestCreateResult
): Promise<GeetestVerifyInput | null> {
  return new Promise<GeetestVerifyInput | null>((resolve) => {
    // 用 ComponentContent 封装弹窗内容，与 UI 树解耦
    let contentNode: ComponentContent<GeetestDialogParams> | null = null;

    const params = new GeetestDialogParams(createResult, (result) => {
      // 关闭弹窗并释放 ComponentContent
      if (contentNode !== null) {
        uiContext.getPromptAction().closeCustomDialog(contentNode)
          .then(() => {
            if (contentNode !== null) {
              contentNode.dispose();
              contentNode = null;
            }
          })
          .catch((e: BusinessError) => {
            console.warn(`GeetestDialog close failed: ${e.message}`);
          });
      }
      resolve(result);
    });

    contentNode = new ComponentContent<GeetestDialogParams>(
      uiContext,
      wrapBuilder(buildGeetestDialogContent),
      params
    );

    const dialogOptions: promptAction.BaseDialogOptions = {
      autoCancel: false,
      alignment: DialogAlignment.Center,
      maskColor: '#80000000',
    };

    uiContext.getPromptAction().openCustomDialog(contentNode, dialogOptions)
      .catch((e: BusinessError) => {
        console.error(`GeetestDialog open failed: ${e.message}`);
        resolve(null);
      });
  });
}
