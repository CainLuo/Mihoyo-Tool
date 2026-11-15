/**
 * HomePage — 首页（View 层，普通内容组件）
 *
 * ViewModel 由 HomePage 自己持有。
 * 通过 @Param 回调把操作函数和状态上报给 MainPage，由 MainPage 挂到 Navigation.menus()。
 */
import { themeManager, ThemeManager, GameRoleCardVM, UserGameSectionHeader, PlaceholderView, PlaceholderState, AccountSignal, SyncRetrySignal, ViewState, AppRoutes, showFeedback, DialogDedup, FeedbackType } from 'basic'
import { HomeViewModel } from '../viewmodel/HomeViewModel'
import { buildHomeListItems, HomeListDataSource, HomeListItem, HomeRoleItem, toggleCollapsedAccount } from '../viewmodel/HomeListDataSource'
import { HomeSkeletonView } from '../views/HomeSkeletonView'
import { GameToolCard } from '../views/GameToolCard'
import { Logger } from 'core'
import { BusinessError } from '@kit.BasicServicesKit'

@ComponentV2
export struct HomePage {
  @Param detailStack: NavPathStack = new NavPathStack()
  @Param isSplit: boolean = false
  @Param onReady: (doRefresh: () => void) => void = (_fn: () => void) => {}
  @Param onMenuStateChange: (shouldShowRefresh: boolean, isRefreshing: boolean) => void =
    (_s: boolean, _r: boolean) => {}
  @Local vm: HomeViewModel = new HomeViewModel()
  @Local private tm: ThemeManager = themeManager
  @Local private signal: AccountSignal = AccountSignal.getInstance()
  @Local private syncRetry: SyncRetrySignal = SyncRetrySignal.getInstance()
  /** 已折叠的账号 ID：列表内容由 rebuildList 显式推给数据源，无需参与状态观察 */
  private collapsedAccountIds: string[] = []
  /** 账号 + 角色扁平化列表的数据源（LazyForEach 用） */
  private listSource: HomeListDataSource = new HomeListDataSource()
  private uiCtx: UIContext | null = null

  aboutToAppear(): void {
    this.uiCtx = this.getUIContext()
    this.onReady(() => { this.vm.refresh() })
    this.vm.loadData()
  }

  aboutToDisappear(): void {
    this.vm.dispose()
  }

  @Monitor('signal.version')
  onAccountDataChanged(_monitor: IMonitor): void {
    this.vm.loadData()
  }

  @Monitor('vm.viewState')
  onViewStateChanged(_monitor: IMonitor): void {
    this.onMenuStateChange(this.vm.viewState === ViewState.DATA, this.vm.isRefreshing)
  }

  /** 账号 / 角色数据变化：重建扁平列表（LazyForEach 不会跟着普通数组自动刷新） */
  @Monitor('vm.accounts')
  onAccountsChanged(_monitor: IMonitor): void {
    this.rebuildList()
  }

  /** 按当前账号数据与折叠状态重建扁平列表 */
  private rebuildList(): void {
    this.listSource.setItems(buildHomeListItems(this.vm.accounts, this.collapsedAccountIds))
  }

  /** 折叠 / 展开某个账号 */
  private toggleAccount(accountId: string): void {
    this.collapsedAccountIds = toggleCollapsedAccount(this.collapsedAccountIds, accountId)
    this.rebuildList()
  }

  @Monitor('vm.isRefreshing')
  onIsRefreshingChanged(_monitor: IMonitor): void {
    this.onMenuStateChange(this.vm.viewState === ViewState.DATA, this.vm.isRefreshing)
  }

  @Monitor('vm.networkErrorMsg')
  onNetworkErrorChanged(_monitor: IMonitor): void {
    const msg = this.vm.networkErrorMsg
    if (msg === '') { return }
    this.vm.networkErrorMsg = ''
    const ctx = this.uiCtx
    if (ctx === null) { return }
    showFeedback(ctx, FeedbackType.ERROR, msg)
  }

  @Monitor('vm.isRefreshCoolingDown')
  onRefreshCoolingDown(_monitor: IMonitor): void {
    const ctx = this.uiCtx
    if (ctx === null) { return }
    // 冷却确认框正在显示时忽略重复点击
    if (!DialogDedup.tryAcquire('home_refresh_cooldown')) { return }
    ctx.getPromptAction().showDialog({
      title: $r('app.string.home_refresh_cooldown_title'),
      message: $r('app.string.home_refresh_cooldown_msg'),
      buttons: [
        { text: $r('app.string.dialog_cancel'), color: $r('app.color.gray_700') },
        { text: $r('app.string.dialog_sync'), color: $r('app.color.color_warning') }
      ]
    }).then((result) => {
      DialogDedup.release('home_refresh_cooldown')
      if (result.index === 1) { this.vm.forceRefresh() }
    }).catch((e: BusinessError) => {
      DialogDedup.release('home_refresh_cooldown')
      Logger.warn('Home', 'showDialog cooldown failed: ' + e.message)
    })
  }

  /** 人机验证通过 / 重新生成设备指纹后重新同步便笺 */
  @Monitor('syncRetry.version')
  onSyncRetry(_monitor: IMonitor): void {
    this.vm.forceRefresh()
  }

  @Monitor('vm.refreshResult')
  onRefreshResultChanged(_monitor: IMonitor): void {
    const result = this.vm.refreshResult
    if (result === '') { return }
    this.vm.refreshResult = ''
    const ctx = this.uiCtx
    if (ctx === null) { return }
    if (result === 'success') {
      showFeedback(ctx, FeedbackType.SUCCESS, $r('app.string.feedback_home_refresh_success'))
    } else {
      showFeedback(ctx, FeedbackType.ERROR, $r('app.string.feedback_refresh_error'))
    }
  }

  build() {
    if (this.vm.viewState === ViewState.LOADING) {
      HomeSkeletonView()
    } else if (this.vm.viewState === ViewState.EMPTY) {
      // 无账号：显示登录占位
      PlaceholderView({
        state: {
          icon: '🎮',
          title: $r('app.string.home_placeholder_title'),
          description: $r('app.string.home_placeholder_desc'),
          buttonText: $r('app.string.home_placeholder_button'),
          isButtonEnabled: true,
          onButtonTap: () => {
            if (this.isSplit) {
              this.detailStack.replacePath({ name: AppRoutes.LOGIN, param: null })
            } else {
              this.detailStack.pushPathByName(AppRoutes.LOGIN, null)
            }
          }
        } as PlaceholderState
      })
    } else {
      List() {
        LazyForEach(this.listSource, (item: HomeListItem, index: number) => {
          ListItem() {
            if (item instanceof HomeRoleItem) {
              // 自定义组件的通用属性作用于其根节点，因此用 Column 包一层做左右留白，
              // 避免 padding 落在卡片内部把内容挤窄。
              Column() {
                GameToolCard({
                  card: item.role,
                  onTap: (card: GameRoleCardVM) => {
                    this.navigateToDetail(item.account.accountId, card)
                  }
                })
              }
              .width(this.tm.current.full)
              .padding({ left: this.tm.current.font16, right: this.tm.current.font16 })
            } else {
              UserGameSectionHeader({
                account: item.account,
                isCollapsed: item.isCollapsed,
                onToggle: () => { this.toggleAccount(item.account.accountId) }
              })
            }
          }
          .width(this.tm.current.full)
          .margin({
            top: item instanceof HomeRoleItem
              ? (item.isFirstRoleInSection ? this.tm.current.value8 : this.tm.current.value12)
              : (index === 0 ? 0 : this.tm.current.font20)
          })
        }, (item: HomeListItem) => item.key)
      }
      .edgeEffect(EdgeEffect.Spring)
      .scrollBar(BarState.Off)
      .id('home_scroll')
      .width(this.tm.current.full)
      .height(this.tm.current.full)
      .padding({ top: this.tm.current.value8, bottom: this.tm.current.value40 })
    }
  }

  private navigateToDetail(accountId: string, card: GameRoleCardVM): void {
    const route = this.vm.buildCardTapRoute(accountId, card)
    if (route === null) { return }
    if (this.isSplit) {
      this.detailStack.replacePath({ name: route.routeName, param: route.param })
    } else {
      this.detailStack.pushPathByName(route.routeName, route.param)
    }
  }
}

// ─── Preview ─────────────────────────────────────────────────────

@Preview
@ComponentV2
export struct HomePagePreview {
  build() {
    HomePage()
  }
}
