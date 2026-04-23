/**
 * AccountRoleCard — 单个游戏角色卡片
 *
 * 组合 AccountRoleCardHeader、AccountRoleServerRow、AccountRoleStatItem，
 * 只负责整体卡片的布局结构和背景图。
 */
import { themeManager, ThemeManager } from '../../theme/ThemeManager'
import { MyGameRoleVM, GameStatItem } from '../../models/MyModels'
import { GameId } from 'core'
import { AccountRoleCardHeader } from './AccountRoleCardHeader'
import { AccountRoleServerRow } from './AccountRoleServerRow'
import { AccountRoleStatItem } from './AccountRoleStatItem'

@ComponentV2
export struct AccountRoleCard {
  @Param role: MyGameRoleVM = new MyGameRoleVM(
    GameId.GENSHIN,
    $r('app.string.game_name_genshin'),
    $r('app.color.game_color_genshin'),
    '', '', '', 0, '', []
  )
  @Local private tm: ThemeManager = themeManager

  build() {
    Column() {
      // 顶部：游戏 logo + 游戏名 + 昵称 + 等级标签
      AccountRoleCardHeader({ role: this.role })

      // 底部：背景图 + 服务器/UID + 统计数据格子
      Column() {
        AccountRoleServerRow({ server: this.role.server, roleUid: this.role.roleUid })

        if (this.role.stats.length > 0) {
          GridRow({
            columns: 4,
            gutter: { x: this.tm.current.value8, y: this.tm.current.value8 }
          }) {
            ForEach(this.role.stats, (stat: GameStatItem) => {
              GridCol({ span: 1 }) {
                AccountRoleStatItem({ value: stat.value, name: stat.name })
              }
            })
          }
          .width(this.tm.current.full)
          .margin({ top: this.tm.current.value8 })
        }
      }
      .width(this.tm.current.full)
      .padding({
        left: this.tm.current.value16,
        right: this.tm.current.value16,
        top: this.tm.current.value8,
        bottom: this.tm.current.value12
      })
      .alignItems(HorizontalAlign.Start)
      .backgroundImage(this.role.bgImageUrl !== '' ? this.role.bgImageUrl : '')
      .backgroundImageSize(ImageSize.Cover)
      .backgroundImagePosition(Alignment.Top)
    }
    .width(this.tm.current.full)
    .backgroundColor(this.tm.current.colorSurfaceCard)
    .borderRadius(this.tm.current.radius12)
    .clip(true)
    .border({ width: this.tm.current.value1, color: this.tm.current.colorDivider })
    .shadow({
      radius: this.tm.current.shadowRadius,
      color: this.tm.current.shadowColor,
      offsetX: 0,
      offsetY: this.tm.current.shadowOffsetY
    })
  }
}

// ─── Preview ─────────────────────────────────────────────────────

@Preview
@ComponentV2
export struct AccountRoleCardPreview {
  build() {
    Column() {
      AccountRoleCard({
        role: new MyGameRoleVM(
          GameId.GENSHIN,
          $r('app.string.game_name_genshin'),
          $r('app.color.game_color_genshin'),
          '123456789', '旅行者', '天空岛', 60, '',
          [
            new GameStatItem('活跃天数', '365'),
            new GameStatItem('成就数', '800')
          ],
          $r('app.media.logo_genshin')
        )
      })
    }
    .padding(16)
    .backgroundColor('#1a1a2e')
  }
}
