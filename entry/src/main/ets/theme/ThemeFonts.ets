/**
 * ============================================================
 * ThemeFonts — 字体预设对象
 * ============================================================
 *
 * 提供 makeFont() 创建的 Font 对象，用于 entry 层组件。
 * Widget 不能使用 Font 类型，必须直接用 .fontSize() + .fontWeight()。
 *
 * 用法：
 *   Text('hello').font(ThemeFonts.font17)
 *
 * Widget 用法：
 *   Text('hello').fontSize(this.tm.current.font17).fontWeight(FontWeight.Normal)
 * ============================================================
 */

import { makeFont } from './AppTheme'

/**
 * 字体预设对象（entry 层专用）
 */
export class ThemeFonts {
  static readonly font10: Font = makeFont(10, FontWeight.Normal)
  static readonly font11: Font = makeFont(11, FontWeight.Normal)
  static readonly font13: Font = makeFont(13, FontWeight.Normal)
  static readonly fontBold13: Font = makeFont(13, FontWeight.Bold)
  static readonly font14: Font = makeFont(14, FontWeight.Normal)
  static readonly fontBold14: Font = makeFont(14, FontWeight.Bold)
  static readonly font16: Font = makeFont(16, FontWeight.Normal)
  static readonly fontBold16: Font = makeFont(16, FontWeight.Bold)
  static readonly font17: Font = makeFont(17, FontWeight.Normal)
  static readonly fontMedium17: Font = makeFont(17, FontWeight.Medium)
  static readonly font18: Font = makeFont(18, FontWeight.Normal)
  static readonly fontBold18: Font = makeFont(18, FontWeight.Bold)
  static readonly font20: Font = makeFont(20, FontWeight.Normal)
  static readonly fontBold20: Font = makeFont(20, FontWeight.Bold)
  static readonly font24: Font = makeFont(24, FontWeight.Normal)
  static readonly fontBold24: Font = makeFont(24, FontWeight.Bold)
  static readonly font26: Font = makeFont(26, FontWeight.Normal)
  static readonly fontBold26: Font = makeFont(26, FontWeight.Bold)
}
