/**
 * DailyNoteEmptyView — 便笺详情页无数据状态
 */
import { themeManager, ThemeManager, ThemeFonts } from 'basic'

@ComponentV2
export struct DailyNoteEmptyView {
  @Local private tm: ThemeManager = themeManager

  build() {
    Row() {
      Text($r('app.string.home_no_data_hint'))
        .font(ThemeFonts.FONT_14)
        .fontColor(this.tm.current.colorTextSecondary)
    }
    .width(this.tm.current.full)
    .layoutWeight(1)
    .justifyContent(FlexAlign.Center)
  }
}
