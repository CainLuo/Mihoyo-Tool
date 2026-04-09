/**
 * CharactersSkeleton — 角色列表骨架屏
 *
 * 在 Characters 页面 loading 状态时展示，模拟角色卡片网格布局。
 * 仅在 Characters 页面使用。
 */

import { themeManager, ThemeManager } from '../../theme/ThemeManager';
import { AppConstants } from '../../constants/AppConstants';

@Preview
@ComponentV2
export struct CharactersSkeletonPreview {
  build() {
    CharactersSkeleton()
      .height(themeManager.current.value600)
      .backgroundColor(themeManager.current.colorPageBg)
  }
}

@ComponentV2
export struct CharactersSkeleton {
  @Local private tm: ThemeManager = themeManager;
  @Local private imgOpacity: number = themeManager.current.shimmerOpacityHigh;
  private uiCtx: UIContext | null = null;

  aboutToAppear(): void {
    this.uiCtx = this.getUIContext();
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
        this.imgOpacity = this.tm.current.shimmerOpacityLow;
      }
    );
  }

  build() {
    GridRow({
      columns: 2,
      gutter: { x: this.tm.current.value12, y: this.tm.current.value12 },
      breakpoints: {
        value: AppConstants.GRID_BREAKPOINTS,
        reference: BreakpointsReference.WindowSize
      }
    }) {
      ForEach(AppConstants.SKELETON_CHARACTER_INDICES, (skIdx: number) => {
        GridCol({ span: 1 }) {
          Column() {
            // 模拟 1:1 图片区
            Row()
              .width(this.tm.current.full)
              .aspectRatio(1)
              .backgroundColor(this.tm.current.colorSkeletonBg)
              .opacity(this.imgOpacity)

            // 模拟等级 + 好感度信息行
            Row()
              .width(this.tm.current.value120)
              .height(this.tm.current.value16)
              .borderRadius(this.tm.current.value4)
              .backgroundColor(this.tm.current.colorSkeletonBg)
              .opacity(this.imgOpacity)
              .margin(this.tm.current.value8)
          }
          .width(this.tm.current.full)
          .backgroundColor(this.tm.current.colorSurfaceCard)
          .borderRadius(this.tm.current.radius12)
          .border({ width: this.tm.current.value1, color: this.tm.current.colorCardBorder })
          .clip(true)
        }
      }, (skIdx: number) => `sk_${skIdx}`)
    }
    .width(this.tm.current.full)
    .padding({ left: this.tm.current.value16, right: this.tm.current.value16 })
  }
}
