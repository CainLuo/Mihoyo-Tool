/**
 * WidgetGenshinExtraRows.ets — 原神额外数据行组件
 *
 * 显示洞天宝钱、每日委托、参量质变仪等原神专属数据。
 * 使用 @Component（V1 体系），因为卡片渲染引擎不支持 @ComponentV2。
 */

import { DefaultTheme } from '../../theme/DefaultTheme';
import { WidgetDataRow } from './WidgetDataRow';
import { WidgetGameData } from '../models/WidgetModels';

/** 主题常量实例 */
const theme = new DefaultTheme();

@Component
export struct WidgetGenshinExtraRows {

  @Prop game: WidgetGameData = new WidgetGameData();
  /** 数据行字体大小，默认 body12（13vp），4×4 传 body13（14vp） */
  fontSize: number = theme.value12;

  build() {
    Column({ space: 0 }) {
      if (parseInt(this.game.coinStr) >= 0) {
        WidgetDataRow({
          label: $r('app.string.widget_home_coin'),
          value: this.game.coinStr + '/' + this.game.coinMaxStr,
          valueColor: $r('app.color.color_warning'),
          fontSize: this.fontSize
        })
      }

      if (parseInt(this.game.taskStr) >= 0) {
        WidgetDataRow({
          label: $r('app.string.widget_daily_task'),
          value: this.game.taskAllReceived === 'true'
            ? $r('app.string.widget_task_received')
            : this.game.taskStr + '/' + this.game.taskTotalStr,
          valueColor: $r('app.color.color_warning'),
          fontSize: this.fontSize
        })
      }

      WidgetDataRow({
        label: $r('app.string.widget_transformer'),
        value: this.game.transformerStr === 'true'
          ? $r('app.string.widget_transformer_ready')
          : $r('app.string.widget_transformer_cooling'),
        valueColor: this.game.transformerStr === 'true'
          ? $r('app.color.color_warning')
          : $r('app.color.gray_500'),
        fontSize: this.fontSize
      })
    }
    .width(theme.full)
    .height(theme.full)
    .justifyContent(FlexAlign.SpaceEvenly)
  }
}

@Preview
@Component
struct WidgetGenshinExtraRowsPreview {
  build() {
    Column() {
      WidgetGenshinExtraRows({ game: new WidgetGameData(), fontSize: 13 })
    }
    .padding(16)
    .width(200)
    .backgroundColor($r('app.color.dark_400'))
  }
}
