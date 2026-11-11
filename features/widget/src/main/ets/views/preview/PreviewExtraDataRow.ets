/**
 * PreviewExtraDataRow.ets — Widget 配置预览额外数据行
 *
 * 显示单行额外数据（探索派遣、洞天宝钱等）。
 * 2×2 / 2×4 / 4×4 预览共用，字号 / 透明度 / 字重由调用方传入。
 */

import { WidgetColors, DefaultTheme } from 'widgetbase';

/**
 * 预览额外数据行数据模型
 *
 * 2×4 / 4×4 预览共用（行内容按游戏不同，由各自 `getExtraRows()` 提供）。
 */
export class PreviewExtraRow {
  label: ResourceStr = '';
  value: ResourceStr = '';
  valueColor: ResourceColor = WidgetColors.WHITE;

  constructor(label: ResourceStr, value: ResourceStr, valueColor: ResourceColor = WidgetColors.WHITE) {
    this.label = label;
    this.value = value;
    this.valueColor = valueColor;
  }
}

@ComponentV2
export struct PreviewExtraDataRow {
  @Param label: ResourceStr = '';
  @Param value: ResourceStr = '';
  @Param valueColor: ResourceColor = WidgetColors.WHITE;

  /** 字号：2×2 用 11，2×4 / 4×4 用 12 */
  @Param fontSize: number = 11;

  /** 标签透明度：2×2 0.55 / 4×4 0.45 / 2×4 0.4 */
  @Param labelOpacity: number = WidgetColors.OPACITY_TEXT_SECONDARY;

  /** 值字重：2×2 不加粗（400），2×4 / 4×4 用 600 */
  @Param valueFontWeight: number = 400;

  /** 值透明度：2×2 0.95，2×4 / 4×4 为 1 */
  @Param valueOpacity: number = WidgetColors.OPACITY_TEXT_HIGH;

  @Local theme: DefaultTheme = new DefaultTheme();

  build() {
    Row() {
      Text(this.label)
        .fontSize(this.fontSize)
        .fontColor(WidgetColors.WHITE)
        .opacity(this.labelOpacity)
        .layoutWeight(1)

      Text(this.value)
        .fontSize(this.fontSize)
        .fontWeight(this.valueFontWeight)
        .fontColor(this.valueColor)
        .opacity(this.valueOpacity)
    }
    .width(this.theme.full)
  }
}
