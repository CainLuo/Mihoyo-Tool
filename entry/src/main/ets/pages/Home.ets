/**
 * Home — 首页（View 层）
 *
 * vm 由 Home 自己持有（@Local），通过 onVmReady 回调把引用传给 Main，
 * 让 Main 的刷新按钮能访问 vm 状态，同时避免双实例问题。
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
import { BusinessError } from '@kit.BasicServicesKit'
import { AccountSignal } from '../utils/AccountSignal'
import { ViewState } from '../constants/ViewStates'

@ComponentV2
export struct Home {
  @Param detailStack: NavPathStack = new NavPathStack()
  @Param isSplit: boolean = false
  /** Main 通过此回调拿到 vm 引用，用于刷新按钮 */
  @Event onVmReady: (vm: HomeViewModel) => void = (_vm: HomeViewModel) => {}
  @Local vm: HomeViewModel = new HomeViewModel()
  @Local private tm: ThemeManager = themeManager
  @Local private signal: AccountSignal = AccountSignal.instance()
  private uiCtx: UIContext | null = null
  private scroller: Scroller = new Scroller()

  aboutToAppear(): void {
    this.uiCtx = this.getUIContext()
    this.onVmReady(this.vm)
    this.vm.loadData()
  }

  aboutToDisappear(): void {
    this.vm.dispose()
  }

  @Monitor('signal.version')
  onAccountDataChanged(_monitor: IMonitor): void {
    this.vm.loadData()
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
      if (result.index === 1) {
        this.vm.forceRefresh()
      }
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
                Logger.info('Home', `card tapped: ${card.gameId} ${card.roleUid}`)
                this.navigateToDetail(card)
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

  private navigateToDetail(card: GameRoleCardVM): void {
    if (card.gameId === GameId.GENSHIN) {
      const param = new GenshinDailyDetailParam()
      param.gameId = card.gameId
      param.roleUid = card.roleUid
      if (this.isSplit) {
        this.detailStack.replacePath({ name: AppRoutes.GENSHIN_DAILY_DETAIL, param: param })
      } else {
        this.detailStack.pushPathByName(AppRoutes.GENSHIN_DAILY_DETAIL, param)
      }
      return
    }
    Logger.info('Home', `no detail page for gameId: ${card.gameId}`)
  }
}
