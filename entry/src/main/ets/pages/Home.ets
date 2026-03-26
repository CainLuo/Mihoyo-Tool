/**
 * Home — 首页（View 层）
 */
import { themeManager, ThemeManager } from '../theme/ThemeManager'
import { HomeViewModel } from '../viewmodel/HomeViewModel'
import { GameRoleCardVM } from '../components/home/HomeModels'
import { HomeContent } from '../components/home/HomeContent'
import { showGeetestDialog } from '../components/GeetestDialog'
import { Logger } from '../utils/Logger'
import { RouterUtil } from '../utils/RouterUtil'
import { AppRoutes } from '../constants/AppRoutes'
import { GameId } from '../constants/GameId'
import { GenshinDailyDetailParam } from './GenshinDailyDetail'
import { BusinessError } from '@kit.BasicServicesKit'

@ComponentV2
export struct Home {
  @Param vm: HomeViewModel = new HomeViewModel()
  @Local private tm: ThemeManager = themeManager
  private uiCtx: UIContext | null = null
  private scroller: Scroller = new Scroller()

  aboutToAppear(): void {
    this.uiCtx = this.getUIContext()
    this.vm.loadData()
  }

  aboutToDisappear(): void {
    this.vm.dispose()
  }

  @Monitor(HomeViewModel.KEYS.networkErrorMsg)
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

  @Monitor(HomeViewModel.KEYS.refreshCoolingDown)
  onRefreshCoolingDown(_monitor: IMonitor): void {
    const ctx = this.uiCtx
    if (ctx === null) { return }
    ctx.getPromptAction().showDialog({
      title: $r('app.string.home_refresh_cooldown_title'),
      message: $r('app.string.home_refresh_cooldown_msg'),
      buttons: [{ text: $r('app.string.dialog_confirm'), color: $r('app.color.color_accent') }]
    }).catch((e: BusinessError) => {
      Logger.warn('Home', 'showDialog cooldown failed: ' + e.message)
    })
  }

  @Monitor(HomeViewModel.KEYS.geetestTrigger)
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
    HomeContent({
      tm: this.tm,
      vm: this.vm,
      scroller: this.scroller,
      onCardTap: (card: GameRoleCardVM) => {
        Logger.info('Home', `card tapped: ${card.gameId} ${card.roleUid}`)
        this.navigateToDetail(card)
      }
    })
  }

  private navigateToDetail(card: GameRoleCardVM): void {
    if (card.gameId === GameId.GENSHIN) {
      const param = new GenshinDailyDetailParam()
      param.gameId = card.gameId
      param.roleUid = card.roleUid
      RouterUtil.push(AppRoutes.GENSHIN_DAILY_DETAIL, param)
      return
    }
    Logger.info('Home', `no detail page for gameId: ${card.gameId}`)
  }
}
