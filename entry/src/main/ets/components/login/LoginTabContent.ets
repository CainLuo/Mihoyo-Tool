/**
 * LoginTabContent — 登录 Tab 内容区（release 版，无手机号分支）
 */
import { themeManager, ThemeManager } from '../../theme/ThemeManager';
import { LoginViewModel } from 'entry/ets/viewmodel/LoginViewModel';
import { LoginTab } from '../../constants/LoginTabEnum';
import { LoginQRCode } from './LoginQRCode';
import { LoginCookie } from './LoginCookie';

@ComponentV2
export struct LoginTabContent {
  @Param vm: LoginViewModel = new LoginViewModel();
  @Local private tm: ThemeManager = themeManager;

  build() {
    Column() {
      if (this.vm.activeTab === LoginTab.QRCODE) {
        LoginQRCode({ vm: this.vm })
      } else {
        LoginCookie({ vm: this.vm })
      }
    }
    .width(this.tm.current.full)
  }
}
