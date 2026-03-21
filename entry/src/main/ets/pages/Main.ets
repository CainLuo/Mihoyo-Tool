/**
 * Main — 应用主框架
 *
 * 响应式布局：
 *   xs（Phone）/ sm（横屏手机）：底部 TabBar
 *   md（Foldable 展开）/ lg（PC/2in1）：左侧固定侧边导航栏
 *
 * 原型参考：character-card-prototype.html — Foldable / PC 布局
 */

import { themeManager, ThemeManager } from '../theme/ThemeManager';
import { Home } from './Home';
import { Characters } from './Characters';
import { My } from './My';
import { AppConstants } from '../constants/AppConstants';

/** Tab 索引常量 */
const TAB_HOME = 0;
const TAB_CHARACTERS = 1;
const TAB_MY = 2;

@ComponentV2
export struct Main {
  @Local private tm: ThemeManager = themeManager;
  @Local private selectedTab: number = TAB_HOME;
  @Local private breakpoint: string = 'xs';

  /** 是否使用侧边导航（md / lg 断点） */
  private get useSidebar(): boolean {
    return this.breakpoint === 'md' || this.breakpoint === 'lg';
  }

  build() {
    // 用 GridRow 监听断点变化，实际布局在内部手动控制
    GridRow({
      columns: { xs: 1, sm: 1, md: 1, lg: 1 },
      breakpoints: {
        value: AppConstants.GRID_BREAKPOINTS,
        reference: BreakpointsReference.WindowSize
      }
    }) {
      GridCol({ span: 1 }) {
        if (this.useSidebar) {
          // ── md / lg：左侧侧边导航 + 右侧内容区 ──
          Row() {
            // 侧边导航栏
            Column() {
              // 侧边栏标题
              Text(this.sidebarTitle())
                .font(this.tm.current.title20Bold)
                .fontColor(this.tm.current.colorTextPrimary)
                .padding({
                  left: this.tm.current.value16,
                  right: this.tm.current.value16,
                  top: this.tm.current.value20,
                  bottom: this.tm.current.value12
                })
                .width(this.tm.current.widthFull)

              Divider().color(this.tm.current.colorDivider)

              // 导航项列表
              Column({ space: this.tm.current.value4 }) {
                this.SidebarNavItem(TAB_HOME, $r('app.string.main_tab_home'))
                this.SidebarNavItem(TAB_CHARACTERS, $r('app.string.characters_tab_title'))
                this.SidebarNavItem(TAB_MY, $r('app.string.main_tab_my'))
              }
              .padding(this.tm.current.value8)
              .layoutWeight(1)
              .alignItems(HorizontalAlign.Start)
            }
            .width(this.tm.current.sidebarWidth)
            .height(this.tm.current.heightFull)
            .backgroundColor(this.tm.current.colorCardBg)
            .border({ width: { right: this.tm.current.cardBorderWidth }, color: this.tm.current.colorDivider })

            // 右侧内容区
            Column() {
              this.PageContent()
            }
            .layoutWeight(1)
            .height(this.tm.current.heightFull)
          }
          .width(this.tm.current.widthFull)
          .height(this.tm.current.heightFull)
        } else {
          // ── xs / sm：底部 TabBar ──
          Column() {
            Column() {
              this.PageContent()
            }
            .layoutWeight(1)

            Divider().color(this.tm.current.colorDivider)

            // 底部 Tab 按钮行
            Row() {
              this.BottomTabItem(TAB_HOME, $r('app.string.main_tab_home'))
              this.BottomTabItem(TAB_CHARACTERS, $r('app.string.characters_tab_title'))
              this.BottomTabItem(TAB_MY, $r('app.string.main_tab_my'))
            }
            .width(this.tm.current.widthFull)
            .height(this.tm.current.heightNavBar)
            .backgroundColor(this.tm.current.colorCardBg)
          }
          .width(this.tm.current.widthFull)
          .height(this.tm.current.heightFull)
        }
      }
    }
    .onBreakpointChange((bp: string) => {
      this.breakpoint = bp;
    })
  }

  /** 当前选中 Tab 对应的页面内容 */
  @Builder
  PageContent() {
    if (this.selectedTab === TAB_HOME) {
      Home()
    } else if (this.selectedTab === TAB_CHARACTERS) {
      Characters()
    } else {
      My()
    }
  }

  /** 侧边栏顶部标题（显示当前页名称） */
  private sidebarTitle(): Resource {
    if (this.selectedTab === TAB_HOME) { return $r('app.string.main_tab_home'); }
    if (this.selectedTab === TAB_CHARACTERS) { return $r('app.string.characters_tab_title'); }
    return $r('app.string.main_tab_my');
  }

  /** 侧边导航项 */
  @Builder
  SidebarNavItem(tab: number, label: Resource) {
    Row({ space: this.tm.current.value10 }) {
      // 选中指示点
      Column()
        .width(this.tm.current.value4 * 2)
        .height(this.tm.current.value4 * 2)
        .borderRadius(this.tm.current.value4)
        .backgroundColor(tab === this.selectedTab
          ? this.tm.current.colorPrimary
          : this.tm.current.colorTextSecondary)

      Text(label)
        .font(tab === this.selectedTab ? this.tm.current.body16Medium : this.tm.current.body16)
        .fontColor(tab === this.selectedTab
          ? this.tm.current.colorPrimary
          : this.tm.current.colorTextSecondary)
    }
    .width(this.tm.current.widthFull)
    .padding({
      left: this.tm.current.value12,
      right: this.tm.current.value12,
      top: this.tm.current.value10,
      bottom: this.tm.current.value10
    })
    .borderRadius(this.tm.current.radius8)
    .backgroundColor(tab === this.selectedTab
      ? $r('app.color.color_primary_bg')
      : Color.Transparent)
    .onClick(() => { this.selectedTab = tab; })
  }

  /** 底部 Tab 按钮 */
  @Builder
  BottomTabItem(tab: number, label: Resource) {
    Column({ space: this.tm.current.value4 }) {
      // 指示点
      Column()
        .width(this.tm.current.value4 * 5)
        .height(this.tm.current.value4)
        .borderRadius(this.tm.current.value4)
        .backgroundColor(tab === this.selectedTab
          ? this.tm.current.colorPrimary
          : Color.Transparent)

      Text(label)
        .fontSize(this.tm.current.body11FontSize)
        .fontColor(tab === this.selectedTab
          ? this.tm.current.colorPrimary
          : this.tm.current.colorTextSecondary)
    }
    .layoutWeight(1)
    .height(this.tm.current.heightFull)
    .justifyContent(FlexAlign.Center)
    .alignItems(HorizontalAlign.Center)
    .onClick(() => { this.selectedTab = tab; })
  }
}
