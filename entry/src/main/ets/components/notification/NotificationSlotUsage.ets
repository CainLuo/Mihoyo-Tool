/**
 * NotificationSlotUsage — 代理提醒槽位进度条
 */
import { themeManager, ThemeManager } from '../../theme/ThemeManager'
import { ThemeFonts } from '../../theme/ThemeFonts'
import { NotificationSettingsViewModel } from '../../viewmodel/NotificationSettingsViewModel'

@ComponentV2
export struct NotificationSlotUsage {
  @Param vm: NotificationSettingsViewModel = new NotificationSettingsViewModel()
  @Local private tm: ThemeManager = themeManager

  build() {
    Column({ space: this.tm.current.value8 }) {
      Row() {
        Text($r('app.string.notification_slot_usage'))
          .font(ThemeFonts.font14)
          .fontColor(this.tm.current.colorTextPrimary)
          .layoutWeight(1)

        Text(`${this.vm.reminderUsed} / ${this.vm.reminderLimit}`)
          .font(ThemeFonts.fontBold14)
          .fontColor(this.vm.slotColor())
      }
      .width(this.tm.current.full)

      Progress({
        value: this.vm.reminderUsed,
        total: this.vm.reminderLimit,
        type: ProgressType.Linear,
      })
        .color(this.vm.slotColor())
        .backgroundColor(this.tm.current.colorDivider)
        .width(this.tm.current.full)
        .height(this.tm.current.value4)

      Text($r('app.string.notification_slot_usage_desc'))
        .font(ThemeFonts.font11)
        .fontColor(this.tm.current.colorTextSecondary)
    }
    .width(this.tm.current.full)
    .padding(this.tm.current.font16)
    .backgroundColor(this.tm.current.colorSurfaceCard)
    .borderRadius(this.tm.current.radius12)
    .alignItems(HorizontalAlign.Start)
  }
}
