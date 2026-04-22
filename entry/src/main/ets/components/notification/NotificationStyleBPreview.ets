/**
 * NotificationStyleBPreview — 样式 B 通知气泡预览（折叠 + 展开）
 */
import { themeManager, ThemeManager } from '../../theme/ThemeManager'
import { NotificationBubbleCollapsed } from './NotificationBubbleCollapsed'
import { NotificationBubbleExpanded } from './NotificationBubbleExpanded'

@ComponentV2
export struct NotificationStyleBPreview {
  @Local private tm: ThemeManager = themeManager

  build() {
    Column({ space: this.tm.current.value8 }) {
      Text($r('app.string.notification_style_b_title'))
        .font(this.tm.current.body10)
        .fontColor(this.tm.current.colorTextSecondary)
        .opacity(0.7)

      NotificationBubbleCollapsed()

      Text($r('app.string.notification_content_title_style_b_expanded'))
        .font(this.tm.current.body10)
        .fontColor(this.tm.current.colorTextSecondary)
        .opacity(0.7)
        .margin({ top: this.tm.current.value4 })

      NotificationBubbleExpanded()

      Text($r('app.string.notification_style_b_desc'))
        .font(this.tm.current.body10)
        .fontColor(this.tm.current.colorTextSecondary)
        .opacity(0.7)
    }
    .width(this.tm.current.full)
    .alignItems(HorizontalAlign.Start)
  }
}

// ─── Preview ─────────────────────────────────────────────────────

@Preview
@ComponentV2
export struct NotificationStyleBPreviewPreview {
  @Local private tm: ThemeManager = themeManager

  build() {
    Column() {
      NotificationStyleBPreview()
    }
    .padding(this.tm.current.value16)
    .backgroundColor('#1a1a2e')
  }
}
