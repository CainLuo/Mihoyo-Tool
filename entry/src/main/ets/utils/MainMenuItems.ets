/**
 * MainMenuItems — MainPage 标题栏菜单与底部 Tab 项的构建
 *
 * 均为纯函数：输入状态与回调，输出 ArkUI 菜单 / Tab 项结构，
 * 使 MainPage 只保留状态与组装逻辑。
 */
import { SymbolGlyphModifier } from '@kit.ArkUI'

export const TAB_HOME = 0
export const TAB_CHARACTERS = 1
export const TAB_TOOLS = 2
export const TAB_MY = 3

/** 当前 Tab 对应的标题 */
export function resolveTabTitle(selectedTab: number): Resource {
  if (selectedTab === TAB_HOME) { return $r('app.string.main_tab_home') }
  if (selectedTab === TAB_CHARACTERS) { return $r('app.string.characters_tab_title') }
  if (selectedTab === TAB_TOOLS) { return $r('app.string.tools_title') }
  return $r('app.string.main_tab_my')
}

/** HomePage 标题栏菜单（刷新按钮） */
export function buildHomeMenuItems(shouldShow: boolean, isRefreshing: boolean,
                                   doRefresh: () => void): NavigationMenuItem[] {
  if (!shouldShow) { return []; }
  return [{
    value: 'refresh',
    symbolIcon: new SymbolGlyphModifier($r('sys.symbol.arrow_clockwise')),
    isEnabled: !isRefreshing,
    action: () => { doRefresh() }
  }];
}

/** CharactersPage 标题栏菜单（账号切换 + 刷新） */
export function buildCharMenuItems(shouldShowSwitcher: boolean, shouldShowRefresh: boolean,
                                   isRefreshing: boolean, doRefresh: () => void,
                                   onSwitchAccount: () => void): NavigationMenuItem[] {
  const items: NavigationMenuItem[] = [];
  if (shouldShowSwitcher) {
    items.push({
      value: 'switch_account',
      symbolIcon: new SymbolGlyphModifier($r('sys.symbol.person_2')),
      action: () => { onSwitchAccount() }
    });
  }
  if (shouldShowRefresh) {
    items.push({
      value: 'refresh',
      symbolIcon: new SymbolGlyphModifier($r('sys.symbol.arrow_clockwise')),
      isEnabled: !isRefreshing,
      action: () => { doRefresh() }
    });
  }
  return items;
}

/** MyPage 标题栏菜单（仅 DEBUG 构建显示测试页入口） */
export function buildMyMenuItems(debug: boolean, onOpenTestPage: () => void): NavigationMenuItem[] {
  if (!debug) { return []; }
  return [{
    value: 'test',
    symbolIcon: new SymbolGlyphModifier($r('sys.symbol.wrench_and_screwdriver')),
    action: () => { onOpenTestPage() }
  }];
}

/** 生成底部 Tab 项（图标 / 选中态 / 切换行为一致） */
export function createTabItem(label: Resource, icon: Resource, tab: number, selectedTab: number,
                              colorSecondary: ResourceColor, colorPrimary: ResourceColor,
                              onSelect: (tab: number) => void): ToolbarItem {
  return {
    value: label,
    symbolIcon: new SymbolGlyphModifier(icon)
      .fontColor([colorSecondary]),
    activeSymbolIcon: new SymbolGlyphModifier(icon)
      .fontColor([colorPrimary]),
    status: selectedTab === tab ? ToolbarItemStatus.ACTIVE : ToolbarItemStatus.NORMAL,
    action: () => { onSelect(tab) }
  }
}
