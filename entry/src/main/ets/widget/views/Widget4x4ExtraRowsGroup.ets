/**
 * Widget4x4ExtraRowsGroup.ets — 4×4 Widget 额外数据行分组
 *
 * 渲染一组额外数据行（标签 + 值），用于 4×4 布局的上下两个分组。
 * 分组均分剩余高度（layoutWeight:1），底部分隔线由后续区块是否存在决定。
 *
 * 使用 @Component（V1 体系），因为卡片渲染引擎不支持 @ComponentV2。
 */

import { WidgetExtraRow, WidgetColors } from 'widgetbase';

@Component
export struct Widget4x4ExtraRowsGroup {
  /** 本组数据行 */
  @Prop rows: WidgetExtraRow[] = [];

  /** 是否显示底部分隔线（由后续区块是否存在决定） */
  showBottomBorder: boolean = false;

  build() {
    Column() {
      ForEach(this.rows, (row: WidgetExtraRow) => {
        Row() {
          Text(row.labelResource)
            .fontSize(12)
            .fontColor(WidgetColors.WHITE)
            .opacity(0.45)
            .layoutWeight(1)

          Text(row.displayValue)
            .fontSize(12)
            .fontWeight(600)
            .fontColor(row.valueColor)
        }
        .width('100%')
        .justifyContent(FlexAlign.SpaceBetween)
        .margin({ top: 4, bottom: 4 })
      })
    }
    .width('100%')
    .layoutWeight(1)
    .justifyContent(FlexAlign.Start)
    .alignItems(HorizontalAlign.Start)
    .padding({ top: 6, bottom: 6 })
    .border({ width: { bottom: this.showBottomBorder ? 1 : 0 }, color: 'rgba(255,255,255,0.1)' })
  }
}

@Preview
@Component
struct Widget4x4ExtraRowsGroupPreview {
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
    Column() {
      Widget4x4ExtraRowsGroup({ rows: this.rows, showBottomBorder: true })
    }
    .padding(16)
    .backgroundColor($r('app.color.dark_400'))
  }
}
