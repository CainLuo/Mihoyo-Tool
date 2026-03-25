/**
 * LoginAgreement — 登录协议文字
 */
import { ThemeManager } from '../../theme/ThemeManager'

@ComponentV2
export struct LoginAgreement {
  @Param tm: ThemeManager = new ThemeManager()

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
      Text($r('app.string.login_agreement_and'))
        .font(this.tm.current.body12)
        .fontColor(this.tm.current.colorTextSecondary)
        .margin({ right: this.tm.current.value4 })
      Text($r('app.string.login_agreement_privacy'))
        .font(this.tm.current.body12)
        .fontColor(this.tm.current.colorPrimary)
    }
    .width(this.tm.current.widthFull)
  }
}
