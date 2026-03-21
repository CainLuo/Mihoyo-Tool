/**
 * CharactersSkeleton — 角色列表骨架屏
 *
 * 在 Characters 页面 loading 状态时展示，模拟角色卡片网格布局。
 * 仅在 Characters 页面使用。
 */

import { themeManager, ThemeManager } from '../../theme/ThemeManager';
import { AppConstants } from '../../constants/AppConstants';

@ComponentV2
export struct CharactersSkeleton {
  @Local private tm: ThemeManager = themeManager;

  build() {
    GridRow({
      columns: { xs: 2, sm: 3, md: 4, lg: 5 },
      gutter: { x: this.tm.current.value12, y: this.tm.current.value12 },
      breakpoints: {
        value: AppConstants.GRID_BREAKPOINTS,
        reference: BreakpointsReference.WindowSize
      }
    }) {
      ForEach(AppConstants.SKELETON_CHARACTER_INDICES, (skIdx: number) => {
        GridCol({ span: 1 }) {
          Column({ space: this.tm.current.value8 }) {
            Row()
              .width(this.tm.current.widthFull)
              .height(this.tm.current.skeletonBlockH)
              .borderRadius(this.tm.current.skeletonBlockR)
              .backgroundColor(this.tm.current.colorDivider)
            Row()
              .width(this.tm.current.skeletonTextW)
              .height(this.tm.current.skeletonBlockH)
              .borderRadius(this.tm.current.skeletonBlockR)
              .backgroundColor(this.tm.current.colorDivider)
            Row()
              .width(this.tm.current.value40)
              .height(this.tm.current.skeletonBlockH)
              .borderRadius(this.tm.current.skeletonBlockR)
              .backgroundColor(this.tm.current.colorDivider)
          }
          .width(this.tm.current.widthFull)
          .padding(this.tm.current.value12)
          .backgroundColor(this.tm.current.colorCardBg)
          .borderRadius(this.tm.current.radius12)
        }
      }, (skIdx: number) => `sk_${skIdx}`)
    }
    .width(this.tm.current.widthFull)
    .padding({ left: this.tm.current.value16, right: this.tm.current.value16 })
  }
}
