/**
 * UserGameSection — 单个米游社账号的游戏角色区块（账号标题行 + 可折叠的角色列表）
 *
 * 通用容器，不关心每个角色卡片长什么样：由调用方通过 roleBuilder 传入。
 * - 首页：传入 GameToolCard（点击跳转详情）
 * - 小组件设置：传入 WidgetSlotOption（点击切换选中）
 *
 * 调用方传 roleBuilder 时用箭头函数包一层，保证 @Builder 内的 this 指向调用方：
 *   roleBuilder: (role: GameRoleCardVM): void => { this.xxxRoleBuilder(account, role) }
 */
import { themeManager, ThemeManager } from '../theme/ThemeManager';
import { MihoyoAccountVM, GameRoleCardVM } from '../model/AccountRoleModels';
import { UserGameSectionHeader } from './UserGameSectionHeader';

@ComponentV2
export struct UserGameSection {
  /** 账号数据 */
  @Param account: MihoyoAccountVM = new MihoyoAccountVM('', '', []);
  /** 单个角色的渲染方式（由调用方提供） */
  @BuilderParam roleBuilder: (role: GameRoleCardVM) => void = this.emptyRoleBuilder;

  @Local private tm: ThemeManager = themeManager;
  @Local private isCollapsed: boolean = false;

  @Builder
  emptyRoleBuilder(_role: GameRoleCardVM) {
  }

  build() {
    Column({ space: this.tm.current.value8 }) {
      UserGameSectionHeader({
        account: this.account,
        isCollapsed: this.isCollapsed,
        onToggle: () => { this.isCollapsed = !this.isCollapsed; }
      })

      if (!this.isCollapsed) {
        Column({ space: this.tm.current.value12 }) {
          ForEach(this.account.roles, (role: GameRoleCardVM) => {
            this.roleBuilder(role)
          }, (role: GameRoleCardVM) => role.roleUid + role.gameId)
        }
        .width(this.tm.current.full)
        .padding({ left: this.tm.current.font16, right: this.tm.current.font16 })
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

  @Builder
  previewRoleBuilder(role: GameRoleCardVM) {
    Text(role.nickname)
  }

  build() {
    Column({ space: 16 }) {
      UserGameSection({
        account: this.account,
        roleBuilder: (role: GameRoleCardVM): void => { this.previewRoleBuilder(role) }
      })
    }
    .padding(this.tm.current.font16)
    .backgroundColor('#1a1a2e')
  }
}
