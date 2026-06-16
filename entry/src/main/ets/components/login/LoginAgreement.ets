/**
 * LoginAgreement — 登录协议文字
 * 点击"用户协议"或"隐私政策"触发对应回调，由父组件负责跳转
 */
import { themeManager, ThemeManager } from '../../theme/ThemeManager';
import { ThemeFonts } from '../../theme/ThemeFonts'

@ComponentV2
export struct LoginAgreement {
  @Event onTapTerms: () => void = () => {};
  @Event onTapPrivacy: () => void = () => {};
  @Local private tm: ThemeManager = themeManager;

  build() {
    Flex({ wrap: FlexWrap.Wrap, justifyContent: FlexAlign.Center }) {
      Text($r('app.string.login_agreement_prefix'))
        .font(ThemeFonts.font13)
        .fontColor(this.tm.current.colorTextSecondary)
        .margin({ right: this.tm.current.value4 })

      Text($r('app.string.login_agreement_terms'))
        .font(ThemeFonts.font13)
        .fontColor(this.tm.current.colorPrimary)
        .margin({ right: this.tm.current.value4 })
        .onClick(() => { this.onTapTerms() })

      Text($r('app.string.login_agreement_and'))
        .font(ThemeFonts.font13)
        .fontColor(this.tm.current.colorTextSecondary)
        .margin({ right: this.tm.current.value4 })

      Text($r('app.string.login_agreement_privacy'))
        .font(ThemeFonts.font13)
        .fontColor(this.tm.current.colorPrimary)
        .onClick(() => { this.onTapPrivacy() })
    }
    .width(this.tm.current.full)
  }
}
