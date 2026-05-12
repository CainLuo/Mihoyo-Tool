/**
 * WidgetTheme.ets — Widget 专用主题工具
 *
 * Widget 组件使用 @Component（V1 体系），不能使用 @ObservedV2/@Trace。
 * 此文件提供 Widget 组件专用的主题数据，直接返回 DefaultTheme 实例。
 *
 * 使用方式：
 *   import { widgetTheme } from './WidgetTheme'
 *   Text('hello').fontSize(widgetTheme.value10)
 */

import { DefaultTheme } from '../../theme/DefaultTheme'

/**
 * Widget 专用的 Theme 实例（直接返回，不使用 @ObservedV2）
 */
const widgetTheme = new DefaultTheme()

export { widgetTheme }
