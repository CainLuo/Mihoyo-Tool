/**
 * AppearanceSettingsViewModel.ets
 *
 * 外观设置页 ViewModel，持有当前主题模式状态，提供三种主题选项列表供 View 渲染。
 * `ThemeModeItem` 与标签映射在 `model/AppearanceSettingsModels.ets`，供页面 / 组件 / My 页共用。
 *
 * 注意：
 *   - ThemeModeItem 必须是 class（ArkTS 严格模式禁止 interface 或对象字面量）
 *   - getThemeItems() 用 for 循环构建数组（ArkTS 严格模式禁止 Array.map()）
 *   - $r() 返回 Resource 类型，不是 string
 */

import { ConfigurationConstant } from '@kit.AbilityKit';
import { getThemeModeLabel, ThemeModeItem } from '../model/AppearanceSettingsModels';

@ObservedV2
export class AppearanceSettingsViewModel {
  /** 当前选中的主题模式，初始值为跟随系统 */
  @Trace themeMode: number = ConfigurationConstant.ColorMode.COLOR_MODE_NOT_SET;

  /**
   * 从路由参数初始化 themeMode
   * @param mode ConfigurationConstant.ColorMode 枚举值
   */
  init(mode: number): void {
    this.themeMode = mode;
  }

  /**
   * 返回三种主题模式的选项列表，顺序固定：浅色 → 深色 → 跟随系统
   */
  getThemeItems(): ThemeModeItem[] {
    const items: ThemeModeItem[] = [];

    const light = new ThemeModeItem();
    light.mode = ConfigurationConstant.ColorMode.COLOR_MODE_LIGHT;
    light.label = getThemeModeLabel(light.mode);
    light.desc = $r('app.string.appearance_theme_light_desc');
    items[items.length] = light;

    const dark = new ThemeModeItem();
    dark.mode = ConfigurationConstant.ColorMode.COLOR_MODE_DARK;
    dark.label = getThemeModeLabel(dark.mode);
    dark.desc = $r('app.string.appearance_theme_dark_desc');
    items[items.length] = dark;

    const system = new ThemeModeItem();
    system.mode = ConfigurationConstant.ColorMode.COLOR_MODE_NOT_SET;
    system.label = getThemeModeLabel(system.mode);
    system.desc = $r('app.string.appearance_theme_system_desc');
    items[items.length] = system;

    return items;
  }
}
