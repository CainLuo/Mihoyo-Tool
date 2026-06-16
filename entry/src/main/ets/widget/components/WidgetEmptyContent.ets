/**
 * WidgetEmptyContent.ets — Widget 空态内容组件
 *
 * 职责：
 * - 显示无账号/无数据时的占位提示
 *
 * 注意：
 * - Widget 使用 @Component（V1 体系）
 */

import { DefaultTheme } from '../../theme/DefaultTheme';

/** 默认主题实例 */
const theme = new DefaultTheme();

/**
 * Widget 空态内容
 */
@Component
export struct WidgetEmptyContent {
  build() {
    Column() {
      Text($r('app.string.widget_no_account'))
        .fontSize(theme.font13)
        .fontColor(Color.White)
        .opacity(0.7)
        .textAlign(TextAlign.Center)
        .maxLines(2)
        .textOverflow({ overflow: TextOverflow.Ellipsis })
    }
    .width(theme.full)
    .height(theme.full)
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
  }
}

/**
 * 调试内容组件
 */
@Component
export struct WidgetDebugContent {
  /** 调试信息 */
  debugInfo: string = '';

  build() {
    Column() {
      Text('DEBUG MODE')
        .fontSize(theme.font9)
        .fontColor($r('app.color.color_warning'))
        .fontWeight(FontWeight.Bold)
        .margin({ bottom: theme.value2 })
      
      Text(this.debugInfo)
        .fontSize(theme.font9)
        .fontColor(Color.White)
        .opacity(0.7)
        .fontFamily('monospace')
        .maxLines(20)
    }
    .width(theme.full)
    .height(theme.full)
    .alignItems(HorizontalAlign.Start)
    .justifyContent(FlexAlign.Start)
  }
}
