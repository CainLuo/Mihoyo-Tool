/**
 * Main — 应用主框架
 *
 * 每个 Tab 有独立的 NavPathStack（对应 iOS 每个 Tab 独立 NavigationController）：
 * - homeStack：Home Tab 的导航栈
 * - charStack：Characters Tab 的导航栈
 * - myStack：My Tab 的导航栈
 *
 * 切换 Tab 时各栈互不影响，登录成功后可操作 myStack 实现 setViewControllers 效果。
 */
import { SymbolGlyphModifier, ComponentContent } from '@kit.ArkUI'
import { themeManager, ThemeManager } from '../theme/ThemeManager'
import { HomeViewModel } from '../viewmodel/HomeViewModel'
import { Home } from './Home'
import { Characters, charDetailBuilder } from './Characters'
import { My } from './My'
import { GenshinDailyDetail, GenshinDailyDetailParam } from './GenshinDailyDetail'
import { GenshinCharacterDetailParam, GenshinCharacterDetail } from './GenshinCharacterDetail'
import { AccountDetail } from './AccountDetail'
import { Login } from './Login'
import { MyAccountVM } from '../components/my/MyModels'
import { AppRoutes } from '../constants/AppRoutes'
import { splitPlaceholderBuilder } from '../components/SplitPlaceholder'
import { HomeRefreshButton } from '../components/home/HomeRefreshButton'

@Builder
function allDetailBuilder(name: string, param: Object) {
  if (name === AppRoutes.GENSHIN_DAILY_DETAIL) {
    GenshinDailyDetail({ routerParam: param as GenshinDailyDetailParam })
  } else if (name === 'CharDetail' || name === AppRoutes.GENSHIN_CHARACTER_DETAIL) {
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

@ComponentV2
export struct Main {
  @Local private tm: ThemeManager = themeManager
  @Local private selectedTab: number = TAB_HOME
  @Local private homeVm: HomeViewModel = new HomeViewModel()
  @Local private isSplit: boolean = false

  // 每个 Tab 独立的导航栈
  readonly homeStack: NavPathStack = new NavPathStack()
  readonly charStack: NavPathStack = new NavPathStack()
  readonly myStack: NavPathStack = new NavPathStack()

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
        action: () => { this.selectedTab = TAB_HOME }
      },
      {
        value: $r('app.string.characters_tab_title'),
        symbolIcon: new SymbolGlyphModifier($r('sys.symbol.ohos_lungs')),
        status: this.selectedTab === TAB_CHARACTERS ? ToolbarItemStatus.ACTIVE : ToolbarItemStatus.NORMAL,
        action: () => { this.selectedTab = TAB_CHARACTERS }
      },
      {
        value: $r('app.string.main_tab_my'),
        symbolIcon: new SymbolGlyphModifier($r('sys.symbol.ohos_lungs')),
        status: this.selectedTab === TAB_MY ? ToolbarItemStatus.ACTIVE : ToolbarItemStatus.NORMAL,
        action: () => { this.selectedTab = TAB_MY }
      }
    ]
    return items
  }

  @Builder
  homeMenus() {
    HomeRefreshButton({
      viewState: this.homeVm.viewState,
      isRefreshing: this.homeVm.isRefreshing,
      onRefresh: () => { this.homeVm.refresh() }
    })
  }

  private tabTitle(): Resource {
    if (this.selectedTab === TAB_HOME) { return $r('app.string.main_tab_home') }
    if (this.selectedTab === TAB_CHARACTERS) { return $r('app.string.characters_tab_title') }
    return $r('app.string.main_tab_my')
  }

  // 当前 Tab 对应的栈
  private get currentStack(): NavPathStack {
    if (this.selectedTab === TAB_HOME) { return this.homeStack }
    if (this.selectedTab === TAB_CHARACTERS) { return this.charStack }
    return this.myStack
  }

  build() {
    NavDestination() {
      Navigation(this.currentStack) {
        Stack() {
          Home({ detailStack: this.homeStack, isSplit: this.isSplit,
            onVmReady: (vm: HomeViewModel) => { this.homeVm = vm } })
            .visibility(this.selectedTab === TAB_HOME ? Visibility.Visible : Visibility.None)
          Characters({ detailStack: this.charStack, isSplit: this.isSplit })
            .visibility(this.selectedTab === TAB_CHARACTERS ? Visibility.Visible : Visibility.None)
          My({ detailStack: this.myStack, isSplit: this.isSplit })
            .visibility(this.selectedTab === TAB_MY ? Visibility.Visible : Visibility.None)
        }
        .width(this.tm.current.full)
        .height(this.tm.current.full)
      }
      .navDestination(allDetailBuilder)
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
