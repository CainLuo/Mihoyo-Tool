/**
 * SkeletonBlock — 单个骨架色块，用 animateTo 实现无限呼吸效果
 *
 * 仅在 HomeSkeletonView 相关组件中使用。
 */
import { themeManager, ThemeManager } from '../../theme/ThemeManager';

@ComponentV2
export struct SkeletonBlock {
  @Local private tm: ThemeManager = themeManager;
  @Param blockW: Length = themeManager.current.full;
  @Param blockH: number = themeManager.current.value16;
  @Param blockR: number = themeManager.current.value8;
  @Local private shimmerOpacity: number = themeManager.current.shimmerOpacityHigh;
  private uiCtx: UIContext | null = null;

  aboutToAppear(): void {
    this.uiCtx = this.getUIContext();
    this.startShimmer();
  }

  private startShimmer(): void {
    const ctx = this.uiCtx;
    if (ctx === null) { return; }
    ctx.animateTo(
      {
        duration: this.tm.current.value800,
        curve: Curve.EaseInOut,
        iterations: -1,
        playMode: PlayMode.Alternate
      },
      () => {
        this.shimmerOpacity = this.tm.current.shimmerOpacityLow;
      }
    );
  }

  build() {
    Row()
      .width(this.blockW)
      .height(this.blockH)
      .borderRadius(this.blockR)
      .backgroundColor(this.tm.current.colorSurfaceSubtle)
      .opacity(this.shimmerOpacity)
  }
}
