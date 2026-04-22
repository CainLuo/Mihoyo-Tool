/**
 * ZZZShopCard — 绝区零商店卡片（录像店 + 刮刮卡）
 *
 * 仅在 DailyNoteZZZ 中使用。
 */
import { themeManager, ThemeManager } from '../../../theme/ThemeManager';
import { ZZZDailyNoteVM } from '../../../models/DailyNoteModels';
import { DailyNoteDataRow } from '../common/DailyNoteDataRow';

@ComponentV2
export struct ZZZShopCard {
  @Param data: ZZZDailyNoteVM = new ZZZDailyNoteVM();
  @Local private tm: ThemeManager = themeManager;

  private vhsLabel(): ResourceStr {
    if (this.data.vhsSaleState === 'SaleStateDone') { return $r('app.string.daily_note_vhs_done'); }
    if (this.data.vhsSaleState === 'SaleStateDoing') { return $r('app.string.daily_note_vhs_doing'); }
    return $r('app.string.daily_note_vhs_no');
  }

  private vhsColor(): ResourceColor {
    if (this.data.vhsSaleState === 'SaleStateDone') { return this.tm.current.colorPrimary; }
    if (this.data.vhsSaleState === 'SaleStateDoing') { return this.tm.current.colorWarning; }
    return this.tm.current.colorTextSecondary;
  }

  private cardSignLabel(): ResourceStr {
    if (this.data.cardSign === 'CardSignDone') { return $r('app.string.daily_note_card_done'); }
    return $r('app.string.daily_note_card_no');
  }

  private cardSignColor(): ResourceColor {
    if (this.data.cardSign === 'CardSignDone') { return this.tm.current.colorPrimary; }
    return this.tm.current.colorTextSecondary;
  }

  build() {
    Column({ space: this.tm.current.value0 }) {
      DailyNoteDataRow({
        label: $r('app.string.daily_note_vhs_sale'),
        value: this.vhsLabel(),
        valueColor: this.vhsColor(),
        isFirst: true
      })

      DailyNoteDataRow({
        label: $r('app.string.daily_note_card_sign'),
        value: this.cardSignLabel(),
        valueColor: this.cardSignColor()
      })

      Row().height(this.tm.current.value4)
    }
    .width(this.tm.current.full)
    .backgroundColor(this.tm.current.colorSurfaceCard)
    .borderRadius(this.tm.current.radius12)
  }
}
