/**
 * Main — 应用主框架
 *
 * Navigation 管底部 toolbarConfiguration（Tab 栏）、title、menus 和路由。
 * menus 使用 NavigationMenuItem[] 实现，由系统统一渲染样式。
 * 各 Tab 页的 ViewModel 通过 @Param 回调把状态和操作函数传给 Main。
 */
import { ComponentContent, SymbolGlyphModifier } from '@kit.ArkUI'
import { promptAction } from '@kit.ArkUI'
import { window } from '@kit.ArkUI'
import { display } from '@kit.ArkUI'
import { themeManager, ThemeManager } from '../theme/ThemeManager'
import { AccountOption } from '../models/AccountOption'
import { AccountSwitchDialog, AccountSwitchDialogParams } from '../components/characters/AccountSwitchDialog'
import { Home } from './Home'
import { Characters } from './Characters'
import { My } from './My'
import { AppRoutes } from '../constants/AppRoutes'
import { splitPlaceholderBuilder } from '../components/SplitPlaceholder'
import { CookieExpiredSignal } from '../utils/CookieExpiredSignal'
import { FailedAccountInfo } from 'core'
import BuildProfile from 'BuildProfile'

@Builder
function accountSwitchDialogBuilder(params: AccountSwitchDialogParams) {
  AccountSwitchDialog({ params: params })
}

const TAB_HOME = 0
const TAB_CHARACTERS = 1
const TAB_MY = 2

@ComponentV2
export struct Main {
  @Local private tm: ThemeManager = themeManager
  @Local private selectedTab: number = TAB_HOME
  @Local private tabVersion: number = 0
  @Local private isSplit: boolean = false
  /** 当前 Navigation 显示模式，由 setCurrentMode() 综合屏幕方向和窗口状态计算 */
  @Local private navMode: NavigationMode = NavigationMode.Stack
  /** 当前窗口宽度（vp），用于动态计算 navBarWidth */
  @Local private windowWidthVp: number = 360

  private windowClass: window.Window | undefined = AppStorage.get<window.Window>('windowClass')
  private currentWindowStatusType: window.WindowStatusType | undefined =
    this.windowClass?.getWindowStatus()

  readonly stack: NavPathStack = new NavPathStack()
  private placeholder: ComponentContent<object> | null = null
  private uiCtx: UIContext | null = null
  @Local private cookieExpiredSignal: CookieExpiredSignal = CookieExpiredSignal.instance()

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
    // 初始化窗口宽度和模式
    const ctx = this.uiCtx
    if (this.windowClass !== undefined) {
      try {
        const rect = this.windowClass.getWindowProperties().windowRect
        this.windowWidthVp = ctx.px2vp(rect.width)
      } catch (_e) {
        // 获取窗口属性失败时保持默认宽度
      }
    }
    this.setCurrentMode()
    // 监听窗口尺寸变化（折叠屏展开/折叠、旋转）
    this.windowClass?.on('windowSizeChange', () => {
      const ctx2 = this.uiCtx
      if (ctx2 !== null && this.windowClass !== undefined) {
        try {
          const rect = this.windowClass.getWindowProperties().windowRect
          this.windowWidthVp = ctx2.px2vp(rect.width)
        } catch (_e) {
          // 获取窗口属性失败时保持当前宽度
        }
      }
      this.setCurrentMode()
    })
    // 监听窗口状态变化（分屏模式检测）
    try {
      this.windowClass?.on('windowStatusChange', (statusType: window.WindowStatusType) => {
        this.currentWindowStatusType = statusType
        this.setCurrentMode()
      })
    } catch (_e) {
      // 注册窗口状态监听失败时忽略
    }
  }

  aboutToDisappear(): void {
    try {
      this.windowClass?.off('windowSizeChange')
      this.windowClass?.off('windowStatusChange')
    } catch (_e) {
      // 注销监听失败时忽略
    }
  }

  /**
   * 综合屏幕方向 + 窗口状态计算 Navigation 显示模式。
   * 官方 FAQ 推荐方案：横屏时分栏（分屏除外），竖屏时按断点决定。
   */
  private setCurrentMode(): void {
    try {
      const orientation = display.getDefaultDisplaySync().orientation
      const isLandscape = orientation === display.Orientation.LANDSCAPE ||
        orientation === display.Orientation.LANDSCAPE_INVERTED
      if (isLandscape) {
        // 横屏：分屏（WindowStatusType=4）强制单栏，否则分栏
        this.navMode = (this.currentWindowStatusType === 4)
          ? NavigationMode.Stack
          : NavigationMode.Split
      } else {
        // 竖屏：窗口宽度 < 520vp 单栏，≥ 520vp 分栏（Auto 模式阈值）
        this.navMode = this.windowWidthVp < 520
          ? NavigationMode.Stack
          : NavigationMode.Split
      }
    } catch (_e) {
      // 获取屏幕方向失败时保持当前模式
    }
  }

  @Monitor('cookieExpiredSignal.queue')
  onCookieExpiredQueueChanged(_monitor: IMonitor): void {
    if (this.cookieExpiredSignal.queue.length === 0) { return }
    const info = this.cookieExpiredSignal.queue[0]
    // 从队列移除
    const newQueue: FailedAccountInfo[] = []
    for (let i = 1; i < this.cookieExpiredSignal.queue.length; i++) {
      newQueue[newQueue.length] = this.cookieExpiredSignal.queue[i]
    }
    this.cookieExpiredSignal.queue = newQueue

    const ctx = this.uiCtx
    if (ctx === null) { return }
    ctx.getPromptAction().showDialog({
      title: $r('app.string.cookie_expired_dialog_title'),
      message: $r('app.string.cookie_expired_dialog_msg', info.nickname),
      buttons: [
        { text: $r('app.string.dialog_cancel'), color: '#999999' },
        { text: $r('app.string.cookie_expired_go_login'), color: '#E8534A' },
      ],
    }).then((result: promptAction.ShowDialogSuccessResponse) => {
      if (result.index === 1) {
        this.stack.pushPathByName(AppRoutes.LOGIN, null)
      }
      // 若队列还有，继续弹下一个
      if (this.cookieExpiredSignal.queue.length > 0) {
        this.cookieExpiredSignal.queue = this.cookieExpiredSignal.queue
      }
    }).catch((_: Error | object) => {})
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
    if (this.selectedTab === TAB_MY && BuildProfile.DEBUG) {
      return [{
        value: 'test',
        symbolIcon: new SymbolGlyphModifier($r('sys.symbol.wrench_and_screwdriver')),
        action: () => { this.stack.pushPathByName(AppRoutes.TEST_PAGE, null) }
      }];
    }
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
      maskColor: '#80000000',
      isModal: true,
      autoCancel: true
    }).catch((_: Error | object) => {});
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
      .title(this.tabTitle())
      .menus(this.currentMenuItems)
      .toolbarConfiguration([
        {
          value: $r('app.string.main_tab_home'),
          symbolIcon: new SymbolGlyphModifier($r('sys.symbol.house'))
            .fontColor([this.tm.current.colorTextSecondary]),
          activeSymbolIcon: new SymbolGlyphModifier($r('sys.symbol.house'))
            .fontColor([this.tm.current.colorPrimary]),
          status: (this.selectedTab === TAB_HOME && this.tabVersion >= 0)
            ? ToolbarItemStatus.ACTIVE : ToolbarItemStatus.NORMAL,
          action: () => { this.selectedTab = TAB_HOME; this.tabVersion++; if (this.isSplit) { this.stack.clear() } }
        },
        {
          value: $r('app.string.characters_tab_title'),
          symbolIcon: new SymbolGlyphModifier($r('sys.symbol.person'))
            .fontColor([this.tm.current.colorTextSecondary]),
          activeSymbolIcon: new SymbolGlyphModifier($r('sys.symbol.person'))
            .fontColor([this.tm.current.colorPrimary]),
          status: (this.selectedTab === TAB_CHARACTERS && this.tabVersion >= 0)
            ? ToolbarItemStatus.ACTIVE : ToolbarItemStatus.NORMAL,
          action: () => { this.selectedTab = TAB_CHARACTERS; this.tabVersion++; if (this.isSplit) { this.stack.clear() } }
        },
        {
          value: $r('app.string.main_tab_my'),
          symbolIcon: new SymbolGlyphModifier($r('sys.symbol.gearshape'))
            .fontColor([this.tm.current.colorTextSecondary]),
          activeSymbolIcon: new SymbolGlyphModifier($r('sys.symbol.gearshape'))
            .fontColor([this.tm.current.colorPrimary]),
          status: (this.selectedTab === TAB_MY && this.tabVersion >= 0)
            ? ToolbarItemStatus.ACTIVE : ToolbarItemStatus.NORMAL,
          action: () => { this.selectedTab = TAB_MY; this.tabVersion++; if (this.isSplit) { this.stack.clear() } }
        }
      ])
      .mode(this.navMode)
      .navBarWidth(0.4 * this.windowWidthVp)
      .navBarWidthRange([240, 400])
      .minContentWidth(320)
      .splitPlaceholder(this.placeholder!)
      .onNavigationModeChange((mode: NavigationMode) => {
        this.isSplit = mode === NavigationMode.Split
      })
      .backgroundColor(this.tm.current.colorPageBg)
    }
    // Navigation 组件默认实现了底部 Tab 栏的延伸，无需手动设置 background 或 expandSafeArea
  }
}

// ─── Preview ─────────────────────────────────────────────────────

@Preview
@ComponentV2
export struct MainPreview {
  build() {
    Main()
  }
}
