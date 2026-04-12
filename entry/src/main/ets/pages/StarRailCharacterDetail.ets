/**
 * StarRailCharacterDetail — 星穹铁道角色详情页（View 层）
 */
import display from '@ohos.display'
import { window, UIContext } from '@kit.ArkUI'
import { themeManager, ThemeManager } from '../theme/ThemeManager'
import { StarRailCharacterDetailViewModel } from '../viewmodel/StarRailCharacterDetailViewModel'
import { CharDetailLoadingView } from '../components/chardetail/CharDetailLoadingView'
import { CharDetailEmptyView } from '../components/chardetail/CharDetailEmptyView'
import { StarRailCharDetailContent } from '../components/chardetail/StarRailCharDetailContent'
import { ViewState } from '../constants/ViewStates'
import { CharDetailRouterParam, CharDetailRankItem } from '../components/chardetail/CharDetailModels'

@ComponentV2
export struct StarRailCharacterDetail {
  @Param routerParam: CharDetailRouterParam = new CharDetailRouterParam()
  @Local private tm: ThemeManager = themeManager
  @Local private vm: StarRailCharacterDetailViewModel = new StarRailCharacterDetailViewModel()
  @Local private windowWidthVp: number = themeManager.current.value360
  @Local private windowHeightVp: number = 780

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
    this.vm.init(this.routerParam.accountId, this.routerParam.roleUid, this.routerParam.entityId)
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

  private isPortrait(): boolean {
    return this.windowWidthVp <= this.windowHeightVp
  }

  private heroHeight(): number {
    return this.isPortrait() ? this.tm.current.value260 : this.tm.current.value200
  }

  build() {
    NavDestination() {
      Column() {
        if (this.vm.viewState === ViewState.LOADING) {
          CharDetailLoadingView({ tm: this.tm })
        } else if (this.vm.viewState === ViewState.EMPTY || this.vm.viewState === ViewState.ERROR) {
          CharDetailEmptyView({ tm: this.tm })
        } else {
          Scroll() {
            Column() {
              this.HeroSection()
              StarRailCharDetailContent({ vm: this.vm })
            }
            .width(this.tm.current.full)
          }
          .scrollBar(BarState.Off)
          .width(this.tm.current.full)
          .height(this.tm.current.full)
          .align(Alignment.Top)
          .edgeEffect(EdgeEffect.Spring)
        }
      }
      .width(this.tm.current.full)
      .height(this.tm.current.full)
      .backgroundColor(this.tm.current.bgPageDeep)
    }
    .title($r('app.string.starrail_char_detail_title'))
    .hideTitleBar(false)
  }

  @Builder
  HeroSection() {
    Stack() {
      Column()
        .width(this.tm.current.full)
        .height(this.tm.current.full)
        .linearGradient({
          angle: this.tm.current.a150,
          colors: [[this.tm.current.bgPortrait1, 0], [this.tm.current.bgPortrait2, 1.0]]
        })
      if (this.vm.charImageUrl !== '') {
        // 立绘：贴右边，从顶部开始，高度撑满容器
        Image(this.vm.charImageUrl)
          .width('60%')
          .height(this.tm.current.full)
          .objectFit(ImageFit.Cover)
          .position({ x: '100%', y: 0 })
          .markAnchor({ x: '100%', y: 0 })
      }
      Column()
        .width(this.tm.current.full)
        .height(this.tm.current.full)
        .linearGradient({
          angle: this.tm.current.a90,
          colors: [[this.tm.current.overlayPortraitBase, 0], [this.tm.current.overlayPortraitStrong, 0.32],
            [this.tm.current.overlayPortraitMid, 0.55], [this.tm.current.colorTransparent, 1.0]]
        })
      Column()
        .width(this.tm.current.full)
        .height(this.tm.current.full)
        .linearGradient({
          angle: this.tm.current.a0,
          colors: [[this.tm.current.overlayPortraitBot, 0], [this.tm.current.colorTransparent, 0.45]]
        })
      Column({ space: this.tm.current.value4 }) {
        ForEach(this.vm.ranks, (rank: CharDetailRankItem) => {
          Column({ space: this.tm.current.value2 }) {
            if (rank.iconUrl !== '') {
              Image(rank.iconUrl)
                .width(this.tm.current.value28)
                .height(this.tm.current.value28)
                .objectFit(ImageFit.Contain)
                .opacity(rank.isActived ? 1.0 : this.tm.current.charDetailConsInactiveOpacity)
            } else {
              Column()
                .width(this.tm.current.value28)
                .height(this.tm.current.value28)
                .borderRadius(this.tm.current.value14)
                .backgroundColor(rank.isActived ? this.tm.current.accentPrimaryStrong : this.tm.current.surfaceDark2xl)
                .opacity(rank.isActived ? 1.0 : this.tm.current.charDetailConsInactiveOpacity)
            }
          }
          .width(this.tm.current.value36)
          .height(this.tm.current.value36)
          .borderRadius(this.tm.current.value8)
          .backgroundColor(rank.isActived ? this.tm.current.surfaceActivePrimary : this.tm.current.surfaceDark2xl)
          .justifyContent(FlexAlign.Center)
          .alignItems(HorizontalAlign.Center)
          .border({ width: this.tm.current.value1, color: rank.isActived ? this.tm.current.surfaceActiveBorder : this.tm.current.surfaceInactiveBorder })
        }, (rank: CharDetailRankItem) => `rank_${rank.pos}`)
      }
      .position({ x: this.tm.current.value12, y: 0 })
      .height(this.tm.current.full)
      .justifyContent(FlexAlign.Center)
      .alignItems(HorizontalAlign.Center)
      .zIndex(3)
      Column({ space: this.tm.current.value4 }) {
        Text(this.vm.charName)
          .fontSize(this.tm.current.value22)
          .fontWeight(FontWeight.Bold)
          .fontColor(this.tm.current.textOnDarkHigh)
          .textShadow({ radius: this.tm.current.value8, color: this.tm.current.overlayShadow, offsetY: 2 })
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
        Row({ space: this.tm.current.value8 }) {
          Text(`Lv.${this.vm.charLevel}`)
            .fontSize(this.tm.current.body12.size)
            .fontColor(this.tm.current.textOnDarkMedium)
          Text($r('app.string.starrail_char_detail_rank_prefix', this.vm.charRank))
            .fontSize(this.tm.current.body10.size)
            .fontWeight(FontWeight.Bold)
            .fontColor(this.tm.current.accentRefine)
            .backgroundColor(this.tm.current.accentRefineBg)
            .borderRadius(this.tm.current.value4)
            .padding({ left: this.tm.current.value4, right: this.tm.current.value4, top: this.tm.current.value1, bottom: this.tm.current.value1 })
        }
      }
      .width(this.tm.current.full)
      .height(this.tm.current.full)
      .alignItems(HorizontalAlign.Start)
      .justifyContent(FlexAlign.End)
      .padding({ left: this.tm.current.value56, right: this.tm.current.pct40, bottom: this.tm.current.value24 })
      .zIndex(2)
    }
    .width(this.tm.current.full)
    .height(this.heroHeight())
    .clip(true)
  }
}
