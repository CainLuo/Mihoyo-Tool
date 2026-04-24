/**
 * SplitPlaceholder — 分栏占位组件
 *
 * 用于 Navigation splitPlaceholder，在分栏模式下右侧无内容时显示。
 * 参考官方示例（Navigation在分栏模式下页面有大量留白）：居中显示引导文字。
 * - SplitPlaceholder struct：标准组件，供普通场景使用
 * - splitPlaceholderBuilder：@Builder 函数，供 ComponentContent + wrapBuilder 使用
 */
import { themeManager, ThemeManager } from '../theme/ThemeManager'

@ComponentV2
export struct SplitPlaceholder {
  @Local private tm: ThemeManager = themeManager

  build() {
    Column() {
      Text($r('app.string.split_placeholder_hint'))
        .fontSize(this.tm.current.body16.size)
        .fontColor(this.tm.current.colorTextSecondary)
        .fontWeight(FontWeight.Medium)
        .textAlign(TextAlign.Center)
    }
    .width(this.tm.current.full)
    .height(this.tm.current.full)
    .justifyContent(FlexAlign.Center)
    .backgroundColor(this.tm.current.colorPageBg)
    .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.BOTTOM])
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
export struct SplitPlaceholderPreview {
  build() {
    SplitPlaceholder()
  }
}
