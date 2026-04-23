/**
 * AboutSection — 关于 Section
 *
 * 纯渲染组件，业务逻辑（日志导出、缓存清理）由 MyViewModel 负责。
 */
import BuildProfile from 'BuildProfile'
import { themeManager, ThemeManager } from '../../theme/ThemeManager'
import { MyViewModel } from '../../viewmodel/MyViewModel'
import { SettingRow } from '../SettingRow'

@ComponentV2
export struct AboutSection {
  @Param vm: MyViewModel = new MyViewModel()
  @Local private tm: ThemeManager = themeManager

  aboutToAppear(): void {
    this.vm.refreshLogSize();
  }

  build() {
    Column() {
      SettingRow({
        label: $r('app.string.my_export_logs'),
        onTap: () => { this.vm.exportLogs(this.getUIContext()) }
      })

      Divider()
        .color(this.tm.current.colorDivider)
        .margin({ left: this.tm.current.value16 })

      SettingRow({
        label: $r('app.string.my_clear_cache'),
        value: this.vm.logSize,
        onTap: () => { this.vm.clearCache(this.getUIContext()) }
      })

      Divider()
        .color(this.tm.current.colorDivider)
        .margin({ left: this.tm.current.value16 })

      SettingRow({
        label: $r('app.string.my_about_version'),
        value: BuildProfile.VERSION_NAME
      })
    }
    .width(this.tm.current.full)
    .backgroundColor(this.tm.current.colorSurfaceCard)
    .borderRadius(this.tm.current.radius12)
    .clip(true)
    .onVisibleAreaChange([0.0, 1.0], (isVisible: boolean, _ratio: number) => {
      if (isVisible) {
        this.vm.refreshLogSize();
      }
    })
  }
}

// ─── Preview ─────────────────────────────────────────────────────

@Preview
@ComponentV2
export struct AboutSectionPreview {
  @Local private tm: ThemeManager = themeManager

  build() {
    Column() {
      AboutSection({ vm: new MyViewModel() })
    }
    .padding(this.tm.current.value16)
    .backgroundColor('#1a1a2e')
  }
}
