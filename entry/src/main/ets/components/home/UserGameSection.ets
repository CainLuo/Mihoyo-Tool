/**
 * UserGameSection — 单个米游社账号的游戏卡片组
 *
 * 支持两种模式：
 * - HOME（默认）：战绩工具首页，点击卡片跳转详情
 * - WIDGET_CONFIG：Widget 配置页，点击卡片切换选中状态
 */
import { themeManager, ThemeManager } from '../../theme/ThemeManager';
import { MihoyoAccountVM, GameRoleCardVM } from '../../models/HomeModels';
import { WidgetSlotRef } from '../../widget/models/WidgetDataStore';
import { GameToolCard } from './GameToolCard';
import { UserGameSectionHeader } from './UserGameSectionHeader';
import { WidgetSlotOption } from '../widgetconfig/WidgetSlotOption';
import { gameIdStrToColor, gameIdStrToName } from '../../utils/GameIdUtil';

/** Section 模式枚举 */
export enum UserGameSectionMode {
  /** 战绩工具首页：点击跳转详情 */
  HOME = 'home',
  /** Widget 配置页：点击切换选中 */
  WIDGET_CONFIG = 'widget_config'
}

@ComponentV2
export struct UserGameSection {
  /** 账号数据 */
  @Param account: MihoyoAccountVM = new MihoyoAccountVM('', '', []);
  /** 模式：HOME 或 WIDGET_CONFIG */
  @Param mode: UserGameSectionMode = UserGameSectionMode.HOME;
  /** 战绩模式：卡片点击回调 */
  @Param onCardTap: (card: GameRoleCardVM) => void = (_c: GameRoleCardVM) => {};
  /** Widget 模式：判断 slot 是否选中 */
  @Param isSlotSelected: (accountId: string, gameId: string, roleId: string) => boolean = (_a: string, _g: string, _r: string) => false;
  /** Widget 模式：slot 点击回调 */
  @Param onSlotToggle: (slot: WidgetSlotRef) => void = (_slot: WidgetSlotRef) => {};

  @Local private tm: ThemeManager = themeManager;
  @Local private collapsed: boolean = false;

  /**
   * 构建 WidgetSlotRef（仅 Widget 模式使用）
   */
  private buildSlotRef(role: GameRoleCardVM): WidgetSlotRef {
    const slot = new WidgetSlotRef();
    slot.accountId = this.account.accountId;
    slot.accountName = this.account.nickname !== '' ? this.account.nickname : this.account.username;
    slot.gameId = role.gameId;
    slot.roleId = role.roleUid;
    slot.nickname = role.nickname;
    slot.server = role.server as string;
    return slot;
  }

  build() {
    Column({ space: this.tm.current.value8 }) {
      UserGameSectionHeader({
        account: this.account,
        collapsed: this.collapsed,
        onToggle: () => { this.collapsed = !this.collapsed; }
      })

      if (!this.collapsed) {
        Column({ space: this.tm.current.value12 }) {
          ForEach(this.account.roles, (role: GameRoleCardVM) => {
            if (this.mode === UserGameSectionMode.HOME) {
              // 战绩模式：渲染 GameToolCard
              GameToolCard({ card: role, onTap: this.onCardTap })
            } else {
              // Widget 配置模式：渲染 WidgetSlotOption
              WidgetSlotOption({
                slot: this.buildSlotRef(role),
                gameColor: gameIdStrToColor(role.gameId),
                gameName: gameIdStrToName(role.gameId),
                isSelected: this.isSlotSelected(this.account.accountId, role.gameId, role.roleUid),
                onTap: () => {
                  this.onSlotToggle(this.buildSlotRef(role));
                }
              })
            }
          }, (role: GameRoleCardVM) => role.roleUid + role.gameId)
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
    Column({ space: 16 }) {
      // 战绩模式
      UserGameSection({
        account: this.account,
        mode: UserGameSectionMode.HOME
      })

      // Widget 配置模式
      UserGameSection({
        account: this.account,
        mode: UserGameSectionMode.WIDGET_CONFIG,
        isSlotSelected: (_a: string, _g: string, _r: string) => true,
        onSlotToggle: () => {}
      })
    }
    .padding(this.tm.current.value16)
    .backgroundColor('#1a1a2e')
  }
}
