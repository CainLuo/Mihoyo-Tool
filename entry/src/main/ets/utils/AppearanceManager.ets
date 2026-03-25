/**
 * AppearanceManager — 应用外观（深色/浅色/跟随系统）管理器
 *
 * 正确 API：
 *   ConfigurationConstant.ColorMode.COLOR_MODE_LIGHT   → 强制浅色
 *   ConfigurationConstant.ColorMode.COLOR_MODE_DARK    → 强制深色
 *   ConfigurationConstant.ColorMode.COLOR_MODE_NOT_SET → 跟随系统（默认）
 *
 * 切换方式：UIAbilityContext.setColorMode(colorMode)
 * 持久化：Preferences（与 CookieManager 共用同一个 store）
 */

import { ConfigurationConstant } from '@kit.AbilityKit';
import { common } from '@kit.AbilityKit';
import { preferences } from '@kit.ArkData';
import { Logger } from './Logger';

const TAG: string = 'AppearanceManager';
const PREFS_NAME: string = 'mihoyo_tool_preferences';
const KEY_COLOR_MODE: string = 'app_color_mode';

// 默认值：跟随系统
const DEFAULT_COLOR_MODE: number = ConfigurationConstant.ColorMode.COLOR_MODE_NOT_SET;

export class AppearanceManager {
  private static prefs: preferences.Preferences | null = null;

  private static async getPrefs(context: common.UIAbilityContext): Promise<preferences.Preferences> {
    if (AppearanceManager.prefs !== null) {
      return AppearanceManager.prefs;
    }
    try {
      AppearanceManager.prefs = await preferences.getPreferences(context, PREFS_NAME);
    } catch (error) {
      Logger.error(TAG, `getPreferences failed: ${error instanceof Error ? error.message : String(error)}`);
      throw new Error('getPreferences failed');
    }
    return AppearanceManager.prefs;
  }

  /** 读取已保存的颜色模式，未保存时返回 COLOR_MODE_NOT_SET */
  public static async getSavedColorMode(context: common.UIAbilityContext): Promise<number> {
    try {
      const prefs = await AppearanceManager.getPrefs(context);
      const saved = await prefs.get(KEY_COLOR_MODE, DEFAULT_COLOR_MODE) as number;
      return saved;
    } catch (error) {
      Logger.error(TAG, `getSavedColorMode failed: ${error instanceof Error ? error.message : String(error)}`);
      return DEFAULT_COLOR_MODE;
    }
  }

  /** 应用颜色模式：立即生效 + 持久化 */
  public static async applyColorMode(
    context: common.UIAbilityContext,
    colorMode: number
  ): Promise<void> {
    // 1. 立即切换
    try {
      context.setColorMode(colorMode);
      Logger.info(TAG, `setColorMode(${colorMode}) success`);
    } catch (error) {
      Logger.error(TAG, `setColorMode failed: ${error instanceof Error ? error.message : String(error)}`);
    }

    // 2. 持久化
    try {
      const prefs = await AppearanceManager.getPrefs(context);
      await prefs.put(KEY_COLOR_MODE, colorMode);
      await prefs.flush();
    } catch (error) {
      Logger.error(TAG, `persist colorMode failed: ${error instanceof Error ? error.message : String(error)}`);
    }
  }

  /** 启动时恢复：在 EntryAbility.onCreate 中调用 */
  public static async restoreOnLaunch(context: common.UIAbilityContext): Promise<void> {
    try {
      const colorMode = await AppearanceManager.getSavedColorMode(context);
      if (colorMode === ConfigurationConstant.ColorMode.COLOR_MODE_NOT_SET) {
        Logger.info(TAG, 'restoreOnLaunch: follow system, skip');
        return;
      }
      context.setColorMode(colorMode);
      Logger.info(TAG, `restoreOnLaunch: restored colorMode=${colorMode}`);
    } catch (error) {
      Logger.error(TAG, `restoreOnLaunch failed: ${error instanceof Error ? error.message : String(error)}`);
    }
  }
}
