/**
 * LoginPhone.ets — 手机号 + 短信验证码登录组件
 */
import { MmtData, GeetestCreateResult } from 'core'
import { LoginViewModel } from '../../viewmodel/LoginViewModel'
import { PhoneStep } from '../../constants/LoginTabEnum'
import { showGeetestDialog } from '../GeetestDialog'
import { themeManager, ThemeManager } from '../../theme/ThemeManager'
import { LoginPhoneInput } from './LoginPhoneInput'
import { LoginCodeInput } from './LoginCodeInput'
import { Logger } from '../../utils/Logger'

const TAG: string = 'LoginPhone'

@ComponentV2
export struct LoginPhone {
  @Param vm: LoginViewModel = new LoginViewModel()
  @Local private tm: ThemeManager = themeManager
  private uiContext: UIContext | null = null

  aboutToAppear(): void {
    this.uiContext = this.getUIContext()
  }

  build() {
    Column({ space: this.tm.current.value16 }) {
      if (this.vm.phoneStep === PhoneStep.INPUT_PHONE) {
        LoginPhoneInput({
          tm: this.tm,
          vm: this.vm,
          onSendSms: () => { this.handleSendSms() }
        })
      } else {
        LoginCodeInput({
          tm: this.tm,
          vm: this.vm,
          onResendSms: () => { this.handleSendSms() }
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

  private handleSendSms(): void {
    this.vm.prepareSendSms().then((mmt: MmtData) => {
      if (mmt.use_v4 !== true && mmt.gt === undefined) {
        this.vm.sendSmsCode()
        return
      }
      if (this.uiContext === null) {
        Logger.error(TAG, 'uiContext is null')
        return
      }
      const createResult: GeetestCreateResult = {
        gt: mmt.gt ?? '',
        challenge: mmt.challenge,
        risk_type: mmt.risk_type,
        new_captcha: mmt.new_captcha === 1
      }
      showGeetestDialog(this.uiContext, createResult).then((verifyInput) => {
        if (verifyInput === null) { return }
        this.vm.sendSmsCode(
          undefined,
          verifyInput.geetest_challenge,
          verifyInput.geetest_validate,
          verifyInput.geetest_seccode
        )
      }).catch((e: Error) => {
        Logger.error(TAG, 'showGeetestDialog failed: ' + e.message)
      })
    }).catch((e: Error) => {
      Logger.error(TAG, 'prepareSendSms failed: ' + e.message)
    })
  }
}
