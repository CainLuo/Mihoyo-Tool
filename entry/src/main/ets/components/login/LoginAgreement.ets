/**
 * LoginAgreement — 登录协议文字
 * 点击"用户协议"或"隐私政策"触发对应回调，由父组件负责跳转
 */
import { themeManager, ThemeManager } from '../../theme/ThemeManager';

@ComponentV2
export struct LoginAgreement {
  @Event onTapTerms: () => void = () => {};
  @Event onTapPrivacy: () => void = () => {};
  @Local private tm: ThemeManager = themeManager;

  build() {
    Flex({ wrap: FlexWrap.Wrap, justifyContent: FlexAlign.Center }) {
      Text($r('app.string.login_agreement_prefix'))
        .font(this.tm.current.body12)
        .fontColor(this.tm.current.colorTextSecondary)
        .margin({ right: this.tm.current.value4 })

      Text($r('app.string.login_agreement_terms'))
        .font(this.tm.current.body12)
        .fontColor(this.tm.current.colorPrimary)
        .margin({ right: this.tm.current.value4 })
        .onClick(() => { this.onTapTerms() })

      Text($r('app.string.login_agreement_and'))
        .font(this.tm.current.body12)
        .fontColor(this.tm.current.colorTextSecondary)
        .margin({ right: this.tm.current.value4 })

      Text($r('app.string.login_agreement_privacy'))
        .font(this.tm.current.body12)
        .fontColor(this.tm.current.colorPrimary)
        .onClick(() => { this.onTapPrivacy() })
    }
    .width(this.tm.current.full)
  }
}
