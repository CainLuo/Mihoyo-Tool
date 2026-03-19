/**
 * GenshinDailyDetail — 原神实时便笺详情页（View 层）
 *
 * 通过 HMRouter 路由参数接收 gameId + roleUid，
 * 由 GenshinDailyDetailViewModel 从 DB 读取并解析数据。
 */

import display from '@ohos.display'
import { window, UIContext } from '@kit.ArkUI'
import { HMRouterMgr } from '@hadss/hmrouter'
import { themeManager, ThemeManager } from '../theme/ThemeManager'
import { DailyNoteGenshin } from '../components/dailynote/DailyNoteGenshin'
import { GenshinDailyDetailViewModel } from '../viewmodel/GenshinDailyDetailViewModel'

/** HMRouter 传入的路由参数 */
export class GenshinDailyDetailParam {
  gameId: string = 'genshin';
  roleUid: string = '';
}

@ComponentV2
export struct GenshinDailyDetail {
  @Param routerParam: GenshinDailyDetailParam = new GenshinDailyDetailParam()
  @Local private tm: ThemeManager = themeManager
  @Local private vm: GenshinDailyDetailViewModel = new GenshinDailyDetailViewModel()
  @Local private windowWidthVp: number = themeManager.current.windowWidthDefault

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
        if (err.code !== 0 || win === undefined) return
        try {
          win.on('windowSizeChange', this.sizeCallback)
        } catch (_e) {}
      })
    } catch (_e) {}

    this.vm.init(this.routerParam.gameId, this.routerParam.roleUid)
    this.vm.loadData()
  }

  aboutToDisappear(): void {
    const ctx = this.uiCtx
    if (ctx === null) return
    try {
      window.getLastWindow(ctx.getHostContext(), (err, win) => {
        if (err.code !== 0 || win === undefined) return
        try {
          win.off('windowSizeChange', this.sizeCallback)
        } catch (_e) {}
      })
    } catch (_e) {}
  }

  build() {
    Column() {
      // ── 导航栏 ──────────────────────────────────────────────
      Row() {
        Button({ type: ButtonType.Circle }) {
          Text('‹')
            .font(this.tm.current.title24Bold)
            .fontColor(this.tm.current.colorTextPrimary)
        }
        .width(this.tm.current.heightNavBar)
        .height(this.tm.current.heightNavBar)
        .backgroundColor(Color.Transparent)
        .onClick(() => { HMRouterMgr.pop() })

        Text($r('app.string.genshin_daily_title'))
          .font(this.tm.current.title18Bold)
          .fontColor(this.tm.current.colorTextPrimary)
          .layoutWeight(1)
          .textAlign(TextAlign.Center)

        Row().width(this.tm.current.heightNavBar)
      }
      .width(this.tm.current.widthFull)
      .height(this.tm.current.heightNavBar)
      .alignItems(VerticalAlign.Center)
      .backgroundColor(this.tm.current.colorCardBg)

      Divider().color(this.tm.current.colorDivider)

      // ── 内容区 ──────────────────────────────────────────────
      if (this.vm.viewState === 'loading') {
        Row() {
          LoadingProgress()
            .width(this.tm.current.progressSizeMD)
            .height(this.tm.current.progressSizeMD)
            .color(this.tm.current.colorPrimary)
        }
        .width(this.tm.current.widthFull)
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
      } else if (this.vm.viewState === 'empty' || this.vm.viewState === 'error') {
        Row() {
          Text($r('app.string.home_no_data_hint'))
            .font(this.tm.current.body13)
            .fontColor(this.tm.current.colorTextSecondary)
        }
        .width(this.tm.current.widthFull)
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
      } else {
        Scroll() {
          Column({ space: this.tm.current.value8 }) {
            Text($r('app.string.genshin_daily_data_delay_hint'))
              .font(this.tm.current.body13)
              .fontColor(this.tm.current.colorTextSecondary)
              .width(this.tm.current.widthFull)
              .padding({
                left: this.tm.current.value16,
                right: this.tm.current.value16,
                top: this.tm.current.value12
              })

            DailyNoteGenshin({ data: this.vm.note })
              .padding({ left: this.tm.current.value16, right: this.tm.current.value16 })
          }
          .width(this.tm.current.widthFull)
          .constraintSize({ maxWidth: this.tm.current.contentMaxWidth })
          .padding({ bottom: this.tm.current.value40 })
          .alignSelf(ItemAlign.Center)
        }
        .scrollBar(BarState.Off)
        .layoutWeight(1)
        .width(this.tm.current.widthFull)
        .align(Alignment.Top)
      }
    }
    .width(this.tm.current.widthFull)
    .height(this.tm.current.heightFull)
    .backgroundColor(this.tm.current.colorPageBg)
  }
}
