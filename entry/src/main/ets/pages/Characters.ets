/**
 * Characters — 角色 Tab 页（View 层）
 */
import { BusinessError } from '@kit.BasicServicesKit'
import { themeManager, ThemeManager } from '../theme/ThemeManager'
import { CharactersViewModel } from '../viewmodel/CharactersViewModel'
import { CharactersContent } from '../components/characters/CharactersContent'
import { Logger } from '../utils/Logger'
import { AppConstants } from '../constants/AppConstants'

@ComponentV2
export struct Characters {
  @Local private tm: ThemeManager = themeManager
  @Local private vm: CharactersViewModel = new CharactersViewModel()
  @Local private currentBreakpoint: string = 'xs'
  private uiCtx: UIContext | null = null
  private scroller: Scroller = new Scroller()

  aboutToAppear(): void {
    this.uiCtx = this.getUIContext()
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
      buttons: [{ text: $r('app.string.dialog_confirm'), color: $r('app.color.color_accent') }]
    }).catch((e: BusinessError) => {
      Logger.warn('Characters', 'showDialog cooldown failed: ' + e.message)
    })
  }

  build() {
    GridRow({
      columns: { xs: 1, sm: 1, md: 1, lg: 1 },
      breakpoints: { value: AppConstants.GRID_BREAKPOINTS, reference: BreakpointsReference.WindowSize }
    }) {
      GridCol({ span: 1 }) {
        CharactersContent({
          tm: this.tm,
          vm: this.vm,
          currentBreakpoint: this.currentBreakpoint,
          scroller: this.scroller
        })
      }
    }
    .onBreakpointChange((bp: string) => {
      this.currentBreakpoint = bp
    })
  }
}
