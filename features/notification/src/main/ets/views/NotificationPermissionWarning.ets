/**
 * NotificationPermissionWarning — 通知权限被拒绝提示
 */
import { themeManager, ThemeManager, ThemeFonts } from 'basic'

@ComponentV2
export struct NotificationPermissionWarning {
  @Local private tm: ThemeManager = themeManager

  build() {
    Row({ space: this.tm.current.value8 }) {
      Text($r('app.string.notification_warning_icon'))
        .fontSize(this.tm.current.font16)
      Column({ space: this.tm.current.value4 }) {
        Text($r('app.string.notification_permission_denied_title'))
          .font(ThemeFonts.FONT_BOLD_14)
          .fontColor(this.tm.current.colorWarning)
        Text($r('app.string.notification_permission_denied_desc'))
          .font(ThemeFonts.FONT_13)
          .fontColor(this.tm.current.colorWarning)
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)
    }
    .width(this.tm.current.full)
    .padding(this.tm.current.value12)
    .backgroundColor(this.tm.current.colorDangerBg)
    .borderRadius(this.tm.current.radius12)
  }
}
