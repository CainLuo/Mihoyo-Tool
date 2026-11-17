/**
 * SettingRow — 设置行组件（我的页/关于/外观）
 *
 * 左侧标签 + 可选右侧值文字 + 箭头，适用于所有"点击跳转/触发操作"的设置行。
 * 不传 onTap 时不显示箭头，仅展示标签和值（用于纯展示行如版本号）。
 * 背景色和圆角由父容器负责。
 *
 * 目前只有 account 功能（MyPage / AboutSection / AppearanceSection）使用，
 * 因此放在本模块 views/ 而不是 basic 共享层；其他功能若需要，再协商上移。
 */
import { themeManager, ThemeManager, ThemeFonts } from 'basic'

@ComponentV2
export struct SettingRow {
  @Param label: ResourceStr = ''
  @Param value: ResourceStr | string = ''
  @Param onTap: (() => void) | null = null
  @Local private tm: ThemeManager = themeManager

  build() {
    Row() {
      Text(this.label)
        .font(ThemeFonts.FONT_17)
        .fontColor(this.tm.current.colorTextPrimary)
        .layoutWeight(1)
      if (this.value !== '') {
        Text(this.value)
          .font(ThemeFonts.FONT_17)
          .fontColor(this.tm.current.colorTextSecondary)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .margin({ right: this.onTap !== null ? this.tm.current.value8 : 0 })
      }
      if (this.onTap !== null) {
        Text($r('app.string.common_arrow_right'))
          .font(ThemeFonts.FONT_17)
          .fontColor(this.tm.current.colorTextSecondary)
      }
    }
    .width(this.tm.current.full)
    .height(this.tm.current.value50)
    .padding({ left: this.tm.current.font16, right: this.tm.current.font16 })
    .alignItems(VerticalAlign.Center)
    .onClick(this.onTap !== null ? this.onTap : () => {})
  }
}

// ─── Preview ─────────────────────────────────────────────────────

@Preview
@ComponentV2
export struct SettingRowPreview {
  @Local private tm: ThemeManager = themeManager

  build() {
    Column() {
      SettingRow({ label: $r('app.string.my_export_logs'), onTap: () => {} })

      Divider().color(this.tm.current.colorDivider).margin({ left: this.tm.current.font16 })

      SettingRow({ label: $r('app.string.my_about_version'), value: '1.0.0' })
    }
    .width(this.tm.current.value360)
    .borderRadius(this.tm.current.radius12)
    .clip(true)
    .padding({ top: this.tm.current.font16, bottom: this.tm.current.font16 })
    .backgroundColor('#1a1a2e')
  }
}
