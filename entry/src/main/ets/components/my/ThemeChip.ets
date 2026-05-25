/**
 * ThemeChip — 主题模式选择按钮
 *
 * @deprecated 已被 AppearanceSettingsPage 替代。
 * AppearanceSection 不再使用内联 Chip，改为 SettingRow 样式跳转二级页。
 * 保留此文件以维护 git history，不得删除。
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
      .fontSize(this.tm.current.font14)
      .fontWeight(FontWeight.Normal)
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
