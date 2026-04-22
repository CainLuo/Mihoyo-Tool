/**
 * NotificationMasterToggle — 通知总开关行
 */
import { common } from '@kit.AbilityKit'
import { themeManager, ThemeManager } from '../../theme/ThemeManager'
import { NotificationSettingsViewModel } from '../../viewmodel/NotificationSettingsViewModel'

@ComponentV2
export struct NotificationMasterToggle {
  @Param vm: NotificationSettingsViewModel = new NotificationSettingsViewModel()
  @Param context: common.UIAbilityContext | null = null
  @Local private tm: ThemeManager = themeManager

  build() {
    Row() {
      Column({ space: this.tm.current.value4 }) {
        Text($r('app.string.notification_master_switch'))
          .font(this.tm.current.body16)
          .fontColor(this.tm.current.colorTextPrimary)
        Text($r('app.string.notification_master_switch_desc'))
          .font(this.tm.current.body12)
          .fontColor(this.tm.current.colorTextSecondary)
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)

      Toggle({ type: ToggleType.Switch, isOn: this.vm.enabled })
        .onChange((isOn: boolean) => {
          if (this.context === null) { return }
          this.vm.onToggleEnabled(this.context, isOn).catch((_: Error | object) => {})
        })
        .selectedColor($r('app.color.color_primary'))
    }
    .width(this.tm.current.full)
    .padding({
      left: this.tm.current.value16,
      right: this.tm.current.value16,
      top: this.tm.current.value14,
      bottom: this.tm.current.value14,
    })
    .backgroundColor(this.tm.current.colorSurfaceCard)
    .borderRadius(this.tm.current.radius12)
  }
}
