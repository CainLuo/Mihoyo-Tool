/**
 * AccountSkeletonCard — 单个账号区块的骨架卡片
 *
 * 仅在 HomeSkeletonView 中使用。
 */
import { themeManager, ThemeManager } from '../../theme/ThemeManager';
import { SkeletonBlock } from './SkeletonBlock';

@ComponentV2
export struct AccountSkeletonCard {
  @Local private tm: ThemeManager = themeManager;

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
