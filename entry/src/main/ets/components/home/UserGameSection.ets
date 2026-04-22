import { GameId } from 'core';
/**
 * UserGameSection — 单个米游社账号的游戏卡片组
 *
 * 支持点击 header 折叠/展开卡片列表，带 animateTo 动画。
 */
import { themeManager, ThemeManager } from '../../theme/ThemeManager'
import { MihoyoAccountVM, GameRoleCardVM } from '../../models/HomeModels'
import { GameToolCard } from './GameToolCard'

@ComponentV2
export struct UserGameSection {
  @Param account: MihoyoAccountVM = new MihoyoAccountVM('', '', [])
  @Param onCardTap: (card: GameRoleCardVM) => void = (_c: GameRoleCardVM) => {}

  @Local private tm: ThemeManager = themeManager
  @Local private collapsed: boolean = false

  private toggleCollapsed(): void {
    this.collapsed = !this.collapsed;
  }

  build() {
    Column({ space: this.tm.current.value8 }) {
      // 账号标题行（可点击折叠/展开）
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
        // 折叠/展开箭头
        SymbolGlyph($r('sys.symbol.chevron_down'))
          .fontSize(this.tm.current.value16)
          .fontColor([this.tm.current.colorTextSecondary])
          .rotate({ angle: this.collapsed ? -90 : 0 })
          .animation({ duration: 250, curve: Curve.EaseInOut })
      }
      .width(this.tm.current.full)
      .padding({ left: this.tm.current.value16, right: this.tm.current.value16 })
      .alignItems(VerticalAlign.Center)
      .onClick(() => { this.toggleCollapsed() })

      // 游戏卡片列表（折叠时隐藏）
      if (!this.collapsed) {
        Column({ space: this.tm.current.value12 }) {
          ForEach(this.account.roles, (card: GameRoleCardVM) => {
            GameToolCard({ card: card, onTap: this.onCardTap })
          }, (card: GameRoleCardVM) => card.roleUid + card.gameId)
        }
        .width(this.tm.current.full)
        .padding({ left: this.tm.current.value16, right: this.tm.current.value16 })
        .transition(TransitionEffect.OPACITY.animation({ duration: 200, curve: Curve.EaseInOut })
          .combine(TransitionEffect.translate({ y: -8 })))
      }
    }
    .width(this.tm.current.full)
  }
}

// ─── Preview ─────────────────────────────────────────────────────

@Preview
@ComponentV2
export struct UserGameSectionPreview {
  @Local private card: GameRoleCardVM = new GameRoleCardVM(GameId.GENSHIN, GameId.GENSHIN, $r('app.color.game_color_genshin'), '123456789', '旅行者', '天空岛', null, 'sync_just_now');
  @Local private account: MihoyoAccountVM = new MihoyoAccountVM('user001', 'user001', [], '旅行者', '');

  build() {
    Column() {
      UserGameSection({ account: this.account })
    }
    .padding(16)
    .backgroundColor('#1a1a2e')
  }
}
