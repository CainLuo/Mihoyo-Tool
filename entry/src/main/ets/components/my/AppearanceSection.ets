/**
 * AppearanceSection — 外观设置 Section
 *
 * 主题模式切换（浅色 / 深色 / 跟随系统）。
 */
import { ConfigurationConstant, common } from '@kit.AbilityKit'
import { themeManager, ThemeManager } from '../../theme/ThemeManager'
import { AppearanceManager } from '../../utils/AppearanceManager'
import { Logger } from '../../utils/Logger'

const TAG: string = 'AppearanceSection'

@ComponentV2
export struct AppearanceSection {
  @Param themeMode: number = ConfigurationConstant.ColorMode.COLOR_MODE_NOT_SET
  @Param onThemeChange: (mode: number) => void = (_m: number) => {}
  @Local private tm: ThemeManager = themeManager

  build() {
    Column() {
      Row() {
        Text($r('app.string.my_theme_label'))
          .font(this.tm.current.body16)
          .fontColor(this.tm.current.colorTextPrimary)
          .layoutWeight(1)
        Row({ space: this.tm.current.value8 }) {
          this.ThemeChip($r('app.string.my_theme_light'), ConfigurationConstant.ColorMode.COLOR_MODE_LIGHT)
          this.ThemeChip($r('app.string.my_theme_dark'), ConfigurationConstant.ColorMode.COLOR_MODE_DARK)
          this.ThemeChip($r('app.string.my_theme_system'), ConfigurationConstant.ColorMode.COLOR_MODE_NOT_SET)
        }
      }
      .width(this.tm.current.full)
      .height(this.tm.current.value50)
      .padding({ left: this.tm.current.value16, right: this.tm.current.value16 })
      .alignItems(VerticalAlign.Center)
    }
    .width(this.tm.current.full)
    .backgroundColor(this.tm.current.colorSurfaceCard)
    .borderRadius(this.tm.current.radius12)
  }

  @Builder
  private ThemeChip(label: ResourceStr, mode: number) {
    Button(label, { type: ButtonType.Normal })
      .fontSize(this.tm.current.body13.size)
      .fontWeight(this.tm.current.body13.weight)
      .fontColor(this.themeMode === mode ? this.tm.current.textOnDarkHigh : this.tm.current.colorTextSecondary)
      .padding({
        left: this.tm.current.value8,
        right: this.tm.current.value8,
        top: this.tm.current.value4,
        bottom: this.tm.current.value4
      })
      .borderRadius(this.tm.current.radius8)
      .backgroundColor(this.themeMode === mode ? this.tm.current.colorPrimary : this.tm.current.colorDivider)
      .onClick(() => { this.onThemeChange(mode) })
  }
}
