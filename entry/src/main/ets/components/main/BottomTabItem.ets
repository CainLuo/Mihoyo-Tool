/**
 * BottomTabItem — 底部 Tab 按钮
 */
import { ThemeManager } from '../../theme/ThemeManager'

@ComponentV2
export struct BottomTabItem {
  @Param tm: ThemeManager = new ThemeManager()
  @Param tab: number = 0
  @Param selectedTab: number = 0
  @Param label: Resource = $r('app.string.main_tab_home')
  @Param icon: string = ''  // emoji 占位，后续替换为真实图标
  @Param onSelect: (tab: number) => void = (_tab: number) => {}

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
