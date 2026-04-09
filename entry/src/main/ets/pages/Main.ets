/**
 * Main — 应用主框架
 *
 * Navigation 管底部 toolbarConfiguration（Tab 栏）、title、menus 和路由。
 * menus 使用 NavigationMenuItem[] 实现，由系统统一渲染样式。
 * 各 Tab 页的 ViewModel 通过 @Param 回调把状态和操作函数传给 Main。
 */
import { ComponentContent, SymbolGlyphModifier } from '@kit.ArkUI'
import { promptAction } from '@kit.ArkUI'
import { themeManager, ThemeManager } from '../theme/ThemeManager'
import { AccountOption } from '../viewmodel/CharactersViewModel'
import { AccountSwitchDialog, AccountSwitchDialogParams } from '../components/characters/AccountSwitchDialog'
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
function accountSwitchDialogBuilder(params: AccountSwitchDialogParams) {
  AccountSwitchDialog({ params: params })
}

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

  readonly stack: NavPathStack = new NavPathStack()
  private placeholder: ComponentContent<object> | null = null
  private uiCtx: UIContext | null = null

  // ── Home 标题栏状态（由 Home 页通过 @Param 回调上报）──────────
  @Local private homeShowRefresh: boolean = false
  @Local private homeIsRefreshing: boolean = false
  private homeDoRefresh: () => void = () => {}

  // ── Characters 标题栏状态（由 Characters 页通过 @Param 回调上报）
  @Local private charShowRefresh: boolean = false
  @Local private charShowSwitcher: boolean = false
  @Local private charIsRefreshing: boolean = false
  @Local private charAccountOptions: AccountOption[] = []
  @Local private charSelectedIdx: number = 0
  private charDoRefresh: () => void = () => {}
  private charDoSelectAccount: (idx: number) => void = (_idx: number) => {}

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

  private get homeMenuItems(): NavigationMenuItem[] {
    if (!this.homeShowRefresh) { return []; }
    return [{
      value: 'refresh',
      symbolIcon: new SymbolGlyphModifier($r('sys.symbol.arrow_clockwise')),
      isEnabled: !this.homeIsRefreshing,
      action: () => { this.homeDoRefresh() }
    }];
  }

  private get charMenuItems(): NavigationMenuItem[] {
    const items: NavigationMenuItem[] = [];
    if (this.charShowSwitcher) {
      items[items.length] = {
        value: 'switch_account',
        symbolIcon: new SymbolGlyphModifier($r('sys.symbol.person_2')),
        action: () => { this.showAccountSwitchSheet() }
      };
    }
    if (this.charShowRefresh) {
      items[items.length] = {
        value: 'refresh',
        symbolIcon: new SymbolGlyphModifier($r('sys.symbol.arrow_clockwise')),
        isEnabled: !this.charIsRefreshing,
        action: () => { this.charDoRefresh() }
      };
    }
    return items;
  }

  private get currentMenuItems(): NavigationMenuItem[] {
    if (this.selectedTab === TAB_HOME) { return this.homeMenuItems; }
    if (this.selectedTab === TAB_CHARACTERS) { return this.charMenuItems; }
    return [];
  }

  private showAccountSwitchSheet(): void {
    const ctx = this.uiCtx;
    if (ctx === null || this.charAccountOptions.length === 0) { return; }
    const params = new AccountSwitchDialogParams();
    params.options = this.charAccountOptions;
    params.selectedIdx = this.charSelectedIdx;
    params.onSelect = (idx: number) => { this.charDoSelectAccount(idx); };
    const content = new ComponentContent(ctx, wrapBuilder(accountSwitchDialogBuilder), params);
    params.onClose = () => { ctx.getPromptAction().closeCustomDialog(content); };
    ctx.getPromptAction().openCustomDialog(content, {
      alignment: DialogAlignment.Bottom,
      offset: { dx: 0, dy: 0 },
      maskColor: 'rgba(0,0,0,0.5)',
      isModal: true,
      autoCancel: true
    });
  }

  private tabTitle(): Resource {
    if (this.selectedTab === TAB_HOME) { return $r('app.string.main_tab_home') }
    if (this.selectedTab === TAB_CHARACTERS) { return $r('app.string.characters_tab_title') }
    return $r('app.string.main_tab_my')
  }

  build() {
    NavDestination() {
      Navigation(this.stack) {
        Stack() {
          Home({
            detailStack: this.stack,
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
            detailStack: this.stack,
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
          My({ detailStack: this.stack, isSplit: this.isSplit })
            .visibility(this.selectedTab === TAB_MY ? Visibility.Visible : Visibility.None)
        }
        .width(this.tm.current.full)
        .height(this.tm.current.full)
      }
      .navDestination(allDetailBuilder)
      .title(this.tabTitle())
      .menus(this.currentMenuItems)
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
