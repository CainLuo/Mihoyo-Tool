import { themeManager, ThemeManager } from '../../theme/ThemeManager'

@Preview
@ComponentV2
export struct HomeSkeletonViewPreview {
  build() {
    HomeSkeletonView()
      .height(themeManager.current.value600)
      .backgroundColor(themeManager.current.colorPageBg)
  }
}

/** 单个骨架色块，用 animateTo 实现无限呼吸效果 */
@ComponentV2
struct SkeletonBlock {
  @Local private tm: ThemeManager = themeManager
  @Param blockW: Length = themeManager.current.full
  @Param blockH: number = themeManager.current.value16
  @Param blockR: number = themeManager.current.value8
  @Local private shimmerOpacity: number = themeManager.current.shimmerOpacityHigh
  private uiCtx: UIContext | null = null

  aboutToAppear(): void {
    this.uiCtx = this.getUIContext()
    this.startShimmer()
  }

  private startShimmer(): void {
    const ctx = this.uiCtx
    if (ctx === null) { return }
    ctx.animateTo(
      {
        duration: this.tm.current.value800,
        curve: Curve.EaseInOut,
        iterations: -1,
        playMode: PlayMode.Alternate
      },
      () => {
        this.shimmerOpacity = this.tm.current.shimmerOpacityLow
      }
    )
  }

  build() {
    Row()
      .width(this.blockW)
      .height(this.blockH)
      .borderRadius(this.blockR)
      .backgroundColor(this.tm.current.colorSkeletonBg)
      .opacity(this.shimmerOpacity)
  }
}

/** 单个账号区块的骨架 */
@ComponentV2
struct AccountSkeletonCard {
  @Local private tm: ThemeManager = themeManager

  build() {
    Column({ space: this.tm.current.value12 }) {
      Row({ space: this.tm.current.value12 }) {
          SkeletonBlock({ blockW: this.tm.current.value36, blockH: this.tm.current.value36, blockR: this.tm.current.value18 })
        SkeletonBlock({ blockW: this.tm.current.value120, blockH: this.tm.current.value16, blockR: this.tm.current.radius8 })
      }
      .width(this.tm.current.full)
      .padding({ left: this.tm.current.value16, right: this.tm.current.value16 })

      Column({ space: this.tm.current.value12 }) {
        SkeletonBlock({ blockW: this.tm.current.full, blockH: this.tm.current.value100, blockR: this.tm.current.radius16 })
        SkeletonBlock({ blockW: this.tm.current.full, blockH: this.tm.current.value100, blockR: this.tm.current.radius16 })
      }
      .width(this.tm.current.full)
      .padding({ left: this.tm.current.value16, right: this.tm.current.value16 })
    }
    .width(this.tm.current.full)
  }
}

/** 首页骨架屏 */
@ComponentV2
export struct HomeSkeletonView {
  @Local private tm: ThemeManager = themeManager

  build() {
    Scroll() {
      Column({ space: this.tm.current.value20 }) {
        AccountSkeletonCard()
        AccountSkeletonCard()
        Row().height(this.tm.current.value40)
      }
      .width(this.tm.current.full)
      .padding({ top: this.tm.current.value16 })
    }
    .scrollBar(BarState.Off)
    .layoutWeight(1)
  }
}
