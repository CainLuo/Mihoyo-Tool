/**
 * Main — 应用主框架
 *
 * 每个 Tab 有独立的 NavPathStack。
 *
 * 架构说明：
 * Navigation.menus() 是 Navigation 组件的属性，必须在 Navigation 所在的组件里定义。
 * 因此 homeMenus/charMenus 的 @Builder 写在 Main 里是框架约束，不是设计选择。
 * 但 Main 不持有任何 ViewModel 实例，menu 按钮的显示逻辑由各 Tab 页的 ViewModel 决定，
 * 通过 @Event 回调把操作函数和状态上报给 Main。
 */
import { ComponentContent, SymbolGlyphModifier } from '@kit.ArkUI'
import { themeManager, ThemeManager } from '../theme/ThemeManager'
import { AccountOption } from '../viewmodel/CharactersViewModel'
import { Home } from './Home'
import { Characters } from './Characters'
import { My } from './My'
import { GenshinDailyDetail, GenshinDailyDetailParam } from './GenshinDailyDetail'
import { GenshinCharacterDetailParam, GenshinCharacterDetail } from './GenshinCharacterDetail'
import { AccountDetail } from './AccountDetail'
import { Login } from './Login'
import { MyAccountVM } from '../components/my/MyModels'
import { AppRoutes } from '../constants/AppRoutes'
import { splitPlaceholderBuilder } from '../components/SplitPlaceholder'

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
  @Local private isSplit: boolean = false

  // 每个 Tab 独立的导航栈
  readonly homeStack: NavPathStack = new NavPathStack()
  readonly charStack: NavPathStack = new NavPathStack()
  readonly myStack: NavPathStack = new NavPathStack()

  // ── Home 标题栏状态（由 Home 页通过 @Event 上报）──────────────
  @Local private homeShowRefresh: boolean = false
  @Local private homeIsRefreshing: boolean = false
  private homeDoRefresh: () => void = () => {}

  // ── Characters 标题栏状态（由 Characters 页通过 @Event 上报）──
  @Local private charShowRefresh: boolean = false
  @Local private charShowSwitcher: boolean = false
  @Local private charIsRefreshing: boolean = false
  @Local private charAccountOptions: AccountOption[] = []
  @Local private charSelectedIdx: number = 0
  private charDoRefresh: () => void = () => {}
  private charDoSelectAccount: (idx: number) => void = (_idx: number) => {}

  private placeholder: ComponentContent<object> | null = null
  private uiCtx: UIContext | null = null

  aboutToAppear(): void {
    this.uiCtx = this.getUIContext()
    this.placeholder = new ComponentContent(this.uiCtx, wrapBuilder(splitPlaceholderBuilder))
  }

  private get tabItems(): ToolbarItem[] {
    return [
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
  }

  // Navigation.menus() 必须在 Navigation 所在组件里定义，这是框架约束
  @Builder
  homeMenus() {
    if (this.homeShowRefresh) {
      Button({ type: ButtonType.Circle }) {
        Image($r('app.media.ic_refresh'))
          .width(this.tm.current.value22)
          .height(this.tm.current.value22)
          .fillColor(this.homeIsRefreshing
            ? this.tm.current.colorTextSecondary
            : this.tm.current.colorTextPrimary)
      }
      .width(this.tm.current.value56)
      .height(this.tm.current.value56)
      .backgroundColor(this.tm.current.colorTransparent)
      .enabled(!this.homeIsRefreshing)
      .onClick(() => { this.homeDoRefresh() })
    }
  }

  @Builder
  charMenus() {
    Row({ space: this.tm.current.value8 }) {
      if (this.charShowSwitcher) {
        Button({ type: ButtonType.Circle }) {
          SymbolGlyph($r('sys.symbol.person_2'))
            .fontSize(this.tm.current.value20)
            .fontColor([this.tm.current.colorTextPrimary])
        }
        .width(this.tm.current.value36)
        .height(this.tm.current.value36)
        .backgroundColor(this.tm.current.colorTransparent)
        .bindMenu(this.accountMenuBuilder)
      }
      if (this.charShowRefresh) {
        Button({ type: ButtonType.Circle }) {
          SymbolGlyph($r('sys.symbol.arrow_clockwise'))
            .fontSize(this.tm.current.value20)
            .fontColor([this.charIsRefreshing
              ? this.tm.current.colorTextSecondary
              : this.tm.current.colorTextPrimary])
        }
        .width(this.tm.current.value36)
        .height(this.tm.current.value36)
        .backgroundColor(this.tm.current.colorTransparent)
        .enabled(!this.charIsRefreshing)
        .onClick(() => { this.charDoRefresh() })
      }
    }
  }

  @Builder
  accountMenuBuilder() {
    Menu() {
      ForEach(this.charAccountOptions, (opt: AccountOption, i: number) => {
        MenuItem({
          content: opt.nickname !== '' ? opt.nickname : opt.username,
          labelInfo: opt.uid !== '' ? 'UID: ' + opt.uid : '',
          symbolEndIcon: i === this.charSelectedIdx
            ? new SymbolGlyphModifier($r('sys.symbol.checkmark'))
            : undefined
        })
        .selected(i === this.charSelectedIdx)
        .onClick(() => { this.charDoSelectAccount(i) })
      }, (opt: AccountOption) => opt.accountId.toString())
    }
  }

  private tabTitle(): Resource {
    if (this.selectedTab === TAB_HOME) { return $r('app.string.main_tab_home') }
    if (this.selectedTab === TAB_CHARACTERS) { return $r('app.string.characters_tab_title') }
    return $r('app.string.main_tab_my')
  }

  private get currentStack(): NavPathStack {
    if (this.selectedTab === TAB_HOME) { return this.homeStack }
    if (this.selectedTab === TAB_CHARACTERS) { return this.charStack }
    return this.myStack
  }

  build() {
    NavDestination() {
      Navigation(this.currentStack) {
        Stack() {
          Home({
            detailStack: this.homeStack,
            isSplit: this.isSplit,
            onReady: (doRefresh: () => void) => {
              this.homeDoRefresh = doRefresh
            },
            onMenuStateChange: (showRefresh: boolean, isRefreshing: boolean) => {
              this.homeShowRefresh = showRefresh
              this.homeIsRefreshing = isRefreshing
            }
          })
          .visibility(this.selectedTab === TAB_HOME ? Visibility.Visible : Visibility.None)
          Characters({
            detailStack: this.charStack,
            isSplit: this.isSplit,
            onReady: (doRefresh: () => void, doSelectAccount: (idx: number) => void) => {
              this.charDoRefresh = doRefresh
              this.charDoSelectAccount = doSelectAccount
            },
            onMenuStateChange: (
              showRefresh: boolean,
              showSwitcher: boolean,
              isRefreshing: boolean,
              accountOptions: AccountOption[],
              selectedIdx: number
            ) => {
              this.charShowRefresh = showRefresh
              this.charShowSwitcher = showSwitcher
              this.charIsRefreshing = isRefreshing
              this.charAccountOptions = accountOptions
              this.charSelectedIdx = selectedIdx
            }
          })
          .visibility(this.selectedTab === TAB_CHARACTERS ? Visibility.Visible : Visibility.None)
          My({ detailStack: this.myStack, isSplit: this.isSplit })
            .visibility(this.selectedTab === TAB_MY ? Visibility.Visible : Visibility.None)
        }
        .width(this.tm.current.full)
        .height(this.tm.current.full)
      }
      .navDestination(allDetailBuilder)
      .title(this.tabTitle())
      .menus(this.selectedTab === TAB_HOME ? this.homeMenus
        : this.selectedTab === TAB_CHARACTERS ? this.charMenus
        : null)
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
