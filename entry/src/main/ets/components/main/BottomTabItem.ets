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
  @Param onSelect: (tab: number) => void = (_tab: number) => {}

  build() {
    Column({ space: this.tm.current.value4 }) {
      Column()
        .width(this.tm.current.value4 * 5)
        .height(this.tm.current.value4)
        .borderRadius(this.tm.current.value4)
        .backgroundColor(this.tab === this.selectedTab
          ? this.tm.current.colorPrimary
          : Color.Transparent)
      Text(this.label)
        .fontSize(this.tm.current.body11FontSize)
        .fontColor(this.tab === this.selectedTab
          ? this.tm.current.colorPrimary
          : this.tm.current.colorTextSecondary)
    }
    .layoutWeight(1)
    .height(this.tm.current.heightFull)
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
    .onClick(() => { this.onSelect(this.tab) })
  }
}
