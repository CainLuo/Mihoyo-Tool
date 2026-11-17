/**
 * AppearanceManager — 应用外观（深色/浅色/跟随系统）管理器
 *
 * 正确 API：
 *   ConfigurationConstant.ColorMode.COLOR_MODE_LIGHT   → 强制浅色
 *   ConfigurationConstant.ColorMode.COLOR_MODE_DARK    → 强制深色
 *   ConfigurationConstant.ColorMode.COLOR_MODE_NOT_SET → 跟随系统（默认）
 *
 * 切换方式：UIAbilityContext.setColorMode(colorMode)
 * 持久化：Preferences（沿用旧 store 名，保留已有设置）
 */

import { ConfigurationConstant } from '@kit.AbilityKit';
import { common } from '@kit.AbilityKit';
import { preferences } from '@kit.ArkData';
import { Logger } from 'core';

const TAG: string = 'AppearanceManager';
const PREFS_NAME: string = 'mihoyo_tool_preferences';
const KEY_COLOR_MODE: string = 'app_color_mode';

// 默认值：跟随系统
const DEFAULT_COLOR_MODE: number = ConfigurationConstant.ColorMode.COLOR_MODE_NOT_SET;

export class AppearanceManager {
  private static prefs: preferences.Preferences | null = null;
  /** 内存缓存，避免 MyPage 页每次进入都有异步延迟导致的 UI 跳变 */
  private static cachedColorMode: number = ConfigurationConstant.ColorMode.COLOR_MODE_NOT_SET;

  /** 同步读取缓存的颜色模式（无需 context，启动后即可用） */
  public static getCachedColorMode(): number {
    return AppearanceManager.cachedColorMode;
  }

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

  /**
   * 应用颜色模式：立即生效，成功后持久化。
   *
   * @returns true = 系统已接受切换（内存缓存与持久化已同步）；
   *          false = setColorMode 失败。调用方必须提示用户并留在当前页，不能 pop：
   *          之前这里吞掉异常，页面照常返回，用户看到的是"点了没反应但页面退了"。
   */
  public static async applyColorMode(
    context: common.UIAbilityContext,
    colorMode: number
  ): Promise<boolean> {
    // 1. 立即切换：失败时缓存也不能改，否则下次进入我的页会显示一个没生效的模式
    try {
      context.setColorMode(colorMode);
      Logger.info(TAG, `setColorMode(${colorMode}) success`);
    } catch (error) {
      Logger.error(TAG, `setColorMode failed: ${error instanceof Error ? error.message : String(error)}`);
      return false;
    }
    AppearanceManager.cachedColorMode = colorMode;

    // 2. 持久化：失败只影响下次启动的恢复，本次切换已生效，不作为失败
    try {
      const prefs = await AppearanceManager.getPrefs(context);
      await prefs.put(KEY_COLOR_MODE, colorMode);
      await prefs.flush();
    } catch (error) {
      Logger.error(TAG, `persist colorMode failed: ${error instanceof Error ? error.message : String(error)}`);
    }
    return true;
  }

  /**
   * 启动时恢复：在 EntryAbility.onCreate 中调用。
   * 同步读取并应用（与 LegalPreferences.hasAgreed 相同的 getPreferencesSync 写法），
   * 保证在 onWindowStageCreate 的 loadContent 之前完成，避免首帧先按系统颜色模式绘制再切换造成闪烁。
   */
  public static async restoreOnLaunch(context: common.UIAbilityContext): Promise<void> {
    try {
      const prefs = preferences.getPreferencesSync(context, { name: PREFS_NAME });
      AppearanceManager.prefs = prefs;
      const colorMode = prefs.getSync(KEY_COLOR_MODE, DEFAULT_COLOR_MODE) as number;
      // 更新内存缓存，供 MyPage 页同步读取
      AppearanceManager.cachedColorMode = colorMode;
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
