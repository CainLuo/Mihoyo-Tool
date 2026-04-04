/**
 * StarRailGameToolCardContent — 崩坏：星穹铁道战绩卡片内容区
 */
import { themeManager, ThemeManager } from '../../theme/ThemeManager'
import { GameNoteSnapshotVM } from './HomeModels'
import { GameDataRow } from './GameDataRow'

@ComponentV2
export struct StarRailGameToolCardContent {
  @Param snap: GameNoteSnapshotVM = new GameNoteSnapshotVM('', 0, 0, '', '', '', false)
  @Param primaryColor: ResourceColor = $r('app.color.color_primary')
  @Param progressRatio: number = 0
  @Local private tm: ThemeManager = themeManager

  build() {
    Column({ space: this.tm.current.value8 }) {
      // 开拓力：大数字 + 环形进度
      Row({ space: this.tm.current.value10 }) {
        Text('⚡')
          .width(this.tm.current.value32)
          .height(this.tm.current.value32)
          .textAlign(TextAlign.Center)
          .fontSize(this.tm.current.value32 - 4)
          .borderRadius(this.tm.current.value8)
          .backgroundColor($r('app.color.surface_glass_xs'))

        Column({ space: this.tm.current.value2 }) {
          Text($r('app.string.starrail_stamina_title'))
            .font(this.tm.current.body13)
            .fontColor(this.tm.current.colorTextSecondary)

          Row({ space: this.tm.current.value4 }) {
            Text(this.snap.primaryCurrent.toString())
              .font(this.tm.current.title24Bold)
              .fontColor(this.primaryColor)
            Text('/' + this.snap.primaryMax.toString())
              .font(this.tm.current.body16)
              .fontColor(this.tm.current.colorTextSecondary)
              .alignSelf(ItemAlign.End)
              .margin({ bottom: this.tm.current.value2 })
          }
          .alignItems(VerticalAlign.Bottom)

          if (this.snap.primaryRecoveryDesc !== '') {
            Text(this.snap.primaryRecoveryDesc)
              .font(this.tm.current.body13)
              .fontColor(this.snap.isFull ? this.tm.current.colorDanger : this.tm.current.colorTextSecondary)
              .maxLines(1)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
          }
        }
        .alignItems(HorizontalAlign.Start)
        .layoutWeight(1)

        Progress({
          value: Math.round(this.progressRatio * 100),
          total: 100,
          type: ProgressType.Ring
        })
          .width(this.tm.current.value52)
          .height(this.tm.current.value52)
          .color(this.primaryColor)
          .backgroundColor(this.tm.current.colorDivider)
          .style({ strokeWidth: this.tm.current.value5 })
      }
      .width(this.tm.current.full)
      .alignItems(VerticalAlign.Center)

      if (this.snap.reserveStamina >= 0) {
        GameDataRow({
          emoji: '🔋',
          label: $r('app.string.starrail_reserve_stamina_title'),
          value: this.snap.reserveStamina.toString(),
          valueColor: this.tm.current.colorTextSecondary
        })
      }

      Divider().color(this.tm.current.colorDivider)

      if (this.snap.trainScoreCurrent >= 0) {
        GameDataRow({
          emoji: '📅',
          label: $r('app.string.starrail_train_score_title'),
          value: this.snap.trainScoreCurrent.toString() + '/' + this.snap.trainScoreMax.toString(),
          valueColor: this.tm.current.colorPrimary
        })
      }
      if (this.snap.weeklyCocoonCnt >= 0) {
        GameDataRow({
          emoji: '⚔️',
          label: $r('app.string.starrail_cocoon_title'),
          value: this.snap.weeklyCocoonCnt.toString() + '/' + this.snap.weeklyCocoonLimit.toString(),
          valueColor: this.tm.current.colorWarning
        })
      }
      if (this.snap.rogueScoreCurrent >= 0) {
        GameDataRow({
          emoji: '🌌',
          label: $r('app.string.starrail_rogue_score_title'),
          value: this.snap.rogueScoreCurrent.toString() + '/' + this.snap.rogueScoreMax.toString(),
          valueColor: this.tm.current.colorPrimary
        })
      }
      if (this.snap.tournScoreCurrent >= 0) {
        GameDataRow({
          emoji: '💰',
          label: $r('app.string.starrail_tourn_score_title'),
          value: this.snap.tournScoreCurrent.toString() + '/' + this.snap.tournScoreMax.toString(),
          valueColor: this.tm.current.colorDanger
        })
      }
    }
    .width(this.tm.current.full)
    .padding({
      left: this.tm.current.value12,
      right: this.tm.current.value12,
      top: this.tm.current.value8,
      bottom: this.tm.current.value12
    })
    .alignItems(HorizontalAlign.Start)
  }
}

// ─── Preview ─────────────────────────────────────────────────────

@Preview
@ComponentV2
struct StarRailGameToolCardContentPreview {
  build() {
    Column() {
      StarRailGameToolCardContent({
        snap: (() => {
          const snap = new GameNoteSnapshotVM('starrail', 180, 300, '将于2小时后全部恢复', '', '', false);
          snap.reserveStamina = 2400;
          snap.trainScoreCurrent = 400;
          snap.trainScoreMax = 500;
          snap.weeklyCocoonCnt = 2;
          snap.weeklyCocoonLimit = 3;
          snap.rogueScoreCurrent = 10000;
          snap.rogueScoreMax = 14000;
          snap.tournScoreCurrent = 800;
          snap.tournScoreMax = 1000;
          return snap;
        })(),
        primaryColor: $r('app.color.game_color_starrail'),
        progressRatio: 0.6
      })
    }
    .backgroundColor('#1a1a2e')
  }
}
