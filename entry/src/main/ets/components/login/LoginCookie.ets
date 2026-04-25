/**
 * LoginCookie.ets — 手动输入 Cookie 登录组件
 */

import { LoginViewModel } from 'entry/ets/viewmodel/LoginViewModel';
import { themeManager, ThemeManager } from '../../theme/ThemeManager';

@ComponentV2
export struct LoginCookie {
  @Param vm: LoginViewModel = new LoginViewModel();
  @Local private tm: ThemeManager = themeManager;

  build() {
    Column({ space: this.tm.current.value16 }) {
      // Cookie 输入框
      Column({ space: this.tm.current.value8 }) {
        Text($r('app.string.login_cookie_label'))
          .font(this.tm.current.body12)
          .fontColor(this.tm.current.colorTextSecondary)
          .width(this.tm.current.full)

        // 操作说明
        Text($r('app.string.login_cookie_hint'))
          .font(this.tm.current.body10)
          .fontColor(this.tm.current.colorPlaceholder)
          .width(this.tm.current.full)

        TextArea({ placeholder: $r('app.string.login_cookie_placeholder'), text: this.vm.cookieInput })
          .width(this.tm.current.full)
          .height(this.tm.current.value108)
          .borderRadius(this.tm.current.radius8)
          .borderWidth(this.tm.current.value1)
          .borderColor(this.tm.current.colorDivider)
          .backgroundColor(this.tm.current.loginInputBg)
          .placeholderColor(this.tm.current.colorPlaceholder)
          .onChange((val: string) => {
            this.vm.cookieInput = val;
          })
      }
      .alignItems(HorizontalAlign.Start)

      // 确认登录按钮
      Button($r('app.string.login_button'), { type: ButtonType.Normal })
        .width(this.tm.current.full)
        .height(this.tm.current.value46)
        .borderRadius(this.tm.current.radius8)
        .backgroundColor(this.tm.current.colorPrimary)
        .fontSize(this.tm.current.value15)
        .fontWeight(FontWeight.Bold)
        .fontColor(this.tm.current.textOnDarkHigh)
        .enabled(!this.vm.isLoading && this.vm.cookieInput.trim().length > 0)
        .onClick(() => {
          this.vm.loginByCookie();
        })

      // 安全提示
      Text($r('app.string.login_cookie_security_hint'))
        .font(this.tm.current.body12)
        .fontColor(this.tm.current.colorPlaceholder)
        .width(this.tm.current.full)
        .textAlign(TextAlign.Center)

      // 错误提示
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

// ─── Preview ─────────────────────────────────────────────────────

@Preview
@ComponentV2
export struct LoginCookiePreview {
  @Local private tm: ThemeManager = themeManager;

  build() {
    Column() {
      LoginCookie({ vm: new LoginViewModel() })
    }
    .padding(this.tm.current.value16)
    .backgroundColor('#1a1a2e')
  }
}
