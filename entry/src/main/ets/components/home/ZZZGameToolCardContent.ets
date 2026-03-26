/**
 * ZZZGameToolCardContent — 绝区零战绩卡片内容区
 * 从 GameToolCard 拆分出来，避免单文件过大
 */
import { themeManager, ThemeManager } from '../../theme/ThemeManager'
import { GameNoteSnapshotVM } from './HomeModels'

@ComponentV2
export struct ZZZGameToolCardContent {
  @Param snap: GameNoteSnapshotVM = new GameNoteSnapshotVM('', 0, 0, '', '', '', false)
  @Param primaryColor: ResourceColor = $r('app.color.color_primary')
  @Param progressRatio: number = 0
  @Local private tm: ThemeManager = themeManager

  @Builder
  dataRow(emoji: string, label: Resource, value: string, valueColor: ResourceColor) {
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

  build() {
    Column({ space: this.tm.current.value8 }) {
      // 电量：大数字 + 环形进度
      Row({ space: this.tm.current.value10 }) {
        Text('⚡')
          .width(this.tm.current.iconSizeSM)
          .height(this.tm.current.iconSizeSM)
          .textAlign(TextAlign.Center)
          .fontSize(this.tm.current.iconSizeSM - 4)
          .borderRadius(this.tm.current.value8)
          .backgroundColor($r('app.color.surface_glass_xs'))

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
          .width(this.tm.current.progressSizeMD)
          .height(this.tm.current.progressSizeMD)
          .color(this.primaryColor)
          .backgroundColor(this.tm.current.colorDivider)
          .style({ strokeWidth: this.tm.current.progressStroke })
      }
      .width(this.tm.current.widthFull)
      .alignItems(VerticalAlign.Center)

      Divider().color(this.tm.current.colorDivider)

      // 今日活跃度
      if (this.snap.vitalityCurrent >= 0) {
        this.dataRow('🎯', $r('app.string.zzz_vitality_title'),
          this.snap.vitalityCurrent.toString() + '/' + this.snap.vitalityMax.toString(),
          this.tm.current.colorPrimary)
      }

      // 刮刮卡/占卜
      this.dataRow('🃏', $r('app.string.zzz_card_sign_title'),
        this.snap.scratchCardDone ? '已完成' : '未完成',
        this.snap.scratchCardDone ? this.tm.current.colorPrimary : this.tm.current.colorDanger)

      // 录像店经营
      if (this.snap.videoStoreState !== '') {
        this.dataRow('📼', $r('app.string.zzz_video_store_title'),
          this.snap.videoStoreState === 'done' ? '已结算'
            : this.snap.videoStoreState === 'open' ? '营业中' : '未营业',
          this.snap.videoStoreState === 'done' ? this.tm.current.colorPrimary
            : this.snap.videoStoreState === 'open' ? this.tm.current.colorWarning
            : this.tm.current.colorTextSecondary)
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
}
