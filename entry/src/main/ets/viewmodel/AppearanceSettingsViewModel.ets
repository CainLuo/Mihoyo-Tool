/**
 * AppearanceSettingsViewModel.ets
 *
 * 外观设置页 ViewModel，持有当前主题模式状态，提供三种主题选项列表供 View 渲染。
 * ThemeModeItem 定义在同文件，供 AppearanceSettingsPage 使用。
 *
 * 注意：
 *   - ThemeModeItem 必须是 class（ArkTS 严格模式禁止 interface 或对象字面量）
 *   - themeItems() 用 for 循环构建数组（ArkTS 严格模式禁止 Array.map()）
 *   - $r() 返回 Resource 类型，不是 string
 */

import { ConfigurationConstant } from '@kit.AbilityKit';

/**
 * 主题模式选项数据模型
 * 对应外观设置页列表中的每一行
 */
export class ThemeModeItem {
  /** 对应 ConfigurationConstant.ColorMode 枚举值 */
  mode: number = 0;
  /** emoji 图标字符串（☀️ / 🌙 / ⚙️） */
  icon: string = '';
  /** 本地化标签，如 $r('app.string.my_theme_light') */
  label: Resource = $r('app.string.my_theme_system');
  /** 本地化描述，如 $r('app.string.appearance_theme_system_desc') */
  desc: Resource = $r('app.string.appearance_theme_system_desc');
}

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
   * 返回 ThemeMode 对应的本地化标签
   * @param mode ConfigurationConstant.ColorMode 枚举值
   */
  themeModeLabel(mode: number): Resource {
    if (mode === ConfigurationConstant.ColorMode.COLOR_MODE_LIGHT) {
      return $r('app.string.my_theme_light');
    }
    if (mode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK) {
      return $r('app.string.my_theme_dark');
    }
    return $r('app.string.my_theme_system');
  }

  /**
   * 返回三种主题模式的选项列表，顺序固定：浅色 → 深色 → 跟随系统
   */
  themeItems(): ThemeModeItem[] {
    const items: ThemeModeItem[] = [];

    const light = new ThemeModeItem();
    light.mode = ConfigurationConstant.ColorMode.COLOR_MODE_LIGHT;
    light.icon = '☀️';
    light.label = $r('app.string.my_theme_light');
    light.desc = $r('app.string.appearance_theme_light_desc');
    items[items.length] = light;

    const dark = new ThemeModeItem();
    dark.mode = ConfigurationConstant.ColorMode.COLOR_MODE_DARK;
    dark.icon = '🌙';
    dark.label = $r('app.string.my_theme_dark');
    dark.desc = $r('app.string.appearance_theme_dark_desc');
    items[items.length] = dark;

    const system = new ThemeModeItem();
    system.mode = ConfigurationConstant.ColorMode.COLOR_MODE_NOT_SET;
    system.icon = '⚙️';
    system.label = $r('app.string.my_theme_system');
    system.desc = $r('app.string.appearance_theme_system_desc');
    items[items.length] = system;

    return items;
  }
}
