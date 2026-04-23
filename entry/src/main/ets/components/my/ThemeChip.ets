/**
 * ThemeChip — 主题模式选择按钮
 */
import { themeManager, ThemeManager } from '../../theme/ThemeManager'

@ComponentV2
export struct ThemeChip {
  @Param label: ResourceStr = ''
  @Param mode: number = 0
  @Param selectedMode: number = 0
  @Param onSelect: (mode: number) => void = (_m: number) => {}
  @Local private tm: ThemeManager = themeManager

  build() {
    Button(this.label, { type: ButtonType.Normal })
      .fontSize(this.tm.current.body13.size)
      .fontWeight(this.tm.current.body13.weight)
      .fontColor(this.selectedMode === this.mode ? this.tm.current.textOnDarkHigh : this.tm.current.colorTextSecondary)
      .padding({
        left: this.tm.current.value8,
        right: this.tm.current.value8,
        top: this.tm.current.value4,
        bottom: this.tm.current.value4
      })
      .borderRadius(this.tm.current.radius8)
      .backgroundColor(this.selectedMode === this.mode ? this.tm.current.colorPrimary : this.tm.current.colorDivider)
      .onClick(() => { this.onSelect(this.mode) })
  }
}
