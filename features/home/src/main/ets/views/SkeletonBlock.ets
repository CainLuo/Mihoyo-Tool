/**
 * SkeletonBlock — 单个骨架色块，用 animation 修饰器实现无限呼吸效果
 *
 * 仅在 HomeSkeletonView 相关组件中使用。
 *
 * 注意：不要用 ctx.animateTo({ iterations: -1 }) 实现无限循环。
 * animateTo 是全局隐式动画，iterations: -1 会让动画永不结束，
 * 后续任何布局变化都会被同一个无限动画接管，表现为页面元素持续上下浮动。
 * 组件级 .animation() 只作用于本组件的属性变化，不会外溢。
 */
import { themeManager, ThemeManager } from 'basic';

@ComponentV2
export struct SkeletonBlock {
  @Local private tm: ThemeManager = themeManager;
  @Param blockWidth: Length = themeManager.current.full;
  @Param blockHeight: number = themeManager.current.value16;
  @Param blockRadius: number = themeManager.current.value8;
  @Local private shimmerOpacity: number = 1.0;

  build() {
    Row()
      .width(this.blockWidth)
      .height(this.blockHeight)
      .borderRadius(this.blockRadius)
      .opacity(this.shimmerOpacity)
      .animation({
        duration: this.tm.current.duration800,
        curve: Curve.EaseInOut,
        iterations: -1,
        playMode: PlayMode.Alternate
      })
      // 放在 .animation() 之后：换主题时颜色直接切换，不参与呼吸动画
      .backgroundColor(this.tm.current.colorSurfaceSubtle)
      .onAppear(() => {
        this.shimmerOpacity = this.tm.current.opacity03;
      })
  }
}
