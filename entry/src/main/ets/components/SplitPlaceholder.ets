/**
 * SplitPlaceholder — 分栏占位组件
 *
 * 用于 Navigation splitPlaceholder，在分栏模式下右侧无内容时显示空白背景。
 * - SplitPlaceholder struct：标准组件，供普通场景使用
 * - splitPlaceholderBuilder：@Builder 函数，供 ComponentContent + wrapBuilder 使用
 */
import { themeManager, ThemeManager } from '../theme/ThemeManager'

@ComponentV2
export struct SplitPlaceholder {
  @Local private tm: ThemeManager = themeManager

  build() {
    Column()
      .width(this.tm.current.full)
      .height(this.tm.current.full)
      .backgroundColor(this.tm.current.colorPageBg)
  }
}

// ComponentContent + wrapBuilder 要求必须是模块级 @Builder 函数
@Builder
export function splitPlaceholderBuilder() {
  SplitPlaceholder()
}

// ─── Preview ─────────────────────────────────────────────────────

@Preview
@ComponentV2
struct SplitPlaceholderPreview {
  build() {
    SplitPlaceholder()
  }
}
