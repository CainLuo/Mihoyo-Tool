/**
 * GameToolCard — 游戏战绩工具卡片（首页）
 *
 * 原神：树脂大数字 + 环形进度 + 探索派遣 / 洞天财瓮 / 每日委托三行
 * 其他游戏：主要资源大数字 + 环形进度 + 次要指标一行
 */

import { themeManager, ThemeManager } from '../../theme/ThemeManager'
import { GameRoleCardVM, GameNoteSnapshotVM } from './HomeModels'
import { gameIdToName, gameIdToPrimaryLabel } from '../../utils/GameIdUtil'
import { GameId } from '../../constants/GameId'

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

  // ── 原神专属：数据行（emoji icon + 标签 + 值）────────────────────────
  @Builder
  genshinDataRow(emoji: string, label: Resource, value: string, valueColor: ResourceColor) {
    Row({ space: this.tm.current.value8 }) {
      Text(emoji)
        .width(this.tm.current.iconSizeSM)
        .height(this.tm.current.iconSizeSM)
        .textAlign(TextAlign.Center)
        .fontSize(this.tm.current.iconSizeSM - 4)
        .borderRadius(this.tm.current.value8)
        .backgroundColor($r('app.color.surface_glass_xs'))

      Text(label)
        .font(this.tm.current.body13)
        .fontColor(this.tm.current.colorTextSecondary)
        .layoutWeight(1)

      Text(value)
        .font(this.tm.current.body13Bold)
        .fontColor(valueColor)
    }
    .width(this.tm.current.widthFull)
    .alignItems(VerticalAlign.Center)
  }

  // ── 原神卡片内容区 ────────────────────────────────────────────
  @Builder
  genshinContent(snap: GameNoteSnapshotVM) {
    Column({ space: this.tm.current.value8 }) {
      // 树脂：大数字 + 环形进度
      Row({ space: this.tm.current.value10 }) {
        Text('🌙')
          .width(this.tm.current.iconSizeSM)
          .height(this.tm.current.iconSizeSM)
          .textAlign(TextAlign.Center)
          .fontSize(this.tm.current.iconSizeSM - 4)
          .borderRadius(this.tm.current.value8)
          .backgroundColor($r('app.color.surface_glass_xs'))

        Column({ space: this.tm.current.value2 }) {
          Text($r('app.string.daily_note_resin_title'))
            .font(this.tm.current.body13)
            .fontColor(this.tm.current.colorTextSecondary)

          Row({ space: this.tm.current.value4 }) {
            Text(snap.primaryCurrent.toString())
              .font(this.tm.current.title24Bold)
              .fontColor(this.primaryColor())

            Text('/' + snap.primaryMax.toString())
              .font(this.tm.current.body16)
              .fontColor(this.tm.current.colorTextSecondary)
              .alignSelf(ItemAlign.End)
              .margin({ bottom: this.tm.current.value2 })
          }
          .alignItems(VerticalAlign.Bottom)

          if (snap.primaryRecoveryDesc !== '') {
            Text(snap.primaryRecoveryDesc)
              .font(this.tm.current.body13)
              .fontColor(snap.isFull ? this.tm.current.colorDanger : this.tm.current.colorTextSecondary)
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
      .alignItems(VerticalAlign.Center)

      Divider().color(this.tm.current.colorDivider)

      // 探索派遣
      if (snap.expeditionCurrent >= 0) {
        this.genshinDataRow(
          '🗺️',
          $r('app.string.daily_note_expedition_title'),
          snap.expeditionCurrent.toString() + '/' + snap.expeditionMax.toString(),
          this.tm.current.colorTextPrimary
        )
      }

      // 洞天财瓮
      if (snap.homeCoinCurrent >= 0) {
        this.genshinDataRow(
          '🏡',
          $r('app.string.daily_note_home_coin_title'),
          snap.homeCoinCurrent.toString() + '/' + snap.homeCoinMax.toString(),
          this.tm.current.colorTextPrimary
        )
      }

      // 每日委托
      if (snap.dailyTaskFinished >= 0) {
        this.genshinDataRow(
          '📋',
          $r('app.string.daily_note_daily_task_title'),
          snap.dailyTaskAllReceived
            ? '已全部领取'
            : snap.dailyTaskFinished.toString() + '/' + snap.dailyTaskTotal.toString(),
          snap.dailyTaskAllReceived ? this.tm.current.colorPrimary : this.tm.current.colorTextPrimary
        )
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
  }

  // ── 崩铁卡片内容区 ────────────────────────────────────────────
  @Builder
  starrailContent(snap: GameNoteSnapshotVM) {
    Column({ space: this.tm.current.value8 }) {
      // 开拓力：大数字 + 环形进度
      Row({ space: this.tm.current.value10 }) {
        Text('⚡')
          .width(this.tm.current.iconSizeSM)
          .height(this.tm.current.iconSizeSM)
          .textAlign(TextAlign.Center)
          .fontSize(this.tm.current.iconSizeSM - 4)
          .borderRadius(this.tm.current.value8)
          .backgroundColor($r('app.color.surface_glass_xs'))

        Column({ space: this.tm.current.value2 }) {
          Text($r('app.string.starrail_stamina_title'))
            .font(this.tm.current.body13)
            .fontColor(this.tm.current.colorTextSecondary)

          Row({ space: this.tm.current.value4 }) {
            Text(snap.primaryCurrent.toString())
              .font(this.tm.current.title24Bold)
              .fontColor(this.primaryColor())

            Text('/' + snap.primaryMax.toString())
              .font(this.tm.current.body16)
              .fontColor(this.tm.current.colorTextSecondary)
              .alignSelf(ItemAlign.End)
              .margin({ bottom: this.tm.current.value2 })
          }
          .alignItems(VerticalAlign.Bottom)

          if (snap.primaryRecoveryDesc !== '') {
            Text(snap.primaryRecoveryDesc)
              .font(this.tm.current.body13)
              .fontColor(snap.isFull ? this.tm.current.colorDanger : this.tm.current.colorTextSecondary)
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
      .alignItems(VerticalAlign.Center)

      // 后备开拓力（只显示当前值，无封顶）
      if (snap.reserveStamina >= 0) {
        this.genshinDataRow('🔋', $r('app.string.starrail_reserve_stamina_title'),
          snap.reserveStamina.toString(), this.tm.current.colorTextSecondary)
      }

      Divider().color(this.tm.current.colorDivider)

      // 每日实训
      if (snap.trainScoreCurrent >= 0) {
        this.genshinDataRow('📅', $r('app.string.starrail_train_score_title'),
          snap.trainScoreCurrent.toString() + '/' + snap.trainScoreMax.toString(),
          this.tm.current.colorPrimary)
      }

      // 历战余响
      if (snap.weeklyCocoonCnt >= 0) {
        this.genshinDataRow('⚔️', $r('app.string.starrail_cocoon_title'),
          snap.weeklyCocoonCnt.toString() + '/' + snap.weeklyCocoonLimit.toString(),
          this.tm.current.colorWarning)
      }

      // 模拟宇宙积分
      if (snap.rogueScoreCurrent >= 0) {
        this.genshinDataRow('🌌', $r('app.string.starrail_rogue_score_title'),
          snap.rogueScoreCurrent.toString() + '/' + snap.rogueScoreMax.toString(),
          this.tm.current.colorPrimary)
      }

      // 货币战争积分
      if (snap.tournScoreCurrent >= 0) {
        this.genshinDataRow('💰', $r('app.string.starrail_tourn_score_title'),
          snap.tournScoreCurrent.toString() + '/' + snap.tournScoreMax.toString(),
          this.tm.current.colorDanger)
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
  }
  @Builder
  genericContent(snap: GameNoteSnapshotVM) {
    Column({ space: this.tm.current.value8 }) {
      Row({ space: this.tm.current.value8 }) {
        Column({ space: this.tm.current.value2 }) {
          Text(gameIdToPrimaryLabel(this.card.gameName))
            .font(this.tm.current.body13)
            .fontColor(this.tm.current.colorTextSecondary)

          Row({ space: this.tm.current.value4 }) {
            Text(snap.primaryCurrent.toString())
              .font(this.tm.current.title24Bold)
              .fontColor(this.primaryColor())

            Text('/' + snap.primaryMax.toString())
              .font(this.tm.current.body16)
              .fontColor(this.tm.current.colorTextSecondary)
              .alignSelf(ItemAlign.End)
              .margin({ bottom: this.tm.current.value2 })
          }
          .alignItems(VerticalAlign.Bottom)

          if (snap.primaryRecoveryDesc !== '') {
            Text(snap.primaryRecoveryDesc)
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

      if (snap.secondaryLabel !== '') {
        Row() {
          Text(snap.secondaryLabel)
            .font(this.tm.current.body13)
            .fontColor(this.tm.current.colorTextSecondary)
          Blank()
          Text(snap.secondaryDesc)
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
  }

  build() {
    Column() {
      // 卡片头部
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

      // 内容区：有数据时按游戏类型分支
      if (this.card.snapshot !== null) {
        if (this.card.gameId === GameId.GENSHIN) {
          this.genshinContent(this.card.snapshot)
        } else if (this.card.gameId === GameId.STARRAIL) {
          this.starrailContent(this.card.snapshot)
        } else {
          this.genericContent(this.card.snapshot)
        }
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
    .onClick(() => { this.onTap(this.card) })
  }
}
