import { GameId } from 'core';
/**
 * GenshinGameToolCardContent — 原神战绩卡片内容区
 */
import { themeManager, ThemeManager } from '../../theme/ThemeManager'
import { GameNoteSnapshotVM } from '../../models/HomeModels'
import { GameDataRow } from './GameDataRow'
import { TimeFormatUtil } from '../../utils/TimeFormatUtil'

@ComponentV2
export struct GenshinGameToolCardContent {
  @Param snap: GameNoteSnapshotVM = new GameNoteSnapshotVM('', 0, 0, 0, '', '', false)
  @Param primaryColor: ResourceColor = $r('app.color.color_primary')
  @Param progressRatio: number = 0
  @Local private tm: ThemeManager = themeManager

  build() {
    Column({ space: this.tm.current.value8 }) {
      // 树脂：大数字 + 环形进度
      Row({ space: this.tm.current.value10 }) {
        Text('🌙')
          .width(0)
          .height(0)
          .visibility(Visibility.None)

        Column({ space: this.tm.current.value2 }) {
          Text($r('app.string.daily_note_resin_title'))
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

      Divider().color(this.tm.current.colorDivider)

      if (this.snap.expeditionCurrent >= 0) {
        GameDataRow({
          emoji: '🗺️',
          label: $r('app.string.daily_note_expedition_title'),
          value: this.snap.expeditionCurrent.toString() + '/' + this.snap.expeditionMax.toString(),
          valueColor: this.snap.expeditionCurrent >= this.snap.expeditionMax
            ? this.tm.current.colorPrimary
            : this.snap.expeditionCurrent === 0
              ? this.tm.current.colorDanger
              : this.tm.current.colorWarning
        })
      }
      if (this.snap.homeCoinCurrent >= 0) {
        GameDataRow({
          emoji: '🏡',
          label: $r('app.string.daily_note_home_coin_title'),
          value: this.snap.homeCoinCurrent.toString() + '/' + this.snap.homeCoinMax.toString(),
          valueColor: this.snap.homeCoinMax > 0 && this.snap.homeCoinCurrent >= this.snap.homeCoinMax
            ? this.tm.current.colorDanger
            : this.snap.homeCoinMax > 0 && this.snap.homeCoinCurrent / this.snap.homeCoinMax >= 0.5
              ? this.tm.current.colorWarning
              : this.tm.current.colorPrimary
        })
      }
      if (this.snap.dailyTaskFinished >= 0) {
        GameDataRow({
          emoji: '📋',
          label: $r('app.string.daily_note_daily_task_title'),
          value: this.snap.dailyTaskAllReceived
            ? $r('app.string.daily_note_task_all_received')
            : this.snap.dailyTaskFinished.toString() + '/' + this.snap.dailyTaskTotal.toString(),
          valueColor: this.snap.dailyTaskAllReceived
            ? this.tm.current.colorPrimary
            : this.snap.dailyTaskFinished === 0
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
export struct GenshinGameToolCardContentPreview {
  build() {
    Column() {
      GenshinGameToolCardContent({
        snap: (() => {
          const snap = new GameNoteSnapshotVM(GameId.GENSHIN, 140, 200, 14400, '', '', false);
          snap.expeditionCurrent = 3;
          snap.expeditionMax = 5;
          snap.homeCoinCurrent = 1800;
          snap.homeCoinMax = 2400;
          snap.dailyTaskFinished = 4;
          snap.dailyTaskTotal = 4;
          snap.dailyTaskAllReceived = true;
          return snap;
        })(),
        primaryColor: $r('app.color.game_color_genshin'),
        progressRatio: 0.7
      })
    }
    .backgroundColor('#1a1a2e')
  }
}
