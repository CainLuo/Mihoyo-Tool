/**
 * HomeSyncCoordinator.ets
 *
 * 首页同步编排：单角色同步、按需同步、全量同步、冷启动结果处理。
 * 错误通过返回值上报，由 HomeViewModel 决定是否写入 networkErrorMsg。
 */
import {
  AccountRow,
  AuthExpiredError,
  ColdStartRefreshResult,
  CoreInitializer,
  FailedAccountInfo,
  GameId,
  GameRoleRow,
  Logger,
  RetcodeKind,
  RetcodeRegistry,
} from 'core';
import { CookieExpiredSignal } from 'basic';
import { StaminaNotificationService } from 'notification';
import { HomeDataLoader } from './HomeDataLoader';

const TAG: string = 'HomeSyncCoordinator';

export class HomeSyncCoordinator {
  /**
   * 单个角色的便笺同步：委托给对应游戏 Repository 完成 API 调用 + 写 DB。
   * @returns 需要提示给用户的错误信息；空字符串表示无需提示
   */
  static async syncDailyNote(account: AccountRow, role: GameRoleRow, isAutoSync: boolean): Promise<string> {
    const gameId = role.gameId;
    try {
      if (gameId === GameId.GENSHIN) {
        await CoreInitializer.genshinRepository.syncDailyNote(
          account.uid, role.roleId, role.server, account.cookie
        );
      } else if (gameId === GameId.STARRAIL) {
        await CoreInitializer.starRailRepository.syncDailyNote(
          account.uid, role.roleId, role.server, account.cookie
        );
      } else if (gameId === GameId.ZZZ) {
        await CoreInitializer.zzzRepository.syncDailyNote(
          account.uid, role.roleId, role.server, account.cookie
        );
      }
      return '';
    } catch (error) {
      const msg = error instanceof Error ? error.message : `${error}`;
      if (error instanceof AuthExpiredError) {
        // Cookie 失效（-100 / 10001）：推入过期队列，MainPage.ets 统一弹重新登录 Dialog
        const info = new FailedAccountInfo();
        info.username = account.username;
        info.nickname = account.nickname.length > 0 ? account.nickname : account.username;
        info.isNetworkError = false;
        CookieExpiredSignal.getInstance().push(info, `Home.syncDailyNote ${role.gameId}/${role.roleId}: ${msg}`);
        Logger.warn(TAG, `Cookie expired for ${account.username} (${role.gameId}/${role.roleId}): ${msg}`);
        return '';
      }
      if (RetcodeRegistry.messageHasKind(msg, RetcodeKind.VERIFICATION_REQUIRED)) {
        // 人机验证已由 Repository 上报、GeetestCenter 统一弹框，这里不再提示错误
        Logger.warn(TAG, `syncDailyNote needs geetest for ${role.gameId}/${role.roleId}: ${msg}`);
        return '';
      }
      // 始终记录日志
      Logger.error(TAG, `syncDailyNote error for ${role.gameId}/${role.roleId}: ${msg}`);
      // 自动同步静默，手动刷新才触发 Snackbar
      return isAutoSync ? '' : msg;
    }
  }

  /** 按需同步：遍历所有账号角色，只对需要同步的角色触发同步 */
  static async syncIfNeeded(isAutoSync: boolean, onError: (msg: string) => void): Promise<void> {
    const accounts = await CoreInitializer.bbsRepository.getAllAccounts();
    for (let ai = 0; ai < accounts.length; ai++) {
      const account = accounts[ai];
      const roles = await CoreInitializer.bbsRepository.getGameRoles(account.uid);
      for (let ri = 0; ri < roles.length; ri++) {
        const role = roles[ri];
        let needed = false;
        try {
          needed = await HomeDataLoader.shouldSyncDailyNote(account.uid, role.roleId, role.gameId);
        } catch (_) {
          needed = true;
        }
        if (!needed) {
          Logger.info(TAG, `skip sync (within 30min): ${role.gameId}/${role.roleId}`);
          continue;
        }
        const errorMsg = await HomeSyncCoordinator.syncDailyNote(account, role, isAutoSync);
        if (errorMsg !== '') {
          onError(errorMsg);
        }
      }
    }
    // 同步完成后触发通知阈值检查和 Widget 数据推送
    StaminaNotificationService.getInstance().onDailyNotesSynced().catch((_: Error | object) => {});
  }

  /** 遍历所有账号角色，逐一调用 syncDailyNote 进行全量同步 */
  static async syncAllDailyNotes(isAutoSync: boolean, onError: (msg: string) => void): Promise<void> {
    const accounts = await CoreInitializer.bbsRepository.getAllAccounts();
    for (let ai = 0; ai < accounts.length; ai++) {
      const account = accounts[ai];
      const roles = await CoreInitializer.bbsRepository.getGameRoles(account.uid);
      for (let ri = 0; ri < roles.length; ri++) {
        const role = roles[ri];
        const errorMsg = await HomeSyncCoordinator.syncDailyNote(account, role, isAutoSync);
        if (errorMsg !== '') {
          onError(errorMsg);
        }
      }
    }
    // 同步完成后触发通知阈值检查
    StaminaNotificationService.getInstance().onDailyNotesSynced().catch((_: Error | object) => {});
  }

  /**
   * 处理冷启动刷新结果：将 stoken 过期的失败账号写入全局 CookieExpiredSignal，
   * 若有成功刷新则触发一次重新同步。
   */
  static handleColdStartRefreshResult(result: ColdStartRefreshResult, resync: () => Promise<void>): void {
    const signal = CookieExpiredSignal.getInstance();
    for (let i = 0; i < result.failedAccounts.length; i++) {
      const info = result.failedAccounts[i];
      if (!info.isNetworkError) {
        signal.push(info, 'ColdStartCookieChecker');
      }
    }
    if (result.successCount > 0) {
      resync().catch((_: Error | object) => {});
    }
  }
}
