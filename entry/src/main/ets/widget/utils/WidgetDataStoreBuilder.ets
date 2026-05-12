/**
 * WidgetDataStoreBuilder.ets — Widget 数据构建器
 *
 * 从 DB 读取所有账号的游戏角色，填充 rawJson 到 WidgetDataStore。
 * 调用时机：
 * 1. App 启动时调用 buildFromDB() 初始化数据
 * 2. 用户手动刷新时调用 refreshData() 更新数据
 */

import { Logger } from 'core';
import { CoreInitializer } from 'core';
import { GameRoleRow } from 'core';
import { GameId } from 'core';
import { WidgetDataStore } from '../models/WidgetDataStore';
import { WidgetAccount } from '../models/WidgetAccount';
import { WidgetGame } from '../models/WidgetGame';
import { WidgetRole } from '../models/WidgetRole';
import { WidgetDataStoreManager } from './WidgetDataStoreManager';

const TAG = 'WIDGET';

export class WidgetDataStoreBuilder {
  /**
   * 从 DB 构建完整的 WidgetDataStore
   *
   * 遍历所有账号的所有游戏角色，读取便签数据填充 rawJson
   */
  static async buildFromDB(): Promise<WidgetDataStore> {
    Logger.info(TAG, '[WIDGET_DEBUG] buildFromDB: start');
    const store = new WidgetDataStore();
    store.updatedAt = Math.floor(Date.now() / 1000);

    try {
      // 1. 获取所有账号
      const accounts = await CoreInitializer.bbsRepository.getAllAccounts();
      Logger.info(TAG, `[WIDGET_DEBUG] buildFromDB: found ${accounts.length} accounts`);
      if (accounts.length === 0) {
        Logger.info(TAG, '[WIDGET_DEBUG] buildFromDB: no accounts found, returning empty store');
        return store;
      }

      // 2. 遍历每个账号
      for (let i = 0; i < accounts.length; i++) {
        const account = accounts[i];
        Logger.info(TAG, `[WIDGET_DEBUG] buildFromDB: processing account[${i}] uid=${account.uid} nickname=${account.nickname || 'null'}`);
        
        const widgetAccount = new WidgetAccount();
        widgetAccount.accountId = account.uid;
        widgetAccount.accountName = account.nickname || account.username;

        // 3. 获取该账号下的所有游戏角色
        const roles = await CoreInitializer.bbsRepository.getGameRoles(account.uid);
        Logger.info(TAG, `[WIDGET_DEBUG] buildFromDB:   account ${account.uid} has ${roles.length} roles`);
        if (roles.length === 0) {
          Logger.info(TAG, `[WIDGET_DEBUG] buildFromDB:   no roles for account ${account.uid}, skipping`);
          continue;
        }

        // 4. 按 gameId 分组
        const gameMap: Record<string, WidgetGame> = {};
        for (let j = 0; j < roles.length; j++) {
          const role = roles[j];
          const gameIdStr = WidgetDataStoreBuilder.gameIdToString(role.gameId);
          Logger.info(TAG, `[WIDGET_DEBUG] buildFromDB:     role[${j}] gameId=${gameIdStr} roleId=${role.roleId} nickname=${role.nickname || 'null'}`);

          // 创建或获取 WidgetGame
          let widgetGame = gameMap[gameIdStr];
          if (widgetGame === undefined) {
            widgetGame = new WidgetGame();
            widgetGame.gameId = gameIdStr;
            gameMap[gameIdStr] = widgetGame;
          }

          // 创建 WidgetRole 并填充 rawJson
          const widgetRole = await WidgetDataStoreBuilder.buildWidgetRole(account.uid, role);
          Logger.info(TAG, `[WIDGET_DEBUG] buildFromDB:       rawJson.length=${widgetRole.rawJson.length} hasData=${widgetRole.rawJson.length > 0}`);
          widgetGame.roles.push(widgetRole);
        }

        // 5. 将所有游戏添加到账号
        const gameIds = Object.keys(gameMap);
        Logger.info(TAG, `[WIDGET_DEBUG] buildFromDB:   account ${account.uid} has ${gameIds.length} games: ${gameIds.join(', ')}`);
        for (let k = 0; k < gameIds.length; k++) {
          widgetAccount.games.push(gameMap[gameIds[k]]);
        }

        store.accounts.push(widgetAccount);
      }

      Logger.info(TAG, `[WIDGET_DEBUG] buildFromDB: done, total=${store.accounts.length} accounts, ${WidgetDataStoreBuilder.countTotalRoles(store)} roles`);
    } catch (e) {
      Logger.error(TAG, `buildFromDB failed: ${JSON.stringify(e)}`);
    }

    return store;
  }

  /**
   * 构建单个 WidgetRole，从 DB 读取便签 rawJson
   */
  private static async buildWidgetRole(accountId: string, role: GameRoleRow): Promise<WidgetRole> {
    const widgetRole = new WidgetRole();
    widgetRole.roleId = role.roleId;
    widgetRole.nickname = role.nickname;
    widgetRole.server = role.server;

    // 根据 gameId 从对应的 Repository 读取便签数据
    try {
      let rawJson = '';

      if (role.gameId === GameId.GENSHIN) {
        Logger.info(TAG, `[WIDGET_DEBUG] buildWidgetRole: reading genshin dailyNote for ${accountId}/${role.roleId}`);
        const dailyNote = await CoreInitializer.genshinRepository.getDailyNote(accountId, role.roleId);
        rawJson = dailyNote?.rawJson ?? '';
        Logger.info(TAG, `[WIDGET_DEBUG] buildWidgetRole:   genshin dailyNote found=${dailyNote !== null} rawJson.length=${rawJson.length}`);
      } else if (role.gameId === GameId.STARRAIL) {
        Logger.info(TAG, `[WIDGET_DEBUG] buildWidgetRole: reading starrail dailyNote for ${accountId}/${role.roleId}`);
        const dailyNote = await CoreInitializer.starRailRepository.getDailyNote(accountId, role.roleId);
        rawJson = dailyNote?.rawJson ?? '';
        Logger.info(TAG, `[WIDGET_DEBUG] buildWidgetRole:   starrail dailyNote found=${dailyNote !== null} rawJson.length=${rawJson.length}`);
      } else if (role.gameId === GameId.ZZZ) {
        Logger.info(TAG, `[WIDGET_DEBUG] buildWidgetRole: reading zzz dailyNote for ${accountId}/${role.roleId}`);
        const dailyNote = await CoreInitializer.zzzRepository.getDailyNote(accountId, role.roleId);
        rawJson = dailyNote?.rawJson ?? '';
        Logger.info(TAG, `[WIDGET_DEBUG] buildWidgetRole:   zzz dailyNote found=${dailyNote !== null} rawJson.length=${rawJson.length}`);
      } else {
        Logger.warn(TAG, `[WIDGET_DEBUG] buildWidgetRole: unsupported gameId=${role.gameId}`);
      }

      widgetRole.rawJson = rawJson;
      Logger.info(TAG, `[WIDGET_DEBUG] buildWidgetRole: final rawJson.length=${widgetRole.rawJson.length}`);
    } catch (e) {
      Logger.error(TAG, `buildWidgetRole failed for ${accountId}/${role.gameId}/${role.roleId}: ${JSON.stringify(e)}`);
      widgetRole.rawJson = '';
    }

    return widgetRole;
  }

  /**
   * 刷新数据：重新构建并保存到 Preferences
   *
   * @returns 是否刷新成功
   */
  static async refreshAndSave(): Promise<boolean> {
    Logger.info(TAG, '[WIDGET_DEBUG] refreshAndSave: start');
    try {
      const store = await WidgetDataStoreBuilder.buildFromDB();
      Logger.info(TAG, `[WIDGET_DEBUG] refreshAndSave: buildFromDB done, accounts=${store.accounts.length}`);
      const success = await WidgetDataStoreManager.save(store);
      Logger.info(TAG, `[WIDGET_DEBUG] refreshAndSave: save done, success=${success}`);
      return success;
    } catch (e) {
      Logger.error(TAG, `[WIDGET_DEBUG] refreshAndSave failed: ${JSON.stringify(e)}`);
      return false;
    }
  }

  /**
   * 初始化：从 DB 构建数据并保存（首次启动时调用）
   */
  static async initAndSave(): Promise<boolean> {
    Logger.info(TAG, '[WIDGET_DEBUG] initAndSave: start');
    // 先尝试加载已有数据
    const existingStore = await WidgetDataStoreManager.load();
    Logger.info(TAG, `[WIDGET_DEBUG] initAndSave: existing accounts=${existingStore.accounts.length}`);
    if (existingStore.accounts.length > 0) {
      Logger.info(TAG, '[WIDGET_DEBUG] initAndSave: data already exists, skip build');
      return true;
    }

    // 无数据则构建新数据
    Logger.info(TAG, '[WIDGET_DEBUG] initAndSave: no data, calling refreshAndSave');
    const success = await WidgetDataStoreBuilder.refreshAndSave();
    Logger.info(TAG, `[WIDGET_DEBUG] initAndSave: refreshAndSave result=${success}`);
    return success;
  }

  /**
   * 更新单个角色的 rawJson
   *
   * 用于增量更新，避免全量重建
   */
  static async updateRoleRawJson(
    accountId: string,
    gameId: string,
    roleId: string,
  ): Promise<boolean> {
    Logger.info(TAG, `[WIDGET_DEBUG] updateRoleRawJson: start ${accountId}/${gameId}/${roleId}`);
    try {
      const store = await WidgetDataStoreManager.load();
      const role = store.getRole(accountId, gameId, roleId);
      if (role === null) {
        Logger.warn(TAG, `updateRoleRawJson: role not found ${accountId}/${gameId}/${roleId}`);
        return false;
      }

      // 从 DB 读取最新数据
      let rawJson = '';
      const gameIdEnum = WidgetDataStoreBuilder.stringToGameId(gameId);

      if (gameIdEnum === GameId.GENSHIN) {
        Logger.info(TAG, `[WIDGET_DEBUG] updateRoleRawJson: reading genshin dailyNote for ${accountId}/${roleId}`);
        const dailyNote = await CoreInitializer.genshinRepository.getDailyNote(accountId, roleId);
        rawJson = dailyNote?.rawJson ?? '';
        Logger.info(TAG, `[WIDGET_DEBUG] updateRoleRawJson:   genshin dailyNote found=${dailyNote !== null} rawJson.length=${rawJson.length}`);
      } else if (gameIdEnum === GameId.STARRAIL) {
        Logger.info(TAG, `[WIDGET_DEBUG] updateRoleRawJson: reading starrail dailyNote for ${accountId}/${roleId}`);
        const dailyNote = await CoreInitializer.starRailRepository.getDailyNote(accountId, roleId);
        rawJson = dailyNote?.rawJson ?? '';
        Logger.info(TAG, `[WIDGET_DEBUG] updateRoleRawJson:   starrail dailyNote found=${dailyNote !== null} rawJson.length=${rawJson.length}`);
      } else if (gameIdEnum === GameId.ZZZ) {
        Logger.info(TAG, `[WIDGET_DEBUG] updateRoleRawJson: reading zzz dailyNote for ${accountId}/${roleId}`);
        const dailyNote = await CoreInitializer.zzzRepository.getDailyNote(accountId, roleId);
        rawJson = dailyNote?.rawJson ?? '';
        Logger.info(TAG, `[WIDGET_DEBUG] updateRoleRawJson:   zzz dailyNote found=${dailyNote !== null} rawJson.length=${rawJson.length}`);
      } else {
        Logger.warn(TAG, `[WIDGET_DEBUG] updateRoleRawJson: unsupported gameId=${gameId}`);
      }

      role.rawJson = rawJson;
      store.updatedAt = Math.floor(Date.now() / 1000);
      await WidgetDataStoreManager.save(store);

      Logger.info(TAG, `[WIDGET_DEBUG] updateRoleRawJson: updated ${accountId}/${gameId}/${roleId}, rawJson.length=${rawJson.length}`);
      return true;
    } catch (e) {
      Logger.error(TAG, `updateRoleRawJson failed: ${JSON.stringify(e)}`);
      return false;
    }
  }

  // ── 工具方法 ────────────────────────────────────────────────

  private static gameIdToString(gameId: GameId): string {
    switch (gameId) {
      case GameId.GENSHIN:
        return 'genshin';
      case GameId.STARRAIL:
        return 'starrail';
      case GameId.ZZZ:
        return 'zzz';
      case GameId.HONKAI3:
        return 'honkai3';
      default:
        return 'unknown';
    }
  }

  private static stringToGameId(str: string): GameId {
    if (str === 'genshin') {
      return GameId.GENSHIN;
    } else if (str === 'starrail') {
      return GameId.STARRAIL;
    } else if (str === 'zzz') {
      return GameId.ZZZ;
    } else if (str === 'honkai3') {
      return GameId.HONKAI3;
    }
    return GameId.GENSHIN;
  }

  private static countTotalRoles(store: WidgetDataStore): number {
    let count = 0;
    for (let i = 0; i < store.accounts.length; i++) {
      for (let j = 0; j < store.accounts[i].games.length; j++) {
        count += store.accounts[i].games[j].roles.length;
      }
    }
    return count;
  }
}
