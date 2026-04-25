/**
 * AppearanceSection — 外观设置 Section
 *
 * 以 SettingRow 样式展示当前主题模式，点击后由外部处理跳转逻辑。
 * 不再内嵌 ThemeChip，改为显示当前选中值 + 箭头，onTap 由调用方传入。
 */
import { ConfigurationConstant } from '@kit.AbilityKit'
import { themeManager, ThemeManager } from '../../theme/ThemeManager'
import { SettingRow } from '../SettingRow'

@ComponentV2
export struct AppearanceSection {
  @Param themeMode: number = ConfigurationConstant.ColorMode.COLOR_MODE_NOT_SET
  @Param onTap: () => void = () => {}
  @Local private tm: ThemeManager = themeManager

  /**
   * 返回主题模式对应的本地化标签
   * 映射逻辑与 AppearanceSettingsViewModel.themeModeLabel 一致
   */
  private themeModeLabel(mode: number): Resource {
    if (mode === ConfigurationConstant.ColorMode.COLOR_MODE_LIGHT) {
      return $r('app.string.my_theme_light')
    }
    if (mode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK) {
      return $r('app.string.my_theme_dark')
    }
    return $r('app.string.my_theme_system')
  }

  build() {
    Column() {
      SettingRow({
        label: $r('app.string.my_theme_label'),
        value: this.themeModeLabel(this.themeMode),
        onTap: this.onTap
      })
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
    Column({ space: this.tm.current.value8 }) {
      AppearanceSection({
        themeMode: ConfigurationConstant.ColorMode.COLOR_MODE_LIGHT,
        onTap: () => {}
      })

      AppearanceSection({
        themeMode: ConfigurationConstant.ColorMode.COLOR_MODE_DARK,
        onTap: () => {}
      })

      AppearanceSection({
        themeMode: ConfigurationConstant.ColorMode.COLOR_MODE_NOT_SET,
        onTap: () => {}
      })
    }
    .padding(this.tm.current.value16)
    .backgroundColor('#1a1a2e')
  }
}
