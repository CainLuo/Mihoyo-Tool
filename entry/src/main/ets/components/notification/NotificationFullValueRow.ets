/**
 * NotificationFullValueRow — 快捷设置满值行
 */
import { themeManager, ThemeManager } from '../../theme/ThemeManager'
import { ThemeFonts } from '../../theme/ThemeFonts'
import { NotificationSettingsViewModel } from '../../viewmodel/NotificationSettingsViewModel'

@ComponentV2
export struct NotificationFullValueRow {
  @Param accountId: string = ''
  @Param vm: NotificationSettingsViewModel = new NotificationSettingsViewModel()
  @Local private tm: ThemeManager = themeManager

  build() {
    Row() {
      Column({ space: this.tm.current.value4 }) {
        Text($r('app.string.notification_full_value_shortcut'))
          .font(ThemeFonts.font14)
          .fontColor(this.tm.current.colorTextPrimary)

        Text($r('app.string.notification_full_value_shortcut_desc'))
          .font(ThemeFonts.font11)
          .fontColor(this.tm.current.colorTextSecondary)
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)

      Row() {
        Text($r('app.string.notification_full_value_set'))
          .fontSize(this.tm.current.font13)
          .fontWeight(FontWeight.Normal)
          .fontColor($r('app.color.color_primary'))
      }
      .height(this.tm.current.value32)
      .padding({ left: this.tm.current.value12, right: this.tm.current.value12 })
      .borderRadius(this.tm.current.radius8)
      .border({ width: this.tm.current.value1, color: $r('app.color.color_primary') })
      .onClick(() => {
        this.vm.onFullValueShortcut(this.accountId).catch((_: Error | object) => {})
      })
    }
    .width(this.tm.current.full)
    .height(this.tm.current.value50)
    .padding({ left: this.tm.current.font16, right: this.tm.current.font16 })
  }
}
