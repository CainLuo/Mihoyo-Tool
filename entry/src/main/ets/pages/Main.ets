/**
 * Main — 应用主框架
 *
 * 按 Navigation11 示例结构：
 * - 一个 Navigation，内容区 if/else 切换三个 Tab 页
 * - toolbarConfiguration 做底部 TabBar，宽屏时自动只在左侧 NavBar 显示
 * - splitPlaceholder 宽屏右侧占位
 */
import { SymbolGlyphModifier, ComponentContent } from '@kit.ArkUI'
import { themeManager, ThemeManager } from '../theme/ThemeManager'
import { Home } from './Home'
import { Characters, charDetailBuilder } from './Characters'
import { My } from './My'
import { HomeViewModel } from '../viewmodel/HomeViewModel'
import { ViewState } from '../constants/ViewStates'
import { GenshinDailyDetail, GenshinDailyDetailParam } from './GenshinDailyDetail'
import { GenshinCharacterDetailParam, GenshinCharacterDetail } from './GenshinCharacterDetail'
import { AccountDetail } from './AccountDetail'
import { Login } from './Login'
import { MyAccountVM } from '../components/my/MyModels'
import { AppRoutes } from '../constants/AppRoutes'

@Builder
function detailBuilder(name: string, param: Object) {
  if (name === 'CharDetail') {
    charDetailBuilder(name, param)
  } else if (name === AppRoutes.GENSHIN_DAILY_DETAIL) {
    GenshinDailyDetail({ routerParam: param as GenshinDailyDetailParam })
  } else if (name === AppRoutes.GENSHIN_CHARACTER_DETAIL) {
    GenshinCharacterDetail({ routerParam: param as GenshinCharacterDetailParam })
  } else if (name === AppRoutes.ACCOUNT_DETAIL) {
    AccountDetail({ account: param as MyAccountVM })
  } else if (name === AppRoutes.LOGIN) {
    Login()
  }
}

const TAB_HOME = 0
const TAB_CHARACTERS = 1
const TAB_MY = 2

@Builder
function splitPlaceholderBuilder() {
  Column() {}
  .width('100%')
  .height('100%')
  .backgroundColor($r('app.color.color_page_bg'))
}

@ComponentV2
export struct Main {
  @Local private tm: ThemeManager = themeManager
  @Local private selectedTab: number = TAB_HOME
  @Local private homeVm: HomeViewModel = new HomeViewModel()
  @Local private isSplit: boolean = false
  private detailStack: NavPathStack = new NavPathStack()
  private placeholder: ComponentContent<object> | null = null
  private uiCtx: UIContext | null = null

  aboutToAppear(): void {
    this.uiCtx = this.getUIContext()
    this.placeholder = new ComponentContent(this.uiCtx, wrapBuilder(splitPlaceholderBuilder))
  }

  private get tabItems(): ToolbarItem[] {
    const items: ToolbarItem[] = [
      {
        value: $r('app.string.main_tab_home'),
        symbolIcon: new SymbolGlyphModifier($r('sys.symbol.ohos_star')),
        status: this.selectedTab === TAB_HOME ? ToolbarItemStatus.ACTIVE : ToolbarItemStatus.NORMAL,
        action: () => {
          this.selectedTab = TAB_HOME
          this.detailStack.clear()
        }
      },
      {
        value: $r('app.string.characters_tab_title'),
        symbolIcon: new SymbolGlyphModifier($r('sys.symbol.ohos_lungs')),
        status: this.selectedTab === TAB_CHARACTERS ? ToolbarItemStatus.ACTIVE : ToolbarItemStatus.NORMAL,
        action: () => {
          this.selectedTab = TAB_CHARACTERS
          this.detailStack.clear()
        }
      },
      {
        value: $r('app.string.main_tab_my'),
        symbolIcon: new SymbolGlyphModifier($r('sys.symbol.ohos_lungs')),
        status: this.selectedTab === TAB_MY ? ToolbarItemStatus.ACTIVE : ToolbarItemStatus.NORMAL,
        action: () => {
          this.selectedTab = TAB_MY
          this.detailStack.clear()
        }
      }
    ]
    return items
  }

  @Builder
  homeMenus() {
    if (this.homeVm.viewState === ViewState.DATA) {
      Button({ type: ButtonType.Circle }) {
        Image($r('app.media.ic_refresh'))
          .width(this.tm.current.value22)
          .height(this.tm.current.value22)
          .fillColor(this.homeVm.isRefreshing
            ? this.tm.current.colorTextSecondary
            : this.tm.current.colorTextPrimary)
      }
      .width(this.tm.current.value56)
      .height(this.tm.current.value56)
      .backgroundColor(Color.Transparent)
      .enabled(!this.homeVm.isRefreshing)
      .onClick(() => { this.homeVm.refresh() })
    }
  }

  private tabTitle(): Resource {
    if (this.selectedTab === TAB_HOME) { return $r('app.string.main_tab_home') }
    if (this.selectedTab === TAB_CHARACTERS) { return $r('app.string.characters_tab_title') }
    return $r('app.string.main_tab_my')
  }

  build() {
    NavDestination() {
      Navigation(this.detailStack) {
        // NavBar 内容区：根据 selectedTab 切换
        if (this.selectedTab === TAB_HOME) {
          Home({ vm: this.homeVm, detailStack: this.detailStack, isSplit: this.isSplit })
        } else if (this.selectedTab === TAB_CHARACTERS) {
          Characters({ detailStack: this.detailStack, isSplit: this.isSplit })
        } else {
          My({ detailStack: this.detailStack, isSplit: this.isSplit })
        }
      }
      .navDestination(detailBuilder)
      .title(this.tabTitle())
      .menus(this.selectedTab === TAB_HOME ? this.homeMenus : null)
      .toolbarConfiguration(this.tabItems)
      .mode(NavigationMode.Auto)
      .navBarWidth(this.tm.current.pct45)
      .splitPlaceholder(this.placeholder!)
      .onNavigationModeChange((mode: NavigationMode) => {
        this.isSplit = mode === NavigationMode.Split
      })
    }
    .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.BOTTOM])
  }
}
