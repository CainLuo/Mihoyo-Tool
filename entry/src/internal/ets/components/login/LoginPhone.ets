/**
 * LoginPhone.ets — 手机号 + 短信验证码登录组件（仅 internal）
 */
import { LoginViewModel } from 'entry/ets/viewmodel/LoginViewModel';
import { PhoneStep } from 'entry/ets/constants/LoginTabEnum';
import { themeManager, ThemeManager } from 'entry/ets/theme/ThemeManager';
import { LoginPhoneInput } from 'entry/ets/components/login/LoginPhoneInput';
import { LoginCodeInput } from 'entry/ets/components/login/LoginCodeInput';

@ComponentV2
export struct LoginPhone {
  @Param vm: LoginViewModel = new LoginViewModel();
  @Local private tm: ThemeManager = themeManager;

  build() {
    Column({ space: this.tm.current.value16 }) {
      if (this.vm.phoneStep === PhoneStep.INPUT_PHONE) {
        LoginPhoneInput({
          vm: this.vm,
          onSendSms: () => { this.vm.sendSmsCode() }
        })
      } else {
        LoginCodeInput({
          vm: this.vm,
          onResendSms: () => { this.vm.sendSmsCode() }
        })
      }

      if (this.vm.errorMsg.length > 0) {
        Text(this.vm.errorMsg)
          .font(this.tm.current.body13)
          .fontColor(this.tm.current.colorDanger)
          .width(this.tm.current.full)
          .textAlign(TextAlign.Center)
      }
    }
    .width(this.tm.current.full)
  }
}
