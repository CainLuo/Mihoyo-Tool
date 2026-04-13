/**
 * Characters — 角色 Tab 页（View 层，普通内容组件）
 *
 * ViewModel 由 Characters 自己持有。
 * 通过 @Param 回调把操作函数和状态上报给 Main，由 Main 挂到 Navigation.menus()。
 */
import { BusinessError } from '@kit.BasicServicesKit'
import { themeManager, ThemeManager } from '../theme/ThemeManager'
import { CharactersViewModel } from '../viewmodel/CharactersViewModel'
import { AccountOption } from '../models/AccountOption'
import { CharactersContent } from '../components/characters/CharactersContent'
import { Logger } from 'core'
import { GenshinCharacterDetailParam } from './GenshinCharacterDetail'
import { GameDataSummary, GameId } from 'core'
import { AccountSignal } from '../utils/AccountSignal'
import { AppRoutes } from '../constants/AppRoutes'
import { CharDetailRouterParam } from '../components/chardetail/CharDetailModels'

@ComponentV2
export struct Characters {
  @Param detailStack: NavPathStack = new NavPathStack()
  @Param isSplit: boolean = false
  @Param onReady: (doRefresh: () => void, doSelectAccount: (idx: number) => void) => void =
    (_r: () => void, _s: (idx: number) => void) => {}
  @Param onMenuStateChange: (
    showRefresh: boolean,
    showSwitcher: boolean,
    isRefreshing: boolean,
    accountOptions: AccountOption[],
    selectedIdx: number
  ) => void = (_sr: boolean, _ss: boolean, _ir: boolean, _ao: AccountOption[], _si: number) => {}

  @Local private tm: ThemeManager = themeManager
  @Local private vm: CharactersViewModel = new CharactersViewModel()
  @Local private signal: AccountSignal = AccountSignal.instance()
  private uiCtx: UIContext | null = null
  private scroller: Scroller = new Scroller()

  aboutToAppear(): void {
    this.uiCtx = this.getUIContext()
    this.onReady(
      () => { this.vm.refresh() },
      (idx: number) => { this.vm.selectAccount(idx).catch((_: Error | object) => {}) }
    )
    this.vm.loadData().then(() => {
      this.notifyMenuState()
    }).catch((_: Error | object) => {})
  }

  @Monitor('signal.version')
  onAccountDataChanged(_monitor: IMonitor): void {
    this.vm.loadData().then(() => {
      this.notifyMenuState()
    }).catch((_: Error | object) => {})
  }

  @Monitor('vm.showRefreshButton')
  onShowRefreshChanged(_monitor: IMonitor): void { this.notifyMenuState() }

  @Monitor('vm.showAccountSwitcher')
  onShowSwitcherChanged(_monitor: IMonitor): void { this.notifyMenuState() }

  @Monitor('vm.isRefreshing')
  onIsRefreshingChanged(_monitor: IMonitor): void { this.notifyMenuState() }

  @Monitor('vm.accountOptions')
  onAccountOptionsChanged(_monitor: IMonitor): void { this.notifyMenuState() }

  @Monitor('vm.selectedAccountIdx')
  onSelectedAccountIdxChanged(_monitor: IMonitor): void { this.notifyMenuState() }

  private notifyMenuState(): void {
    this.onMenuStateChange(
      this.vm.showRefreshButton,
      this.vm.showAccountSwitcher,
      this.vm.isRefreshing,
      this.vm.accountOptions,
      this.vm.selectedAccountIdx
    )
  }

  @Monitor(CharactersViewModel.KEYS.networkErrorMsg)
  onNetworkError(_monitor: IMonitor): void {
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
      Logger.warn('Characters', 'showDialog failed: ' + e.message)
    })
  }

  @Monitor(CharactersViewModel.KEYS.refreshCoolingDown)
  onRefreshCoolingDown(_monitor: IMonitor): void {
    const ctx = this.uiCtx
    if (ctx === null) { return }
    ctx.getPromptAction().showDialog({
      title: $r('app.string.characters_refresh_cooldown_title'),
      message: $r('app.string.characters_refresh_cooldown_msg'),
      buttons: [
        { text: $r('app.string.dialog_cancel'), color: $r('app.color.color_text_secondary') },
        { text: $r('app.string.dialog_sync'), color: $r('app.color.color_accent') }
      ]
    }).then((result) => {
      if (result.index === 1) { this.vm.forceRefresh() }
    }).catch((e: BusinessError) => {
      Logger.warn('Characters', 'showDialog cooldown failed: ' + e.message)
    })
  }

  private onCardTap(character: GameDataSummary): void {
    const gameId = this.vm.gameTabs.length > 0
      ? this.vm.gameTabs[this.vm.selectedGameIdx].gameId : GameId.GENSHIN
    const roleUid = this.vm.gameTabs.length > 0
      ? this.vm.gameTabs[this.vm.selectedGameIdx].roleUid : ''
    const accountId = this.vm.accountOptions.length > 0
      ? this.vm.accountOptions[this.vm.selectedAccountIdx].accountId : ''

    if (gameId === GameId.GENSHIN) {
      const param = new GenshinCharacterDetailParam()
      param.accountId = accountId
      param.roleUid = roleUid
      param.entityId = character.entityId
      if (this.isSplit) {
        this.detailStack.replacePath({ name: AppRoutes.GENSHIN_CHARACTER_DETAIL, param: param })
      } else {
        this.detailStack.pushPath({ name: AppRoutes.GENSHIN_CHARACTER_DETAIL, param: param })
      }
    } else if (gameId === GameId.STARRAIL) {
      const param = new CharDetailRouterParam()
      param.accountId = accountId
      param.roleUid = roleUid
      param.entityId = character.entityId
      if (this.isSplit) {
        this.detailStack.replacePath({ name: AppRoutes.STARRAIL_CHARACTER_DETAIL, param: param })
      } else {
        this.detailStack.pushPath({ name: AppRoutes.STARRAIL_CHARACTER_DETAIL, param: param })
      }
    } else if (gameId === GameId.ZZZ) {
      const param = new CharDetailRouterParam()
      param.accountId = accountId
      param.roleUid = roleUid
      param.entityId = character.entityId
      if (this.isSplit) {
        this.detailStack.replacePath({ name: AppRoutes.ZZZ_CHARACTER_DETAIL, param: param })
      } else {
        this.detailStack.pushPath({ name: AppRoutes.ZZZ_CHARACTER_DETAIL, param: param })
      }
    }
    // 其他 gameId（如 honkai3）暂不跳转，静默忽略
  }

  build() {
    CharactersContent({
      tm: this.tm,
      vm: this.vm,
      scroller: this.scroller,
      onCardTap: (c: GameDataSummary) => { this.onCardTap(c) }
    })
  }
}
