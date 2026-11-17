/**
 * LaunchPage.ets — 启动页
 *
 * 职责：
 *   - 展示 App Logo + 名称动画
 *   - 等待 Core 初始化完成（含 DB 初始化）
 *   - 初始化失败 / 超时时展示错误态与重试入口，不再永久停在 Logo 页
 *   - 就绪后直接 replace 到 MainPage（MainPage 内部负责判断是否需要登录）
 *
 * 路由：Navigation 入口页，由 Index.ets 通过 initialStack 指定。
 */

import { ThemeFonts, AppRoutes, RouterUtil, themeManager, ThemeManager } from 'basic'
import { Logger } from 'core';
import { common } from '@kit.AbilityKit';
import { LaunchViewModel } from '../viewmodel/LaunchViewModel';

const TAG: string = 'Launch';
/** 等待 Core 就绪的最长时间；超时按初始化失败处理，避免初始化卡住时永久停在启动页 */
const INIT_TIMEOUT_MS: number = 20000;
/** 启动页最短展示时长（与 Core 就绪取最长） */
const MIN_DISPLAY_MS: number = 1200;

@ComponentV2
export struct LaunchPage {
  @Local private tm: ThemeManager = themeManager;
  @Local private logoScale: number = 0.8;
  @Local private logoOpacity: number = 0;
  /** 初始化失败 / 超时：展示错误态与重试按钮 */
  @Local private initFailed: boolean = false;
  private viewModel: LaunchViewModel = new LaunchViewModel();
  private uiCtx: UIContext | null = null;
  private timeoutId: number = -1;
  /** 本轮等待已结束（已跳转或已进入错误态），用于忽略迟到的初始化结果 */
  private settled: boolean = false;

  aboutToAppear(): void {
    this.uiCtx = this.getUIContext();
    // 入场动画：Logo 淡入 + 放大
    this.uiCtx.animateTo({ duration: 600, curve: Curve.EaseOut }, () => {
      this.logoScale = 1.0;
      this.logoOpacity = 1.0;
    });
    this.checkPrivacyAndProceed();
  }

  aboutToDisappear(): void {
    this.clearTimeout();
  }

  private checkPrivacyAndProceed(): void {
    const ctx = this.getUIContext().getHostContext() as common.UIAbilityContext;
    const agreed = this.viewModel.hasAgreed(ctx);
    if (agreed) {
      this.startBootstrap(ctx);
    } else {
      // 未同意：replace 到合规流程页，不保留 LaunchPage 在返回栈
      RouterUtil.replace(AppRoutes.PRIVACY_CONSENT);
    }
  }

  /**
   * 等 Core 就绪 + 最短展示时长，两者取最长。
   * 初始化 reject 或超过 INIT_TIMEOUT_MS 都进入错误态，由用户点重试。
   */
  private startBootstrap(ctx: common.UIAbilityContext): void {
    this.settled = false;
    this.initFailed = false;
    this.clearTimeout();
    this.timeoutId = setTimeout(() => {
      this.timeoutId = -1;
      if (this.settled) {
        return;
      }
      this.settled = true;
      Logger.error(TAG, `core init timeout after ${INIT_TIMEOUT_MS}ms`);
      this.initFailed = true;
    }, INIT_TIMEOUT_MS);

    const minDelay = new Promise<void>((resolve) => setTimeout(resolve, MIN_DISPLAY_MS));
    Promise.all([this.viewModel.waitForReady(), minDelay])
      .then(() => {
        if (this.settled) {
          return;
        }
        this.settled = true;
        this.clearTimeout();
        Logger.info(TAG, 'core ready, navigate to Main');
        RouterUtil.replace(AppRoutes.MAIN);
      })
      .catch((error: Error) => {
        if (this.settled) {
          return;
        }
        this.settled = true;
        this.clearTimeout();
        Logger.error(TAG, `core init failed: ${error.message}`);
        this.initFailed = true;
      });
  }

  /** 重试：重新触发 Core 初始化（仍在进行中则复用同一任务），并重新计时 */
  private onRetry(): void {
    const ctx = this.getUIContext().getHostContext() as common.UIAbilityContext;
    this.viewModel.retryInit(ctx).catch((_e: Error) => {});
    this.startBootstrap(ctx);
  }

  private clearTimeout(): void {
    if (this.timeoutId !== -1) {
      clearTimeout(this.timeoutId);
      this.timeoutId = -1;
    }
  }

  build() {
    NavDestination() {
      Column({ space: this.tm.current.font16 }) {
        Image($r('app.media.ic_app_logo'))
          .width(this.tm.current.value120)
          .height(this.tm.current.value120)
          .borderRadius(this.tm.current.value28)
          .scale({ x: this.logoScale, y: this.logoScale })
          .opacity(this.logoOpacity)

        Text($r('app.string.app_display_name'))
          .font(ThemeFonts.FONT_BOLD_26)
          .fontColor(this.tm.current.colorTextPrimary)
          .opacity(this.logoOpacity)

        Text($r('app.string.launch_subtitle'))
          .font(ThemeFonts.FONT_14)
          .fontColor(this.tm.current.colorTextSecondary)
          .opacity(this.logoOpacity)

        if (this.initFailed) {
          Text($r('app.string.launch_init_failed_title'))
            .id('launch_init_failed_title')
            .font(ThemeFonts.FONT_BOLD_16)
            .fontColor(this.tm.current.colorTextPrimary)
            .margin({ top: this.tm.current.value16 })

          Text($r('app.string.launch_init_failed_desc'))
            .id('launch_init_failed_desc')
            .font(ThemeFonts.FONT_14)
            .fontColor(this.tm.current.colorTextSecondary)
            .textAlign(TextAlign.Center)
            .padding({ left: this.tm.current.value32, right: this.tm.current.value32 })

          Button($r('app.string.launch_retry'))
            .id('launch_retry')
            .type(ButtonType.Capsule)
            .height(this.tm.current.value44)
            .padding({ left: this.tm.current.value24, right: this.tm.current.value24 })
            .backgroundColor(this.tm.current.colorPrimary)
            .fontColor(Color.White)
            .fontSize(this.tm.current.font14)
            .margin({ top: this.tm.current.value8 })
            .onClick(() => {
              this.onRetry();
            })
        }
      }
      .width(this.tm.current.full)
      .height(this.tm.current.full)
      .justifyContent(FlexAlign.Center)
      .alignItems(HorizontalAlign.Center)
    }
    .hideTitleBar(true)
    .backgroundColor($r('app.color.dark_400'))
    .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM])
  }
}
