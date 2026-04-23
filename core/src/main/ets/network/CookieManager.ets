import { preferences } from '@kit.ArkData';
import { CoreInitializer } from '../CoreInitializer';
import { Logger } from '../utils/Logger';

/**
 * Cookie 管理器
 * 从本地首选项或内存缓存中读取和存储 Cookie
 */
export class CookieManager {
  private static prefs: preferences.Preferences | null = null;
  private static cookieCache: string | null = null;
  private static readonly PREFERENCES_NAME = 'mihoyo_tool_preferences';
  private static readonly COOKIE_KEY = 'current_user_cookie';

  /**
   * 懒初始化首选项实例
   */
  private static async initPreferences(): Promise<preferences.Preferences> {
    if (CookieManager.prefs !== null) {
      return CookieManager.prefs;
    }
    try {
      const context = CoreInitializer.getContext();
      CookieManager.prefs = await preferences.getPreferences(context, CookieManager.PREFERENCES_NAME);
      return CookieManager.prefs;
    } catch (error) {
      throw new Error(`Init preferences failed: ${CookieManager.toErrorMessage(error)}`);
    }
  }

  /**
   * 存储 Cookie（同时写入内存缓存和持久化存储）
   */
  public static async setCookie(cookie: string): Promise<void> {
    CookieManager.cookieCache = cookie;
    try {
      const prefs = await CookieManager.initPreferences();
      await prefs.put(CookieManager.COOKIE_KEY, cookie);
      await prefs.flush();
    } catch (error) {
      const message: string = CookieManager.toErrorMessage(error);
      Logger.error('CookieManager', `Failed to persist cookie: ${message}`);
      throw new Error(`Persist cookie failed: ${message}`);
    }
  }

  /**
   * 获取 Cookie（优先内存缓存，其次持久化存储）
   */
  public static async getCookie(): Promise<string | null> {
    if (CookieManager.cookieCache) {
      return CookieManager.cookieCache;
    }
    try {
      const prefs = await CookieManager.initPreferences();
      const cookie = await prefs.get(CookieManager.COOKIE_KEY, '') as string;
      if (cookie) {
        CookieManager.cookieCache = cookie;
        return cookie;
      }
    } catch (error) {
      Logger.error('CookieManager', `Failed to get cookie: ${CookieManager.toErrorMessage(error)}`);
    }
    return null;
  }

  /**
   * 清除 Cookie（同时清除内存缓存和持久化存储）
   */
  public static async clearCookie(): Promise<void> {
    CookieManager.cookieCache = null;
    try {
      const prefs = await CookieManager.initPreferences();
      await prefs.delete(CookieManager.COOKIE_KEY);
      await prefs.flush();
    } catch (error) {
      Logger.error('CookieManager', `Failed to clear cookie: ${CookieManager.toErrorMessage(error)}`);
    }
  }

  private static toErrorMessage(error: Error | object): string {
    if (error instanceof Error) {
      return error.message;
    }
    return `${error}`;
  }
}

export const getCookie = (): Promise<string | null> => CookieManager.getCookie();
export const setCookie = (cookie: string): Promise<void> => CookieManager.setCookie(cookie);
export const clearCookie = (): Promise<void> => CookieManager.clearCookie();
