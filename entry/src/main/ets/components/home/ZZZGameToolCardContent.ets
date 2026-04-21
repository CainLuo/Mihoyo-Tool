import { GameId } from 'core';
/**
 * ZZZGameToolCardContent — 绝区零战绩卡片内容区
 */
import { themeManager, ThemeManager } from '../../theme/ThemeManager'
import { GameNoteSnapshotVM } from './HomeModels'
import { GameDataRow } from './GameDataRow'
import { ZZZVideoStoreState, ZZZCardSign } from '../../constants/ZZZEnums'
import { TimeFormatUtil } from '../../utils/TimeFormatUtil'

@ComponentV2
export struct ZZZGameToolCardContent {
  @Param snap: GameNoteSnapshotVM = new GameNoteSnapshotVM('', 0, 0, 0, '', '', false)
  @Param primaryColor: ResourceColor = $r('app.color.color_primary')
  @Param progressRatio: number = 0
  @Local private tm: ThemeManager = themeManager

  build() {
    Column({ space: this.tm.current.value8 }) {
      // 电量：大数字 + 环形进度
      Row({ space: this.tm.current.value10 }) {
        Text('⚡')
          .width(0)
          .height(0)
          .visibility(Visibility.None)

        Column({ space: this.tm.current.value2 }) {
          Text($r('app.string.zzz_energy_title'))
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

      Divider().color(this.tm.current.colorDivider)

      if (this.snap.vitalityCurrent >= 0) {
        GameDataRow({
          emoji: '🎯',
          label: $r('app.string.zzz_vitality_title'),
          value: this.snap.vitalityCurrent.toString() + '/' + this.snap.vitalityMax.toString(),
          valueColor: this.snap.vitalityCurrent >= this.snap.vitalityMax
            ? this.tm.current.colorPrimary
            : this.snap.vitalityCurrent === 0
              ? this.tm.current.colorDanger
              : this.tm.current.colorWarning
        })
      }

      GameDataRow({
        emoji: '🃏',
        label: $r('app.string.zzz_card_sign_title'),
        value: this.snap.scratchCardSign === ZZZCardSign.DONE
          ? $r('app.string.zzz_card_sign_done')
          : $r('app.string.zzz_card_sign_todo'),
        valueColor: this.snap.scratchCardSign === ZZZCardSign.DONE
          ? this.tm.current.colorPrimary
          : this.tm.current.colorDanger
      })

      if (this.snap.videoStoreState !== ZZZVideoStoreState.UNKNOWN) {
        GameDataRow({
          emoji: '📼',
          label: $r('app.string.zzz_video_store_title'),
          value: this.snap.videoStoreState === ZZZVideoStoreState.DONE
            ? $r('app.string.zzz_video_store_done')
            : this.snap.videoStoreState === ZZZVideoStoreState.OPEN
              ? $r('app.string.zzz_video_store_open')
              : $r('app.string.zzz_video_store_closed'),
          valueColor: this.snap.videoStoreState === ZZZVideoStoreState.DONE
            ? this.tm.current.colorPrimary
            : this.snap.videoStoreState === ZZZVideoStoreState.OPEN
              ? this.tm.current.colorWarning
              : this.tm.current.colorTextSecondary
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
export struct ZZZGameToolCardContentPreview {
  build() {
    Column() {
      ZZZGameToolCardContent({
        snap: (() => {
          const snap = new GameNoteSnapshotVM(GameId.ZZZ, 180, 240, 3600, '', '', false);
          snap.vitalityCurrent = 300;
          snap.vitalityMax = 400;
          snap.scratchCardSign = ZZZCardSign.DONE;
          snap.videoStoreState = ZZZVideoStoreState.OPEN;
          return snap;
        })(),
        primaryColor: $r('app.color.game_color_zzz'),
        progressRatio: 0.75
      })
    }
    .backgroundColor('#1a1a2e')
  }
}
