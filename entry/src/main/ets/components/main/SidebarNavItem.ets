/**
 * SidebarNavItem — 侧边导航项
 */
import { themeManager, ThemeManager } from '../../theme/ThemeManager'

@ComponentV2
export struct SidebarNavItem {
  @Param tab: number = 0
  @Param selectedTab: number = 0
  @Param label: Resource = $r('app.string.main_tab_home')
  @Param onSelect: (tab: number) => void = (_tab: number) => {}
  @Local private tm: ThemeManager = themeManager

  build() {
    Row({ space: this.tm.current.value10 }) {
      Column()
        .width(this.tm.current.value4 * 2)
        .height(this.tm.current.value4 * 2)
        .borderRadius(this.tm.current.value4)
        .backgroundColor(this.tab === this.selectedTab
          ? this.tm.current.colorPrimary
          : this.tm.current.colorTextSecondary)

      Text(this.label)
        .font(this.tab === this.selectedTab ? this.tm.current.fontMedium17 : this.tm.current.font17)
        .fontColor(this.tab === this.selectedTab
          ? this.tm.current.colorPrimary
          : this.tm.current.colorTextSecondary)
    }
    .width(this.tm.current.full)
    .padding({
      left: this.tm.current.value12,
      right: this.tm.current.value12,
      top: this.tm.current.value10,
      bottom: this.tm.current.value10
    })
    .borderRadius(this.tm.current.radius8)
    .backgroundColor(this.tab === this.selectedTab
      ? $r('app.color.color_primary_bg')
      : Color.Transparent)
    .onClick(() => { this.onSelect(this.tab) })
  }
}

// ─── Preview ─────────────────────────────────────────────────────

@Preview
@ComponentV2
export struct SidebarNavItemPreview {
  @Local private tm: ThemeManager = themeManager

  build() {
    Column({ space: this.tm.current.value4 }) {
      SidebarNavItem({ tab: 0, selectedTab: 0, label: $r('app.string.main_tab_home') })

      SidebarNavItem({ tab: 1, selectedTab: 0, label: $r('app.string.main_tab_characters') })

      SidebarNavItem({ tab: 2, selectedTab: 0, label: $r('app.string.main_tab_my') })
    }
    .padding(this.tm.current.font16)
    .width(this.tm.current.value200)
    .backgroundColor('#1a1a2e')
  }
}
