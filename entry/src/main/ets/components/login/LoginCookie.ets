/**
 * LoginCookie.ets — 手动输入 Cookie 登录组件
 */

import { LoginViewModel } from 'entry/ets/viewmodel/LoginViewModel';
import { ThemeFonts } from '../../theme/ThemeFonts';
import { themeManager, ThemeManager } from '../../theme/ThemeManager';
import { PrimaryButtonModifier } from '../../styles/ButtonModifier';

@ComponentV2
export struct LoginCookie {
  @Param vm: LoginViewModel = new LoginViewModel();
  @Local private tm: ThemeManager = themeManager;
  @Local private buttonModifier: PrimaryButtonModifier = new PrimaryButtonModifier(true);

  build() {
    Column({ space: this.tm.current.font16 }) {
      // Cookie 输入框
      Column({ space: this.tm.current.value8 }) {
        Text($r('app.string.login_cookie_label'))
          .font(ThemeFonts.font13)
          .fontColor(this.tm.current.colorTextSecondary)
          .width(this.tm.current.full)

        // 操作说明
        Text($r('app.string.login_cookie_hint'))
          .font(ThemeFonts.font11)
          .fontColor(this.tm.current.colorPlaceholder)
          .width(this.tm.current.full)

        TextArea({ placeholder: $r('app.string.login_cookie_placeholder'), text: $$this.vm.cookieInput })
          .width(this.tm.current.full)
          .height(this.tm.current.value108)
          .borderRadius(this.tm.current.radius8)
          .borderWidth(this.tm.current.value1)
          .borderColor(this.tm.current.colorDivider)
          .backgroundColor(this.tm.current.loginInputBg)
          .placeholderColor(this.tm.current.colorPlaceholder)
      }
      .alignItems(HorizontalAlign.Start)

      // 确认登录按钮
      Button($r('app.string.login_button'), { type: ButtonType.Normal })
        .attributeModifier(this.buttonModifier)
        .width(this.tm.current.full)
        .enabled(!this.vm.isLoading && this.vm.cookieInput.trim().length > 0)
        .onClick(() => {
          this.vm.loginByCookie();
        })

      // 安全提示
      Text($r('app.string.login_cookie_security_hint'))
        .font(ThemeFonts.font13)
        .fontColor(this.tm.current.colorPlaceholder)
        .width(this.tm.current.full)
        .textAlign(TextAlign.Center)

      // 错误提示
      if (this.vm.errorMsg.length > 0) {
        Text(this.vm.errorMsg)
          .font(ThemeFonts.font14)
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
    .padding(this.tm.current.font16)
    .backgroundColor('#1a1a2e')
  }
}
