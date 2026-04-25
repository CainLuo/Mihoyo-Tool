/**
 * LoginCard — 登录卡片（Tab 栏 + Tab 内容）
 */
import { themeManager, ThemeManager } from '../../theme/ThemeManager';
import { LoginViewModel } from 'entry/ets/viewmodel/LoginViewModel';
import { LoginTabBar } from 'entry/ets/components/login/LoginTabBar';
import { LoginTabContent } from 'entry/ets/components/login/LoginTabContent';

@ComponentV2
export struct LoginCard {
  @Param vm: LoginViewModel = new LoginViewModel();
  @Local private tm: ThemeManager = themeManager;

  build() {
    Column({ space: this.tm.current.value0 }) {
      LoginTabBar({ vm: this.vm })
      LoginTabContent({ vm: this.vm })
    }
    .width(this.tm.current.full)
    .backgroundColor(this.tm.current.colorSurfaceCard)
    .borderRadius(this.tm.current.radius12)
    .borderWidth(this.tm.current.value1)
    .borderColor(this.tm.current.colorDivider)
    .padding(this.tm.current.value20)
    .shadow({
      radius: this.tm.current.shadowRadius,
      color: this.tm.current.shadowColor,
      offsetY: this.tm.current.shadowOffsetY
    })
  }
}
