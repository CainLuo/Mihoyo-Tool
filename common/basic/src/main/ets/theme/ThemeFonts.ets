/**
 * ============================================================
 * ThemeFonts — 字体预设对象
 * ============================================================
 *
 * 提供 makeFont() 创建的 Font 对象，用于 entry 层组件。
 * Widget 不能使用 Font 类型，必须直接用 .fontSize() + .fontWeight()。
 *
 * 用法：
 *   Text('hello').font(ThemeFonts.FONT_17)
 *
 * Widget 用法：
 *   Text('hello').fontSize(this.tm.current.font17).fontWeight(FontWeight.Normal)
 * ============================================================
 */

import { makeFont } from 'widgetbase'

/**
 * 字体预设对象（entry 层专用）
 */
export class ThemeFonts {
  static readonly FONT_10: Font = makeFont(10, FontWeight.Normal)
  static readonly FONT_11: Font = makeFont(11, FontWeight.Normal)
  static readonly FONT_13: Font = makeFont(13, FontWeight.Normal)
  static readonly FONT_BOLD_13: Font = makeFont(13, FontWeight.Bold)
  static readonly FONT_14: Font = makeFont(14, FontWeight.Normal)
  static readonly FONT_BOLD_14: Font = makeFont(14, FontWeight.Bold)
  static readonly FONT_16: Font = makeFont(16, FontWeight.Normal)
  static readonly FONT_BOLD_16: Font = makeFont(16, FontWeight.Bold)
  static readonly FONT_17: Font = makeFont(17, FontWeight.Normal)
  static readonly FONT_MEDIUM_17: Font = makeFont(17, FontWeight.Medium)
  static readonly FONT_18: Font = makeFont(18, FontWeight.Normal)
  static readonly FONT_BOLD_18: Font = makeFont(18, FontWeight.Bold)
  static readonly FONT_20: Font = makeFont(20, FontWeight.Normal)
  static readonly FONT_BOLD_20: Font = makeFont(20, FontWeight.Bold)
  static readonly FONT_24: Font = makeFont(24, FontWeight.Normal)
  static readonly FONT_BOLD_24: Font = makeFont(24, FontWeight.Bold)
  static readonly FONT_26: Font = makeFont(26, FontWeight.Normal)
  static readonly FONT_BOLD_26: Font = makeFont(26, FontWeight.Bold)
}
