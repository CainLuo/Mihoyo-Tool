/**
 * CookieRefreshCoordinator — Cookie 刷新并发控制
 *
 * 单例，维护每个账号的刷新锁（Map<username, Promise<string>>），
 * 防止同一账号在短时间内并发发起多次刷新请求。
 *
 * 设计原则：
 * - 同一账号 60 秒内只发起一次网络请求，并发调用复用同一个 Promise
 * - 不同账号可以并行刷新，互不影响
 * - 账号删除时调用 clearLock 清除状态
 */

import { BBSRepository } from '../repository/BBSRepository';
import { AuthExpiredError } from '../errors/ApiErrors';
import { ApiLogSystem } from '../log/ApiLogSystem';
import { LogEventType } from '../log/ApiLogEntry';

/** 60 秒内同一账号不重复刷新 */
const REFRESH_COOLDOWN_SECONDS: number = 60;

export class CookieRefreshCoordinator {

  private static _instance: CookieRefreshCoordinator | null = null;

  /** 单例入口 */
  static get instance(): CookieRefreshCoordinator {
    if (CookieRefreshCoordinator._instance === null) {
      CookieRefreshCoordinator._instance = new CookieRefreshCoordinator();
    }
    return CookieRefreshCoordinator._instance;
  }

  /** 进行中的刷新 Promise，key=username */
  private refreshLocks: Map<string, Promise<string>> = new Map();

  /** 上次刷新完成的时间戳（Unix 秒），key=username */
  private lastRefreshTime: Map<string, number> = new Map();

  private constructor() {}

  /**
   * 带锁的刷新：同一账号 60 秒内只发起一次网络请求，并发调用复用结果。
   *
   * @param username       账号 username
   * @param cookie         当前 cookie 字符串
   * @param bbsRepository  BBSRepository 实例
   * @returns 刷新后的新 cookie 字符串
   * @throws AuthExpiredError  stoken 不存在或已过期
   */
  async refreshWithLock(
    username: string,
    cookie: string,
    bbsRepository: BBSRepository,
  ): Promise<string> {
    // 60 秒内已完成刷新，从 DB 读取最新 cookie 返回
    const lastTime = this.lastRefreshTime.get(username);
    if (lastTime !== undefined) {
      const now = Math.floor(Date.now() / 1000);
      if (now - lastTime < REFRESH_COOLDOWN_SECONDS) {
        // 读取 DB 中最新的 cookie
        try {
          const account = await bbsRepository.getAccountByUsername(username);
          if (account !== null && account.cookie.length > 0) {
            return account.cookie;
          }
        } catch (_) {}
        return cookie;
      }
    }

    // 已有进行中的刷新，复用同一个 Promise
    const existing = this.refreshLocks.get(username);
    if (existing !== undefined) {
      return existing;
    }

    // 发起新的刷新请求
    const refreshPromise = this.doRefresh(username, cookie, bbsRepository);
    this.refreshLocks.set(username, refreshPromise);

    try {
      const newCookie = await refreshPromise;
      this.lastRefreshTime.set(username, Math.floor(Date.now() / 1000));
      return newCookie;
    } finally {
      this.refreshLocks.delete(username);
    }
  }

  /**
   * 清除指定账号的刷新锁和时间戳（账号删除时调用）。
   */
  clearLock(username: string): void {
    this.refreshLocks.delete(username);
    this.lastRefreshTime.delete(username);
  }

  private async doRefresh(
    username: string,
    cookie: string,
    bbsRepository: BBSRepository,
  ): Promise<string> {
    try {
      const newCookie = await bbsRepository.refreshCookieIfNeeded(username, cookie);
      ApiLogSystem.getInstance().info(
        'CookieRefreshCoordinator',
        'cookie refreshed for: ' + username,
        LogEventType.LIFECYCLE,
      );
      return newCookie;
    } catch (e) {
      if (e instanceof AuthExpiredError) {
        throw e;
      }
      throw new AuthExpiredError('Cookie refresh failed: ' + (e instanceof Error ? e.message : String(e)));
    }
  }
}
