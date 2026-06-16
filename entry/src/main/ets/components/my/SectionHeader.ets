/**
 * SectionHeader — 分区标题组件（My 页面通用）
 */
import { themeManager, ThemeManager } from '../../theme/ThemeManager'
import { ThemeFonts } from '../../theme/ThemeFonts'

@ComponentV2
export struct SectionHeader {
  @Param title: ResourceStr = ''
  @Local private tm: ThemeManager = themeManager

  build() {
    Text(this.title)
      .font(ThemeFonts.font14)
      .fontColor(this.tm.current.colorTextSecondary)
      .width(this.tm.current.full)
      .padding({ bottom: this.tm.current.value8 })
  }
}

// ─── Preview ─────────────────────────────────────────────────────

@Preview
@ComponentV2
export struct SectionHeaderPreview {
  @Local private tm: ThemeManager = themeManager

  build() {
    Column({ space: this.tm.current.value8 }) {
      SectionHeader({ title: $r('app.string.my_section_account') })

      SectionHeader({ title: $r('app.string.my_section_about') })
    }
    .padding(this.tm.current.font16)
    .backgroundColor('#1a1a2e')
  }
}
