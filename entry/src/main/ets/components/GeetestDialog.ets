/**
 * GeetestDialog — Geetest 验证码弹窗卡片组件（entry 层）
 *
 * 只渲染卡片本身（标题栏 + Web），不包含全屏遮罩。
 * 遮罩由 openCustomDialog 的 maskColor 参数负责。
 *
 * 自适应策略：
 *   - 外层容器 padding 16vp 留边距，卡片 constraintSize 限制最大宽度 400vp
 *   - Web 高度动态跟随窗口高度（55%），并限制 min/max，适配横屏/分屏/折叠屏
 *   - 注册 windowSizeChange 监听，形态切换时自动重算高度
 *
 * 调用入口：showGeetestDialog()，位于 GeetestDialogHelper.ets
 */
import { webview } from '@kit.ArkWeb';
import { window } from '@kit.ArkUI';
import { BusinessError } from '@kit.BasicServicesKit';
import { GeetestCreateResult, GeetestVerifyInput } from 'core';
import { themeManager, ThemeManager } from '../theme/ThemeManager';
import { Logger } from 'core';
import { GeetestDialogTitleBar } from './GeetestDialogTitleBar';
import { GeetestBridge } from './GeetestBridge';
import { buildGeetestHtml } from './GeetestHtmlBuilder';

@ComponentV2
export struct GeetestDialog {
  /** createVerification 返回的参数，由调用方传入 */
  @Param createResult: GeetestCreateResult = new GeetestCreateResult();
  /** 验证完成/取消的回调，由 showGeetestDialog 注入 */
  @Param onResult: (result: GeetestVerifyInput | null) => void = () => {};

  @Local private webHeight: number = themeManager.current.value360;
  @Local private tm: ThemeManager = themeManager;

  private controller: webview.WebviewController = new webview.WebviewController();
  private bridge: GeetestBridge = new GeetestBridge();
  private win: window.Window | null = null;

  /** 根据窗口高度（px）计算 Web 组件高度（vp），取 55% 并限制范围 */
  private calcWebHeight(windowHeightPx: number): number {
    const heightVp = this.getUIContext().px2vp(windowHeightPx) * 0.55;
    if (heightVp < 200) { return 200; }
    if (heightVp > 480) { return 480; }
    return heightVp;
  }

  aboutToAppear(): void {
    this.bridge.setCallback((result) => { this.onResult(result); });

    try {
      const ctx = this.getUIContext().getHostContext();
      window.getLastWindow(ctx).then((win) => {
        this.win = win;
        const rect = win.getWindowProperties().windowRect;
        this.webHeight = this.calcWebHeight(rect.height);
        win.on('windowSizeChange', (size: window.Size) => {
          this.webHeight = this.calcWebHeight(size.height);
        });
      }).catch((e: BusinessError) => {
        Logger.warn('GeetestDialog', 'getLastWindow failed: ' + e.message);
      });
    } catch (e) {
      Logger.warn('GeetestDialog', 'window init failed: ' + (e as Error).message);
    }
  }

  aboutToDisappear(): void {
    if (this.win !== null) {
      try {
        this.win.off('windowSizeChange');
      } catch (e) {
        Logger.warn('GeetestDialog', 'off windowSizeChange failed: ' + (e as Error).message);
      }
      this.win = null;
    }
  }

  build() {
    Column() {
      Column() {
        GeetestDialogTitleBar({ onClose: () => { this.onResult(null); } })

        Divider()
          .color(this.tm.current.colorDivider)

        Web({
          src: buildGeetestHtml(this.createResult),
          controller: this.controller
        })
          .width(this.tm.current.full)
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
              Logger.error('GeetestDialog', 'registerJavaScriptProxy failed: ' + (e as Error).message);
            }
          })
          .onErrorReceive((event) => {
            Logger.error('GeetestDialog', 'Web error: ' + event?.error?.getErrorInfo());
            this.onResult(null);
          })
      }
      .width(this.tm.current.full)
      .constraintSize({
        minWidth: this.tm.current.value280,
        maxWidth: this.tm.current.value400
      })
      .backgroundColor(this.tm.current.colorSurfaceCard)
      .borderRadius(this.tm.current.radius12)
      .clip(true)
    }
    .width(this.tm.current.full)
    .padding({ left: this.tm.current.font16, right: this.tm.current.font16 })
  }
}

// ─── Preview ─────────────────────────────────────────────────────

@Preview
@ComponentV2
export struct GeetestDialogPreview {
  @Local private tm: ThemeManager = themeManager

  build() {
    Column() {
      GeetestDialog({ createResult: new GeetestCreateResult() })
    }
    .padding(this.tm.current.font16)
    .backgroundColor('#1a1a2e')
  }
}
