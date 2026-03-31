/**
 * SidebarNavItem — 侧边导航项
 */
import { ThemeManager } from '../../theme/ThemeManager'

@ComponentV2
export struct SidebarNavItem {
  @Param tm: ThemeManager = new ThemeManager()
  @Param tab: number = 0
  @Param selectedTab: number = 0
  @Param label: Resource = $r('app.string.main_tab_home')
  @Param onSelect: (tab: number) => void = (_tab: number) => {}

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
        .font(this.tab === this.selectedTab ? this.tm.current.body16Medium : this.tm.current.body16)
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
      : this.tm.current.colorTransparent)
    .onClick(() => { this.onSelect(this.tab) })
  }
}
