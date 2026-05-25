/**
 * WidgetDataStoreBuilder.ets — Widget 数据构建器（v2）
 *
 * 从 DB 读取所有账号的游戏角色，填充 rawJson 到 WidgetDataStore。
 * 
 * v2 数据结构（扁平化）：
 * {
 *   "version": 2,
 *   "updatedAt": 1779012632,
 *   "data": {
 *     "{accountId}": { "accountName": "...", "slots": { "{roleId}": {...} } }
 *   },
 *   "widgets": { "widget12": [...], "form_xxx": [...] }
 * }
 *
 * 调用时机：
 * 1. App 启动时调用 initAndSave() 初始化数据
 * 2. 数据同步完成后调用 refreshAndSave() 更新数据
 */

import { Logger } from 'core';
import { CoreInitializer } from 'core';
import { GameRoleRow } from 'core';
import { GameId } from 'core';
import { WidgetDataStore, WidgetSlotData, WidgetAccountDataV2 } from '../models/WidgetDataStore';
import { WidgetDataStoreManager } from './WidgetDataStoreManager';

const TAG = 'WIDGET';

export class WidgetDataStoreBuilder {
  /**
   * 从 DB 构建完整的 WidgetDataStore（v2 扁平结构）
   *
   * 遍历所有账号的所有游戏角色，读取便签数据填充 rawJson
   */
  static async buildFromDB(): Promise<WidgetDataStore> {
    Logger.info(TAG, '[WIDGET_DEBUG] buildFromDB: start (v2)');
    const store = new WidgetDataStore();
    store.version = 2;
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

        // 创建账号数据
        const accountData = new WidgetAccountDataV2();
        accountData.accountName = account.nickname || account.username;
        accountData.avatarUrl = account.avatarUrl || '';

        // 3. 获取该账号下的所有游戏角色
        const roles = await CoreInitializer.bbsRepository.getGameRoles(account.uid);
        Logger.info(TAG, `[WIDGET_DEBUG] buildFromDB:   account ${account.uid} has ${roles.length} roles`);
        if (roles.length === 0) {
          Logger.info(TAG, `[WIDGET_DEBUG] buildFromDB:   no roles for account ${account.uid}, skipping`);
          continue;
        }

        // 4. 遍历每个角色，填充 slots
        for (let j = 0; j < roles.length; j++) {
          const role = roles[j];
          const gameIdStr = WidgetDataStoreBuilder.gameIdToString(role.gameId);
          Logger.info(TAG, `[WIDGET_DEBUG] buildFromDB:     role[${j}] gameId=${gameIdStr} roleId=${role.roleId} nickname=${role.nickname || 'null'}`);

          // 构建 slot 数据
          const slotData = await WidgetDataStoreBuilder.buildSlotData(account.uid, role);
          Logger.info(TAG, `[WIDGET_DEBUG] buildFromDB:       rawJson.length=${slotData.rawJson.length} hasData=${slotData.rawJson.length > 0}`);

          // 添加到 slots（扁平结构，key 是 roleId）
          accountData.slots[role.roleId] = slotData;
        }

        // 5. 将账号添加到 store.data
        store.data[account.uid] = accountData;
      }

      // 6. 保留现有的 widgets 配置（如果有）
      const existingStore = await WidgetDataStoreManager.load();
      if (existingStore.widgets !== undefined) {
        store.widgets = existingStore.widgets;
      }

      const totalRoles = WidgetDataStoreBuilder.countTotalRoles(store);
      Logger.info(TAG, `[WIDGET_DEBUG] buildFromDB: done, total=${Object.keys(store.data).length} accounts, ${totalRoles} roles`);
    } catch (e) {
      Logger.error(TAG, `buildFromDB failed: ${JSON.stringify(e)}`);
    }

    return store;
  }

  /**
   * 构建单个 slot 数据，从 DB 读取便签 rawJson
   */
  private static async buildSlotData(accountId: string, role: GameRoleRow): Promise<WidgetSlotData> {
    const slotData = new WidgetSlotData();
    slotData.gameId = WidgetDataStoreBuilder.gameIdToString(role.gameId);
    slotData.nickname = role.nickname;
    slotData.server = role.server;
    slotData.serverName = role.regionName;
    slotData.level = role.level;

    // 根据 gameId 从对应的 Repository 读取便签数据
    try {
      let rawJson = '';

      if (role.gameId === GameId.GENSHIN) {
        Logger.info(TAG, `[WIDGET_DEBUG] buildSlotData: reading genshin dailyNote for ${accountId}/${role.roleId}`);
        const dailyNote = await CoreInitializer.genshinRepository.getDailyNote(accountId, role.roleId);
        rawJson = dailyNote?.rawJson ?? '';
        Logger.info(TAG, `[WIDGET_DEBUG] buildSlotData:   genshin dailyNote found=${dailyNote !== null} rawJson.length=${rawJson.length}`);
      } else if (role.gameId === GameId.STARRAIL) {
        Logger.info(TAG, `[WIDGET_DEBUG] buildSlotData: reading starrail dailyNote for ${accountId}/${role.roleId}`);
        const dailyNote = await CoreInitializer.starRailRepository.getDailyNote(accountId, role.roleId);
        rawJson = dailyNote?.rawJson ?? '';
        Logger.info(TAG, `[WIDGET_DEBUG] buildSlotData:   starrail dailyNote found=${dailyNote !== null} rawJson.length=${rawJson.length}`);
      } else if (role.gameId === GameId.ZZZ) {
        Logger.info(TAG, `[WIDGET_DEBUG] buildSlotData: reading zzz dailyNote for ${accountId}/${role.roleId}`);
        const dailyNote = await CoreInitializer.zzzRepository.getDailyNote(accountId, role.roleId);
        rawJson = dailyNote?.rawJson ?? '';
        Logger.info(TAG, `[WIDGET_DEBUG] buildSlotData:   zzz dailyNote found=${dailyNote !== null} rawJson.length=${rawJson.length}`);
      } else {
        Logger.warn(TAG, `[WIDGET_DEBUG] buildSlotData: unsupported gameId=${role.gameId}`);
      }

      slotData.rawJson = rawJson;
      Logger.info(TAG, `[WIDGET_DEBUG] buildSlotData: final rawJson.length=${slotData.rawJson.length}`);
      // 打印 rawJson 前 500 字符，检查是否包含派遣和洞天宝钱字段
      if (slotData.rawJson.length > 0) {
        Logger.info(TAG, `[WIDGET_DEBUG] buildSlotData: rawJson preview=${slotData.rawJson.substring(0, Math.min(500, slotData.rawJson.length))}`);
        const hasExpedition = slotData.rawJson.includes('max_expedition_num');
        const hasHomeCoin = slotData.rawJson.includes('current_home_coin');
        Logger.info(TAG, `[WIDGET_DEBUG] buildSlotData: hasExpedition=${hasExpedition} hasHomeCoin=${hasHomeCoin}`);
      }
    } catch (e) {
      Logger.error(TAG, `buildSlotData failed for ${accountId}/${role.gameId}/${role.roleId}: ${JSON.stringify(e)}`);
      slotData.rawJson = '';
    }

    return slotData;
  }

  /**
   * 刷新数据：重新构建并保存到 Preferences
   */
  static async refreshAndSave(): Promise<boolean> {
    Logger.info(TAG, '[WIDGET_DEBUG] refreshAndSave: start');
    try {
      const store = await WidgetDataStoreBuilder.buildFromDB();
      const accountCount = Object.keys(store.data).length;
      Logger.info(TAG, `[WIDGET_DEBUG] refreshAndSave: buildFromDB done, accounts=${accountCount}`);
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
    Logger.info(TAG, '[WIDGET_DEBUG] initAndSave: start - will always refresh from DB');
    const success = await WidgetDataStoreBuilder.refreshAndSave();
    Logger.info(TAG, `[WIDGET_DEBUG] initAndSave: refreshAndSave result=${success}`);
    return success;
  }

  /**
   * 更新单个角色的 rawJson
   */
  static async updateRoleRawJson(
    accountId: string,
    gameId: string,
    roleId: string,
  ): Promise<boolean> {
    Logger.info(TAG, `[WIDGET_DEBUG] updateRoleRawJson: start ${accountId}/${gameId}/${roleId}`);
    try {
      const store = await WidgetDataStoreManager.load();
      const slot = store.getRole(accountId, roleId);
      if (slot === null) {
        Logger.warn(TAG, `updateRoleRawJson: role not found ${accountId}/${roleId}`);
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

      slot.rawJson = rawJson;
      store.updatedAt = Math.floor(Date.now() / 1000);
      await WidgetDataStoreManager.save(store);

      Logger.info(TAG, `[WIDGET_DEBUG] updateRoleRawJson: updated ${accountId}/${roleId}, rawJson.length=${rawJson.length}`);
      return true;
    } catch (e) {
      Logger.error(TAG, `updateRoleRawJson failed: ${JSON.stringify(e)}`);
      return false;
    }
  }

  /**
   * 保存 widgets 配置
   */
  static async saveWidgetsConfig(widgets: Record<string, string[]>): Promise<boolean> {
    Logger.info(TAG, `[WIDGET_DEBUG] saveWidgetsConfig: start, keys=${Object.keys(widgets).join(',')}`);
    try {
      const store = await WidgetDataStoreManager.load();
      store.widgets = widgets;
      store.updatedAt = Math.floor(Date.now() / 1000);
      await WidgetDataStoreManager.save(store);
      Logger.info(TAG, '[WIDGET_DEBUG] saveWidgetsConfig: done');
      return true;
    } catch (e) {
      Logger.error(TAG, `saveWidgetsConfig failed: ${JSON.stringify(e)}`);
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
    const accountIds = Object.keys(store.data);
    for (let i = 0; i < accountIds.length; i++) {
      const account = store.data[accountIds[i]];
      count += Object.keys(account.slots).length;
    }
    return count;
  }
}
