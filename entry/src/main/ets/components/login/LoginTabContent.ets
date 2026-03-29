/**
 * LoginTabContent — 登录 Tab 内容区（根据 activeTab 切换）
 */
import { ThemeManager } from '../../theme/ThemeManager'
import { LoginViewModel } from '../../viewmodel/LoginViewModel'
import { LoginTab } from '../../constants/LoginTabEnum'
import { LoginPhone } from './LoginPhone'
import { LoginQRCode } from './LoginQRCode'
import { LoginCookie } from './LoginCookie'

@ComponentV2
export struct LoginTabContent {
  @Param tm: ThemeManager = new ThemeManager()
  @Param vm: LoginViewModel = new LoginViewModel()

  build() {
    Column() {
      if (this.vm.activeTab === LoginTab.PHONE) {
        LoginPhone({ vm: this.vm })
      } else if (this.vm.activeTab === LoginTab.QRCODE) {
        LoginQRCode({ vm: this.vm })
      } else {
        LoginCookie({ vm: this.vm })
      }
    }
    .width(this.tm.current.full)
  }
}
