/**
 * WidgetDataRow.ets — Widget 通用数据行
 *
 * 左侧标签 + 右侧数值，用于 2×2、2×4、4×4 卡片的数据展示行。
 * 使用 @Component（V1 体系），因为卡片渲染引擎不支持 @ComponentV2。
 */

import { widgetTheme } from '../utils/WidgetTheme';

@Component
export struct WidgetDataRow {
  label: ResourceStr = '';
  value: ResourceStr = '';
  valueColor: ResourceColor = $r('app.color.text_on_dark_high');
  fontSize: number = 13;

  build() {
    Row() {
      Text(this.label)
        .fontSize(this.fontSize)
        .fontColor($r('app.color.text_on_dark_secondary'))
        .layoutWeight(1)

      Text(this.value)
        .fontSize(this.fontSize)
        .fontWeight(FontWeight.Medium)
        .fontColor(this.valueColor)
    }
    .width(widgetTheme.full)
  }
}

@Preview
@Component
struct WidgetDataRowPreview {
  build() {
    Column({ space: 8 }) {
      WidgetDataRow({
        label: $r('app.string.widget_home_coin'),
        value: '1800/2400',
        valueColor: $r('app.color.accent_refine'),
        fontSize: 13
      })

      WidgetDataRow({
        label: $r('app.string.widget_daily_task'),
        value: '4/4',
        valueColor: $r('app.color.accent_refine'),
        fontSize: 13
      })
    }
    .padding(16)
    .width(200)
    .backgroundColor('#1a1a2e')
  }
}
