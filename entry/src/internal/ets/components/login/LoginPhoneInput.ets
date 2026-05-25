/**
 * LoginPhoneInput — 手机号输入步骤 UI（仅 internal）
 */
import { themeManager, ThemeManager } from 'entry/ets/theme/ThemeManager';
import { ThemeFonts } from '../../../../../main/ets/theme/ThemeFonts'
import { LoginViewModel } from 'entry/ets/viewmodel/LoginViewModel';

@ComponentV2
export struct LoginPhoneInput {
  @Param vm: LoginViewModel = new LoginViewModel();
  @Param onSendSms: () => void = () => {};
  @Local private tm: ThemeManager = themeManager;

  build() {
    Column({ space: this.tm.current.font16 }) {
      Column({ space: this.tm.current.value8 }) {
        Text($r('app.string.login_phone_label'))
          .font(ThemeFonts.font13)
          .fontColor(this.tm.current.colorTextSecondary)
          .width(this.tm.current.full)

        TextInput({ placeholder: $r('app.string.login_phone_placeholder'), text: this.vm.phoneNumber })
          .width(this.tm.current.full)
          .height(this.tm.current.value46)
          .borderRadius(this.tm.current.radius8)
          .borderWidth(this.tm.current.value1)
          .borderColor(this.tm.current.colorDivider)
          .backgroundColor(this.tm.current.loginInputBg)
          .placeholderColor(this.tm.current.colorPlaceholder)
          .type(InputType.PhoneNumber)
          .onChange((val: string) => { this.vm.phoneNumber = val })
      }
      .alignItems(HorizontalAlign.Start)

      Button($r('app.string.login_send_sms_button'), { type: ButtonType.Normal })
        .width(this.tm.current.full)
        .height(this.tm.current.value46)
        .borderRadius(this.tm.current.radius8)
        .backgroundColor(this.tm.current.colorPrimary)
        .fontSize(this.tm.current.value15)
        .fontWeight(FontWeight.Bold)
        .fontColor(this.tm.current.textOnDarkHigh)
        .enabled(!this.vm.isLoading && this.vm.phoneNumber.length > 0)
        .onClick(() => { this.onSendSms() })

      Text($r('app.string.login_phone_hint'))
        .font(ThemeFonts.font13)
        .fontColor(this.tm.current.colorPlaceholder)
        .width(this.tm.current.full)
        .textAlign(TextAlign.Center)
    }
    .width(this.tm.current.full)
  }
}
