/**
 * StarRailStaminaCard — 星铁日常卡片（开拓力 + 后备 + 派遣 + 实训 + 历战）
 *
 * 仅在 DailyNoteStarRail 中使用。
 */
import { themeManager, ThemeManager } from '../../../theme/ThemeManager';
import { StarRailDailyNoteVM } from '../../../models/DailyNoteModels';
import { DailyNoteDataRow } from '../common/DailyNoteDataRow';
import { TimeFormatUtil } from '../../../utils/TimeFormatUtil';

@ComponentV2
export struct StarRailStaminaCard {
  @Param data: StarRailDailyNoteVM = new StarRailDailyNoteVM();
  @Local private tm: ThemeManager = themeManager;
  private uiCtx: UIContext | null = null;

  aboutToAppear(): void {
    this.uiCtx = this.getUIContext();
  }

  private staminaColor(): ResourceColor {
    if (this.data.maxStamina <= 0) { return this.tm.current.colorPrimary; }
    const ratio = this.data.currentStamina / this.data.maxStamina;
    if (ratio < 0.3) { return this.tm.current.colorDanger; }
    if (ratio < 0.7) { return this.tm.current.colorWarning; }
    return this.tm.current.colorPrimary;
  }

  build() {
    Column({ space: this.tm.current.value0 }) {
      // 开拓力主行
      Row() {
        Column({ space: this.tm.current.value2 }) {
          Text($r('app.string.daily_note_stamina'))
            .font(this.tm.current.body16Medium)
            .fontColor(this.tm.current.colorTextPrimary)

          if (this.data.staminaRecoverySeconds > 0) {
            Text(TimeFormatUtil.formatSeconds(this.data.staminaRecoverySeconds, this.getUIContext()))
              .font(this.tm.current.body12)
              .fontColor(this.tm.current.colorTextSecondary)
          } else {
            Text($r('app.string.daily_note_expedition_finished'))
              .font(this.tm.current.body12)
              .fontColor(this.tm.current.colorPrimary)
          }
        }
        .alignItems(HorizontalAlign.Start)
        .layoutWeight(1)

        Row({ space: this.tm.current.value2 }) {
          Text(this.data.currentStamina.toString())
            .font(this.tm.current.title20Bold)
            .fontColor(this.staminaColor())

          Text('/' + this.data.maxStamina.toString())
            .font(this.tm.current.body13)
            .fontColor(this.tm.current.colorTextSecondary)
        }
        .alignItems(VerticalAlign.Bottom)
      }
      .width(this.tm.current.full)
      .padding({
        left: this.tm.current.value16,
        right: this.tm.current.value16,
        top: this.tm.current.value12,
        bottom: this.tm.current.value8
      })

      DailyNoteDataRow({
        label: $r('app.string.daily_note_reserve_stamina'),
        value: this.data.isReserveStaminaFull
          ? $r('app.string.daily_note_reserve_stamina_full_value', this.data.currentReserveStamina)
          : this.data.currentReserveStamina.toString(),
        valueColor: this.data.isReserveStaminaFull ? this.tm.current.colorPrimary : this.tm.current.colorTextPrimary
      })

      DailyNoteDataRow({
        label: $r('app.string.daily_note_expedition_sr'),
        value: this.data.acceptedExpeditionNum.toString() + ' / ' + this.data.totalExpeditionNum.toString(),
        valueColor: this.tm.current.colorTextPrimary
      })

      DailyNoteDataRow({
        label: $r('app.string.daily_note_train_score'),
        value: this.data.currentTrainScore.toString() + ' / ' + this.data.maxTrainScore.toString(),
        valueColor: this.tm.current.colorTextPrimary
      })

      DailyNoteDataRow({
        label: $r('app.string.daily_note_cocoon'),
        value: this.data.weeklyCocoonCnt.toString() + ' / ' + this.data.weeklyCocoonLimit.toString(),
        valueColor: this.data.weeklyCocoonCnt >= this.data.weeklyCocoonLimit
          ? this.tm.current.colorPrimary : this.tm.current.colorTextPrimary
      })

      Row().height(this.tm.current.value4)
    }
    .width(this.tm.current.full)
    .backgroundColor(this.tm.current.colorSurfaceCard)
    .borderRadius(this.tm.current.radius12)
  }
}
