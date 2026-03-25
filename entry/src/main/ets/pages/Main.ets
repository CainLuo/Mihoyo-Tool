/**
 * Main — 应用主框架
 *
 * Tabs 做底部导航，每个 Tab 页内用 Navigation 渲染标题栏。
 * 系统自动处理多设备适配和安全区域。
 */
import { themeManager, ThemeManager } from '../theme/ThemeManager'
import { Home } from './Home'
import { Characters } from './Characters'
import { My } from './My'
import { BottomTabItem } from '../components/main/BottomTabItem'

const TAB_HOME = 0
const TAB_CHARACTERS = 1
const TAB_MY = 2

@ComponentV2
export struct Main {
  @Local private tm: ThemeManager = themeManager
  @Local private selectedTab: number = TAB_HOME

  @Builder
  tabBarBuilder(tab: number, label: Resource) {
    BottomTabItem({
      tm: this.tm,
      tab: tab,
      selectedTab: this.selectedTab,
      label: label,
      onSelect: (t: number) => { this.selectedTab = t }
    })
  }

  build() {
    Tabs({ index: this.selectedTab }) {
      TabContent() {
        Navigation() {
          Home()
        }
        .title($r('app.string.main_tab_home'))
        .mode(NavigationMode.Auto)
        .hideNavBar(false)
      }
      .tabBar(this.tabBarBuilder(TAB_HOME, $r('app.string.main_tab_home')))

      TabContent() {
        Navigation() {
          Characters()
        }
        .title($r('app.string.characters_tab_title'))
        .mode(NavigationMode.Auto)
        .hideNavBar(false)
      }
      .tabBar(this.tabBarBuilder(TAB_CHARACTERS, $r('app.string.characters_tab_title')))

      TabContent() {
        Navigation() {
          My()
        }
        .title($r('app.string.main_tab_my'))
        .mode(NavigationMode.Auto)
        .hideNavBar(false)
      }
      .tabBar(this.tabBarBuilder(TAB_MY, $r('app.string.main_tab_my')))
    }
    .barPosition(BarPosition.End)
    .onChange((index: number) => { this.selectedTab = index })
    .width(this.tm.current.widthFull)
    .height(this.tm.current.heightFull)
  }
}
