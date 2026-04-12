/**
 * Home — 首页（View 层，普通内容组件）
 *
 * ViewModel 由 Home 自己持有。
 * 通过 @Param 回调把操作函数和状态上报给 Main，由 Main 挂到 Navigation.menus()。
 */
import { themeManager, ThemeManager } from '../theme/ThemeManager'
import { HomeViewModel } from '../viewmodel/HomeViewModel'
import { MihoyoAccountVM, GameRoleCardVM } from '../components/home/HomeModels'
import { UserGameSection } from '../components/home/UserGameSection'
import { HomeSkeletonView } from '../components/home/HomeSkeletonView'
import { HomePlaceholderView } from '../components/home/HomePlaceholderView'
import { showGeetestDialog } from '../components/GeetestDialog'
import { Logger } from '../utils/Logger'
import { AppRoutes } from '../constants/AppRoutes'
import { GameId } from '../constants/GameId'
import { GenshinDailyDetailParam } from './GenshinDailyDetail'
import { StarRailDailyDetailParam } from './StarRailDailyDetail'
import { ZZZDailyDetailParam } from './ZZZDailyDetail'
import { BusinessError } from '@kit.BasicServicesKit'
import { AccountSignal } from '../utils/AccountSignal'
import { ViewState } from '../constants/ViewStates'

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
    ctx.getPromptAction().showDialog({
      title: $r('app.string.home_network_error_title'),
      message: msg,
      buttons: [{ text: $r('app.string.dialog_confirm'), color: $r('app.color.color_accent') }]
    }).catch((e: BusinessError) => {
      Logger.warn('Home', 'showDialog failed: ' + e.message)
    })
  }

  @Monitor('vm.refreshCoolingDown')
  onRefreshCoolingDown(_monitor: IMonitor): void {
    const ctx = this.uiCtx
    if (ctx === null) { return }
    ctx.getPromptAction().showDialog({
      title: $r('app.string.home_refresh_cooldown_title'),
      message: $r('app.string.home_refresh_cooldown_msg'),
      buttons: [
        { text: $r('app.string.dialog_cancel'), color: $r('app.color.color_text_secondary') },
        { text: $r('app.string.dialog_sync'), color: $r('app.color.color_accent') }
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

  build() {
    if (this.vm.viewState === ViewState.LOADING) {
      HomeSkeletonView()
    } else if (this.vm.viewState === ViewState.EMPTY) {
      HomePlaceholderView()
    } else {
      Scroll(this.scroller) {
        Column({ space: this.tm.current.value20 }) {
          ForEach(this.vm.accounts, (account: MihoyoAccountVM) => {
            UserGameSection({
              account: account,
              onCardTap: (card: GameRoleCardVM) => {
                this.navigateToDetail(account.accountId, card)
              }
            })
          }, (account: MihoyoAccountVM) => `${account.accountId}_${account.roles.length}`)
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
    if (card.gameId === GameId.GENSHIN) {
      const param = new GenshinDailyDetailParam()
      param.accountId = accountId
      param.roleUid = card.roleUid
      if (this.isSplit) {
        this.detailStack.replacePath({ name: AppRoutes.GENSHIN_DAILY_DETAIL, param: param })
      } else {
        this.detailStack.pushPathByName(AppRoutes.GENSHIN_DAILY_DETAIL, param)
      }
      return
    }
    if (card.gameId === GameId.STARRAIL) {
      const param = new StarRailDailyDetailParam()
      param.accountId = accountId
      param.roleUid = card.roleUid
      if (this.isSplit) {
        this.detailStack.replacePath({ name: AppRoutes.STARRAIL_DAILY_DETAIL, param: param })
      } else {
        this.detailStack.pushPathByName(AppRoutes.STARRAIL_DAILY_DETAIL, param)
      }
      return
    }
    if (card.gameId === GameId.ZZZ) {
      const param = new ZZZDailyDetailParam()
      param.accountId = accountId
      param.roleUid = card.roleUid
      if (this.isSplit) {
        this.detailStack.replacePath({ name: AppRoutes.ZZZ_DAILY_DETAIL, param: param })
      } else {
        this.detailStack.pushPathByName(AppRoutes.ZZZ_DAILY_DETAIL, param)
      }
      return
    }
  }
}
