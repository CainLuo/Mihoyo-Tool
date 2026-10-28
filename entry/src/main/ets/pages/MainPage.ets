/**
 * MainPage — 应用主框架
 *
 * Navigation 管底部 toolbarConfiguration（Tab 栏）、title、menus 和路由。
 * menus 使用 NavigationMenuItem[] 实现，由系统统一渲染样式。
 * 各 Tab 页的 ViewModel 通过 @Param 回调把状态和操作函数传给 MainPage。
 */
import { ComponentContent, SymbolGlyphModifier } from '@kit.ArkUI'
import { promptAction } from '@kit.ArkUI'
import { window } from '@kit.ArkUI'
import { display } from '@kit.ArkUI'
import { themeManager, ThemeManager, AccountOption, AccountSwitchDialog, AccountSwitchDialogParams, AppRoutes, splitPlaceholderBuilder, CookieExpiredSignal, getGameName, DialogDedup, showFeedback, FeedbackType } from 'basic'
import { HomePage } from 'home'
import { CharactersPage } from 'characters'
import { MyPage } from 'account'
import { ToolsPage } from 'material'
import { GeetestSignal, GeetestQueueItem, showGeetestDialog, GeetestCenter, DeviceFpCenter, DeviceFpInvalidSignal } from 'verification'
import { FailedAccountInfo, GameId, GeetestVerifyInput, Logger } from 'core'
import { common } from '@kit.AbilityKit'
import BuildProfile from 'BuildProfile'


@Builder
function accountSwitchDialogBuilder(params: AccountSwitchDialogParams) {
  AccountSwitchDialog({ params: params })
}

const TAB_HOME = 0
const TAB_CHARACTERS = 1
const TAB_TOOLS = 2
const TAB_MY = 3

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

  readonly stack: NavPathStack = new NavPathStack()
  private placeholder: ComponentContent<object> | null = null
  private uiCtx: UIContext | null = null
  @Local private cookieExpiredSignal: CookieExpiredSignal = CookieExpiredSignal.getInstance()
  @Local private geetestSignal: GeetestSignal = GeetestSignal.getInstance()
  @Local private deviceFpInvalidSignal: DeviceFpInvalidSignal = DeviceFpInvalidSignal.getInstance()
  /** 用户是否请求取消全部验证队列 */
  private isGeetestCancelAllRequested: boolean = false
  /**
   * 人机验证框与"设备指纹无效"提示排队显示，同一时间只显示一个：
   * 一方显示中时另一方先挂起，关闭后再弹（指纹提示等人机验证队列全部处理完）
   */
  private isGeetestShowing: boolean = false
  private isGeetestPending: boolean = false
  private isFpPromptShowing: boolean = false
  private isFpPromptPending: boolean = false

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
    // 同一账号的登录过期弹框正在显示时，忽略重复触发
    const dedupKey = `cookie_expired:${info.username}`
    if (!DialogDedup.tryAcquire(dedupKey)) {
      return
    }
    ctx.getPromptAction().showDialog({
      title: $r('app.string.cookie_expired_dialog_title'),
      message: $r('app.string.cookie_expired_dialog_msg', info.nickname),
      buttons: [
        { text: $r('app.string.dialog_cancel'), color: '#999999' },
        { text: $r('app.string.cookie_expired_go_login'), color: '#E8534A' },
      ],
    }).then((result: promptAction.ShowDialogSuccessResponse) => {
      DialogDedup.release(dedupKey)
      if (result.index === 1) {
        this.stack.pushPathByName(AppRoutes.LOGIN, null)
      }
      // 若队列还有，继续弹下一个
      if (this.cookieExpiredSignal.queue.length > 0) {
        this.cookieExpiredSignal.queue = this.cookieExpiredSignal.queue
      }
    }).catch((_: Error | object) => {
      DialogDedup.release(dedupKey)
    })
  }

  /** 验证框标题栏：多账号排队时提示是哪个游戏账号（游戏名 · UID）；取不到游戏 UID 时显示米游社昵称 */
  private getGeetestLabel(item: GeetestQueueItem): string {
    return this.getGameAccountLabel(item.trigger.gameId, item.trigger.roleId, item.accountName)
  }

  /** "游戏名 · UID xxx"；roleId 为空时返回 fallback */
  private getGameAccountLabel(gameId: GameId, roleId: string, fallback: string): string {
    if (roleId.length === 0) {
      return fallback
    }
    let gameName = ''
    try {
      gameName = this.uiCtx?.getHostContext()?.resourceManager.getStringSync(getGameName(gameId).id) ?? ''
    } catch (_) {
    }
    return gameName.length > 0 ? `${gameName} · UID ${roleId}` : `UID ${roleId}`
  }

  /** 设备指纹无效（5003 / 10041）：统一提示，可直接重新生成设备指纹 */
  @Monitor('deviceFpInvalidSignal.version')
  onDeviceFpInvalid(_monitor: IMonitor): void {
    // 人机验证框显示中或还有排队项：等验证队列处理完再提示
    if (this.isGeetestShowing || this.geetestSignal.queueLength > 0) {
      this.isFpPromptPending = true
      return
    }
    this.showDeviceFpPrompt()
  }

  private showDeviceFpPrompt(): void {
    const ctx = this.uiCtx
    if (ctx === null) {
      DeviceFpCenter.dismiss()
      return
    }
    const signal = this.deviceFpInvalidSignal
    let fallback = ''
    try {
      fallback = ctx.getHostContext()?.resourceManager.getStringSync($r('app.string.device_fp_unknown_account').id) ?? ''
    } catch (_) {
    }
    const label = this.getGameAccountLabel(signal.gameId, signal.roleUid, fallback)
    this.isFpPromptShowing = true
    ctx.getPromptAction().showDialog({
      title: $r('app.string.device_fp_invalid_title'),
      message: $r('app.string.device_fp_invalid_msg', label, signal.retcode),
      buttons: [
        { text: $r('app.string.dialog_cancel'), color: '#999999' },
        // 弹框按钮宽度有限，用短文案（完整文案"重新生成设备指纹"会被截断）
        { text: $r('app.string.device_fp_regenerate_short'), color: '#E8534A' },
      ],
    }).then((result: promptAction.ShowDialogSuccessResponse) => {
      this.onDeviceFpPromptClosed()
      if (result.index !== 1) {
        DeviceFpCenter.dismiss()
        return
      }
      DeviceFpCenter.regenerate(ctx.getHostContext() as common.UIAbilityContext).then(() => {
        showFeedback(ctx, FeedbackType.SUCCESS, $r('app.string.device_fp_regenerate_success'))
      }).catch((e: Error | object) => {
        Logger.error('Main', `regenerate device fp failed: ${e instanceof Error ? e.message : String(e)}`)
        showFeedback(ctx, FeedbackType.ERROR, $r('app.string.device_fp_regenerate_failed'))
      })
    }).catch((_: Error | object) => {
      this.onDeviceFpPromptClosed()
      DeviceFpCenter.dismiss()
    })
  }

  /** "设备指纹无效"提示关闭：弹出挂起的人机验证框 */
  private onDeviceFpPromptClosed(): void {
    this.isFpPromptShowing = false
    if (this.isGeetestPending) {
      this.isGeetestPending = false
      this.showCurrentGeetest()
    }
  }

  @Monitor('geetestSignal.trigger')
  async onGeetestTriggered(_monitor: IMonitor): Promise<void> {
    if (this.geetestSignal.trigger === 0) { return }
    // "设备指纹无效"提示显示中：等它关闭后再弹验证框
    if (this.isFpPromptShowing) {
      this.isGeetestPending = true
      return
    }
    await this.showCurrentGeetest()
  }

  private async showCurrentGeetest(): Promise<void> {
    const item = this.geetestSignal.getCurrentItem()
    if (item === null) { return }

    const progress = this.geetestSignal.getProgress()
    const ctx = this.uiCtx
    if (ctx === null) { return }

    // 重置"取消全部"标记
    this.isGeetestCancelAllRequested = false

    // 弹出 Geetest 验证对话框
    this.isGeetestShowing = true
    let result: GeetestVerifyInput | null = null
    try {
      result = await showGeetestDialog(
        ctx,
        item.trigger.createResult,
        progress,
        this.getGeetestLabel(item)
      )
    } finally {
      this.isGeetestShowing = false
    }

    // 处理结果
    if (result !== null) {
      // 验证成功，回调原调用方
      // gt 来自 createResult，challenge 和 validate 来自验证结果
      const trigger = item.trigger
      this.geetestSignal.resolveSuccess(
        trigger.createResult.gt,
        result.geetest_challenge,
        result.geetest_validate
      )
    } else if (this.isGeetestCancelAllRequested) {
      // 用户请求取消全部队列
      this.geetestSignal.resolveCancelAll()
    } else {
      // 用户只取消当前项
      this.geetestSignal.resolveCancelCurrent()
    }
    // 人机验证队列全部处理完：弹出挂起的"设备指纹无效"提示
    if (this.geetestSignal.queueLength === 0 && this.isFpPromptPending) {
      this.isFpPromptPending = false
      this.showDeviceFpPrompt()
    }
  }


  private get homeMenuItems(): NavigationMenuItem[] {
    if (!this.shouldShowHomeRefresh) { return []; }
    return [{
      value: 'refresh',
      symbolIcon: new SymbolGlyphModifier($r('sys.symbol.arrow_clockwise')),
      isEnabled: !this.isHomeRefreshing,
      action: () => { this.homeDoRefresh() }
    }];
  }

  private get charMenuItems(): NavigationMenuItem[] {
    const items: NavigationMenuItem[] = [];
    if (this.shouldShowCharSwitcher) {
      items[items.length] = {
        value: 'switch_account',
        symbolIcon: new SymbolGlyphModifier($r('sys.symbol.person_2')),
        action: () => { this.showAccountSwitchSheet() }
      };
    }
    if (this.shouldShowCharRefresh) {
      items[items.length] = {
        value: 'refresh',
        symbolIcon: new SymbolGlyphModifier($r('sys.symbol.arrow_clockwise')),
        isEnabled: !this.isCharRefreshing,
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

  private getTabTitle(): Resource {
    if (this.selectedTab === TAB_HOME) { return $r('app.string.main_tab_home') }
    if (this.selectedTab === TAB_CHARACTERS) { return $r('app.string.characters_tab_title') }
    if (this.selectedTab === TAB_TOOLS) { return $r('app.string.tools_title') }
    return $r('app.string.main_tab_my')
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
      .title(this.getTabTitle())
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
          value: $r('app.string.tools_title'),
          symbolIcon: new SymbolGlyphModifier($r('sys.symbol.wrench_and_screwdriver'))
            .fontColor([this.tm.current.colorTextSecondary]),
          activeSymbolIcon: new SymbolGlyphModifier($r('sys.symbol.wrench_and_screwdriver'))
            .fontColor([this.tm.current.colorPrimary]),
          status: (this.selectedTab === TAB_TOOLS && this.tabVersion >= 0)
            ? ToolbarItemStatus.ACTIVE : ToolbarItemStatus.NORMAL,
          action: () => { this.selectedTab = TAB_TOOLS; this.tabVersion++; if (this.isSplit) { this.stack.clear() } }
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
export struct MainPagePreview {
  build() {
    MainPage()
  }
}
