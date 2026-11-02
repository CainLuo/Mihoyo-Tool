/**
 * PrivacyConsentPage — 首屏隐私合规流程页（全屏 Splash Screen 样式）
 *
 * 两步流程：
 *   步骤一：用户协议 → 滑到底部后「下一步」Enable
 *   步骤二：隐私政策 → 滑到底部后「同意并继续」和「不同意，退出」Enable
 */
import { common } from '@kit.AbilityKit';
import { ThemeFonts, themeManager, ThemeManager, RouterUtil, AppRoutes } from 'basic'
import { BusinessError } from '@kit.BasicServicesKit';
import { PrivacyConsentStep, PrivacyConsentViewModel } from '../viewmodel/PrivacyConsentViewModel';
import { LegalI18nRouter } from '../utils/LegalI18nUtil';
import { LegalPreferences } from '../model/service/LegalPreferences';
import { Logger } from 'core';
import { PrivacyConsentFooter } from '../views/PrivacyConsentFooter';
import { PrivacyConsentWebView } from '../views/PrivacyConsentWebView';

const TAG: string = 'PrivacyConsentPage';

@ComponentV2
export struct PrivacyConsentPage {
  @Local private vm: PrivacyConsentViewModel = new PrivacyConsentViewModel();
  @Local private tm: ThemeManager = themeManager;

  private get isTermsStep(): boolean {
    return this.vm.step === PrivacyConsentStep.TERMS;
  }

  private get currentHtmlFile(): string {
    return this.isTermsStep ? LegalI18nRouter.getTermsPath() : LegalI18nRouter.getPrivacyPath();
  }

  private get canProceed(): boolean {
    return this.isTermsStep ? this.vm.canProceedFromTerms : this.vm.canAgree;
  }

  private get currentTitle(): ResourceStr {
    return this.isTermsStep
      ? $r('app.string.privacy_consent_terms_title')
      : $r('app.string.privacy_consent_privacy_title');
  }

  private handleReachedBottom(): void {
    if (this.isTermsStep) {
      this.vm.markTermsRead();
    } else {
      this.vm.markPrivacyRead();
    }
  }

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
        if (this.isTermsStep) {
          PrivacyConsentWebView({
            htmlFile: this.currentHtmlFile,
            onReachedBottom: () => { this.handleReachedBottom(); }
          })
        } else {
          PrivacyConsentWebView({
            htmlFile: this.currentHtmlFile,
            onReachedBottom: () => { this.handleReachedBottom(); }
          })
        }

        PrivacyConsentFooter({
          step: this.vm.step,
          canProceed: this.canProceed,
          onNext: () => { this.vm.goToPrivacy(); },
          onAgree: () => { this.handleAgree(); },
          onDisagree: () => { this.handleDisagree(); }
        })
      }
      .width(this.tm.current.full)
      .height(this.tm.current.full)
    }
    .title(this.currentTitle)
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
          .font(ThemeFonts.FONT_14)
          .fontColor(this.tm.current.colorTextSecondary)
      }
      .width(this.tm.current.full)
      .layoutWeight(1)
      .justifyContent(FlexAlign.Center)
      .alignItems(HorizontalAlign.Center)
      .backgroundColor(this.tm.current.colorPageBg)

      PrivacyConsentFooter({ step: PrivacyConsentStep.TERMS, canProceed: false })
    }
    .width(this.tm.current.full)
    .height(this.tm.current.full)
    .backgroundColor(this.tm.current.colorPageBg)
  }
}
