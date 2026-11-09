/**
 * MainPage — 应用主框架
 *
 * Navigation 管底部 toolbarConfiguration（Tab 栏）、title、menus 和路由。
 * menus 使用 NavigationMenuItem[] 实现，由系统统一渲染样式。
 * 各 Tab 页的 ViewModel 通过 @Param 回调把状态和操作函数传给 MainPage。
 */
import { ComponentContent } from '@kit.ArkUI'
import { window } from '@kit.ArkUI'
import { display } from '@kit.ArkUI'
import { themeManager, ThemeManager, AccountOption, AccountSwitchDialogParams, AppRoutes, splitPlaceholderBuilder, CookieExpiredSignal } from 'basic'
import { HomePage } from 'home'
import { CharactersPage } from 'characters'
import { MyPage } from 'account'
import { ToolsPage } from 'material'
import { GeetestSignal, GeetestCenter, DeviceFpCenter, DeviceFpInvalidSignal } from 'verification'
import BuildProfile from 'BuildProfile'
import { isLandscapeOrientation, resolveNavigationMode } from '../utils/MainNavigationMode'
import { MainDialogArbiter } from '../utils/MainDialogArbiter'
import { TAB_HOME, TAB_CHARACTERS, TAB_TOOLS, TAB_MY, resolveTabTitle, buildHomeMenuItems,
  buildCharMenuItems, buildMyMenuItems, createTabItem } from '../utils/MainMenuItems'
import { accountSwitchDialogBuilder } from './MainPageBuilders'


@ComponentV2
export struct MainPage {
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
  /** 窗口尺寸回调存为字段，注销时精确传入，避免清掉同窗口其它监听 */
  private windowSizeCallback: (size: window.Size) => void = (_size: window.Size) => {
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
  }

  readonly stack: NavPathStack = new NavPathStack()
  private placeholder: ComponentContent<object> | null = null
  private uiCtx: UIContext | null = null
  @Local private cookieExpiredSignal: CookieExpiredSignal = CookieExpiredSignal.getInstance()
  @Local private geetestSignal: GeetestSignal = GeetestSignal.getInstance()
  @Local private deviceFpInvalidSignal: DeviceFpInvalidSignal = DeviceFpInvalidSignal.getInstance()
  /** 全局弹窗仲裁（Cookie 过期 / 人机验证 / 设备指纹无效） */
  private dialogArbiter: MainDialogArbiter = new MainDialogArbiter()

  // ── HomePage 标题栏状态（由 HomePage 页通过 @Param 回调上报）──────────
  @Local private shouldShowHomeRefresh: boolean = false
  @Local private isHomeRefreshing: boolean = false
  private homeDoRefresh: () => void = () => {}

  // ── CharactersPage 标题栏状态（由 CharactersPage 页通过 @Param 回调上报）
  @Local private shouldShowCharRefresh: boolean = false
  @Local private shouldShowCharSwitcher: boolean = false
  @Local private isCharRefreshing: boolean = false
  @Local private charAccountOptions: AccountOption[] = []
  @Local private charSelectedIdx: number = 0
  private charDoRefresh: () => void = () => {}
  private charDoSelectAccount: (idx: number) => void = (_idx: number) => {}

  aboutToAppear(): void {
    this.uiCtx = this.getUIContext()
    this.dialogArbiter.attach(this.uiCtx, this.stack, this.geetestSignal, this.deviceFpInvalidSignal)
    // 人机验证（1034 / 10035）统一处理：任何接口遇到都推入 geetestSignal，由本页弹框
    GeetestCenter.init()
    // 设备指纹无效（5003 / 10041）统一处理：任何接口遇到都由本页提示，可重新生成设备指纹
    DeviceFpCenter.init()
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
    this.windowClass?.on('windowSizeChange', this.windowSizeCallback)
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
      this.windowClass?.off('windowSizeChange', this.windowSizeCallback)
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
      this.navMode = resolveNavigationMode(
        isLandscapeOrientation(orientation), this.windowWidthVp, this.currentWindowStatusType)
    } catch (_e) {
      // 获取屏幕方向失败时保持当前模式
    }
  }

  @Monitor('cookieExpiredSignal.queue')
  onCookieExpiredQueueChanged(_monitor: IMonitor): void {
    this.dialogArbiter.onCookieExpiredQueueChanged(this.cookieExpiredSignal)
  }

  /** 设备指纹无效（5003 / 10041）：统一提示，可直接重新生成设备指纹 */
  @Monitor('deviceFpInvalidSignal.version')
  onDeviceFpInvalid(_monitor: IMonitor): void {
    this.dialogArbiter.onDeviceFpInvalid(this.deviceFpInvalidSignal, this.geetestSignal.queueLength)
  }

  @Monitor('geetestSignal.trigger')
  async onGeetestTriggered(_monitor: IMonitor): Promise<void> {
    await this.dialogArbiter.onGeetestTriggered(this.geetestSignal.trigger, this.geetestSignal)
  }


  private get homeMenuItems(): NavigationMenuItem[] {
    return buildHomeMenuItems(this.shouldShowHomeRefresh, this.isHomeRefreshing, this.homeDoRefresh)
  }

  private get charMenuItems(): NavigationMenuItem[] {
    return buildCharMenuItems(this.shouldShowCharSwitcher, this.shouldShowCharRefresh,
      this.isCharRefreshing, this.charDoRefresh, () => { this.showAccountSwitchSheet() })
  }

  private get currentMenuItems(): NavigationMenuItem[] {
    if (this.selectedTab === TAB_HOME) { return this.homeMenuItems; }
    if (this.selectedTab === TAB_CHARACTERS) { return this.charMenuItems; }
    if (this.selectedTab === TAB_MY) {
      return buildMyMenuItems(BuildProfile.DEBUG, () => { this.stack.pushPathByName(AppRoutes.TEST_PAGE, null) })
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

  /** 切换 Tab：分栏模式下清空共享路由栈 */
  private switchTab(tab: number): void {
    this.selectedTab = tab
    this.tabVersion++
    if (this.isSplit) {
      this.stack.clear()
    }
  }

  /** 生成底部 Tab 项（委托 MainMenuItems，注入主题色与切换行为） */
  private tabItem(label: Resource, icon: Resource, tab: number): ToolbarItem {
    return createTabItem(label, icon, tab, this.selectedTab,
      this.tm.current.colorTextSecondary, this.tm.current.colorPrimary,
      (t: number) => { this.switchTab(t) })
  }

  build() {
    NavDestination() {
      Navigation(this.stack) {
        Stack() {
          HomePage({
            detailStack: this.stack,
            isSplit: this.isSplit,
            onReady: (doRefresh: () => void) => {
              this.homeDoRefresh = doRefresh
            },
            onMenuStateChange: (shouldShowRefresh: boolean, isRefreshing: boolean) => {
              this.shouldShowHomeRefresh = shouldShowRefresh
              this.isHomeRefreshing = isRefreshing
            }
          })
          .visibility(this.selectedTab === TAB_HOME ? Visibility.Visible : Visibility.None)
          CharactersPage({
            detailStack: this.stack,
            isSplit: this.isSplit,
            onReady: (doRefresh: () => void, doSelectAccount: (idx: number) => void) => {
              this.charDoRefresh = doRefresh
              this.charDoSelectAccount = doSelectAccount
            },
            onMenuStateChange: (
              shouldShowRefresh: boolean,
              shouldShowSwitcher: boolean,
              isRefreshing: boolean,
              accountOptions: AccountOption[],
              selectedIdx: number
            ) => {
              this.shouldShowCharRefresh = shouldShowRefresh
              this.shouldShowCharSwitcher = shouldShowSwitcher
              this.isCharRefreshing = isRefreshing
              this.charAccountOptions = accountOptions
              this.charSelectedIdx = selectedIdx
            }
          })
          .visibility(this.selectedTab === TAB_CHARACTERS ? Visibility.Visible : Visibility.None)
          ToolsPage({ detailStack: this.stack })
            .visibility(this.selectedTab === TAB_TOOLS ? Visibility.Visible : Visibility.None)
          MyPage({ detailStack: this.stack, isSplit: this.isSplit })
            .visibility(this.selectedTab === TAB_MY ? Visibility.Visible : Visibility.None)
        }
        .width(this.tm.current.full)
        .height(this.tm.current.full)
      }
      .id('main_navigation')
      .title(resolveTabTitle(this.selectedTab))
      .menus(this.currentMenuItems)
      .toolbarConfiguration([
        this.tabItem($r('app.string.main_tab_home'), $r('sys.symbol.house'), TAB_HOME),
        this.tabItem($r('app.string.characters_tab_title'), $r('sys.symbol.person'), TAB_CHARACTERS),
        this.tabItem($r('app.string.tools_title'), $r('sys.symbol.wrench_and_screwdriver'), TAB_TOOLS),
        this.tabItem($r('app.string.main_tab_my'), $r('sys.symbol.gearshape'), TAB_MY),
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
export struct MainPagePreview {
  build() {
    MainPage()
  }
}
