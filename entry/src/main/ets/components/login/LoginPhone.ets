/**
 * LoginPhone.ets — 手机号 + 短信验证码登录组件
 *
 * 流程：
 *   1. 输入手机号 → 点击"获取验证码"
 *   2. ViewModel.prepareSendSms() → 若 mmt_type=1 则弹 GeetestDialog
 *   3. ViewModel.sendSmsCode() → 进入验证码输入步骤
 *   4. 输入验证码 → ViewModel.loginByPhone()
 */

import { MmtData, GeetestCreateResult } from 'core';
import { LoginViewModel } from '../../viewmodel/LoginViewModel';
import { showGeetestDialog } from '../GeetestDialog';
import { themeManager, ThemeManager } from '../../theme/ThemeManager';
import { Logger } from '../../utils/Logger';

const TAG: string = 'LoginPhone';

@ComponentV2
export struct LoginPhone {
  @Param vm: LoginViewModel = new LoginViewModel();
  @Local private tm: ThemeManager = themeManager;
  private uiContext: UIContext | null = null;

  aboutToAppear(): void {
    this.uiContext = this.getUIContext();
  }

  build() {
    Column({ space: this.tm.current.value16 }) {
      if (this.vm.phoneStep === 'input_phone') {
        this.buildPhoneInput()
      } else {
        this.buildCodeInput()
      }

      // 错误提示
      if (this.vm.errorMsg.length > 0) {
        Text(this.vm.errorMsg)
          .font(this.tm.current.body13)
          .fontColor(this.tm.current.colorDanger)
          .width(this.tm.current.widthFull)
          .textAlign(TextAlign.Center)
      }
    }
    .width(this.tm.current.widthFull)
  }

  @Builder
  private buildPhoneInput() {
    // 手机号输入框
    TextInput({ placeholder: $r('app.string.login_phone_placeholder'), text: this.vm.phoneNumber })
      .width(this.tm.current.widthFull)
      .height(this.tm.current.heightButton)
      .borderRadius(this.tm.current.radius8)
      .borderWidth(this.tm.current.cardBorderWidth)
      .borderColor(this.tm.current.colorCardBorder)
      .backgroundColor(this.tm.current.colorCardBg)
      .placeholderColor(this.tm.current.colorPlaceholder)
      .type(InputType.PhoneNumber)
      .onChange((val: string) => {
        this.vm.phoneNumber = val;
      })

    // 获取验证码按钮
    Button($r('app.string.login_send_sms_button'), { type: ButtonType.Capsule })
      .width(this.tm.current.widthFull)
      .height(this.tm.current.heightButton)
      .backgroundColor(this.tm.current.colorPrimary)
      .enabled(!this.vm.isLoading && this.vm.phoneNumber.length > 0)
      .onClick(() => {
        this.handleSendSms();
      })
  }

  @Builder
  private buildCodeInput() {
    // 提示文字
    Text($r('app.string.login_sms_sent_hint'))
      .font(this.tm.current.body13)
      .fontColor(this.tm.current.colorTextSecondary)
      .width(this.tm.current.widthFull)
      .textAlign(TextAlign.Center)

    // 验证码输入框
    TextInput({ placeholder: $r('app.string.login_code_placeholder'), text: this.vm.smsCode })
      .width(this.tm.current.widthFull)
      .height(this.tm.current.heightButton)
      .borderRadius(this.tm.current.radius8)
      .borderWidth(this.tm.current.cardBorderWidth)
      .borderColor(this.tm.current.colorCardBorder)
      .backgroundColor(this.tm.current.colorCardBg)
      .placeholderColor(this.tm.current.colorPlaceholder)
      .type(InputType.Number)
      .maxLength(6)
      .onChange((val: string) => {
        this.vm.smsCode = val;
      })

    // 登录按钮
    Button($r('app.string.login_button'), { type: ButtonType.Capsule })
      .width(this.tm.current.widthFull)
      .height(this.tm.current.heightButton)
      .backgroundColor(this.tm.current.colorPrimary)
      .enabled(!this.vm.isLoading && this.vm.smsCode.length > 0)
      .onClick(() => {
        this.vm.loginByPhone();
      })

    // 重新发送 / 倒计时
    Row({ space: this.tm.current.value8 }) {
      Text($r('app.string.login_back_to_phone'))
        .font(this.tm.current.body13)
        .fontColor(this.tm.current.colorPrimary)
        .onClick(() => {
          this.vm.backToPhoneInput();
        })

      if (this.vm.smsCooldown > 0) {
        Text(`${this.vm.smsCooldown}s`)
          .font(this.tm.current.body13)
          .fontColor(this.tm.current.colorPlaceholder)
      } else {
        Text($r('app.string.login_resend_sms'))
          .font(this.tm.current.body13)
          .fontColor(this.tm.current.colorPrimary)
          .onClick(() => {
            this.handleSendSms();
          })
      }
    }
    .width(this.tm.current.widthFull)
    .justifyContent(FlexAlign.SpaceBetween)
  }

  private handleSendSms(): void {
    this.vm.prepareSendSms().then((mmt: MmtData) => {
      // mmt_type=0：无需 Geetest，直接发短信
      if (mmt.use_v4 !== true && mmt.gt === undefined) {
        this.vm.sendSmsCode();
        return;
      }
      // mmt_type=1：需要 Geetest 验证
      if (this.uiContext === null) {
        Logger.error(TAG, 'uiContext is null');
        return;
      }
      const createResult: GeetestCreateResult = {
        gt: mmt.gt ?? '',
        challenge: mmt.challenge,
        risk_type: mmt.risk_type,
        new_captcha: mmt.new_captcha === 1
      };
      showGeetestDialog(this.uiContext, createResult).then((verifyInput) => {
        if (verifyInput === null) {
          return;
        }
        if (mmt.use_v4 === true) {
          // v4 验证结果格式不同，此处简化处理：v4 结果通过 challenge/validate/seccode 传递
          this.vm.sendSmsCode(
            undefined,
            verifyInput.geetest_challenge,
            verifyInput.geetest_validate,
            verifyInput.geetest_seccode
          );
        } else {
          this.vm.sendSmsCode(
            undefined,
            verifyInput.geetest_challenge,
            verifyInput.geetest_validate,
            verifyInput.geetest_seccode
          );
        }
      }).catch((e: Error) => {
        Logger.error(TAG, 'showGeetestDialog failed: ' + e.message);
      });
    }).catch((e: Error) => {
      Logger.error(TAG, 'prepareSendSms failed: ' + e.message);
    });
  }
}
