/**
 * PreviewExtraDataRow.ets — Widget 配置预览额外数据行
 *
 * 显示单行额外数据（探索派遣、洞天宝钱等）。
 */

import { WidgetColors } from '../../../widget/models/WidgetUIStates';
import { DefaultTheme } from '../../../theme/DefaultTheme';

@ComponentV2
export struct PreviewExtraDataRow {
  @Param label: ResourceStr = '';
  @Param value: ResourceStr = '';
  @Param valueColor: Resource = WidgetColors.WHITE;

  @Local theme: DefaultTheme = new DefaultTheme();

  build() {
    Row() {
      Text(this.label)
        .fontSize(this.theme.font11)
        .fontColor(WidgetColors.WHITE)
        .opacity(WidgetColors.OPACITY_TEXT_SECONDARY)
        .layoutWeight(1)

      Text(this.value)
        .fontSize(this.theme.font11)
        .fontColor(this.valueColor)
        .opacity(WidgetColors.OPACITY_TEXT_HIGH)
    }
    .width(this.theme.full)
  }
}
