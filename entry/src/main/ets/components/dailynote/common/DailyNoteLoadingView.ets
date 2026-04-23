/**
 * DailyNoteLoadingView — 便笺详情页加载中状态
 */
import { themeManager, ThemeManager } from '../../../theme/ThemeManager'

@ComponentV2
export struct DailyNoteLoadingView {
  @Local private tm: ThemeManager = themeManager

  build() {
    Row() {
      LoadingProgress()
        .width(this.tm.current.value52)
        .height(this.tm.current.value52)
        .color(this.tm.current.colorPrimary)
    }
    .width(this.tm.current.full)
    .layoutWeight(1)
    .justifyContent(FlexAlign.Center)
  }
}
