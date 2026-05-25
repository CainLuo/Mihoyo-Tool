/**
 * HomeSkeletonView — 首页骨架屏
 *
 * 在 HomeContent LOADING 状态时展示，模拟账号+游戏卡片布局。
 */
import { themeManager, ThemeManager } from '../../theme/ThemeManager';
import { AccountSkeletonCard } from './AccountSkeletonCard';

// ─── Preview ─────────────────────────────────────────────────────

@Preview
@ComponentV2
export struct HomeSkeletonViewPreview {
  build() {
    HomeSkeletonView()
      .height(themeManager.current.value600)
      .backgroundColor(themeManager.current.colorPageBg)
  }
}

@ComponentV2
export struct HomeSkeletonView {
  @Local private tm: ThemeManager = themeManager;

  build() {
    Scroll() {
      Column({ space: this.tm.current.font20 }) {
        AccountSkeletonCard()

        AccountSkeletonCard()

        Row().height(this.tm.current.value40)
      }
      .width(this.tm.current.full)
      .padding({ top: this.tm.current.font16 })
    }
    .scrollBar(BarState.Off)
    .layoutWeight(1)
  }
}
