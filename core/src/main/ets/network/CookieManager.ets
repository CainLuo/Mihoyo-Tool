import preferences from '@ohos.data.preferences';
import { CoreInitializer } from '../CoreInitializer';

/**
 * Cookie 管理器
 * 从本地首选项或内存中读取和存储 Cookie
 */
export class CookieManager {
  private static preferences: preferences.Preferences | null = null;
  private static cookieCache: string | null = null;
  private static readonly PREFERENCES_NAME = 'mihoyo_tool_preferences';
  private static readonly COOKIE_KEY = 'current_user_cookie';

  /**
   * 初始化首选项
   */
  private static async initPreferences(): Promise<preferences.Preferences> {
    if (CookieManager.preferences !== null) {
      return CookieManager.preferences;
    }

    try {
      const context = CoreInitializer.getContext();
      CookieManager.preferences = await preferences.getPreferences(
        context,
        CookieManager.PREFERENCES_NAME
      );
      return CookieManager.preferences;
    } catch (error) {
      throw new Error(`Init preferences failed: ${CookieManager.toErrorMessage(error)}`);
    }
  }

  /**
   * 存储 Cookie
   * @param cookie Cookie 字符串
   */
  public static async setCookie(cookie: string): Promise<void> {
    CookieManager.cookieCache = cookie;
    try {
      const prefs = await CookieManager.initPreferences();
      await prefs.put(CookieManager.COOKIE_KEY, cookie);
      await prefs.flush();
    } catch (error) {
      const message: string = CookieManager.toErrorMessage(error);
      console.error(`Failed to persist cookie: ${message}`);
      throw new Error(`Persist cookie failed: ${message}`);
    }
  }

  /**
   * 获取 Cookie
   * @returns Cookie 字符串
   */
  public static async getCookie(): Promise<string | null> {
    // 优先从缓存中获取
    if (CookieManager.cookieCache) {
      return CookieManager.cookieCache;
    }

    // 从首选项中读取
    try {
      const prefs = await CookieManager.initPreferences();
      const cookie = await prefs.get(CookieManager.COOKIE_KEY, '') as string;
      if (cookie) {
        CookieManager.cookieCache = cookie;
        return cookie;
      }
    } catch (error) {
      console.error(`Failed to get cookie: ${CookieManager.toErrorMessage(error)}`);
    }

    return null;
  }

  /**
   * 清除 Cookie
   */
  public static async clearCookie(): Promise<void> {
    CookieManager.cookieCache = null;
    try {
      const prefs = await CookieManager.initPreferences();
      await prefs.delete(CookieManager.COOKIE_KEY);
      await prefs.flush();
    } catch (error) {
      console.error(`Failed to clear cookie: ${CookieManager.toErrorMessage(error)}`);
    }
  }

  private static toErrorMessage(error: object): string {
    if (error instanceof Error) {
      return error.message;
    }
    return `${error}`;
  }
}

// 导出默认实例
export const getCookie = CookieManager.getCookie;
export const setCookie = CookieManager.setCookie;
export const clearCookie = CookieManager.clearCookie;
