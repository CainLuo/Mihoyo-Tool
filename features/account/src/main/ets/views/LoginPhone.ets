/**
 * LoginPhone.ets — 手机号 + 短信验证码登录组件
 */
import { LoginViewModel } from '../viewmodel/LoginViewModel';
import { themeManager, ThemeManager } from 'basic'
import { PhoneStep } from '../constants/LoginConstants';
import { LoginPhoneInput } from './LoginPhoneInput';
import { LoginCodeInput } from './LoginCodeInput';
import { LoginErrorText } from './LoginErrorText';

@ComponentV2
export struct LoginPhone {
  @Param vm: LoginViewModel = new LoginViewModel();
  @Local private tm: ThemeManager = themeManager;

  build() {
    Column({ space: this.tm.current.font16 }) {
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

      LoginErrorText({ message: this.vm.errorMsg })
    }
    .width(this.tm.current.full)
  }
}
