/**
 * ZZZDailyDetail — 绝区零实时便笺详情页（View 层）
 */

import display from '@ohos.display'
import { ThemeFonts } from '../theme/ThemeFonts'
import { window } from '@kit.ArkUI'
import { themeManager, ThemeManager } from '../theme/ThemeManager'
import { DailyNoteZZZ } from '../components/dailynote/zzz/DailyNoteZZZ'
import { ZZZDailyDetailViewModel } from '../viewmodel/ZZZDailyDetailViewModel'
import { ViewState } from '../constants/ViewStates'
import { DailyNoteLoadingView } from '../components/dailynote/common/DailyNoteLoadingView'
import { DailyNoteEmptyView } from '../components/dailynote/common/DailyNoteEmptyView'

export class ZZZDailyDetailParam {
  accountId: string = '';
  roleUid: string = '';
}

@ComponentV2
export struct ZZZDailyDetail {
  @Param routerParam: ZZZDailyDetailParam = new ZZZDailyDetailParam()
  @Local private tm: ThemeManager = themeManager
  @Local private vm: ZZZDailyDetailViewModel = new ZZZDailyDetailViewModel()
  @Local private windowWidthVp: number = themeManager.current.value360

  private uiCtx: UIContext | null = null

  private sizeCallback: (size: window.Size) => void = (size: window.Size) => {
    const ctx = this.uiCtx
    if (ctx !== null) {
      this.windowWidthVp = ctx.px2vp(size.width)
    }
  }

  aboutToAppear(): void {
    this.uiCtx = this.getUIContext()
    const ctx = this.uiCtx
    try {
      const d = display.getDefaultDisplaySync()
      this.windowWidthVp = ctx.px2vp(d.width)
    } catch (_e) {}
    try {
      window.getLastWindow(ctx.getHostContext(), (err, win) => {
        if (err.code !== 0 || win === undefined) { return }
        try { win.on('windowSizeChange', this.sizeCallback) } catch (_e) {}
      })
    } catch (_e) {}

    this.vm.init(this.routerParam.accountId, this.routerParam.roleUid)
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

  build() {
    NavDestination() {
      Column() {
        if (this.vm.viewState === ViewState.LOADING) {
          DailyNoteLoadingView()
        } else if (this.vm.viewState === ViewState.EMPTY || this.vm.viewState === ViewState.ERROR) {
          DailyNoteEmptyView()
        } else {
          Scroll() {
            Column({ space: this.tm.current.value8 }) {
              Text($r('app.string.genshin_daily_data_delay_hint'))
                .font(ThemeFonts.font14)
                .fontColor(this.tm.current.colorTextSecondary)
                .width(this.tm.current.full)
                .padding({
                  left: this.tm.current.font16,
                  right: this.tm.current.font16,
                  top: this.tm.current.value12
                })

              DailyNoteZZZ({ data: this.vm.note })
                .padding({ left: this.tm.current.font16, right: this.tm.current.font16 })
            }
            .width(this.tm.current.full)
            .constraintSize({ maxWidth: this.tm.current.value600 })
            .padding({ bottom: this.tm.current.value40 })
            .alignSelf(ItemAlign.Center)
          }
          .scrollBar(BarState.Off)
          .layoutWeight(1)
          .width(this.tm.current.full)
          .align(Alignment.Top)
          .edgeEffect(EdgeEffect.Spring)
        }
      }
      .width(this.tm.current.full)
      .height(this.tm.current.full)
      .backgroundColor(this.tm.current.colorPageBg)
      .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.BOTTOM])
    }
    .title($r('app.string.zzz_daily_title'))
    .hideTitleBar(false)
  }
}

// ─── Preview ─────────────────────────────────────────────────────

@Preview
@ComponentV2
export struct ZZZDailyDetailPreview {
  build() {
    ZZZDailyDetail({ routerParam: new ZZZDailyDetailParam() })
  }
}

// ─── Router Builder ───────────────────────────────────────────────

@Builder
export function ZZZDailyDetailBuilder(_name: string, param: Object) {
  ZZZDailyDetail({ routerParam: param as ZZZDailyDetailParam })
}
