/**
 * WidgetBackgroundSyncService — Widget 后台同步服务
 *
 * 负责：
 * 1. 在主应用进程中执行便笺数据同步
 * 2. 同步完成后更新 Widget 数据存储并推送更新
 *
 * 触发时机：
 * - FormExtensionAbility.onUpdateForm() 拉起主应用
 * - EntryAbility.onNewWant() 收到后台刷新请求
 *
 * 约束：
 * - 后台同步不能弹出 Geetest 验证（用户无感知）
 * - Cookie 过期时静默失败，等待用户打开 App 时处理
 */

import { common } from '@kit.AbilityKit';
import { Logger, CoreInitializer, GameId, GameRoleRow, AccountRow } from 'core';
import { WidgetDataStoreBuilder } from './WidgetDataStoreBuilder';
import { WidgetUpdateNotifier } from './WidgetUpdateNotifier';

const TAG = 'WIDGET';

export class WidgetBackgroundSyncService {
  /**
   * 执行后台同步
   *
   * 流程：
   * 1. 遍历所有账号的所有游戏角色
   * 2. 调用 Repository.syncDailyNote() 同步便笺（不处理 Geetest）
   * 3. 同步完成后调用 refreshAndSave() 更新数据
   * 4. 推送更新到所有 Widget
   *
   * @param context UIAbilityContext
   */
  static async syncAllAndRefresh(context: common.UIAbilityContext): Promise<void> {
    Logger.info(TAG, '[WIDGET_BG_SYNC] syncAllAndRefresh: start');

    try {
      // 获取所有账号
      const accounts = await CoreInitializer.bbsRepository.getAllAccounts();
      Logger.info(TAG, `[WIDGET_BG_SYNC] syncAllAndRefresh: found ${accounts.length} accounts`);

      if (accounts.length === 0) {
        Logger.info(TAG, '[WIDGET_BG_SYNC] syncAllAndRefresh: no accounts, skipping');
        return;
      }

      // 遍历每个账号
      for (let ai = 0; ai < accounts.length; ai++) {
        const account = accounts[ai];
        Logger.info(TAG, `[WIDGET_BG_SYNC] syncAllAndRefresh: processing account[${ai}] uid=${account.uid}`);

        // 获取该账号下的所有游戏角色
        const roles = await CoreInitializer.bbsRepository.getGameRoles(account.uid);
        Logger.info(TAG, `[WIDGET_BG_SYNC] syncAllAndRefresh: account ${account.uid} has ${roles.length} roles`);

        // 遍历每个角色，同步便笺
        for (let ri = 0; ri < roles.length; ri++) {
          const role = roles[ri];
          await WidgetBackgroundSyncService.syncDailyNoteQuietly(account, role);
        }
      }

      // 同步完成后，刷新 Widget 数据存储
      Logger.info(TAG, '[WIDGET_BG_SYNC] syncAllAndRefresh: all sync done, refreshing data store');
      const success = await WidgetDataStoreBuilder.refreshAndSave(context, undefined, false);

      if (success) {
        // 推送更新到所有 Widget
        Logger.info(TAG, '[WIDGET_BG_SYNC] syncAllAndRefresh: pushing update to widgets');
        await WidgetUpdateNotifier.notifyAllWidgets(context);
      }

      Logger.info(TAG, '[WIDGET_BG_SYNC] syncAllAndRefresh: done');
    } catch (e) {
      const msg = e instanceof Error ? e.message : `${e}`;
      Logger.error(TAG, `[WIDGET_BG_SYNC] syncAllAndRefresh failed: ${msg}`);
    }
  }

  /**
   * 静默同步单个角色的便笺
   *
   * 与 HomeViewModel.syncDailyNote() 的区别：
   * - 不处理 Geetest 验证（后台无法弹出 UI）
   * - Cookie 过期时静默失败
   * - 错误不抛出，只记录日志
   *
   * @param account 账号信息
   * @param role 角色信息
   */
  private static async syncDailyNoteQuietly(account: AccountRow, role: GameRoleRow): Promise<void> {
    const gameId = role.gameId;
    Logger.info(TAG, `[WIDGET_BG_SYNC] syncDailyNoteQuietly: gameId=${gameId} roleId=${role.roleId}`);

    try {
      if (gameId === GameId.GENSHIN) {
        await CoreInitializer.genshinRepository.syncDailyNote(
          account.uid, role.roleId, role.server, account.cookie
        );
        Logger.info(TAG, `[WIDGET_BG_SYNC] syncDailyNoteQuietly: genshin success for ${role.roleId}`);
      } else if (gameId === GameId.STARRAIL) {
        await CoreInitializer.starRailRepository.syncDailyNote(
          account.uid, role.roleId, role.server, account.cookie
        );
        Logger.info(TAG, `[WIDGET_BG_SYNC] syncDailyNoteQuietly: starrail success for ${role.roleId}`);
      } else if (gameId === GameId.ZZZ) {
        await CoreInitializer.zzzRepository.syncDailyNote(
          account.uid, role.roleId, role.server, account.cookie
        );
        Logger.info(TAG, `[WIDGET_BG_SYNC] syncDailyNoteQuietly: zzz success for ${role.roleId}`);
      } else {
        Logger.warn(TAG, `[WIDGET_BG_SYNC] syncDailyNoteQuietly: unsupported gameId=${gameId}`);
      }
    } catch (e) {
      // 静默处理错误，不影响其他角色的同步
      const msg = e instanceof Error ? e.message : `${e}`;

      // 检查是否是 Geetest 验证错误（retcode 10035）
      if (msg.includes('10035') || msg.includes('geetest')) {
        Logger.info(TAG, `[WIDGET_BG_SYNC] syncDailyNoteQuietly: geetest required for ${role.roleId}, skipping (will sync when app is opened)`);
      } else if (msg.includes('retcode') || msg.includes('auth')) {
        Logger.warn(TAG, `[WIDGET_BG_SYNC] syncDailyNoteQuietly: auth error for ${role.roleId}, skipping`);
      } else {
        Logger.error(TAG, `[WIDGET_BG_SYNC] syncDailyNoteQuietly: error for ${role.roleId}: ${msg}`);
      }
    }
  }
}
