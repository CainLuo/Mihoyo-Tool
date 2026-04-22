/**
 * NotificationAccountBlock — 通知设置页账号折叠区块
 */
import { themeManager, ThemeManager } from '../../theme/ThemeManager'
import { AccountNotificationConfig, GameNotificationConfig } from '../../notification/NotificationModels'
import { NotificationSettingsViewModel } from '../../viewmodel/NotificationSettingsViewModel'
import { NotificationGameRow } from './NotificationGameRow'

@ComponentV2
export struct NotificationAccountBlock {
  @Param acct: AccountNotificationConfig = new AccountNotificationConfig()
  @Param vm: NotificationSettingsViewModel = new NotificationSettingsViewModel()
  @Local private tm: ThemeManager = themeManager
  @Local private collapsed: boolean = false

  build() {
    Column() {
      Row({ space: this.tm.current.value12 }) {
        if (this.acct.avatarUrl.length > 0) {
          Image(this.acct.avatarUrl)
            .width(this.tm.current.value32)
            .height(this.tm.current.value32)
            .borderRadius(this.tm.current.value8)
            .objectFit(ImageFit.Cover)
            .border({ width: this.tm.current.value1p5, color: this.tm.current.colorPrimary })
        } else {
          Row()
            .width(this.tm.current.value32)
            .height(this.tm.current.value32)
            .borderRadius(this.tm.current.value8)
            .backgroundColor(this.tm.current.colorPrimary)
            .opacity(0.5)
        }

        Column({ space: this.tm.current.value2 }) {
          Text(this.acct.nickname)
            .font(this.tm.current.body13Bold)
            .fontColor(this.tm.current.colorTextPrimary)
          Text($r('app.string.my_account_role_count', this.acct.games.length))
            .font(this.tm.current.body10)
            .fontColor(this.tm.current.colorTextSecondary)
        }
        .alignItems(HorizontalAlign.Start)
        .layoutWeight(1)

        SymbolGlyph($r('sys.symbol.chevron_down'))
          .fontSize(this.tm.current.value16)
          .fontColor([this.tm.current.colorTextSecondary])
          .rotate({ angle: this.collapsed ? -90 : 0 })
          .animation({ duration: 250, curve: Curve.EaseInOut })
      }
      .width(this.tm.current.full)
      .height(this.tm.current.value56)
      .padding({ left: this.tm.current.value16, right: this.tm.current.value16 })
      .onClick(() => { this.collapsed = !this.collapsed })

      if (!this.collapsed) {
        Column() {
          Divider()
            .color(this.tm.current.colorDivider)
            .margin({ left: this.tm.current.value16, right: this.tm.current.value16 })

          ForEach(this.acct.games, (game: GameNotificationConfig) => {
            NotificationGameRow({ accountId: this.acct.accountId, game: game, vm: this.vm })
            Divider()
              .color(this.tm.current.colorDivider)
              .margin({ left: this.tm.current.value16, right: this.tm.current.value16 })
          }, (game: GameNotificationConfig) => game.gameId)

          Row() {
            Column({ space: this.tm.current.value4 }) {
              Text($r('app.string.notification_full_value_shortcut'))
                .font(this.tm.current.body13)
                .fontColor(this.tm.current.colorTextPrimary)
              Text($r('app.string.notification_full_value_shortcut_desc'))
                .font(this.tm.current.body10)
                .fontColor(this.tm.current.colorTextSecondary)
            }
            .alignItems(HorizontalAlign.Start)
            .layoutWeight(1)

            Row() {
              Text($r('app.string.notification_full_value_set'))
                .fontSize(this.tm.current.body12.size)
                .fontWeight(this.tm.current.body12.weight)
                .fontColor($r('app.color.color_primary'))
            }
            .height(this.tm.current.value32)
            .padding({ left: this.tm.current.value12, right: this.tm.current.value12 })
            .borderRadius(this.tm.current.radius8)
            .border({ width: this.tm.current.value1, color: $r('app.color.color_primary') })
            .onClick(() => {
              this.vm.onFullValueShortcut(this.acct.accountId).catch((_: Error | object) => {})
            })
          }
          .width(this.tm.current.full)
          .height(this.tm.current.value50)
          .padding({ left: this.tm.current.value16, right: this.tm.current.value16 })
        }
        .width(this.tm.current.full)
        .transition(
          TransitionEffect.OPACITY.animation({ duration: 200, curve: Curve.EaseInOut })
            .combine(TransitionEffect.translate({ y: -8 }))
        )
      }
    }
    .width(this.tm.current.full)
    .backgroundColor(this.tm.current.colorSurfaceCard)
    .borderRadius(this.tm.current.radius12)
    .clip(true)
  }
}
