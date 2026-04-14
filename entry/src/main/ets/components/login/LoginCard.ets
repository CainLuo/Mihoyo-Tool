/**
 * LoginCard — 登录卡片（Tab 栏 + Tab 内容）
 */
import { ThemeManager } from '../../theme/ThemeManager'
import { LoginViewModel } from '../../viewmodel/LoginViewModel'
import { LoginTabBar } from './LoginTabBar'
import { LoginTabContent } from './LoginTabContent'

@ComponentV2
export struct LoginCard {
  @Param tm: ThemeManager = new ThemeManager()
  @Param vm: LoginViewModel = new LoginViewModel()

  build() {
    Column({ space: this.tm.current.value0 }) {
      LoginTabBar({ tm: this.tm, vm: this.vm })
      LoginTabContent({ tm: this.tm, vm: this.vm })
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
