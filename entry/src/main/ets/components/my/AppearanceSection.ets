/**
 * AppearanceSection — 外观设置 Section
 *
 * 主题模式切换（浅色 / 深色 / 跟随系统）。
 */
import { ConfigurationConstant } from '@kit.AbilityKit'
import { themeManager, ThemeManager } from '../../theme/ThemeManager'
import { ThemeChip } from './ThemeChip'

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
          ThemeChip({
            label: $r('app.string.my_theme_light'),
            mode: ConfigurationConstant.ColorMode.COLOR_MODE_LIGHT,
            selectedMode: this.themeMode,
            onSelect: (m: number) => { this.onThemeChange(m) }
          })

          ThemeChip({
            label: $r('app.string.my_theme_dark'),
            mode: ConfigurationConstant.ColorMode.COLOR_MODE_DARK,
            selectedMode: this.themeMode,
            onSelect: (m: number) => { this.onThemeChange(m) }
          })

          ThemeChip({
            label: $r('app.string.my_theme_system'),
            mode: ConfigurationConstant.ColorMode.COLOR_MODE_NOT_SET,
            selectedMode: this.themeMode,
            onSelect: (m: number) => { this.onThemeChange(m) }
          })
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
}

// ─── Preview ─────────────────────────────────────────────────────

@Preview
@ComponentV2
export struct AppearanceSectionPreview {
  @Local private tm: ThemeManager = themeManager

  build() {
    Column() {
      AppearanceSection({ themeMode: ConfigurationConstant.ColorMode.COLOR_MODE_DARK })
    }
    .padding(this.tm.current.value16)
    .backgroundColor('#1a1a2e')
  }
}
