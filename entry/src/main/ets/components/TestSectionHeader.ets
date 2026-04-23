/**
 * TestSectionHeader — 测试页分区标题（仅 Mock/Debug 环境使用）
 */
import { themeManager, ThemeManager } from '../theme/ThemeManager'

@ComponentV2
export struct TestSectionHeader {
  @Param title: string = ''
  @Local private tm: ThemeManager = themeManager

  build() {
    Text(this.title)
      .font(this.tm.current.body13)
      .fontColor(this.tm.current.colorTextSecondary)
      .width(this.tm.current.full)
      .padding({
        top: this.tm.current.value8,
        bottom: this.tm.current.value4,
        left: this.tm.current.value4,
      })
  }
}
