/**
 * WidgetDataRow.ets — Widget 额外数据行（标签 + 值）
 *
 * 2×4 / 4×4 卡片共用：结构与对齐一致，仅字号 / 标签透明度 / 值字重不同，
 * 由调用方传入，避免各尺寸各写一份。
 *
 * 使用 @Component（V1 体系），因为卡片渲染引擎不支持 @ComponentV2。
 */

import { WidgetExtraRow, WidgetColors } from 'widgetbase';

@Component
export struct WidgetDataRow {
  /** 数据行 */
  @Prop row: WidgetExtraRow = new WidgetExtraRow();

  /** 字号（2×4 / 4×4 均为 12） */
  fontSize: number = 12;

  /** 标签透明度（4×4 为 0.45，2×4 为 0.4） */
  labelOpacity: number = 0.45;

  /** 值字重（2×4 / 4×4 均为 600） */
  valueFontWeight: number = 600;

  build() {
    Row() {
      Text(this.row.labelResource)
        .fontSize(this.fontSize)
        .fontColor(WidgetColors.WHITE)
        .opacity(this.labelOpacity)
        .layoutWeight(1)

      Text(this.row.displayValue)
        .fontSize(this.fontSize)
        .fontWeight(this.valueFontWeight)
        .fontColor(this.row.valueColor)
    }
    .width('100%')
    .justifyContent(FlexAlign.SpaceBetween)
  }
}

@Preview
@Component
struct WidgetDataRowPreview {
  private row: WidgetExtraRow = new WidgetExtraRow();

  aboutToAppear(): void {
    this.row.labelResource = $r('app.string.widget_expedition');
    this.row.displayValue = '2/5';
    this.row.valueColor = WidgetColors.STARRAIL_PRIMARY;
  }

  build() {
    Column({ space: 8 }) {
      WidgetDataRow({ row: this.row, fontSize: 12, labelOpacity: 0.45, valueFontWeight: 600 })
      WidgetDataRow({ row: this.row, fontSize: 12, labelOpacity: 0.4, valueFontWeight: 600 })
    }
    .width(200)
    .padding(16)
    .backgroundColor($r('app.color.dark_400'))
  }
}
