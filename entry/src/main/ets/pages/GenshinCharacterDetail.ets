/**
 * GenshinCharacterDetail — 角色详情页（View 层）
 */
import display from '@ohos.display'
import { window, UIContext } from '@kit.ArkUI'
import { themeManager, ThemeManager } from '../theme/ThemeManager'
import { GenshinCharacterDetailViewModel } from '../viewmodel/GenshinCharacterDetailViewModel'
import { CharDetailLoadingView } from '../components/chardetail/CharDetailLoadingView'
import { CharDetailEmptyView } from '../components/chardetail/CharDetailEmptyView'
import { CharDetailPortraitLayout } from '../components/chardetail/CharDetailPortraitLayout'
import { CharDetailLandscapeLayout } from '../components/chardetail/CharDetailLandscapeLayout'
import { CharDetailWideLayout } from '../components/chardetail/CharDetailWideLayout'
import { ViewState } from '../constants/ViewStates'

export class GenshinCharacterDetailParam {
  gameId: string = 'genshin'
  roleUid: string = ''
  entityId: string = ''
}

@ComponentV2
export struct GenshinCharacterDetail {
  @Param routerParam: GenshinCharacterDetailParam = new GenshinCharacterDetailParam()
  @Local private tm: ThemeManager = themeManager
  @Local private vm: GenshinCharacterDetailViewModel = new GenshinCharacterDetailViewModel()
  @Local private windowWidthVp: number = themeManager.current.value360
  @Local private windowHeightVp: number = 780
  @Local private currentBreakpoint: string = 'xs'

  private uiCtx: UIContext | null = null

  private sizeCallback: (size: window.Size) => void = (size: window.Size) => {
    const ctx = this.uiCtx
    if (ctx !== null) {
      this.windowWidthVp = ctx.px2vp(size.width)
      this.windowHeightVp = ctx.px2vp(size.height)
    }
  }

  aboutToAppear(): void {
    this.uiCtx = this.getUIContext()
    const ctx = this.uiCtx
    try {
      const d = display.getDefaultDisplaySync()
      this.windowWidthVp = ctx.px2vp(d.width)
      this.windowHeightVp = ctx.px2vp(d.height)
    } catch (_e) {}
    try {
      window.getLastWindow(ctx.getHostContext(), (err, win) => {
        if (err.code !== 0 || win === undefined) { return }
        try { win.on('windowSizeChange', this.sizeCallback) } catch (_e) {}
      })
    } catch (_e) {}
    this.vm.init(this.routerParam.gameId, this.routerParam.roleUid, this.routerParam.entityId)
    this.vm.loadData()
  }

  aboutToDisappear(): void {
    const ctx = this.uiCtx
    if (ctx === null) { return }
    try {
      window.getLastWindow(ctx.getHostContext(), (err, win) => {
        if (err.code !== 0 || win === undefined) { return }
        try { win.off('windowSizeChange', this.sizeCallback) } catch (_e) {}
      })
    } catch (_e) {}
  }

  private isPhoneLandscape(): boolean {
    return this.currentBreakpoint === 'xs' && this.windowWidthVp > this.windowHeightVp
  }

  private isPhonePortrait(): boolean {
    return this.currentBreakpoint === 'xs' && this.windowWidthVp <= this.windowHeightVp
  }

  build() {
    NavDestination() {
      Column() {
        if (this.vm.viewState === ViewState.LOADING) {
          CharDetailLoadingView({ tm: this.tm })
        } else if (this.vm.viewState === ViewState.EMPTY || this.vm.viewState === ViewState.ERROR) {
          CharDetailEmptyView({ tm: this.tm })
        } else {
          if (this.isPhonePortrait()) {
            CharDetailPortraitLayout({ tm: this.tm, vm: this.vm })
          } else if (this.isPhoneLandscape()) {
            CharDetailLandscapeLayout({ tm: this.tm, vm: this.vm })
          } else {
            CharDetailWideLayout({ tm: this.tm, vm: this.vm })
          }
        }
      }
      .width(this.tm.current.full)
      .height(this.tm.current.full)
      .backgroundColor(this.tm.current.bgPageDeep)
      .onAreaChange((_old, newArea) => {
        const w = newArea.width as number
        if (w < 600) { this.currentBreakpoint = 'xs' }
        else if (w < 840) { this.currentBreakpoint = 'sm' }
        else if (w < 1200) { this.currentBreakpoint = 'md' }
        else { this.currentBreakpoint = 'lg' }
      })
    }
    .title($r('app.string.char_detail_title'))
    .hideTitleBar(false)
  }
}
