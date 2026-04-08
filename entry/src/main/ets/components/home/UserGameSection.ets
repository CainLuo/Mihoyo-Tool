/**
 * UserGameSection — 单个米游社账号的游戏卡片组
 */
import { themeManager, ThemeManager } from '../../theme/ThemeManager'
import { MihoyoAccountVM, GameRoleCardVM } from './HomeModels'
import { GameToolCard } from './GameToolCard'

@ComponentV2
export struct UserGameSection {
  @Param account: MihoyoAccountVM = new MihoyoAccountVM(0, '', [])
  @Param onCardTap: (card: GameRoleCardVM) => void = (_c: GameRoleCardVM) => {}

  @Local private tm: ThemeManager = themeManager

  build() {
    Column({ space: this.tm.current.value8 }) {
      // 账号标题行
      Row({ space: this.tm.current.value8 }) {
        if (this.account.avatarUrl !== '') {
          Image(this.account.avatarUrl)
            .width(this.tm.current.value28)
            .height(this.tm.current.value28)
            .borderRadius(this.tm.current.radius8)
            .objectFit(ImageFit.Cover)
            .border({ width: 1, color: this.tm.current.colorPrimary })
            .accessibilityText($r('app.string.home_account_avatar_desc'))
        } else {
          Row()
            .width(this.tm.current.value28)
            .height(this.tm.current.value28)
            .borderRadius(this.tm.current.radius8)
            .backgroundColor(this.tm.current.colorPrimary)
            .accessibilityText($r('app.string.home_account_avatar_desc'))
        }
        Text(this.account.nickname !== '' ? this.account.nickname : this.account.username)
          .font(this.tm.current.body16Medium)
          .fontColor(this.tm.current.colorTextPrimary)
          .layoutWeight(1)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
        Text($r('app.string.home_game_count_format', this.account.roles.length))
          .font(this.tm.current.body13)
          .fontColor(this.tm.current.colorTextSecondary)
      }
      .width(this.tm.current.full)
      .padding({ left: this.tm.current.value16, right: this.tm.current.value16 })
      .alignItems(VerticalAlign.Center)

      // 游戏卡片列表（垂直排列）
      Column({ space: this.tm.current.value12 }) {
        ForEach(this.account.roles, (card: GameRoleCardVM) => {
          GameToolCard({ card: card, onTap: this.onCardTap })
        }, (card: GameRoleCardVM) => card.roleUid + card.gameId)
      }
      .width(this.tm.current.full)
      .padding({ left: this.tm.current.value16, right: this.tm.current.value16 })
    }
    .width(this.tm.current.full)
  }
}

// ─── Preview ─────────────────────────────────────────────────────

@Preview
@ComponentV2
export struct UserGameSectionPreview {
  @Local private card: GameRoleCardVM = new GameRoleCardVM('genshin', 'genshin', $r('app.color.game_color_genshin'), '123456789', '旅行者', '天空岛', null, 'sync_just_now');
  @Local private account: MihoyoAccountVM = new MihoyoAccountVM(1, 'user001', [], '旅行者', '');

  build() {
    Column() {
      UserGameSection({ account: this.account })
    }
    .padding(16)
    .backgroundColor('#1a1a2e')
  }
}
