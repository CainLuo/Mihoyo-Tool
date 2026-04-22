/**
 * LoginTabContent — 登录 Tab 内容区（根据 activeTab 切换）
 */
import { themeManager, ThemeManager } from '../../theme/ThemeManager';
import { LoginViewModel } from '../../viewmodel/LoginViewModel';
import { LoginTab } from '../../constants/LoginTabEnum';
import { LoginPhone } from './LoginPhone';
import { LoginQRCode } from './LoginQRCode';
import { LoginCookie } from './LoginCookie';

@ComponentV2
export struct LoginTabContent {
  @Param vm: LoginViewModel = new LoginViewModel();
  @Local private tm: ThemeManager = themeManager;

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
