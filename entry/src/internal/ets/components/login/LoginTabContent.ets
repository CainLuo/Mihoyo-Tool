/**
 * LoginTabContent — 登录 Tab 内容区（internal 版，含手机号分支）
 */
import { themeManager, ThemeManager } from 'entry/ets/theme/ThemeManager';
import { LoginViewModel } from 'entry/ets/viewmodel/LoginViewModel';
import { LoginTab } from 'entry/ets/constants/LoginTabEnum';
import { LoginPhone } from 'entry/ets/components/login/LoginPhone';
import { LoginQRCode } from 'entry/ets/components/login/LoginQRCode';
import { LoginCookie } from 'entry/ets/components/login/LoginCookie';

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
