/**
 * NotificationSlotUsage — 代理提醒槽位进度条
 */
import { themeManager, ThemeManager } from '../../theme/ThemeManager'
import { NotificationSettingsViewModel } from '../../viewmodel/NotificationSettingsViewModel'

@ComponentV2
export struct NotificationSlotUsage {
  @Param vm: NotificationSettingsViewModel = new NotificationSettingsViewModel()
  @Local private tm: ThemeManager = themeManager

  private slotColor(): Resource {
    const ratio = this.vm.reminderUsed / this.vm.reminderLimit
    if (ratio >= 1) { return $r('app.color.color_danger') }
    if (ratio >= 0.8) { return $r('app.color.color_warning') }
    return $r('app.color.color_primary')
  }

  build() {
    Column({ space: this.tm.current.value8 }) {
      Row() {
        Text($r('app.string.notification_slot_usage'))
          .font(this.tm.current.body13)
          .fontColor(this.tm.current.colorTextPrimary)
          .layoutWeight(1)
        Text(`${this.vm.reminderUsed} / ${this.vm.reminderLimit}`)
          .font(this.tm.current.body13Bold)
          .fontColor(this.slotColor())
      }
      .width(this.tm.current.full)

      Progress({
        value: this.vm.reminderUsed,
        total: this.vm.reminderLimit,
        type: ProgressType.Linear,
      })
        .color(this.slotColor())
        .backgroundColor(this.tm.current.colorDivider)
        .width(this.tm.current.full)
        .height(this.tm.current.value4)

      Text($r('app.string.notification_slot_usage_desc'))
        .font(this.tm.current.body10)
        .fontColor(this.tm.current.colorTextSecondary)
    }
    .width(this.tm.current.full)
    .padding(this.tm.current.value16)
    .backgroundColor(this.tm.current.colorSurfaceCard)
    .borderRadius(this.tm.current.radius12)
    .alignItems(HorizontalAlign.Start)
  }
}
