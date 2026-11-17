/**
 * AppearanceSettingsModels.ets — 外观设置页的数据模型与映射
 *
 * `AppearanceSettingsParam` 同时是 My 页传给外观设置页的路由参数，
 * 放在 model/ 而不是 page 中，避免其它模块依赖页面文件。
 */

import { ConfigurationConstant } from '@kit.AbilityKit';

/** 路由参数 */
export class AppearanceSettingsParam {
  themeMode: number = ConfigurationConstant.ColorMode.COLOR_MODE_NOT_SET;
  onThemeChange: (mode: number) => void = (_m: number) => {};
}

/** 主题模式选项数据模型：外观设置页列表中的每一行 */
export class ThemeModeItem {
  /** 对应 ConfigurationConstant.ColorMode 枚举值 */
  mode: number = 0;
  /** 本地化标签，如 $r('app.string.my_theme_light') */
  label: Resource = $r('app.string.my_theme_system');
  /** 本地化描述，如 $r('app.string.appearance_theme_system_desc') */
  desc: Resource = $r('app.string.appearance_theme_system_desc');
}

/** 主题模式对应的本地化标签 */
export function getThemeModeLabel(mode: number): Resource {
  if (mode === ConfigurationConstant.ColorMode.COLOR_MODE_LIGHT) {
    return $r('app.string.my_theme_light');
  }
  if (mode === ConfigurationConstant.ColorMode.COLOR_MODE_DARK) {
    return $r('app.string.my_theme_dark');
  }
  return $r('app.string.my_theme_system');
}
