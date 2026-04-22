/**
 * NotificationAccountBlock — 通知设置页账号折叠区块
 */
import { themeManager, ThemeManager } from '../../theme/ThemeManager'
import { AccountNotificationConfig, GameNotificationConfig } from '../../notification/NotificationModels'
import { NotificationSettingsViewModel } from '../../viewmodel/NotificationSettingsViewModel'
import { NotificationAccountHeader } from './NotificationAccountHeader'
import { NotificationGameRow } from './NotificationGameRow'
import { NotificationFullValueRow } from './NotificationFullValueRow'

@ComponentV2
export struct NotificationAccountBlock {
  @Param acct: AccountNotificationConfig = new AccountNotificationConfig()
  @Param vm: NotificationSettingsViewModel = new NotificationSettingsViewModel()
  @Local private tm: ThemeManager = themeManager
  @Local private collapsed: boolean = false

  build() {
    Column() {
      NotificationAccountHeader({
        acct: this.acct,
        collapsed: this.collapsed,
        onToggle: () => { this.collapsed = !this.collapsed }
      })

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

          NotificationFullValueRow({ accountId: this.acct.accountId, vm: this.vm })
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

// ─── Preview ─────────────────────────────────────────────────────

@Preview
@ComponentV2
export struct NotificationAccountBlockPreview {
  @Local private tm: ThemeManager = themeManager
  @Local private acct: AccountNotificationConfig = new AccountNotificationConfig()

  aboutToAppear(): void {
    this.acct.nickname = '旅行者';
    this.acct.avatarUrl = '';
    this.acct.accountId = 'preview_uid';
  }

  build() {
    Column() {
      NotificationAccountBlock({ acct: this.acct })
    }
    .padding(this.tm.current.value16)
    .backgroundColor('#1a1a2e')
  }
}
