/**
 * LoginCookie.ets — 手动输入 Cookie 登录组件
 */

import { LoginViewModel } from '../../viewmodel/LoginViewModel';
import { themeManager, ThemeManager } from '../../theme/ThemeManager';

@ComponentV2
export struct LoginCookie {
  @Param vm: LoginViewModel = new LoginViewModel();
  @Local private tm: ThemeManager = themeManager;

  build() {
    Column({ space: this.tm.current.value16 }) {
      Text($r('app.string.login_cookie_hint'))
        .font(this.tm.current.body13)
        .fontColor(this.tm.current.colorTextSecondary)
        .width(this.tm.current.widthFull)
        .textAlign(TextAlign.Center)

      TextArea({ placeholder: $r('app.string.login_cookie_placeholder'), text: this.vm.cookieInput })
        .width(this.tm.current.widthFull)
        .height(this.tm.current.heightTextArea)
        .borderRadius(this.tm.current.radius8)
        .borderWidth(this.tm.current.cardBorderWidth)
        .borderColor(this.tm.current.colorCardBorder)
        .backgroundColor(this.tm.current.colorCardBg)
        .placeholderColor(this.tm.current.colorPlaceholder)
        .onChange((val: string) => {
          this.vm.cookieInput = val;
        })

      Button($r('app.string.login_button'), { type: ButtonType.Capsule })
        .width(this.tm.current.widthFull)
        .height(this.tm.current.heightButton)
        .backgroundColor(this.tm.current.colorPrimary)
        .enabled(!this.vm.isLoading && this.vm.cookieInput.trim().length > 0)
        .onClick(() => {
          this.vm.loginByCookie();
        })

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
}
