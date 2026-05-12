/**
 * WidgetDataStoreManager.ets — Widget 全局数据存储管理器
 *
 * 负责将 WidgetDataStore 持久化到 Preferences
 * 存储位置：Preferences 文件名 widget_data_store，Key global_data
 *
 * 重要约束：
 * - FormExtension 进程不能导入 core 模块（HSP）
 * - 此文件会被 EntryFormAbility 导入，因此不能导入 core
 * - 日志只能使用 hilog 或静默处理
 *
 * 同步 API 说明（API 10+）：
 * - getPreferencesSync() — 同步获取 Preferences 实例
 * - getSync() — 同步读取数据
 * - 用于 FormExtensionAbility.onAddForm() 中同步返回数据
 */

import { preferences } from '@kit.ArkData';
import { common } from '@kit.AbilityKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
import { WidgetDataStore } from '../models/WidgetDataStore';

const TAG = 'WIDGET';
const DOMAIN = 0xFF00;
const PREFS_NAME = 'widget_data_store';
const KEY_GLOBAL_DATA = 'global_data';

export class WidgetDataStoreManager {
  private static prefs: preferences.Preferences | null = null;

  /**
   * 初始化 Preferences（异步版本）
   * 可在 UIAbility 或 FormExtensionAbility 中调用
   */
  static async init(context: common.Context): Promise<void> {
    hilog.info(DOMAIN, TAG, `[WIDGET_DEBUG] init: prefs=${WidgetDataStoreManager.prefs === null ? 'null' : 'not null'}`);
    try {
      WidgetDataStoreManager.prefs = await preferences.getPreferences(context, PREFS_NAME);
      hilog.info(DOMAIN, TAG, `[WIDGET_DEBUG] init success: prefs ready`);
    } catch (e) {
      hilog.error(DOMAIN, TAG, `[WIDGET_DEBUG] init failed: ${JSON.stringify(e)}`);
    }
  }

  /**
   * 初始化 Preferences（同步版本，API 10+）
   * 用于 FormExtensionAbility.onAddForm() 中同步初始化
   *
   * @param context 应用上下文
   * @returns Preferences 实例，失败返回 null
   */
  static initSync(context: common.Context): preferences.Preferences | null {
    hilog.info(DOMAIN, TAG, `[WIDGET_DEBUG] initSync: start`);
    try {
      const prefs = preferences.getPreferencesSync(context, { name: PREFS_NAME });
      hilog.info(DOMAIN, TAG, `[WIDGET_DEBUG] initSync: success`);
      return prefs;
    } catch (e) {
      hilog.error(DOMAIN, TAG, `[WIDGET_DEBUG] initSync failed: ${JSON.stringify(e)}`);
      return null;
    }
  }

  /**
   * 同步加载全局 Widget 数据（API 10+）
   * 用于 FormExtensionAbility.onAddForm() 中同步读取数据
   *
   * @param context 应用上下文（如果 prefs 未初始化）
   * @returns WidgetDataStore 实例，失败时返回空对象
   */
  static loadSync(context?: common.Context): WidgetDataStore {
    hilog.info(DOMAIN, TAG, `[WIDGET_DEBUG] loadSync: start`);
    
    try {
      // 优先使用已缓存的 prefs
      let prefs = WidgetDataStoreManager.prefs;
      
      // 如果没有缓存且提供了 context，则同步初始化
      if (prefs === null && context !== undefined) {
        prefs = WidgetDataStoreManager.initSync(context);
      }
      
      if (prefs === null) {
        hilog.error(DOMAIN, TAG, `[WIDGET_DEBUG] loadSync: prefs is null, returning empty store`);
        return new WidgetDataStore();
      }
      
      const json = prefs.getSync(KEY_GLOBAL_DATA, '') as string;
      hilog.info(DOMAIN, TAG, `[WIDGET_DEBUG] loadSync: payload json length=${json.length}`);
      
      if (json.length === 0) {
        hilog.warn(DOMAIN, TAG, `[WIDGET_DEBUG] loadSync: payload is empty, returning empty store`);
        return new WidgetDataStore();
      }
      
      const data = WidgetDataStore.fromJson(json);
      hilog.info(DOMAIN, TAG, `[WIDGET_DEBUG] loadSync: parsed successfully, accounts=${data.accounts.length}`);
      
      return data;
    } catch (e) {
      hilog.error(DOMAIN, TAG, `[WIDGET_DEBUG] loadSync error: ${JSON.stringify(e)}`);
      return new WidgetDataStore();
    }
  }

  /**
   * 保存全局 Widget 数据
   */
  static async save(data: WidgetDataStore): Promise<boolean> {
    hilog.info(DOMAIN, TAG, `[WIDGET_DEBUG] === SAVE TO PREFERENCES START ===`);
    hilog.info(DOMAIN, TAG, `[WIDGET_DEBUG] save: accounts=${data.accounts.length}`);
    if (WidgetDataStoreManager.prefs === null) {
      hilog.error(DOMAIN, TAG, `[WIDGET_DEBUG] save failed: prefs is null`);
      return false;
    }
    try {
      const json = data.toJson();
      hilog.info(DOMAIN, TAG, `[WIDGET_DEBUG] save: payload json length=${json.length}`);
      
      // 打印完整的payload结构（用于调试）
      hilog.info(DOMAIN, TAG, `[WIDGET_DEBUG] save: payload preview (first 500 chars)=${json.substring(0, 500)}`);
      
      // 打印每个账号的游戏和角色信息
      for (let i = 0; i < data.accounts.length; i++) {
        const acc = data.accounts[i];
        hilog.info(DOMAIN, TAG, `[WIDGET_DEBUG] save: account[${i}] id=${acc.accountId} name=${acc.accountName} games=${acc.games.length}`);
        for (let j = 0; j < acc.games.length; j++) {
          const game = acc.games[j];
          hilog.info(DOMAIN, TAG, `[WIDGET_DEBUG] save:   game[${j}] id=${game.gameId} roles=${game.roles.length}`);
          for (let k = 0; k < game.roles.length; k++) {
            const role = game.roles[k];
            hilog.info(DOMAIN, TAG, `[WIDGET_DEBUG] save:     role[${k}] roleId=${role.roleId} nickname=${role.nickname} server=${role.server} rawJsonLen=${role.rawJson.length}`);
          }
        }
      }
      
      await WidgetDataStoreManager.prefs.put(KEY_GLOBAL_DATA, json);
      await WidgetDataStoreManager.prefs.flush();
      hilog.info(DOMAIN, TAG, `[WIDGET_DEBUG] save: SUCCESS - payload saved to Preferences`);
      hilog.info(DOMAIN, TAG, `[WIDGET_DEBUG] === SAVE TO PREFERENCES END ===`);
      return true;
    } catch (e) {
      hilog.error(DOMAIN, TAG, `[WIDGET_DEBUG] save error: ${JSON.stringify(e)}`);
      return false;
    }
  }

  /**
   * 加载全局 Widget 数据
   * @returns WidgetDataStore 实例，失败时返回空对象
   */
  static async load(): Promise<WidgetDataStore> {
    hilog.info(DOMAIN, TAG, `[WIDGET_DEBUG] === LOAD FROM PREFERENCES START ===`);
    if (WidgetDataStoreManager.prefs === null) {
      hilog.error(DOMAIN, TAG, `[WIDGET_DEBUG] load failed: prefs is null, returning empty store`);
      return new WidgetDataStore();
    }
    try {
      const json = await WidgetDataStoreManager.prefs.get(KEY_GLOBAL_DATA, '') as string;
      hilog.info(DOMAIN, TAG, `[WIDGET_DEBUG] load: payload json length=${json.length}`);
      
      if (json.length === 0) {
        hilog.warn(DOMAIN, TAG, `[WIDGET_DEBUG] load: payload is empty, returning empty store`);
        return new WidgetDataStore();
      }
      
      // 打印payload预览
      hilog.info(DOMAIN, TAG, `[WIDGET_DEBUG] load: payload preview (first 500 chars)=${json.substring(0, 500)}`);
      
      const data = WidgetDataStore.fromJson(json);
      hilog.info(DOMAIN, TAG, `[WIDGET_DEBUG] load: parsed successfully, accounts=${data.accounts.length}`);
      
      // 打印每个账号的游戏和角色信息
      for (let i = 0; i < data.accounts.length; i++) {
        const acc = data.accounts[i];
        hilog.info(DOMAIN, TAG, `[WIDGET_DEBUG] load: account[${i}] id=${acc.accountId} name=${acc.accountName} games=${acc.games.length}`);
        for (let j = 0; j < acc.games.length; j++) {
          const game = acc.games[j];
          hilog.info(DOMAIN, TAG, `[WIDGET_DEBUG] load:   game[${j}] id=${game.gameId} roles=${game.roles.length}`);
          for (let k = 0; k < game.roles.length; k++) {
            const role = game.roles[k];
            hilog.info(DOMAIN, TAG, `[WIDGET_DEBUG] load:     role[${k}] roleId=${role.roleId} nickname=${role.nickname} server=${role.server} rawJsonLen=${role.rawJson.length}`);
          }
        }
      }
      
      hilog.info(DOMAIN, TAG, `[WIDGET_DEBUG] === LOAD FROM PREFERENCES END ===`);
      return data;
    } catch (e) {
      hilog.error(DOMAIN, TAG, `[WIDGET_DEBUG] load error: ${JSON.stringify(e)}`);
      return new WidgetDataStore();
    }
  }

  /**
   * 清除全局 Widget 数据
   */
  static async clear(): Promise<boolean> {
    if (WidgetDataStoreManager.prefs === null) {
      return false;
    }
    try {
      await WidgetDataStoreManager.prefs.delete(KEY_GLOBAL_DATA);
      await WidgetDataStoreManager.prefs.flush();
      return true;
    } catch (e) {
      // 静默处理错误
      return false;
    }
  }
}
