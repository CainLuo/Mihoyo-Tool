/**
 * NotificationGameRow — 单个游戏的体力阈值设置行
 */
import { themeManager, ThemeManager } from '../../theme/ThemeManager'
import { GameNotificationConfig } from '../../notification/NotificationModels'
import { NotificationSettingsViewModel } from '../../viewmodel/NotificationSettingsViewModel'
import { GameId } from 'core'

@ComponentV2
export struct NotificationGameRow {
  @Param accountId: string = ''
  @Param game: GameNotificationConfig = new GameNotificationConfig()
  @Param vm: NotificationSettingsViewModel = new NotificationSettingsViewModel()
  @Local private tm: ThemeManager = themeManager

  private gameColor(gameId: GameId): Resource {
    if (gameId === GameId.GENSHIN) { return $r('app.color.game_color_genshin') }
    if (gameId === GameId.STARRAIL) { return $r('app.color.game_color_starrail') }
    return $r('app.color.game_color_zzz')
  }

  build() {
    Row({ space: this.tm.current.value12 }) {
      Row()
        .width(this.tm.current.value2)
        .height(this.tm.current.value32)
        .borderRadius(this.tm.current.value2)
        .backgroundColor(this.gameColor(this.game.gameId))

      Column({ space: this.tm.current.value4 }) {
        Text($r('app.string.notification_game_stamina_label', this.game.gameName, this.game.staminaName))
          .font(this.tm.current.body13)
          .fontColor(this.tm.current.colorTextPrimary)
        Text(this.game.maxStamina > 0
          ? $r('app.string.notification_max_from_api', this.game.maxStamina, this.game.secondsPerUnit / 60)
          : $r('app.string.notification_max_pending', this.game.secondsPerUnit / 60))
          .font(this.tm.current.body10)
          .fontColor(this.tm.current.colorTextSecondary)
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)

      TextInput({ text: `${this.game.threshold}` })
        .type(InputType.Number)
        .fontSize(this.tm.current.body13.size)
        .fontWeight(this.tm.current.body13.weight)
        .fontColor(this.tm.current.colorTextPrimary)
        .textAlign(TextAlign.Center)
        .width(this.tm.current.value52)
        .height(this.tm.current.value32)
        .backgroundColor(this.tm.current.colorSurfaceSubtle)
        .borderRadius(this.tm.current.radius8)
        .border({ width: this.tm.current.value1, color: this.tm.current.colorDivider })
        .padding({ left: this.tm.current.value4, right: this.tm.current.value4 })
        .onChange((val: string) => {
          const n = parseInt(val)
          if (!isNaN(n)) {
            this.vm.onThresholdChange(this.accountId, this.game.gameId, n).catch((_: Error | object) => {})
          }
        })

      Text(this.game.maxStamina > 0
        ? $r('app.string.notification_stamina_max_suffix', this.game.maxStamina)
        : $r('app.string.notification_stamina_max_unknown'))
        .font(this.tm.current.body12)
        .fontColor(this.tm.current.colorTextSecondary)

      Toggle({ type: ToggleType.Switch, isOn: this.game.enabled })
        .onChange((isOn: boolean) => {
          this.vm.onGameToggle(this.accountId, this.game.gameId, isOn).catch((_: Error | object) => {})
        })
        .selectedColor($r('app.color.color_primary'))
    }
    .width(this.tm.current.full)
    .height(this.tm.current.value56)
    .padding({ left: this.tm.current.value16, right: this.tm.current.value16 })
    .opacity(this.game.enabled ? 1.0 : 0.4)
  }
}
