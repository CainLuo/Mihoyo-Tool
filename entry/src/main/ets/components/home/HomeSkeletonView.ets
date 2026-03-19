import { themeManager, ThemeManager } from '../../theme/ThemeManager'

/** 单个骨架色块，用 .animation() 属性动画实现呼吸效果 */
@ComponentV2
struct SkeletonBlock {
  @Local private tm: ThemeManager = themeManager
  @Param blockW: Length = themeManager.current.widthFull
  @Param blockH: number = themeManager.current.skeletonBlockH
  @Param blockR: number = themeManager.current.skeletonBlockR
  @Local private shimmerOpacity: number = themeManager.current.shimmerOpacityHigh

  aboutToAppear(): void {
    this.shimmerOpacity = this.tm.current.shimmerOpacityLow
  }

  build() {
    Row()
      .width(this.blockW)
      .height(this.blockH)
      .borderRadius(this.blockR)
      .backgroundColor(this.tm.current.colorDivider)
      .opacity(this.shimmerOpacity)
      .animation({
        duration: this.tm.current.animDurationShimmer,
        curve: Curve.EaseInOut,
        iterations: -1,
        playMode: PlayMode.Alternate
      })
  }
}

/** 单个账号区块的骨架 */
@ComponentV2
struct AccountSkeletonCard {
  @Local private tm: ThemeManager = themeManager

  build() {
    Column({ space: this.tm.current.value12 }) {
      Row({ space: this.tm.current.value12 }) {
          SkeletonBlock({ blockW: this.tm.current.skeletonAvatarSize, blockH: this.tm.current.skeletonAvatarSize, blockR: this.tm.current.avatarRadius })
        SkeletonBlock({ blockW: this.tm.current.skeletonTextW, blockH: this.tm.current.value16, blockR: this.tm.current.radius8 })
      }
      .width(this.tm.current.widthFull)
      .padding({ left: this.tm.current.value16, right: this.tm.current.value16 })

      Column({ space: this.tm.current.value12 }) {
        SkeletonBlock({ blockW: this.tm.current.widthFull, blockH: this.tm.current.skeletonCardH, blockR: this.tm.current.radius16 })
        SkeletonBlock({ blockW: this.tm.current.widthFull, blockH: this.tm.current.skeletonCardH, blockR: this.tm.current.radius16 })
      }
      .width(this.tm.current.widthFull)
      .padding({ left: this.tm.current.value16, right: this.tm.current.value16 })
    }
    .width(this.tm.current.widthFull)
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
      .width(this.tm.current.widthFull)
      .padding({ top: this.tm.current.value16 })
    }
    .scrollBar(BarState.Off)
    .layoutWeight(1)
  }
}
