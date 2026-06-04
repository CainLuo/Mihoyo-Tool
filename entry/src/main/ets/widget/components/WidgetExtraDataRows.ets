/**
 * WidgetExtraDataRows.ets — Widget 额外数据行组件
 *
 * 显示额外数据行（探索派遣、洞天宝钱、每日实训等）。
 * 可在多种尺寸的 Widget 中复用。
 *
 * 使用 @Component（V1 体系），因为卡片渲染引擎不支持 @ComponentV2。
 */

import { WidgetExtraRow, WidgetColors } from '../models/WidgetUIStates';
import { DefaultTheme } from '../../theme/DefaultTheme';

@Component
export struct WidgetExtraDataRows {
  /** 额外数据行列表 */
  @Prop extraRows: WidgetExtraRow[] = [];

  /** 是否在嵌套容器中使用 */
  inNestedContainer: boolean = false;

  /** 主题常量 */
  theme: DefaultTheme = new DefaultTheme();

  build() {
    Column({ space: this.theme.value5 }) {
      ForEach(this.extraRows, (row: WidgetExtraRow, idx: number) => {
        Row() {
          Text(row.labelResource)
            .fontSize(this.theme.font11)
            .fontColor(WidgetColors.WHITE)
            .opacity(WidgetColors.OPACITY_TEXT_SECONDARY)
            .layoutWeight(1)
            .maxLines(1)
            .textOverflow({ overflow: TextOverflow.Ellipsis })

          Text(row.displayValue)
            .fontSize(this.theme.font11)
            .fontWeight(FontWeight.Bold)
            .fontColor(row.valueColor)
        }
        .width(this.theme.full)
      })
    }
    .width(this.theme.full)
    .layoutWeight(this.inNestedContainer ? 0 : 1)
    .justifyContent(FlexAlign.Center)
  }
}

@Preview
@Component
struct WidgetExtraDataRowsPreview {
  // Widget 使用 @Component，不能用 @Local，用普通属性
  private rows: WidgetExtraRow[] = [];

  aboutToAppear(): void {
    const row1 = new WidgetExtraRow();
    row1.labelResource = $r('app.string.widget_expedition');
    row1.displayValue = '2/5';
    row1.valueColor = WidgetColors.STARRAIL_PRIMARY;

    const row2 = new WidgetExtraRow();
    row2.labelResource = $r('app.string.widget_home_coin');
    row2.displayValue = '1200/2400';
    row2.valueColor = WidgetColors.STAMINA_MEDIUM;

    this.rows = [row1, row2];
  }

  build() {
    Column({ space: 12 }) {
      WidgetExtraDataRows({ extraRows: this.rows })
    }
    .padding(16)
    .backgroundColor($r('app.color.dark_400'))
  }
}
