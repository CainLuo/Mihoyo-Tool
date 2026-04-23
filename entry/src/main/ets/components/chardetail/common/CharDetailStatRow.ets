/**
 * CharDetailStatRow — 属性列表单行（标签 + 值）
 *
 * 原神属性列表通用，支持高亮颜色（暴击率/暴击伤害等）。
 * 在 CharDetailPortraitLayout 和 CharDetailStatsPanel 中使用。
 */
import { themeManager, ThemeManager } from '../../../theme/ThemeManager';
import { CharDetailStat } from '../../../models/CharDetailModels';
import { GenshinElement, elementColor } from '../../../constants/GenshinElement';

@ComponentV2
export struct CharDetailStatRow {
  @Param stat: CharDetailStat = new CharDetailStat($r('app.string.char_detail_no_data'), '');
  @Param charElement: GenshinElement = GenshinElement.UNKNOWN;
  /** 字体大小：宽屏用 body13，Phone 用 body12 */
  @Param isCompact: boolean = false;
  @Local private tm: ThemeManager = themeManager;

  build() {
    Row() {
      Text(this.stat.labelKey)
        .fontSize(this.isCompact ? this.tm.current.body12.size : this.tm.current.body13.size)
        .fontColor(this.tm.current.textOnDarkSecondary)
        .layoutWeight(1)
      Text(this.stat.value)
        .fontSize(this.isCompact ? this.tm.current.body12.size : this.tm.current.body13Bold.size)
        .fontWeight(FontWeight.Bold)
        .fontColor(this.stat.isHighlight ? elementColor(this.charElement) : this.tm.current.textOnDarkHigh)
    }
    .width(this.tm.current.full)
  }
}
