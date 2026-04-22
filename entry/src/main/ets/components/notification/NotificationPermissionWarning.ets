/**
 * NotificationPermissionWarning — 通知权限被拒绝提示
 */
import { themeManager, ThemeManager } from '../../theme/ThemeManager'

@ComponentV2
export struct NotificationPermissionWarning {
  @Local private tm: ThemeManager = themeManager

  build() {
    Row({ space: this.tm.current.value8 }) {
      Text($r('app.string.notification_warning_icon'))
        .fontSize(this.tm.current.value16)
      Column({ space: this.tm.current.value4 }) {
        Text($r('app.string.notification_permission_denied_title'))
          .font(this.tm.current.body13Bold)
          .fontColor(this.tm.current.colorWarning)
        Text($r('app.string.notification_permission_denied_desc'))
          .font(this.tm.current.body12)
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
