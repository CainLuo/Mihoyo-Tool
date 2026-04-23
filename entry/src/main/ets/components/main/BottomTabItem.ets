/**
 * BottomTabItem — 底部 Tab 按钮
 */
import { themeManager, ThemeManager } from '../../theme/ThemeManager'

@ComponentV2
export struct BottomTabItem {
  @Param tab: number = 0
  @Param selectedTab: number = 0
  @Param label: Resource = $r('app.string.main_tab_home')
  @Param icon: string = ''
  @Param onSelect: (tab: number) => void = (_tab: number) => {}
  @Local private tm: ThemeManager = themeManager

  build() {
    Column({ space: this.tm.current.value2 }) {
      Text(this.icon)
        .fontSize(this.tm.current.value22)
        .opacity(this.tab === this.selectedTab ? 1.0 : 0.4)

      Text(this.label)
        .fontSize(this.tm.current.value11)
        .fontColor(this.tab === this.selectedTab
          ? this.tm.current.colorPrimary
          : this.tm.current.colorTextSecondary)
    }
    .layoutWeight(1)
    .height(this.tm.current.full)
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
    .onClick(() => { this.onSelect(this.tab) })
  }
}

// ─── Preview ─────────────────────────────────────────────────────

@Preview
@ComponentV2
export struct BottomTabItemPreview {
  @Local private tm: ThemeManager = themeManager

  build() {
    Row() {
      BottomTabItem({ tab: 0, selectedTab: 0, label: $r('app.string.main_tab_home'), icon: '🏠' })

      BottomTabItem({ tab: 1, selectedTab: 0, label: $r('app.string.main_tab_characters'), icon: '⚔️' })

      BottomTabItem({ tab: 2, selectedTab: 0, label: $r('app.string.main_tab_my'), icon: '👤' })
    }
    .width(this.tm.current.full)
    .height(this.tm.current.value56)
    .backgroundColor('#1a1a2e')
  }
}
