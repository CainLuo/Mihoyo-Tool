/**
 * LoginTabItem — 登录 Tab 切换项
 */
import { ThemeManager } from '../../theme/ThemeManager'
import { LoginTab } from '../../constants/LoginTabEnum'
import { LoginViewModel } from '../../viewmodel/LoginViewModel'

@ComponentV2
export struct LoginTabItem {
  @Param tm: ThemeManager = new ThemeManager()
  @Param vm: LoginViewModel = new LoginViewModel()
  @Param tab: LoginTab = LoginTab.PHONE
  @Param label: Resource = $r('app.string.login_tab_phone')

  build() {
    Text(this.label)
      .font(this.tm.current.body13)
      .fontColor(this.vm.activeTab === this.tab
        ? Color.White
        : this.tm.current.colorTextSecondary)
      .fontWeight(this.vm.activeTab === this.tab ? FontWeight.Bold : FontWeight.Normal)
      .backgroundColor(this.vm.activeTab === this.tab
        ? this.tm.current.colorPrimary
        : Color.Transparent)
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
