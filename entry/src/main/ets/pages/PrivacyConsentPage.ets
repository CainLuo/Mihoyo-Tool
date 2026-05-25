/**
 * PrivacyConsentPage — 首屏隐私合规流程页（全屏 Splash Screen 样式）
 *
 * 两步流程：
 *   步骤一：用户协议 → 滑到底部后「下一步」Enable
 *   步骤二：隐私政策 → 滑到底部后「同意并继续」和「不同意，退出」Enable
 */
import { common } from '@kit.AbilityKit';
import { ThemeFonts } from '../theme/ThemeFonts'
import { BusinessError } from '@kit.BasicServicesKit';
import { themeManager, ThemeManager } from '../theme/ThemeManager';
import { PrivacyConsentViewModel } from '../viewmodel/PrivacyConsentViewModel';
import { LegalI18nRouter } from '../utils/LegalI18nRouter';
import { LegalPreferences } from '../utils/LegalPreferences';
import { RouterUtil } from '../utils/RouterUtil';
import { AppRoutes } from '../constants/AppRoutes';
import { Logger } from 'core';
import { PrivacyConsentFooter } from '../components/privacyconsent/PrivacyConsentFooter';
import { PrivacyConsentWebView } from '../components/privacyconsent/PrivacyConsentWebView';

const TAG: string = 'PrivacyConsentPage';

@ComponentV2
export struct PrivacyConsentPage {
  @Local private vm: PrivacyConsentViewModel = new PrivacyConsentViewModel();
  @Local private tm: ThemeManager = themeManager;

  private async handleAgree(): Promise<void> {
    const ctx = this.getUIContext().getHostContext() as common.UIAbilityContext;
    try {
      await LegalPreferences.setAgreed(ctx);
    } catch (e) {
      Logger.error(TAG, `setAgreed failed: ${(e as Error).message}`);
    }
    RouterUtil.replace(AppRoutes.MAIN);
  }

  private handleDisagree(): void {
    const ctx = this.getUIContext().getHostContext() as common.UIAbilityContext;
    ctx.terminateSelf().catch((e: BusinessError) => {
      Logger.error(TAG, `terminateSelf failed: ${e.message}`);
    });
  }

  build() {
    NavDestination() {
      Column() {
        if (this.vm.step === 'terms') {
          PrivacyConsentWebView({
            htmlFile: LegalI18nRouter.termsPath(),
            onReachedBottom: () => { this.vm.markTermsRead(); }
          })
        } else {
          PrivacyConsentWebView({
            htmlFile: LegalI18nRouter.privacyPath(),
            onReachedBottom: () => { this.vm.markPrivacyRead(); }
          })
        }

        PrivacyConsentFooter({
          step: this.vm.step,
          canProceed: this.vm.step === 'terms' ? this.vm.canProceedFromTerms : this.vm.canAgree,
          onNext: () => { this.vm.goToPrivacy(); },
          onAgree: () => { this.handleAgree(); },
          onDisagree: () => { this.handleDisagree(); }
        })
      }
      .width(this.tm.current.full)
      .height(this.tm.current.full)
    }
    .title(this.vm.step === 'terms'
      ? $r('app.string.privacy_consent_terms_title')
      : $r('app.string.privacy_consent_privacy_title'))
    .hideTitleBar(false)
    .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.BOTTOM])
  }
}

// ─── Router Builder ───────────────────────────────────────────────

@Builder
export function PrivacyConsentPageBuilder(_name: string, _param: Object) {
  PrivacyConsentPage()
}

// ─── Preview ─────────────────────────────────────────────────────

@Preview
@ComponentV2
export struct PrivacyConsentPagePreview {
  @Local private tm: ThemeManager = themeManager;

  build() {
    Column() {
      // Web 内容区占位（Preview 不加载真实 Web）
      Column() {
        Text('（协议全文）')
          .font(ThemeFonts.font14)
          .fontColor(this.tm.current.colorTextSecondary)
      }
      .width(this.tm.current.full)
      .layoutWeight(1)
      .justifyContent(FlexAlign.Center)
      .alignItems(HorizontalAlign.Center)
      .backgroundColor(this.tm.current.colorPageBg)

      PrivacyConsentFooter({ step: 'terms', canProceed: false })
    }
    .width(this.tm.current.full)
    .height(this.tm.current.full)
    .backgroundColor(this.tm.current.colorPageBg)
  }
}
