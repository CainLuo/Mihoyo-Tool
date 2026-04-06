/**
 * GenericGameToolCardContent — 通用游戏战绩卡片内容区（崩坏3等）
 */
import { themeManager, ThemeManager } from '../../theme/ThemeManager'
import { GameNoteSnapshotVM } from './HomeModels'
import { TimeFormatUtil } from '../../utils/TimeFormatUtil'
import { common } from '@kit.AbilityKit'

@ComponentV2
export struct GenericGameToolCardContent {
  @Param snap: GameNoteSnapshotVM = new GameNoteSnapshotVM('', 0, 0, 0, '', '', false)
  @Param primaryLabel: Resource = $r('app.string.app_name')
  @Param primaryColor: ResourceColor = $r('app.color.color_primary')
  @Param progressRatio: number = 0
  @Local private tm: ThemeManager = themeManager
  @Local private ctx: common.UIAbilityContext = getContext(this) as common.UIAbilityContext

  build() {
    Column({ space: this.tm.current.value8 }) {
      Row({ space: this.tm.current.value8 }) {
        Column({ space: this.tm.current.value2 }) {
          Text(this.primaryLabel)
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
            Text(TimeFormatUtil.recoveryDesc(this.snap.primaryRecoverySeconds, this.ctx))
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

      if (this.snap.secondaryLabel !== '') {
        Row() {
          Text(this.snap.secondaryLabel)
            .font(this.tm.current.body13)
            .fontColor(this.tm.current.colorTextSecondary)
          Blank()
          Text(this.snap.secondaryDesc)
            .font(this.tm.current.body13)
            .fontColor(this.tm.current.colorTextPrimary)
        }
        .width(this.tm.current.full)
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
struct GenericGameToolCardContentPreview {
  build() {
    Column() {
      GenericGameToolCardContent({
        snap: new GameNoteSnapshotVM('honkai3', 120, 240, 10800, '体力', '120/240', false),
        primaryLabel: $r('app.string.app_name'),
        primaryColor: $r('app.color.game_color_genshin'),
        progressRatio: 0.5
      })
    }
    .backgroundColor('#1a1a2e')
  }
}
