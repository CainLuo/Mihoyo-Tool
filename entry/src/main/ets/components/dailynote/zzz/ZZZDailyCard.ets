/**
 * ZZZDailyCard — 绝区零日常卡片（电量 + 活跃度）
 *
 * 仅在 DailyNoteZZZ 中使用。
 */
import { themeManager, ThemeManager } from '../../../theme/ThemeManager';
import { ThemeFonts } from '../../../theme/ThemeFonts'
import { ZZZDailyNoteVM } from '../../../models/DailyNoteModels';
import { TimeFormatUtil } from '../../../utils/TimeFormatUtil';

@ComponentV2
export struct ZZZDailyCard {
  @Param data: ZZZDailyNoteVM = new ZZZDailyNoteVM();
  @Local private tm: ThemeManager = themeManager;

  private energyColor(): ResourceColor {
    if (this.data.maxEnergy <= 0) { return this.tm.current.colorPrimary; }
    const ratio = this.data.currentEnergy / this.data.maxEnergy;
    if (ratio < 0.3) { return this.tm.current.colorDanger; }
    if (ratio < 0.7) { return this.tm.current.colorWarning; }
    return this.tm.current.colorPrimary;
  }

  build() {
    Column({ space: this.tm.current.value0 }) {
      // 电量
      Row() {
        Column({ space: this.tm.current.value2 }) {
          Text($r('app.string.daily_note_energy'))
            .font(ThemeFonts.fontMedium17)
            .fontColor(this.tm.current.colorTextPrimary)

          if (this.data.energyRecoverySeconds > 0) {
            Text(TimeFormatUtil.formatSeconds(this.data.energyRecoverySeconds, this.getUIContext()))
              .font(ThemeFonts.font13)
              .fontColor(this.tm.current.colorTextSecondary)
          } else {
            Text($r('app.string.daily_note_expedition_finished'))
              .font(ThemeFonts.font13)
              .fontColor(this.tm.current.colorPrimary)
          }
        }
        .alignItems(HorizontalAlign.Start)
        .layoutWeight(1)

        Row({ space: this.tm.current.value2 }) {
          Text(this.data.currentEnergy.toString())
            .font(ThemeFonts.fontBold20)
            .fontColor(this.energyColor())

          Text('/' + this.data.maxEnergy.toString())
            .font(ThemeFonts.font14)
            .fontColor(this.tm.current.colorTextSecondary)
        }
        .alignItems(VerticalAlign.Bottom)
      }
      .width(this.tm.current.full)
      .padding({
        left: this.tm.current.font16,
        right: this.tm.current.font16,
        top: this.tm.current.value12,
        bottom: this.tm.current.value8
      })

      // 活跃度
      Row() {
        Column({ space: this.tm.current.value2 }) {
          Text($r('app.string.daily_note_vitality'))
            .font(ThemeFonts.fontMedium17)
            .fontColor(this.tm.current.colorTextPrimary)

          Text(this.data.currentVitality >= this.data.maxVitality
            ? $r('app.string.daily_note_vitality_done')
            : $r('app.string.daily_note_vitality_hint'))
            .font(ThemeFonts.font13)
            .fontColor(this.data.currentVitality >= this.data.maxVitality
              ? this.tm.current.colorPrimary : this.tm.current.colorTextSecondary)
        }
        .alignItems(HorizontalAlign.Start)
        .layoutWeight(1)

        Row({ space: this.tm.current.value2 }) {
          Text(this.data.currentVitality.toString())
            .font(ThemeFonts.fontBold20)
            .fontColor(this.data.currentVitality >= this.data.maxVitality
              ? this.tm.current.colorPrimary : this.tm.current.colorTextSecondary)

          Text('/' + this.data.maxVitality.toString())
            .font(ThemeFonts.font14)
            .fontColor(this.tm.current.colorTextSecondary)
        }
        .alignItems(VerticalAlign.Bottom)
      }
      .width(this.tm.current.full)
      .padding({
        left: this.tm.current.font16,
        right: this.tm.current.font16,
        top: this.tm.current.value12,
        bottom: this.tm.current.value8
      })
      .border({ width: { top: this.tm.current.value1 }, color: this.tm.current.colorDivider })

      Row().height(this.tm.current.value4)
    }
    .width(this.tm.current.full)
    .backgroundColor(this.tm.current.colorSurfaceCard)
    .borderRadius(this.tm.current.radius12)
  }
}
