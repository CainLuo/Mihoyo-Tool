/**
 * PrivacyConsentFooter — 隐私合规页底部操作区
 *
 * 步骤一：「下一步」按钮（未读完时禁用）
 * 步骤二：「同意并继续」+ 「不同意，退出」（未读完时均禁用）
 */
import { themeManager, ThemeManager } from '../../theme/ThemeManager';

@ComponentV2
export struct PrivacyConsentFooter {
  @Param step: string = 'terms';
  @Param canProceed: boolean = false;
  @Event onNext: () => void = () => {};
  @Event onAgree: () => void = () => {};
  @Event onDisagree: () => void = () => {};
  @Local private tm: ThemeManager = themeManager;

  build() {
    Column({ space: this.tm.current.value8 }) {
      if (!this.canProceed) {
        Text($r('app.string.privacy_consent_scroll_hint'))
          .font(this.tm.current.body12)
          .fontColor(this.tm.current.colorTextSecondary)
          .textAlign(TextAlign.Center)
          .width(this.tm.current.full)
      }

      if (this.step === 'terms') {
        Button($r('app.string.privacy_consent_next'), { type: ButtonType.Normal })
          .width(this.tm.current.full)
          .height(this.tm.current.value46)
          .borderRadius(this.tm.current.radius8)
          .backgroundColor(this.canProceed
            ? this.tm.current.colorPrimary
            : this.tm.current.colorSurfaceSubtle)
          .fontSize(this.tm.current.body15Bold.size)
          .fontWeight(this.tm.current.body15Bold.weight)
          .fontColor(this.canProceed
            ? this.tm.current.textOnDarkHigh
            : this.tm.current.colorTextSecondary)
          .enabled(this.canProceed)
          .onClick(() => { this.onNext(); })
      } else {
        Button($r('app.string.privacy_consent_agree'), { type: ButtonType.Normal })
          .width(this.tm.current.full)
          .height(this.tm.current.value46)
          .borderRadius(this.tm.current.radius8)
          .backgroundColor(this.canProceed
            ? this.tm.current.colorPrimary
            : this.tm.current.colorSurfaceSubtle)
          .fontSize(this.tm.current.body15Bold.size)
          .fontWeight(this.tm.current.body15Bold.weight)
          .fontColor(this.canProceed
            ? this.tm.current.textOnDarkHigh
            : this.tm.current.colorTextSecondary)
          .enabled(this.canProceed)
          .onClick(() => { this.onAgree(); })

        Button($r('app.string.privacy_consent_disagree'), { type: ButtonType.Normal })
          .width(this.tm.current.full)
          .height(this.tm.current.value40)
          .borderRadius(this.tm.current.radius8)
          .backgroundColor(Color.Transparent)
          .fontSize(this.tm.current.body13.size)
          .fontColor(this.canProceed
            ? this.tm.current.colorTextSecondary
            : this.tm.current.colorSurfaceSubtle)
          .enabled(this.canProceed)
          .onClick(() => { this.onDisagree(); })
      }
    }
    .width(this.tm.current.full)
    .padding(this.tm.current.value16)
    .border({ width: { top: this.tm.current.value1 }, color: this.tm.current.colorDivider })
  }
}

// ─── Preview ─────────────────────────────────────────────────────

@Preview
@ComponentV2
export struct PrivacyConsentFooterPreview {
  @Local private tm: ThemeManager = themeManager;

  build() {
    Column({ space: this.tm.current.value16 }) {
      PrivacyConsentFooter({ step: 'terms', canProceed: false })

      PrivacyConsentFooter({ step: 'terms', canProceed: true })

      PrivacyConsentFooter({ step: 'privacy', canProceed: false })

      PrivacyConsentFooter({ step: 'privacy', canProceed: true })
    }
    .padding(this.tm.current.value16)
    .backgroundColor('#1a1a2e')
  }
}
