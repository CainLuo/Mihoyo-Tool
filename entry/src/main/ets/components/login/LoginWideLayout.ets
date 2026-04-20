/**
 * LoginWideLayout — 登录页宽屏两栏布局
 */
import { ThemeManager } from '../../theme/ThemeManager'
import { LoginViewModel } from '../../viewmodel/LoginViewModel'
import { LoginLogoSection } from './LoginLogoSection'
import { LoginFeatureItem } from './LoginFeatureItem'
import { LoginCard } from './LoginCard'
import { LoginAgreement } from './LoginAgreement'

@ComponentV2
export struct LoginWideLayout {
  @Param tm: ThemeManager = new ThemeManager()
  @Param vm: LoginViewModel = new LoginViewModel()
  @Event onTapTerms: () => void = () => {}
  @Event onTapPrivacy: () => void = () => {}

  build() {
    Row({ space: this.tm.current.value48 }) {
      Column({ space: this.tm.current.value16 }) {
        LoginLogoSection({ tm: this.tm, logoSize: this.tm.current.value56 })
        Text($r('app.string.login_brand_desc'))
          .font(this.tm.current.body13)
          .fontColor(this.tm.current.colorTextSecondary)
        Column({ space: this.tm.current.value8 }) {
          LoginFeatureItem({ tm: this.tm, label: $r('app.string.login_brand_feature1') })
          LoginFeatureItem({ tm: this.tm, label: $r('app.string.login_brand_feature2') })
        }
        .alignItems(HorizontalAlign.Start)
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)
      .justifyContent(FlexAlign.Center)

      Column({ space: this.tm.current.value16 }) {
        Text($r('app.string.login_title'))
          .font(this.tm.current.title18Bold)
          .fontColor(this.tm.current.colorTextPrimary)
          .width(this.tm.current.full)
        LoginCard({ tm: this.tm, vm: this.vm })
        LoginAgreement({ tm: this.tm, onTapTerms: this.onTapTerms, onTapPrivacy: this.onTapPrivacy })
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)
      .justifyContent(FlexAlign.Center)
    }
    .width(this.tm.current.full)
    .layoutWeight(1)
    .padding({
      left: this.tm.current.value40,
      right: this.tm.current.value40,
      top: this.tm.current.value40,
      bottom: this.tm.current.value40
    })
    .justifyContent(FlexAlign.Center)
    .alignItems(VerticalAlign.Center)
  }
}
