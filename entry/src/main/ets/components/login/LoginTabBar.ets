/**
 * LoginTabBar — 登录方式 Tab 栏
 */
import { ThemeManager } from '../../theme/ThemeManager'
import { LoginViewModel } from '../../viewmodel/LoginViewModel'
import { LoginTab } from '../../constants/LoginTabEnum'
import { LoginTabItem } from './LoginTabItem'

@ComponentV2
export struct LoginTabBar {
  @Param tm: ThemeManager = new ThemeManager()
  @Param vm: LoginViewModel = new LoginViewModel()

  build() {
    Row({ space: this.tm.current.value4 }) {
      LoginTabItem({ tm: this.tm, vm: this.vm, tab: LoginTab.PHONE, label: $r('app.string.login_tab_phone') })
      LoginTabItem({ tm: this.tm, vm: this.vm, tab: LoginTab.QRCODE, label: $r('app.string.login_tab_qrcode') })
      LoginTabItem({ tm: this.tm, vm: this.vm, tab: LoginTab.COOKIE, label: $r('app.string.login_tab_cookie') })
    }
    .width(this.tm.current.widthFull)
    .backgroundColor(this.tm.current.loginTabBarBg)
    .borderRadius(this.tm.current.radius8)
    .padding(this.tm.current.value4)
    .margin({ bottom: this.tm.current.loginTabBarMarginBottom })
  }
}
