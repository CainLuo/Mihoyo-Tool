/**
 * ZZZOtherCard — 绝区零其他卡片（式舆防卫战 + 会员卡 + 咖啡厅）
 *
 * 仅在 DailyNoteZZZ 中使用。
 */
import { themeManager, ThemeManager } from '../../../theme/ThemeManager';
import { ThemeFonts } from '../../../theme/ThemeFonts'
import { ZZZDailyNoteVM } from '../../../models/DailyNoteModels';
import { DailyNoteDataRow } from '../common/DailyNoteDataRow';

@ComponentV2
export struct ZZZOtherCard {
  @Param data: ZZZDailyNoteVM = new ZZZDailyNoteVM();
  @Local private tm: ThemeManager = themeManager;

  private templeLabel(): ResourceStr {
    if (this.data.templeExpeditionState === 'ExpeditionStateRunning') { return $r('app.string.daily_note_temple_running'); }
    if (this.data.templeExpeditionState === 'ExpeditionStateDone') { return $r('app.string.daily_note_temple_done'); }
    if (this.data.templeExpeditionState === 'ExpeditionStateIdle') { return $r('app.string.daily_note_temple_idle'); }
    return $r('app.string.daily_note_temple_unknown');
  }

  private templeColor(): ResourceColor {
    if (this.data.templeExpeditionState === 'ExpeditionStateDone') { return this.tm.current.colorPrimary; }
    if (this.data.templeExpeditionState === 'ExpeditionStateRunning') { return this.tm.current.colorWarning; }
    return this.tm.current.colorTextSecondary;
  }

  private memberCardLabel(): ResourceStr {
    if (this.data.memberCardState === 'MemberCardStateActive') { return $r('app.string.daily_note_member_active'); }
    if (this.data.memberCardState === 'MemberCardStateExpired') { return $r('app.string.daily_note_member_expired'); }
    return $r('app.string.daily_note_member_no');
  }

  private memberCardColor(): ResourceColor {
    if (this.data.memberCardState === 'MemberCardStateActive') { return this.tm.current.colorPrimary; }
    if (this.data.memberCardState === 'MemberCardStateExpired') { return this.tm.current.colorDanger; }
    return this.tm.current.colorTextSecondary;
  }

  private cafeLabel(): ResourceStr {
    if (this.data.cafeState === 'CafeStateDone') { return $r('app.string.daily_note_cafe_done'); }
    if (this.data.cafeState === 'CafeStateOpen') { return $r('app.string.daily_note_cafe_open'); }
    return $r('app.string.daily_note_cafe_no');
  }

  private cafeColor(): ResourceColor {
    if (this.data.cafeState === 'CafeStateDone') { return this.tm.current.colorPrimary; }
    if (this.data.cafeState === 'CafeStateOpen') { return this.tm.current.colorWarning; }
    return this.tm.current.colorTextSecondary;
  }

  build() {
    Column({ space: this.tm.current.value0 }) {
      // 式舆防卫战（首行，含货币数量副标题）
      Row() {
        Text($r('app.string.daily_note_temple'))
          .font(ThemeFonts.font14)
          .fontColor(this.tm.current.colorTextSecondary)
          .layoutWeight(1)

        Column({ space: this.tm.current.value2 }) {
          Text(this.templeLabel())
            .font(ThemeFonts.fontMedium17)
            .fontColor(this.templeColor())

          if (this.data.templeCurrentCurrency > 0) {
            Text($r('app.string.daily_note_temple_currency', this.data.templeCurrentCurrency))
              .font(ThemeFonts.font13)
              .fontColor(this.tm.current.colorTextSecondary)
          }
        }
        .alignItems(HorizontalAlign.End)
      }
      .width(this.tm.current.full)
      .padding({
        left: this.tm.current.font16,
        right: this.tm.current.font16,
        top: this.tm.current.value12,
        bottom: this.tm.current.value8
      })

      DailyNoteDataRow({
        label: $r('app.string.daily_note_member_card'),
        value: this.memberCardLabel(),
        valueColor: this.memberCardColor()
      })

      DailyNoteDataRow({
        label: $r('app.string.daily_note_cafe'),
        value: this.cafeLabel(),
        valueColor: this.cafeColor()
      })

      Row().height(this.tm.current.value4)
    }
    .width(this.tm.current.full)
    .backgroundColor(this.tm.current.colorSurfaceCard)
    .borderRadius(this.tm.current.radius12)
  }
}
