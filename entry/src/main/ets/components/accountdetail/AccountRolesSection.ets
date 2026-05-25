/**
 * AccountRolesSection — 账号详情页角色列表区块
 *
 * 遍历角色列表，每个角色渲染一张 AccountRoleCard。
 * 空态时显示提示文字。
 */
import { themeManager, ThemeManager } from '../../theme/ThemeManager'
import { ThemeFonts } from '../../theme/ThemeFonts'
import { MyGameRoleVM, GameStatItem } from '../../models/MyModels'
import { GameId } from 'core'
import { AccountRoleCard } from './AccountRoleCard'

@ComponentV2
export struct AccountRolesSection {
  @Param roles: MyGameRoleVM[] = []
  @Local private tm: ThemeManager = themeManager

  build() {
    Column({ space: this.tm.current.value12 }) {
      if (this.roles.length === 0) {
        Row() {
          Text($r('app.string.my_account_empty'))
            .font(ThemeFonts.font17)
            .fontColor(this.tm.current.colorTextSecondary)
        }
        .width(this.tm.current.full)
        .height(this.tm.current.value50)
        .justifyContent(FlexAlign.Center)
        .backgroundColor(this.tm.current.colorSurfaceCard)
        .borderRadius(this.tm.current.radius12)
      } else {
        ForEach(this.roles, (role: MyGameRoleVM) => {
          AccountRoleCard({ role: role })
        })
      }
    }
    .width(this.tm.current.full)
  }
}

// ─── Preview ─────────────────────────────────────────────────────

@Preview
@ComponentV2
export struct AccountRolesSectionPreview {
  build() {
    Column() {
      AccountRolesSection({
        roles: [
          new MyGameRoleVM(GameId.GENSHIN, $r('app.string.game_name_genshin'), $r('app.color.game_color_genshin'), '123456789', '旅行者', '天空岛', 60, '', [
            new GameStatItem('活跃天数', '365'),
            new GameStatItem('成就数', '800'),
            new GameStatItem('角色数', '50'),
            new GameStatItem('深渊', '12-3')
          ])
        ]
      })
    }
    .padding(16)
    .backgroundColor('#1a1a2e')
  }
}
