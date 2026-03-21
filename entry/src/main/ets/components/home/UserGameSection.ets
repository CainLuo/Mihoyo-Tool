/**
 * UserGameSection — 单个米游社账号的游戏卡片组
 *
 * 使用 GridRow + GridCol 实现系统级响应式布局（断点基于窗口 vp，设备无关）：
 *   xs (< 600vp)    → 1列  竖屏手机（360-480vp）
 *   sm (600-840vp)  → 2列  横屏手机 / 小折叠展开
 *   md (840-1200vp) → 3列  大折叠展开 / 平板
 *   lg (> 1200vp)   → 4列  PC / 2in1
 * 系统自动处理断点切换，无需手动计算宽度。
 */

import { themeManager, ThemeManager } from '../../theme/ThemeManager'
import { MihoyoAccountVM, GameRoleCardVM } from './HomeModels'
import { GameToolCard } from './GameToolCard'
import { AppConstants } from '../../constants/AppConstants'

@ComponentV2
export struct UserGameSection {
  @Param account: MihoyoAccountVM = new MihoyoAccountVM(0, '', [])
  @Param onCardTap: (card: GameRoleCardVM) => void = (_c: GameRoleCardVM) => {}

  @Local private tm: ThemeManager = themeManager

  build() {
    Column({ space: this.tm.current.value8 }) {
      // 账号标题行
      Row({ space: this.tm.current.value8 }) {
        Row()
          .width(this.tm.current.avatarSizeSM)
          .height(this.tm.current.avatarSizeSM)
          .borderRadius(this.tm.current.avatarRadiusSM)
          .backgroundColor(this.tm.current.colorPrimary)
          .accessibilityText($r('app.string.home_account_avatar_desc'))

        Text(this.account.username)
          .font(this.tm.current.body16Medium)
          .fontColor(this.tm.current.colorTextPrimary)
          .layoutWeight(1)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })

        Text($r('app.string.home_game_count_format', this.account.roles.length))
          .font(this.tm.current.body13)
          .fontColor(this.tm.current.colorTextSecondary)
      }
      .width(this.tm.current.widthFull)
      .padding({ left: this.tm.current.value16, right: this.tm.current.value16 })
      .alignItems(VerticalAlign.Center)

      // 响应式卡片网格
      GridRow({
        columns: { xs: 1, sm: 2, md: 3, lg: 4 },
        gutter: { x: this.tm.current.value12, y: this.tm.current.value12 },
        breakpoints: {
          value: AppConstants.GRID_BREAKPOINTS,
          reference: BreakpointsReference.WindowSize
        }
      }) {
        ForEach(this.account.roles, (card: GameRoleCardVM) => {
          GridCol({ span: 1 }) {
            GameToolCard({ card: card, onTap: this.onCardTap })
          }
        }, (card: GameRoleCardVM) => card.roleUid + card.gameId)
      }
      .width(this.tm.current.widthFull)
      .padding({ left: this.tm.current.value16, right: this.tm.current.value16 })
    }
    .width(this.tm.current.widthFull)
  }
}
