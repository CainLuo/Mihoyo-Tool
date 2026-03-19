/**
 * GameToolCard — 游戏战绩工具卡片（首页简略版）
 *
 * 展示单个游戏角色的实时便签摘要。
 * 点击后跳转到对应游戏的详情页。
 */

import { themeManager, ThemeManager } from '../../theme/ThemeManager'
import { GameRoleCardVM } from './HomeModels'

@ComponentV2
export struct GameToolCard {
  @Param card: GameRoleCardVM = new GameRoleCardVM('', '', '', '', '', '', null, '')
  @Param onTap: (card: GameRoleCardVM) => void = (_c: GameRoleCardVM) => {}

  @Local private tm: ThemeManager = themeManager

  /** 将 gameId 映射为本地化游戏名称资源 */
  private gameNameResource(gameId: string): Resource {
    if (gameId === 'genshin') {
      return $r('app.string.game_name_genshin')
    }
    if (gameId === 'starrail') {
      return $r('app.string.game_name_starrail')
    }
    if (gameId === 'zzz') {
      return $r('app.string.game_name_zzz')
    }
    if (gameId === 'honkai3') {
      return $r('app.string.game_name_honkai3')
    }
    return $r('app.string.game_name_genshin')
  }

  /** 将 gameId 映射为主要资源名称（树脂/开拓力等） */
  private primaryLabelResource(gameId: string): Resource {
    if (gameId === 'genshin') {
      return $r('app.string.daily_note_resin_title')
    }
    if (gameId === 'starrail') {
      return $r('app.string.daily_note_adventure_label')
    }
    if (gameId === 'zzz') {
      return $r('app.string.daily_note_adventure_label')
    }
    if (gameId === 'honkai3') {
      return $r('app.string.daily_note_adventure_label')
    }
    return $r('app.string.daily_note_resin_title')
  }

  /** 将 lastSyncDesc key 映射为本地化字符串资源 */
  private syncDescResource(key: string): Resource {
    if (key === 'sync_just_now') {
      return $r('app.string.sync_just_now')
    }
    return $r('app.string.sync_not_synced')
  }

  private progressRatio(): number {
    const snap = this.card.snapshot
    if (snap === null || snap.primaryMax === 0) return 0
    return Math.min(snap.primaryCurrent / snap.primaryMax, 1)
  }

  private primaryColor(): ResourceColor {
    const snap = this.card.snapshot
    if (snap === null) return this.tm.current.colorTextSecondary
    if (snap.isFull) return this.tm.current.colorDanger
    return this.card.gameColor
  }

  build() {
    Column() {
      // ---- 卡片头部：游戏色条 + 名称 + 同步时间 ----
      Row({ space: this.tm.current.value8 }) {
        Row()
          .width(this.tm.current.gameBarWidth)
          .height(this.tm.current.gameBarHeightMD)
          .borderRadius(this.tm.current.gameBarRadius)
          .backgroundColor(this.card.gameColor)

        Column({ space: this.tm.current.value2 }) {
          Text(this.gameNameResource(this.card.gameName))
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
      .width(this.tm.current.widthFull)
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

      // ---- 便签摘要内容 ----
      if (this.card.snapshot !== null) {
        Column({ space: this.tm.current.value8 }) {
          Row({ space: this.tm.current.value8 }) {
            Column({ space: this.tm.current.value2 }) {
              Text(this.primaryLabelResource(this.card.snapshot.primaryLabel))
                .font(this.tm.current.body13)
                .fontColor(this.tm.current.colorTextSecondary)

              Row({ space: this.tm.current.value4 }) {
                Text(this.card.snapshot.primaryCurrent.toString())
                  .font(this.tm.current.title24Bold)
                  .fontColor(this.primaryColor())

                Text('/' + this.card.snapshot.primaryMax.toString())
                  .font(this.tm.current.body16)
                  .fontColor(this.tm.current.colorTextSecondary)
                  .alignSelf(ItemAlign.End)
                  .margin({ bottom: this.tm.current.value2 })
              }
              .alignItems(VerticalAlign.Bottom)

              if (this.card.snapshot.primaryRecoveryDesc !== '') {
                Text(this.card.snapshot.primaryRecoveryDesc)
                  .font(this.tm.current.body13)
                  .fontColor(this.tm.current.colorTextSecondary)
                  .maxLines(1)
                  .textOverflow({ overflow: TextOverflow.Ellipsis })
              }
            }
            .alignItems(HorizontalAlign.Start)
            .layoutWeight(1)

            Progress({
              value: Math.round(this.progressRatio() * 100),
              total: 100,
              type: ProgressType.Ring
            })
              .width(this.tm.current.progressSizeMD)
              .height(this.tm.current.progressSizeMD)
              .color(this.primaryColor())
              .backgroundColor(this.tm.current.colorDivider)
              .style({ strokeWidth: this.tm.current.progressStroke })
          }
          .width(this.tm.current.widthFull)

          if (this.card.snapshot.secondaryLabel !== '') {
            Row() {
              Text(this.card.snapshot.secondaryLabel)
                .font(this.tm.current.body13)
                .fontColor(this.tm.current.colorTextSecondary)
              Blank()
              Text(this.card.snapshot.secondaryDesc)
                .font(this.tm.current.body13)
                .fontColor(this.tm.current.colorTextPrimary)
            }
            .width(this.tm.current.widthFull)
          }
        }
        .width(this.tm.current.widthFull)
        .padding({
          left: this.tm.current.value12,
          right: this.tm.current.value12,
          top: this.tm.current.value8,
          bottom: this.tm.current.value12
        })
        .alignItems(HorizontalAlign.Start)
      } else {
        Row() {
          Text($r('app.string.home_no_data_hint'))
            .font(this.tm.current.body13)
            .fontColor(this.tm.current.colorTextSecondary)
        }
        .width(this.tm.current.widthFull)
        .justifyContent(FlexAlign.Center)
        .padding({ top: this.tm.current.value40, bottom: this.tm.current.value40 })
      }
    }
    .backgroundColor(this.tm.current.colorCardBg)
    .borderRadius(this.tm.current.radius16)
    .border({ width: this.tm.current.cardBorderWidth, color: this.tm.current.colorCardBorder })
    .shadow({
      radius: this.tm.current.shadowRadius,
      color: this.tm.current.shadowColor,
      offsetX: 0,
      offsetY: this.tm.current.shadowOffsetY
    })
    .clip(true)
    .onClick(() => {
      this.onTap(this.card)
    })
  }
}
