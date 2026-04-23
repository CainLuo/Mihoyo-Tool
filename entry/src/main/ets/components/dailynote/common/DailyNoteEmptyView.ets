/**
 * DailyNoteEmptyView — 便笺详情页无数据状态
 */
import { themeManager, ThemeManager } from '../../../theme/ThemeManager'

@ComponentV2
export struct DailyNoteEmptyView {
  @Local private tm: ThemeManager = themeManager

  build() {
    Row() {
      Text($r('app.string.home_no_data_hint'))
        .font(this.tm.current.body13)
        .fontColor(this.tm.current.colorTextSecondary)
    }
    .width(this.tm.current.full)
    .layoutWeight(1)
    .justifyContent(FlexAlign.Center)
  }
}
