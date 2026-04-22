/**
 * NotificationBubbleHeader — 通知气泡顶部（App 图标 + 名称 + 时间）
 */
import { themeManager, ThemeManager } from '../../theme/ThemeManager'

@ComponentV2
export struct NotificationBubbleHeader {
  @Local private tm: ThemeManager = themeManager

  build() {
    Row({ space: this.tm.current.value5 }) {
      Image($r('app.media.ic_app_logo'))
        .width(this.tm.current.value12)
        .height(this.tm.current.value12)
        .borderRadius(this.tm.current.value4)

      Text($r('app.string.app_name'))
        .font(this.tm.current.body10)
        .fontColor(this.tm.current.colorTextSecondary)

      Text($r('app.string.sync_just_now'))
        .font(this.tm.current.body10)
        .fontColor(this.tm.current.colorTextSecondary)
        .layoutWeight(1)
        .textAlign(TextAlign.End)
    }
    .width(this.tm.current.full)
  }
}
