/**
 * LoginPhone.ets — 手机号 + 短信验证码登录组件
 */
import { LoginViewModel } from '../../viewmodel/LoginViewModel'
import { PhoneStep } from '../../constants/LoginTabEnum'
import { themeManager, ThemeManager } from '../../theme/ThemeManager'
import { LoginPhoneInput } from './LoginPhoneInput'
import { LoginCodeInput } from './LoginCodeInput'

@ComponentV2
export struct LoginPhone {
  @Param vm: LoginViewModel = new LoginViewModel()
  @Local private tm: ThemeManager = themeManager

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
