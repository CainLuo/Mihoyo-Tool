/**
 * WidgetTheme.ets — Widget 专用主题常量
 *
 * 实验版本：不依赖 AppTheme 的 makeFont，直接使用数字常量。
 * 用于排查是否是 makeFont 导致白屏的问题。
 *
 * 使用方式：
 *   import { widgetTheme } from './WidgetTheme'
 *   Text('hello').fontSize(widgetTheme.value10)
 */

/**
 * Widget 专用的主题常量类
 * 
 * 注意：这是一个纯数据类，不依赖任何外部模块。
 */
class WT {
  // ---- Spacing（与 DefaultTheme 保持一致）----
  value0: number = 0
  value1: number = 1
  value1p5: number = 1.5
  value2: number = 2
  value3: number = 3
  value4: number = 4
  value5: number = 5
  value8: number = 8
  value9: number = 9
  value10: number = 10
  value11: number = 11
  value12: number = 12
  value13: number = 13
  value14: number = 14
  value15: number = 15
  value16: number = 16
  value17: number = 17
  value18: number = 18
  value20: number = 20
  value22: number = 22
  value24: number = 24
  value28: number = 28
  value30: number = 30
  value32: number = 32
  value34: number = 34
  value36: number = 36
  value40: number = 40
  value44: number = 44
  value46: number = 46
  value48: number = 48
  value50: number = 50
  value52: number = 52
  value56: number = 56
  value64: number = 64
  value80: number = 80
  value90: number = 90
  value100: number = 100
  value108: number = 108
  value120: number = 120
  value150: number = 150
  value200: number = 200
  value260: number = 260
  value280: number = 280
  value360: number = 360
  value400: number = 400
  value480: number = 480
  value600: number = 600

  // ---- Percent ----
  full: string = '100%'
  pct90: string = '90%'
  pct80: string = '80%'
  pct40: string = '40%'
  pct45: string = '45%'
  pct35: string = '35%'

  // ---- Radius ----
  radius8: number = 8
  radius12: number = 12
  radius16: number = 16

  // ---- Shadow ----
  shadowRadius: number = 8
  shadowOffsetY: number = 2

  // ---- Angle ----
  a0: number = 0
  a90: number = 90
  a135: number = 135
  a150: number = 150
  a180: number = 180

  // ---- Opacity ----
  shimmerOpacityHigh: number = 1.0
  shimmerOpacityLow: number = 0.3
}

const widgetTheme = new WT()

export { widgetTheme, WT }
