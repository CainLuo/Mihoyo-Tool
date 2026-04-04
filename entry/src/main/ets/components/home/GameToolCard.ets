/**
 * GameToolCard — 游戏战绩工具卡片（首页）
 */
import { themeManager, ThemeManager } from '../../theme/ThemeManager'
import { GameRoleCardVM, GameNoteSnapshotVM } from './HomeModels'
import { gameIdToName, gameIdToPrimaryLabel } from '../../utils/GameIdUtil'
import { GameId } from '../../constants/GameId'
import { GenshinGameToolCardContent } from './GenshinGameToolCardContent'
import { StarRailGameToolCardContent } from './StarRailGameToolCardContent'
import { ZZZGameToolCardContent } from './ZZZGameToolCardContent'
import { GenericGameToolCardContent } from './GenericGameToolCardContent'

@ComponentV2
export struct GameToolCard {
  @Param card: GameRoleCardVM = new GameRoleCardVM('', '', '', '', '', '', null, '')
  @Param onTap: (card: GameRoleCardVM) => void = (_c: GameRoleCardVM) => {}
  @Local private tm: ThemeManager = themeManager

  private syncDescResource(key: string): Resource {
    if (key === 'sync_just_now') { return $r('app.string.sync_just_now') }
    return $r('app.string.sync_not_synced')
  }

  private progressRatio(): number {
    const snap = this.card.snapshot
    if (snap === null || snap.primaryMax === 0) { return 0 }
    return Math.min(snap.primaryCurrent / snap.primaryMax, 1)
  }

  private primaryColor(): ResourceColor {
    const snap = this.card.snapshot
    if (snap === null) { return this.tm.current.colorTextSecondary }
    if (snap.isFull) { return this.tm.current.colorDanger }
    return this.card.gameColor
  }

  private gameLogoResource(): Resource {
    if (this.card.gameId === GameId.GENSHIN) { return $r('app.media.logo_genshin') }
    if (this.card.gameId === GameId.STARRAIL) { return $r('app.media.logo_starrail') }
    if (this.card.gameId === GameId.ZZZ) { return $r('app.media.logo_zzz') }
    return $r('app.media.logo_honkai3')
  }

  build() {
    Column() {
      // 卡片头部
      Row({ space: this.tm.current.value8 }) {
        Image(this.gameLogoResource())
          .width(this.tm.current.value32)
          .height(this.tm.current.value32)
          .borderRadius(this.tm.current.value8)
          .border({ width: 1, color: this.tm.current.colorCardBorder })
          .objectFit(ImageFit.Cover)

        Column({ space: this.tm.current.value2 }) {
          Text(gameIdToName(this.card.gameName))
            .font(this.tm.current.body16Medium)
            .fontColor(this.tm.current.colorTextPrimary)
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })

          Row({ space: this.tm.current.value4 }) {
            Text(this.card.nickname)
              .font(this.tm.current.body13)
              .fontColor(this.tm.current.colorTextSecondary)
              .maxLines(1)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
              .layoutWeight(1)
            Text(this.card.server)
              .font(this.tm.current.body13)
              .fontColor(this.tm.current.colorTextSecondary)
              .maxLines(1)
          }
        }
        .alignItems(HorizontalAlign.Start)
        .layoutWeight(1)

        Text(this.syncDescResource(this.card.lastSyncDesc))
          .font(this.tm.current.body13)
          .fontColor(this.tm.current.colorTextSecondary)
      }
      .width(this.tm.current.full)
      .padding({
        left: this.tm.current.value12,
        right: this.tm.current.value12,
        top: this.tm.current.value12,
        bottom: this.tm.current.value8
      })
      .alignItems(VerticalAlign.Center)

      Divider()
        .color(this.tm.current.colorDivider)
        .margin({ left: this.tm.current.value12, right: this.tm.current.value12 })

      // 内容区
      if (this.card.snapshot !== null) {
        if (this.card.gameId === GameId.GENSHIN) {
          GenshinGameToolCardContent({
            snap: this.card.snapshot,
            primaryColor: this.primaryColor(),
            progressRatio: this.progressRatio()
          })
        } else if (this.card.gameId === GameId.STARRAIL) {
          StarRailGameToolCardContent({
            snap: this.card.snapshot,
            primaryColor: this.primaryColor(),
            progressRatio: this.progressRatio()
          })
        } else if (this.card.gameId === GameId.ZZZ) {
          ZZZGameToolCardContent({
            snap: this.card.snapshot,
            primaryColor: this.primaryColor(),
            progressRatio: this.progressRatio()
          })
        } else {
          GenericGameToolCardContent({
            snap: this.card.snapshot,
            primaryLabel: gameIdToPrimaryLabel(this.card.gameName),
            primaryColor: this.primaryColor(),
            progressRatio: this.progressRatio()
          })
        }
      } else {
        Row() {
          Text($r('app.string.home_no_data_hint'))
            .font(this.tm.current.body13)
            .fontColor(this.tm.current.colorTextSecondary)
        }
        .width(this.tm.current.full)
        .justifyContent(FlexAlign.Center)
        .padding({ top: this.tm.current.value16, bottom: this.tm.current.value16 })
      }
    }
    .backgroundColor(this.tm.current.colorSurfaceCard)
    .borderRadius(this.tm.current.radius16)
    .border({ width: this.tm.current.value1, color: this.tm.current.colorCardBorder })
    .shadow({
      radius: this.tm.current.shadowRadius,
      color: this.tm.current.shadowColor,
      offsetX: 0,
      offsetY: this.tm.current.shadowOffsetY
    })
    .clip(true)
    .onClick(() => { this.onTap(this.card) })
  }
}

// ─── Preview ─────────────────────────────────────────────────────

@Preview
@ComponentV2
struct GameToolCardPreview {
  @Local private snap: GameNoteSnapshotVM = new GameNoteSnapshotVM('genshin', 120, 200, '将于 3 小时后全部恢复', '', '', false);
  @Local private card1: GameRoleCardVM = new GameRoleCardVM('genshin', 'genshin', $r('app.color.game_color_genshin'), '123456789', '旅行者', '天空岛', null, 'sync_just_now');
  @Local private card2: GameRoleCardVM = new GameRoleCardVM('starrail', 'starrail', $r('app.color.game_color_starrail'), '987654321', '开拓者', '星穹列车', null, 'sync_not_synced');

  build() {
    Column({ space: 12 }) {
      GameToolCard({ card: this.card1 })
      GameToolCard({ card: this.card2 })
    }
    .padding(16)
    .backgroundColor('#1a1a2e')
  }
}
