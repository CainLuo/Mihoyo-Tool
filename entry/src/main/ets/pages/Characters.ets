/**
 * Characters — 角色 Tab 页（View 层，纯内容组件）
 */
import { BusinessError } from '@kit.BasicServicesKit'
import { themeManager, ThemeManager } from '../theme/ThemeManager'
import { CharactersViewModel } from '../viewmodel/CharactersViewModel'
import { CharactersContent } from '../components/characters/CharactersContent'
import { Logger } from '../utils/Logger'
import { GenshinCharacterDetailParam, GenshinCharacterDetail } from './GenshinCharacterDetail'
import { GameDataSummary } from 'core'
import { AccountSignal } from '../utils/AccountSignal'

@Builder
export function charDetailBuilder(name: string, param: Object) {
  if (name === 'CharDetail') {
    GenshinCharacterDetail({ routerParam: param as GenshinCharacterDetailParam })
  }
}

@ComponentV2
export struct Characters {
  @Local private tm: ThemeManager = themeManager
  @Local private vm: CharactersViewModel = new CharactersViewModel()
  @Local private signal: AccountSignal = AccountSignal.instance()
  private uiCtx: UIContext | null = null
  private scroller: Scroller = new Scroller()
  @Param detailStack: NavPathStack | null = null
  @Param isSplit: boolean = false

  aboutToAppear(): void {
    this.uiCtx = this.getUIContext()
    this.vm.loadData()
  }

  @Monitor('signal.version')
  onAccountDataChanged(_monitor: IMonitor): void {
    this.vm.loadData()
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
      if (result.index === 1) {
        this.vm.forceRefresh()
      }
    }).catch((e: BusinessError) => {
      Logger.warn('Characters', 'showDialog cooldown failed: ' + e.message)
    })
  }

  private onCardTap(character: GameDataSummary): void {
    const gameId = this.vm.gameTabs.length > 0
      ? this.vm.gameTabs[this.vm.selectedGameIdx].gameId : 'genshin'
    const roleUid = this.vm.gameTabs.length > 0
      ? this.vm.gameTabs[this.vm.selectedGameIdx].roleUid : ''
    const accountId = this.vm.accountOptions.length > 0
      ? this.vm.accountOptions[this.vm.selectedAccountIdx].accountId : 0
    const param = new GenshinCharacterDetailParam()
    param.accountId = accountId
    param.roleUid = roleUid
    param.entityId = character.entityId

    if (this.isSplit) {
      this.detailStack?.replacePath({ name: 'CharDetail', param: param })
    } else {
      this.detailStack?.pushPath({ name: 'CharDetail', param: param })
    }
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
