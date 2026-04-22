/**
 * DailyNoteDataRow — 便笺数据行（标签 + 值）
 *
 * 三个游戏便笺通用，支持首行（无顶部分割线）和普通行（有顶部分割线）两种模式。
 * 使用方：DailyNoteStarRail、DailyNoteZZZ
 */
import { themeManager, ThemeManager } from '../../../theme/ThemeManager';

@ComponentV2
export struct DailyNoteDataRow {
  @Param label: ResourceStr = '';
  @Param value: ResourceStr = '';
  @Param valueColor: ResourceColor = '';
  /** true = 首行（无顶部分割线），false = 普通行（有顶部分割线） */
  @Param isFirst: boolean = false;
  @Local private tm: ThemeManager = themeManager;

  build() {
    Row() {
      Text(this.label)
        .font(this.tm.current.body13)
        .fontColor(this.tm.current.colorTextSecondary)
        .layoutWeight(1)

      Text(this.value)
        .font(this.tm.current.body16Medium)
        .fontColor(this.valueColor !== '' ? this.valueColor : this.tm.current.colorTextPrimary)
    }
    .width(this.tm.current.full)
    .padding({
      left: this.tm.current.value16,
      right: this.tm.current.value16,
      top: this.isFirst ? this.tm.current.value12 : this.tm.current.value8,
      bottom: this.tm.current.value8
    })
    .border(this.isFirst ? {} : { width: { top: this.tm.current.value1 }, color: this.tm.current.colorDivider })
  }
}
