import { GameId } from 'core';
/**
 * StarRailGameToolCardContent — 崩坏：星穹铁道战绩卡片内容区
 */
import { themeManager, ThemeManager } from '../../theme/ThemeManager'
import { GameNoteSnapshotVM } from './HomeModels'
import { GameDataRow } from './GameDataRow'
import { TimeFormatUtil } from '../../utils/TimeFormatUtil'

@ComponentV2
export struct StarRailGameToolCardContent {
  @Param snap: GameNoteSnapshotVM = new GameNoteSnapshotVM('', 0, 0, 0, '', '', false)
  @Param primaryColor: ResourceColor = $r('app.color.color_primary')
  @Param progressRatio: number = 0
  @Local private tm: ThemeManager = themeManager

  build() {
    Column({ space: this.tm.current.value8 }) {
      // 开拓力：大数字 + 环形进度
      Row({ space: this.tm.current.value10 }) {
        Text('⚡')
          .width(0)
          .height(0)
          .visibility(Visibility.None)

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

          if (this.snap.primaryRecoverySeconds > 0) {
            Text(TimeFormatUtil.recoveryDesc(this.snap.primaryRecoverySeconds, this.getUIContext()))
              .font(this.tm.current.body13)
              .fontColor(this.tm.current.colorTextSecondary)
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
          valueColor: this.snap.trainScoreCurrent >= this.snap.trainScoreMax
            ? this.tm.current.colorPrimary
            : this.snap.trainScoreCurrent === 0
              ? this.tm.current.colorDanger
              : this.tm.current.colorWarning
        })
      }
      if (this.snap.weeklyCocoonCnt >= 0) {
        GameDataRow({
          emoji: '⚔️',
          label: $r('app.string.starrail_cocoon_title'),
          value: this.snap.weeklyCocoonCnt.toString() + '/' + this.snap.weeklyCocoonLimit.toString(),
          valueColor: this.snap.weeklyCocoonCnt >= this.snap.weeklyCocoonLimit
            ? this.tm.current.colorPrimary
            : this.snap.weeklyCocoonCnt === 0
              ? this.tm.current.colorDanger
              : this.tm.current.colorWarning
        })
      }
      if (this.snap.rogueScoreCurrent >= 0) {
        GameDataRow({
          emoji: '🌌',
          label: $r('app.string.starrail_rogue_score_title'),
          value: this.snap.rogueScoreCurrent.toString() + '/' + this.snap.rogueScoreMax.toString(),
          valueColor: this.snap.rogueScoreCurrent >= this.snap.rogueScoreMax
            ? this.tm.current.colorPrimary
            : this.snap.rogueScoreCurrent === 0
              ? this.tm.current.colorDanger
              : this.tm.current.colorWarning
        })
      }
      if (this.snap.tournScoreCurrent >= 0) {
        GameDataRow({
          emoji: '💰',
          label: $r('app.string.starrail_tourn_score_title'),
          value: this.snap.tournScoreCurrent.toString() + '/' + this.snap.tournScoreMax.toString(),
          valueColor: this.snap.tournScoreCurrent >= this.snap.tournScoreMax
            ? this.tm.current.colorPrimary
            : this.snap.tournScoreCurrent === 0
              ? this.tm.current.colorDanger
              : this.tm.current.colorWarning
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
export struct StarRailGameToolCardContentPreview {
  build() {
    Column() {
      StarRailGameToolCardContent({
        snap: (() => {
          const snap = new GameNoteSnapshotVM(GameId.STARRAIL, 180, 300, 7200, '', '', false);
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
