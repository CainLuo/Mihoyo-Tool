/**
 * AboutSection — 关于 Section
 *
 * 纯渲染组件，业务逻辑（日志导出、缓存清理）由 MyViewModel 负责。
 */
import { bundleManager } from '@kit.AbilityKit'
import { themeManager, ThemeManager, SettingRow } from 'basic'
import { MyViewModel } from '../viewmodel/MyViewModel'

@ComponentV2
export struct AboutSection {
  @Param vm: MyViewModel = new MyViewModel()
  @Local private tm: ThemeManager = themeManager
  /** HAR 的 BuildProfile 没有 VERSION_NAME，改为运行时读取本应用版本号 */
  private versionName: string =
    bundleManager.getBundleInfoForSelfSync(bundleManager.BundleFlag.GET_BUNDLE_INFO_DEFAULT).versionName

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
        .margin({ left: this.tm.current.font16 })

      SettingRow({
        label: $r('app.string.my_clear_cache'),
        value: this.vm.logSize,
        onTap: () => { this.vm.clearCache(this.getUIContext()) }
      })

      Divider()
        .color(this.tm.current.colorDivider)
        .margin({ left: this.tm.current.font16 })

      SettingRow({
        label: $r('app.string.my_about_version'),
        value: this.versionName
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
    .padding(this.tm.current.font16)
    .backgroundColor('#1a1a2e')
  }
}
