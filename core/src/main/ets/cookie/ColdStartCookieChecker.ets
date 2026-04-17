/**
 * ColdStartCookieChecker — 冷启动 Cookie 定期检查
 *
 * 在 App 冷启动后，检查所有账号的 update_time，
 * 超过 7 天且 cookie 中包含 stoken 的账号执行静默刷新。
 *
 * 设计原则：
 * - needsColdStartRefresh 为纯函数，接受可注入的 now 参数，便于单元测试
 * - checkAndRefreshAll 单账号失败不中断其他账号
 * - 不阻塞调用方，由调用方异步触发
 */

import { BBSRepository } from '../repository/BBSRepository';
import { AccountRow } from '../models/AccountRow';
import { AuthExpiredError } from '../errors/ApiErrors';
import { ApiLogSystem } from '../log/ApiLogSystem';
import { LogEventType } from '../log/ApiLogEntry';

/** 7 天阈值（秒） */
const COLD_START_REFRESH_THRESHOLD_SECONDS: number = 604800;

/** 单个账号刷新失败的信息 */
export class FailedAccountInfo {
  /** 账号 username（米游社 account_id） */
  username: string = '';
  /** 账号昵称（用于 Dialog 文案） */
  nickname: string = '';
  /** true=网络错误，false=stoken 过期或不存在 */
  isNetworkError: boolean = false;
}

/** 冷启动检查的整体结果 */
export class ColdStartRefreshResult {
  /** 刷新成功的账号数量 */
  successCount: number = 0;
  /** 刷新失败的账号列表 */
  failedAccounts: FailedAccountInfo[] = [];
}

export class ColdStartCookieChecker {

  /**
   * 纯函数：判断是否需要冷启动刷新。
   * 可注入 now 参数，便于单元测试。
   *
   * @param updateTime  account_table.update_time（Unix 秒）
   * @param now         当前时间戳（Unix 秒）
   * @returns 超过 7 天返回 true，否则返回 false
   */
  static needsColdStartRefresh(updateTime: number, now: number): boolean {
    return now - updateTime > COLD_START_REFRESH_THRESHOLD_SECONDS;
  }

  /**
   * 遍历所有账号，对需要刷新的账号执行静默刷新。
   * 单账号失败不影响其他账号的处理流程。
   *
   * @param bbsRepository  BBSRepository 实例
   * @param now            当前时间戳（Unix 秒），默认 Math.floor(Date.now() / 1000)
   * @returns 刷新结果（成功数量 + 失败账号列表）
   */
  static async checkAndRefreshAll(
    bbsRepository: BBSRepository,
    now?: number,
  ): Promise<ColdStartRefreshResult> {
    const currentTime = now ?? Math.floor(Date.now() / 1000);
    const result = new ColdStartRefreshResult();

    let accounts: AccountRow[] = [];
    try {
      accounts = await bbsRepository.getAllAccounts();
    } catch (e) {
      ApiLogSystem.getInstance().error(
        'ColdStartCookieChecker',
        'getAllAccounts failed: ' + String(e),
        LogEventType.LIFECYCLE,
      );
      return result;
    }

    if (accounts.length === 0) {
      return result;
    }

    for (let i = 0; i < accounts.length; i++) {
      const account = accounts[i];

      // 跳过 cookie 为空的账号
      if (account.cookie.length === 0) {
        continue;
      }

      // 跳过 update_time 未超阈值的账号
      if (!ColdStartCookieChecker.needsColdStartRefresh(account.updateTime, currentTime)) {
        continue;
      }

      // 跳过无 stoken 的账号（静默跳过，不记录失败）
      const stoken = BBSRepository.extractCookieField(account.cookie, 'stoken');
      if (stoken.length === 0) {
        continue;
      }

      // 执行刷新
      try {
        await bbsRepository.refreshCookieIfNeeded(account.username, account.cookie);
        result.successCount++;
        ApiLogSystem.getInstance().info(
          'ColdStartCookieChecker',
          'refreshed account: ' + account.username,
          LogEventType.LIFECYCLE,
        );
      } catch (e) {
        const isNetworkError = !(e instanceof AuthExpiredError);
        const info = new FailedAccountInfo();
        info.username = account.username;
        info.nickname = account.nickname.length > 0 ? account.nickname : account.username;
        info.isNetworkError = isNetworkError;
        result.failedAccounts[result.failedAccounts.length] = info;
        ApiLogSystem.getInstance().warning(
          'ColdStartCookieChecker',
          'refresh failed for ' + account.username + ', isNetworkError=' + isNetworkError,
          LogEventType.LIFECYCLE,
        );
      }
    }

    return result;
  }
}
