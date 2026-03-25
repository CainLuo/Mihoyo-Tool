/**
 * LoginNarrowLayout — 登录页 Phone 单栏布局
 */
import { ThemeManager } from '../../theme/ThemeManager'
import { LoginViewModel } from '../../viewmodel/LoginViewModel'
import { LoginLogoSection } from './LoginLogoSection'
import { LoginCard } from './LoginCard'
import { LoginAgreement } from './LoginAgreement'

@ComponentV2
export struct LoginNarrowLayout {
  @Param tm: ThemeManager = new ThemeManager()
  @Param vm: LoginViewModel = new LoginViewModel()

  build() {
    Scroll() {
      Column({ space: this.tm.current.value20 }) {
        LoginLogoSection({ tm: this.tm, logoSize: this.tm.current.loginLogoSizeSM })
        LoginCard({ tm: this.tm, vm: this.vm })
        LoginAgreement({ tm: this.tm })
      }
      .width(this.tm.current.widthFull)
      .padding({
        left: this.tm.current.value20,
        right: this.tm.current.value20,
        top: this.tm.current.value20,
        bottom: this.tm.current.value40
      })
    }
    .width(this.tm.current.widthFull)
    .layoutWeight(1)
    .align(Alignment.Top)
  }
}
