/**
 * NotificationSection — 通知设置页内容
 *
 * 包含：总开关、权限提示、槽位进度、样式选择、各账号游戏阈值。
 */
import { common } from '@kit.AbilityKit'
import { themeManager, ThemeManager } from '../../theme/ThemeManager'
import { NotificationSettingsViewModel } from '../../viewmodel/NotificationSettingsViewModel'
import { AccountNotificationConfig, NotificationStyle } from '../../notification/NotificationModels'
import { NotificationMasterToggle } from '../notification/NotificationMasterToggle'
import { NotificationPermissionWarning } from '../notification/NotificationPermissionWarning'
import { NotificationSlotUsage } from '../notification/NotificationSlotUsage'
import { NotificationStyleCard } from '../notification/NotificationStyleCard'
import { NotificationGameRow } from '../notification/NotificationGameRow'
import { NotificationAccountBlock } from '../notification/NotificationAccountBlock'

@ComponentV2
export struct NotificationSection {
  @Param context: common.UIAbilityContext | null = null
  @Local private tm: ThemeManager = themeManager
  @Local private vm: NotificationSettingsViewModel = new NotificationSettingsViewModel()

  aboutToAppear(): void {
    this.vm.loadSettings().catch((_: Error | object) => {})
  }

  @Monitor('vm.showLimitDialog')
  onLimitDialogChanged(_monitor: IMonitor): void {
    if (this.vm.showLimitDialog) {
      this.showLimitDialog()
      this.vm.showLimitDialog = false
    }
  }

  private showLimitDialog(): void {
    this.getUIContext().getPromptAction().showDialog({
      title: $r('app.string.notification_limit_dialog_title'),
      message: $r('app.string.notification_limit_dialog_msg'),
      buttons: [{ text: $r('app.string.notification_limit_dialog_confirm'), color: $r('app.color.color_primary') }],
    }).catch((_: Error | object) => {})
  }

  build() {
    Scroll() {
      Column({ space: this.tm.current.value12 }) {
        NotificationMasterToggle({ vm: this.vm, context: this.context })

        if (this.vm.enabled && this.vm.permissionDenied) {
          NotificationPermissionWarning()
        }

        if (this.vm.enabled && !this.vm.permissionDenied) {
          NotificationSlotUsage({ vm: this.vm })
        }

        if (this.vm.enabled && !this.vm.permissionDenied) {
          Column({ space: this.tm.current.value8 }) {
            NotificationStyleCard({
              style: NotificationStyle.STYLE_A,
              title: $r('app.string.notification_style_a_title'),
              desc: $r('app.string.notification_style_a_desc'),
              vm: this.vm,
            })
            NotificationStyleCard({
              style: NotificationStyle.STYLE_B,
              title: $r('app.string.notification_style_b_title'),
              desc: $r('app.string.notification_style_b_desc'),
              vm: this.vm,
            })
          }
          .width(this.tm.current.full)
          .padding(this.tm.current.value12)
          .backgroundColor(this.tm.current.colorSurfaceCard)
          .borderRadius(this.tm.current.radius12)
          .alignItems(HorizontalAlign.Start)
        }

        if (this.vm.enabled && !this.vm.permissionDenied) {
          ForEach(this.vm.accounts, (acct: AccountNotificationConfig) => {
            NotificationAccountBlock({ acct: acct, vm: this.vm })
          })
        }

        Row().height(this.tm.current.value40)
      }
      .width(this.tm.current.full)
      .padding({
        top: this.tm.current.font16,
        left: this.tm.current.font20,
        right: this.tm.current.font20,
      })
    }
    .scrollBar(BarState.Off)
    .width(this.tm.current.full)
    .height(this.tm.current.full)
    .align(Alignment.Top)
    .edgeEffect(EdgeEffect.Spring)
    .backgroundColor(this.tm.current.colorPageBg)
  }
}

// ─── Preview ─────────────────────────────────────────────────────

@Preview
@ComponentV2
export struct NotificationSectionPreview {
  build() {
    Column() {
      NotificationSection()
    }
    .backgroundColor('#1a1a2e')
  }
}
