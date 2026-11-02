/**
 * SkeletonBlock — 单个骨架色块，用 animateTo 实现无限呼吸效果
 *
 * 仅在 HomeSkeletonView 相关组件中使用。
 */
import { themeManager, ThemeManager } from 'basic';

@ComponentV2
export struct SkeletonBlock {
  @Local private tm: ThemeManager = themeManager;
  @Param blockWidth: Length = themeManager.current.full;
  @Param blockHeight: number = themeManager.current.value16;
  @Param blockRadius: number = themeManager.current.value8;
  @Local private shimmerOpacity: number = 1.0;
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
        duration: this.tm.current.duration800,
        curve: Curve.EaseInOut,
        iterations: -1,
        playMode: PlayMode.Alternate
      },
      () => {
        this.shimmerOpacity = this.tm.current.opacity03;
      }
    );
  }

  build() {
    Row()
      .width(this.blockWidth)
      .height(this.blockHeight)
      .borderRadius(this.blockRadius)
      .backgroundColor(this.tm.current.colorSurfaceSubtle)
      .opacity(this.shimmerOpacity)
  }
}
