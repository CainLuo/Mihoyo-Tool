/**
 * Home — 首页（View 层，普通内容组件）
 *
 * ViewModel 由 Home 自己持有。
 * 通过 @Param 回调把操作函数和状态上报给 Main，由 Main 挂到 Navigation.menus()。
 */
import { themeManager, ThemeManager } from '../theme/ThemeManager'
import { HomeViewModel } from '../viewmodel/HomeViewModel'
import { MihoyoAccountVM, GameRoleCardVM } from '../models/HomeModels'
import { UserGameSection } from '../components/home/UserGameSection'
import { HomeSkeletonView } from '../components/home/HomeSkeletonView'
import { HomePlaceholderView } from '../components/home/HomePlaceholderView'
import { showGeetestDialog } from '../components/GeetestDialogHelper'
import { Logger } from 'core'
import { BusinessError } from '@kit.BasicServicesKit'
import { AccountSignal } from '../utils/AccountSignal'
import { ViewState } from '../constants/ViewStates'
import { AppRoutes } from '../constants/AppRoutes'
import { showFeedback } from '../utils/FeedbackUtil'
import { FeedbackType } from '../constants/FeedbackType'

@ComponentV2
export struct Home {
  @Param detailStack: NavPathStack = new NavPathStack()
  @Param isSplit: boolean = false
  @Param onReady: (doRefresh: () => void) => void = (_fn: () => void) => {}
  @Param onMenuStateChange: (showRefresh: boolean, isRefreshing: boolean) => void =
    (_s: boolean, _r: boolean) => {}
  @Local vm: HomeViewModel = new HomeViewModel()
  @Local private tm: ThemeManager = themeManager
  @Local private signal: AccountSignal = AccountSignal.instance()
  private uiCtx: UIContext | null = null
  private scroller: Scroller = new Scroller()

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

  @Monitor('vm.refreshCoolingDown')
  onRefreshCoolingDown(_monitor: IMonitor): void {
    const ctx = this.uiCtx
    if (ctx === null) { return }
    ctx.getPromptAction().showDialog({
      title: $r('app.string.home_refresh_cooldown_title'),
      message: $r('app.string.home_refresh_cooldown_msg'),
      buttons: [
        { text: $r('app.string.dialog_cancel'), color: $r('app.color.gray_700') },
        { text: $r('app.string.dialog_sync'), color: $r('app.color.color_warning') }
      ]
    }).then((result) => {
      if (result.index === 1) { this.vm.forceRefresh() }
    }).catch((e: BusinessError) => {
      Logger.warn('Home', 'showDialog cooldown failed: ' + e.message)
    })
  }

  @Monitor('vm.geetestTrigger')
  onGeetestTriggerChanged(_monitor: IMonitor): void {
    const trigger = this.vm.geetestTrigger
    if (trigger === null) { return }
    const ctx = this.uiCtx
    if (ctx === null) { return }
    showGeetestDialog(ctx, trigger.createResult).then((result) => {
      this.vm.onGeetestResult(result)
    }).catch((e: BusinessError) => {
      Logger.error('Home', 'showGeetestDialog failed: ' + e.message)
      this.vm.onGeetestResult(null)
    })
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
      HomePlaceholderView({
        onTap: () => {
          if (this.isSplit) {
            this.detailStack.replacePath({ name: AppRoutes.LOGIN, param: null })
          } else {
            this.detailStack.pushPathByName(AppRoutes.LOGIN, null)
          }
        }
      })
    } else {
      Scroll(this.scroller) {
        Column({ space: this.tm.current.font20 }) {
          ForEach(this.vm.accounts, (account: MihoyoAccountVM) => {
            UserGameSection({
              account: account,
              onCardTap: (card: GameRoleCardVM) => {
                this.navigateToDetail(account.accountId, card)
              }
            })
          }, (account: MihoyoAccountVM) => {
            let key = account.accountId;
            for (let i = 0; i < account.roles.length; i++) {
              const r = account.roles[i];
              key += `_${r.roleUid}:${r.snapshot !== null ? r.snapshot.primaryCurrent : 'x'}`;
            }
            return key;
          })
          Row().height(this.tm.current.value40)
        }
        .width(this.tm.current.full)
        .padding({ top: this.tm.current.value8 })
      }
      .edgeEffect(EdgeEffect.Spring)
      .scrollBar(BarState.Off)
      .width(this.tm.current.full)
      .height(this.tm.current.full)
      .align(Alignment.Top)
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
export struct HomePreview {
  build() {
    Home()
  }
}
