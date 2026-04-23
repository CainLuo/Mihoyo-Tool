/**
 * UserGameSection — 单个米游社账号的游戏卡片组
 *
 * 支持点击 header 折叠/展开卡片列表，带 animateTo 动画。
 */
import { themeManager, ThemeManager } from '../../theme/ThemeManager';
import { MihoyoAccountVM, GameRoleCardVM } from '../../models/HomeModels';
import { GameToolCard } from './GameToolCard';
import { UserGameSectionHeader } from './UserGameSectionHeader';

@ComponentV2
export struct UserGameSection {
  @Param account: MihoyoAccountVM = new MihoyoAccountVM('', '', []);
  @Param onCardTap: (card: GameRoleCardVM) => void = (_c: GameRoleCardVM) => {};
  @Local private tm: ThemeManager = themeManager;
  @Local private collapsed: boolean = false;

  build() {
    Column({ space: this.tm.current.value8 }) {
      UserGameSectionHeader({
        account: this.account,
        collapsed: this.collapsed,
        onToggle: () => { this.collapsed = !this.collapsed; }
      })

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
  @Local private tm: ThemeManager = themeManager;
  @Local private account: MihoyoAccountVM = new MihoyoAccountVM('user001', 'user001', [], '旅行者', '');

  build() {
    Column() {
      UserGameSection({ account: this.account })
    }
    .padding(this.tm.current.value16)
    .backgroundColor('#1a1a2e')
  }
}
