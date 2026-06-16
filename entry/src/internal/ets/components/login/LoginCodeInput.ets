/**
 * LoginCodeInput — 验证码输入步骤 UI（仅 internal）
 */
import { themeManager, ThemeManager } from 'entry/ets/theme/ThemeManager';
import { ThemeFonts } from '../../../../../main/ets/theme/ThemeFonts'
import { LoginViewModel } from 'entry/ets/viewmodel/LoginViewModel';

@ComponentV2
export struct LoginCodeInput {
  @Param vm: LoginViewModel = new LoginViewModel();
  @Param onResendSms: () => void = () => {};
  @Local private tm: ThemeManager = themeManager;

  build() {
    Column({ space: this.tm.current.font16 }) {
      Column({ space: this.tm.current.value4 }) {
        Text($r('app.string.login_sms_sent_to_prefix'))
          .font(ThemeFonts.font13)
          .fontColor(this.tm.current.colorTextSecondary)
          .textAlign(TextAlign.Center)
          .width(this.tm.current.full)

        Text(this.vm.maskedPhone)
          .font(ThemeFonts.fontMedium17)
          .fontColor(this.tm.current.colorTextPrimary)
          .textAlign(TextAlign.Center)
          .width(this.tm.current.full)
      }

      Column({ space: this.tm.current.value8 }) {
        Text($r('app.string.login_code_label'))
          .font(ThemeFonts.font13)
          .fontColor(this.tm.current.colorTextSecondary)
          .width(this.tm.current.full)

        TextInput({ placeholder: $r('app.string.login_code_placeholder'), text: this.vm.smsCode })
          .width(this.tm.current.full)
          .height(this.tm.current.value46)
          .borderRadius(this.tm.current.radius8)
          .borderWidth(this.tm.current.value1)
          .borderColor(this.tm.current.colorDivider)
          .backgroundColor(this.tm.current.loginInputBg)
          .placeholderColor(this.tm.current.colorPlaceholder)
          .type(InputType.Number)
          .maxLength(6)
          .onChange((val: string) => { this.vm.smsCode = val })
      }
      .alignItems(HorizontalAlign.Start)

      Button($r('app.string.login_button'), { type: ButtonType.Normal })
        .width(this.tm.current.full)
        .height(this.tm.current.value46)
        .borderRadius(this.tm.current.radius8)
        .backgroundColor(this.tm.current.colorPrimary)
        .fontSize(this.tm.current.value15)
        .fontWeight(FontWeight.Bold)
        .fontColor(this.tm.current.textOnDarkHigh)
        .enabled(!this.vm.isLoading && this.vm.smsCode.length > 0)
        .onClick(() => { this.vm.loginByPhone() })

      Row({ space: this.tm.current.value8 }) {
        Text($r('app.string.login_back_to_phone'))
          .font(ThemeFonts.font14)
          .fontColor(this.tm.current.colorPrimary)
          .onClick(() => { this.vm.backToPhoneInput() })

        if (this.vm.smsCooldown > 0) {
          Text($r('app.string.login_sms_cooldown_seconds', this.vm.smsCooldown))
            .font(ThemeFonts.font14)
            .fontColor(this.tm.current.colorPlaceholder)
        } else {
          Text($r('app.string.login_resend_sms'))
            .font(ThemeFonts.font14)
            .fontColor(this.tm.current.colorPrimary)
            .onClick(() => { this.onResendSms() })
        }
      }
      .width(this.tm.current.full)
      .justifyContent(FlexAlign.SpaceBetween)
    }
    .width(this.tm.current.full)
  }
}
