/**
 * SectionHeader — 分区标题组件（My 页面通用）
 */
import { themeManager, ThemeManager } from '../../theme/ThemeManager'

@ComponentV2
export struct SectionHeader {
  @Param title: ResourceStr = ''
  @Local private tm: ThemeManager = themeManager

  build() {
    Text(this.title)
      .font(this.tm.current.body13)
      .fontColor(this.tm.current.colorTextSecondary)
      .width(this.tm.current.full)
      .padding({ bottom: this.tm.current.value8 })
  }
}
