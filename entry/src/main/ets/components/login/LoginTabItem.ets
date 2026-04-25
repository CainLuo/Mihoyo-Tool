/**
 * LoginTabItem — 登录 Tab 切换项
 */
import { themeManager, ThemeManager } from '../../theme/ThemeManager';
import { LoginTab } from '../../constants/LoginTabEnum';
import { LoginViewModel } from 'entry/ets/viewmodel/LoginViewModel';

@ComponentV2
export struct LoginTabItem {
  @Param vm: LoginViewModel = new LoginViewModel();
  @Param tab: LoginTab = LoginTab.PHONE;
  @Param label: Resource = $r('app.string.login_tab_phone');
  @Local private tm: ThemeManager = themeManager;

  build() {
    Text(this.label)
      .font(this.tm.current.body13)
      .fontColor(this.vm.activeTab === this.tab
        ? this.tm.current.textOnDarkHigh
        : this.tm.current.colorTextSecondary)
      .fontWeight(this.vm.activeTab === this.tab ? FontWeight.Bold : FontWeight.Normal)
      .backgroundColor(this.vm.activeTab === this.tab
        ? this.tm.current.colorPrimary
        : this.tm.current.colorTransparent)
      .borderRadius(this.tm.current.radius8)
      .padding({
        left: this.tm.current.value12,
        right: this.tm.current.value12,
        top: this.tm.current.value8,
        bottom: this.tm.current.value8
      })
      .layoutWeight(1)
      .textAlign(TextAlign.Center)
      .onClick(() => { this.vm.switchTab(this.tab) })
  }
}
