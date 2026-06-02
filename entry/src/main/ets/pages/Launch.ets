/**
 * Launch.ets — 启动页
 *
 * 职责：
 *   - 展示 App Logo + 名称动画
 *   - 等待 Core 初始化完成（含 DB 初始化、Mock 数据填充）
 *   - 直接 replace 到 Main（Main 内部负责判断是否需要登录）
 *
 * 路由：Navigation 入口页，由 Index.ets 通过 initialStack 指定。
 */

import { CoreInitializer } from 'core';
import { ThemeFonts } from '../theme/ThemeFonts'
import { AppRoutes } from '../constants/AppRoutes';
import { RouterUtil } from '../utils/RouterUtil';
import { themeManager, ThemeManager } from '../theme/ThemeManager';
import { Logger } from 'core';
import { common } from '@kit.AbilityKit';
import { LegalPreferences } from '../utils/LegalPreferences';

const TAG: string = 'Launch';

@ComponentV2
export struct Launch {
  @Local private tm: ThemeManager = themeManager;
  @Local private logoScale: number = 0.8;
  @Local private logoOpacity: number = 0;
  private uiCtx: UIContext | null = null;

  aboutToAppear(): void {
    this.uiCtx = this.getUIContext();
    // 入场动画：Logo 淡入 + 放大
    this.uiCtx.animateTo({ duration: 600, curve: Curve.EaseOut }, () => {
      this.logoScale = 1.0;
      this.logoOpacity = 1.0;
    });
    this.checkPrivacyAndProceed();
  }

  private checkPrivacyAndProceed(): void {
    const ctx = this.getUIContext().getHostContext() as common.UIAbilityContext;
    const agreed = LegalPreferences.hasAgreed(ctx);
    if (agreed) {
      this.navigateToMain();
    } else {
      // 未同意：replace 到合规流程页，不保留 Launch 在返回栈
      RouterUtil.replace(AppRoutes.PRIVACY_CONSENT);
    }
  }

  private navigateToMain(): void {
    // 等 Core 就绪 + 最短展示 1200ms，两者取最长
    const minDelay = new Promise<void>((resolve) => setTimeout(resolve, 1200));
    Promise.all([CoreInitializer.waitForReady(), minDelay])
      .then(() => {
        Logger.info(TAG, 'core ready, navigate to Main');
        RouterUtil.replace(AppRoutes.MAIN);
      })
      .catch((error: Error) => {
        Logger.error(TAG, `navigateToMain failed: ${error.message}`);
        RouterUtil.replace(AppRoutes.MAIN);
      });
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

        Text($r('app.string.app_name'))
          .font(ThemeFonts.fontBold26)
          .fontColor(this.tm.current.colorTextPrimary)
          .opacity(this.logoOpacity)

        Text($r('app.string.launch_subtitle'))
          .font(ThemeFonts.font14)
          .fontColor(this.tm.current.colorTextSecondary)
          .opacity(this.logoOpacity)
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
