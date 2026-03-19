import { Home } from './Home'
import { My } from './My'

// TabBar 高度不写死，由 ArkUI 布局系统自动适配各机型安全区
@ComponentV2
export struct Main {
  build() {
    Tabs({ barPosition: BarPosition.End }) {
      TabContent() {
        Home()
      }.tabBar($r('app.string.main_tab_home'))

      TabContent() {
        My()
      }.tabBar($r('app.string.main_tab_my'))
    }
    .scrollable(false)
    .barMode(BarMode.Fixed)
  }
}
