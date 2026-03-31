/**
 * AccountRolesSection — 账号详情页角色列表区块
 *
 * 每个游戏角色独立一张卡片，结构：
 *   顶部：游戏 logo + 游戏名 + 昵称 + 等级标签（纯色背景）
 *   底部：服务器/UID 行 + 统计数据格子（叠在背景图上）
 */
import { ThemeManager } from '../../theme/ThemeManager'
import { MyGameRoleVM, GameStatItem } from '../my/MyModels'
import { GameId } from '../../constants/GameId'

@ComponentV2
export struct AccountRolesSection {
  @Param tm: ThemeManager = new ThemeManager()
  @Param roles: MyGameRoleVM[] = []

  private gameLogoResource(gameId: string): Resource {
    if (gameId === GameId.GENSHIN) { return $r('app.media.logo_genshin') }
    if (gameId === GameId.STARRAIL) { return $r('app.media.logo_starrail') }
    if (gameId === GameId.ZZZ) { return $r('app.media.logo_zzz') }
    return $r('app.media.logo_honkai3')
  }

  build() {
    Column({ space: this.tm.current.value12 }) {
      if (this.roles.length === 0) {
        Row() {
          Text($r('app.string.my_account_empty'))
            .font(this.tm.current.body16)
            .fontColor(this.tm.current.colorTextSecondary)
        }
        .width(this.tm.current.full)
        .height(this.tm.current.value50)
        .justifyContent(FlexAlign.Center)
        .backgroundColor(this.tm.current.colorSurfaceCard)
        .borderRadius(this.tm.current.radius12)
      } else {
        ForEach(this.roles, (role: MyGameRoleVM) => {
          Column() {
            // ── 顶部：logo + 游戏名 + 昵称 + 等级标签 ──────────────
            Row({ space: this.tm.current.value10 }) {
              Image(this.gameLogoResource(role.gameId))
                .width(this.tm.current.value32)
                .height(this.tm.current.value32)
                .borderRadius(this.tm.current.value8)
                .border({ width: 1, color: this.tm.current.colorCardBorder })
                .objectFit(ImageFit.Cover)
                .flexShrink(0)

              Column({ space: this.tm.current.value2 }) {
                Text(role.gameName)
                  .font(this.tm.current.body16Medium)
                  .fontColor(this.tm.current.colorTextPrimary)
                  .maxLines(1)
                  .textOverflow({ overflow: TextOverflow.Ellipsis })
                Text(role.nickname)
                  .font(this.tm.current.body13)
                  .fontColor(this.tm.current.colorTextSecondary)
                  .maxLines(1)
              }
              .alignItems(HorizontalAlign.Start)
              .layoutWeight(1)

              if (role.level > 0) {
                Text('Lv.' + role.level.toString())
                  .font(this.tm.current.body13Bold)
                  .fontColor(role.gameColor)
                  .padding({
                    left: this.tm.current.value8,
                    right: this.tm.current.value8,
                    top: this.tm.current.value4,
                    bottom: this.tm.current.value4
                  })
                  .borderRadius(this.tm.current.value8)
                  .border({ width: 1, color: role.gameColor })
                  .backgroundColor(this.tm.current.colorPageBg)
              }
            }
            .width(this.tm.current.full)
            .padding({
              left: this.tm.current.value16,
              right: this.tm.current.value16,
              top: this.tm.current.value12,
              bottom: this.tm.current.value10
            })
            .alignItems(VerticalAlign.Center)

            // ── 底部：背景图 + 服务器/UID + 统计数据 ──────────────
            Column() {
              // 服务器 + UID 行
              Row({ space: this.tm.current.value8 }) {
                Text(role.server)
                  .font(this.tm.current.body13)
                  .fontColor(this.tm.current.textOnDarkHigh)
                  .padding({
                    left: this.tm.current.value8,
                    right: this.tm.current.value8,
                    top: this.tm.current.value2,
                    bottom: this.tm.current.value2
                  })
                  .borderRadius(this.tm.current.value4)
                  .backgroundColor(this.tm.current.roleCardServerBg)

                Text('·')
                  .font(this.tm.current.body13)
                  .fontColor(this.tm.current.textOnDarkMuted)

                Text('UID ' + role.roleUid)
                  .font(this.tm.current.body13)
                  .fontColor(this.tm.current.textOnDarkSecondary)
              }
              .width(this.tm.current.full)
              .alignItems(VerticalAlign.Center)

              // 统计数据格子（2×4）
              if (role.stats.length > 0) {
                GridRow({
                  columns: 4,
                  gutter: { x: this.tm.current.value8, y: this.tm.current.value8 }
                }) {
                  ForEach(role.stats, (stat: GameStatItem) => {
                    GridCol({ span: 1 }) {
                      Column({ space: this.tm.current.value2 }) {
                        Text(stat.value)
                          .font(this.tm.current.body16Medium)
                          .fontColor(this.tm.current.textOnDarkHigh)
                          .maxLines(1)
                          .textOverflow({ overflow: TextOverflow.Ellipsis })
                        Text(stat.name)
                          .font(this.tm.current.body13)
                          .fontColor(this.tm.current.textOnDarkSecondary)
                          .maxLines(2)
                          .textOverflow({ overflow: TextOverflow.Ellipsis })
                      }
                      .width(this.tm.current.full)
                      .padding({
                        left: this.tm.current.value8,
                        right: this.tm.current.value8,
                        top: this.tm.current.value8,
                        bottom: this.tm.current.value8
                      })
                      .alignItems(HorizontalAlign.Start)
                      .backgroundColor(this.tm.current.roleCardStatBg)
                      .borderRadius(this.tm.current.value8)
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
            .backgroundImage(role.bgImageUrl !== '' ? role.bgImageUrl : '')
            .backgroundImageSize(ImageSize.Cover)
            .backgroundImagePosition(Alignment.Top)
          }
          .width(this.tm.current.full)
          .backgroundColor(this.tm.current.colorSurfaceCard)
          .borderRadius(this.tm.current.radius12)
          .clip(true)
          .border({ width: this.tm.current.value1, color: this.tm.current.colorCardBorder })
          .shadow({
            radius: this.tm.current.shadowRadius,
            color: this.tm.current.shadowColor,
            offsetX: 0,
            offsetY: this.tm.current.shadowOffsetY
          })
        })
      }
    }
    .width(this.tm.current.full)
  }
}
