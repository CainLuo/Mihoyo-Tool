/**
 * LoginPhone.ets — 手机号 + 短信验证码登录组件
 */
import { LoginViewModel } from '../viewmodel/LoginViewModel';
import { ThemeFonts, themeManager, ThemeManager } from 'basic'
import { PhoneStep } from '../constants/LoginConstants';
import { LoginPhoneInput } from './LoginPhoneInput';
import { LoginCodeInput } from './LoginCodeInput';

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

      if (this.vm.errorMsg.length > 0) {
        Text(this.vm.errorMsg)
          .font(ThemeFonts.FONT_14)
          .fontColor(this.tm.current.colorDanger)
          .width(this.tm.current.full)
          .textAlign(TextAlign.Center)
      }
    }
    .width(this.tm.current.full)
  }
}
