/**
 * WidgetDataStoreManager.ets — Widget 全局数据存储管理器（v2）
 *
 * 负责将 WidgetDataStore 持久化到 Preferences
 * 存储位置：Preferences 文件名 widget_data_store，Key global_data
 *
 * v2 数据结构：扁平化的 data + widgets 配置
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
   */
  static loadSync(context?: common.Context): WidgetDataStore {
    hilog.info(DOMAIN, TAG, `[WIDGET_DEBUG] loadSync: start`);
    
    try {
      let prefs = WidgetDataStoreManager.prefs;
      
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
      const accountCount = Object.keys(data.data).length;
      hilog.info(DOMAIN, TAG, `[WIDGET_DEBUG] loadSync: parsed successfully, accounts=${accountCount} version=${data.version}`);
      
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
    const accountCount = Object.keys(data.data).length;
    hilog.info(DOMAIN, TAG, `[WIDGET_DEBUG] save: accounts=${accountCount} version=${data.version}`);
    if (WidgetDataStoreManager.prefs === null) {
      hilog.error(DOMAIN, TAG, `[WIDGET_DEBUG] save failed: prefs is null`);
      return false;
    }
    try {
      const json = data.toJson();
      hilog.info(DOMAIN, TAG, `[WIDGET_DEBUG] save: payload json length=${json.length}`);
      
      // 打印 payload 预览
      hilog.info(DOMAIN, TAG, `[WIDGET_DEBUG] save: payload preview (first 500 chars)=${json.substring(0, 500)}`);
      
      // 打印每个账号的角色信息
      const accountIds = Object.keys(data.data);
      for (let i = 0; i < accountIds.length; i++) {
        const accountId = accountIds[i];
        const account = data.data[accountId];
        const roleIds = Object.keys(account.slots);
        hilog.info(DOMAIN, TAG, `[WIDGET_DEBUG] save: account[${i}] id=${accountId} name=${account.accountName} roles=${roleIds.length}`);
        for (let j = 0; j < roleIds.length; j++) {
          const roleId = roleIds[j];
          const slot = account.slots[roleId];
          hilog.info(DOMAIN, TAG, `[WIDGET_DEBUG] save:   role[${j}] roleId=${roleId} gameId=${slot.gameId} rawJsonLen=${slot.rawJson.length}`);
        }
      }
      
      // 打印 widgets 配置
      const widgetKeys = Object.keys(data.widgets);
      hilog.info(DOMAIN, TAG, `[WIDGET_DEBUG] save: widgets config keys=${widgetKeys.length}`);
      for (let i = 0; i < widgetKeys.length; i++) {
        const key = widgetKeys[i];
        const slots = data.widgets[key];
        hilog.info(DOMAIN, TAG, `[WIDGET_DEBUG] save:   widgets[${key}]=${slots.join(',')}`);
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
      
      hilog.info(DOMAIN, TAG, `[WIDGET_DEBUG] load: payload preview (first 500 chars)=${json.substring(0, 500)}`);
      
      const data = WidgetDataStore.fromJson(json);
      const accountCount = Object.keys(data.data).length;
      hilog.info(DOMAIN, TAG, `[WIDGET_DEBUG] load: parsed successfully, accounts=${accountCount} version=${data.version}`);
      
      // 打印每个账号的角色信息
      const accountIds = Object.keys(data.data);
      for (let i = 0; i < accountIds.length; i++) {
        const accountId = accountIds[i];
        const account = data.data[accountId];
        const roleIds = Object.keys(account.slots);
        hilog.info(DOMAIN, TAG, `[WIDGET_DEBUG] load: account[${i}] id=${accountId} roles=${roleIds.length}`);
        for (let j = 0; j < roleIds.length; j++) {
          const roleId = roleIds[j];
          const slot = account.slots[roleId];
          hilog.info(DOMAIN, TAG, `[WIDGET_DEBUG] load:   role[${j}] roleId=${roleId} gameId=${slot.gameId} rawJsonLen=${slot.rawJson.length}`);
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
      return false;
    }
  }
}
