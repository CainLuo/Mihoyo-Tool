/**
 * LoginTabContent — 登录 Tab 内容区（手机号 / 二维码 / Cookie）
 */
import { themeManager, ThemeManager } from '../../theme/ThemeManager';
import { LoginViewModel } from 'entry/ets/viewmodel/LoginViewModel';
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
