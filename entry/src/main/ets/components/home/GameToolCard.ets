/**
 * GameToolCard — 游戏战绩工具卡片（首页简略版）
 *
 * 展示单个游戏角色的实时便签摘要。
 * 点击后跳转到对应游戏的详情页。
 */

import { themeManager, ThemeManager } from '../../theme/ThemeManager'
import { GameRoleCardVM, GameNoteSnapshotVM } from './HomeModels'
import { gameIdToName, gameIdToPrimaryLabel } from '../../utils/GameIdUtil'

// ── Preview：有便签数据（树脂未满）──
@Preview
@ComponentV2
struct GameToolCardPreviewNormal {
  build() {
    GameToolCard({
      card: new GameRoleCardVM(
        'genshin', 'genshin', $r('app.color.game_color_genshin'),
        '123456789', '旅行者', '天空岛',
        new GameNoteSnapshotVM('resin', 140, 200, '将于4小时后全部恢复', '每日委托', '4/4 已领取', false),
        'sync_just_now'
      )
    })
    .padding(16)
    .backgroundColor('#F5F5F5')
  }
}

// ── Preview：树脂已满（红色警告）──
@Preview
@ComponentV2
struct GameToolCardPreviewFull {
  build() {
    GameToolCard({
      card: new GameRoleCardVM(
        'genshin', 'genshin', $r('app.color.game_color_genshin'),
        '987654321', '钟离', '世界树',
        new GameNoteSnapshotVM('resin', 200, 200, '已全部恢复', '每日委托', '0/4', true),
        'sync_just_now'
      )
    })
    .padding(16)
    .backgroundColor('#F5F5F5')
  }
}

// ── Preview：无便签数据（未同步）──
@Preview
@ComponentV2
struct GameToolCardPreviewNoData {
  build() {
    GameToolCard({
      card: new GameRoleCardVM(
        'starrail', 'starrail', $r('app.color.game_color_starrail'),
        '111222333', '开拓者', '星穹列车',
        null,
        'sync_not_synced'
      )
    })
    .padding(16)
    .backgroundColor('#F5F5F5')
  }
}

@ComponentV2
export struct GameToolCard {
  @Param card: GameRoleCardVM = new GameRoleCardVM('', '', '', '', '', '', null, '')
  @Param onTap: (card: GameRoleCardVM) => void = (_c: GameRoleCardVM) => {}

  @Local private tm: ThemeManager = themeManager



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
              Text(gameIdToPrimaryLabel(this.card.gameName))
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
    .backgroundColor(this.tm.current.colorSurfaceCard)
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
