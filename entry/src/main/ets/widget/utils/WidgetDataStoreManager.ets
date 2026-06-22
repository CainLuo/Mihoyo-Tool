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
import { WidgetLogger } from './WidgetLogger';
import { WidgetDataStore } from '../models/WidgetDataStore';

const TAG = 'WIDGET';
const PREFS_NAME = 'widget_data_store';
const KEY_GLOBAL_DATA = 'global_data';

export class WidgetDataStoreManager {
  private static prefs: preferences.Preferences | null = null;

  /**
   * 初始化 Preferences（异步版本）
   */
  static async init(context: common.Context): Promise<void> {
    WidgetLogger.debug(TAG, `init: prefs=${WidgetDataStoreManager.prefs === null ? 'null' : 'not null'}`);
    try {
      WidgetDataStoreManager.prefs = await preferences.getPreferences(context, PREFS_NAME);
      WidgetLogger.debug(TAG, 'init success: prefs ready');
    } catch (e) {
      WidgetLogger.error(TAG, `init failed: ${JSON.stringify(e)}`);
    }
  }

  /**
   * 初始化 Preferences（同步版本，API 10+）
   */
  static initSync(context: common.Context): preferences.Preferences | null {
    WidgetLogger.debug(TAG, 'initSync: start');
    try {
      const prefs = preferences.getPreferencesSync(context, { name: PREFS_NAME });
      WidgetLogger.debug(TAG, 'initSync: success');
      return prefs;
    } catch (e) {
      WidgetLogger.error(TAG, `initSync failed: ${JSON.stringify(e)}`);
      return null;
    }
  }

  /**
   * 同步加载全局 Widget 数据（API 10+）
   */
  static loadSync(context?: common.Context): WidgetDataStore {
    WidgetLogger.debug(TAG, 'loadSync: start');
    
    try {
      let prefs = WidgetDataStoreManager.prefs;
      
      if (prefs === null && context !== undefined) {
        prefs = WidgetDataStoreManager.initSync(context);
      }
      
      if (prefs === null) {
        WidgetLogger.error(TAG, 'loadSync: prefs is null, returning empty store');
        return new WidgetDataStore();
      }
      
      const json = prefs.getSync(KEY_GLOBAL_DATA, '') as string;
      WidgetLogger.debug(TAG, `loadSync: payload json length=${json.length}`);
      
      if (json.length === 0) {
        WidgetLogger.warn(TAG, 'loadSync: payload is empty, returning empty store');
        return new WidgetDataStore();
      }
      
      const data = WidgetDataStore.fromJson(json);
      const accountCount = Object.keys(data.data).length;
      WidgetLogger.debug(TAG, `loadSync: parsed successfully, accounts=${accountCount} version=${data.version}`);
      
      return data;
    } catch (e) {
      WidgetLogger.error(TAG, `loadSync error: ${JSON.stringify(e)}`);
      return new WidgetDataStore();
    }
  }

  /**
   * 保存全局 Widget 数据
   */
  static async save(data: WidgetDataStore): Promise<boolean> {
    const accountCount = Object.keys(data.data).length;
    WidgetLogger.debug(TAG, `save: accounts=${accountCount} version=${data.version}`);
    if (WidgetDataStoreManager.prefs === null) {
      WidgetLogger.error(TAG, 'save failed: prefs is null');
      return false;
    }
    try {
      const json = data.toJson();
      WidgetLogger.debug(TAG, `save: payload json length=${json.length}`);
      
      await WidgetDataStoreManager.prefs.put(KEY_GLOBAL_DATA, json);
      await WidgetDataStoreManager.prefs.flush();
      WidgetLogger.debug(TAG, 'save: SUCCESS - payload saved to Preferences');
      return true;
    } catch (e) {
      WidgetLogger.error(TAG, `save error: ${JSON.stringify(e)}`);
      return false;
    }
  }

  /**
   * 加载全局 Widget 数据
   */
  static async load(): Promise<WidgetDataStore> {
    if (WidgetDataStoreManager.prefs === null) {
      WidgetLogger.error(TAG, 'load failed: prefs is null, returning empty store');
      return new WidgetDataStore();
    }
    try {
      const json = await WidgetDataStoreManager.prefs.get(KEY_GLOBAL_DATA, '') as string;
      WidgetLogger.debug(TAG, `load: payload json length=${json.length}`);
      
      if (json.length === 0) {
        WidgetLogger.warn(TAG, 'load: payload is empty, returning empty store');
        return new WidgetDataStore();
      }
      
      const data = WidgetDataStore.fromJson(json);
      const accountCount = Object.keys(data.data).length;
      WidgetLogger.debug(TAG, `load: parsed successfully, accounts=${accountCount} version=${data.version}`);
      
      return data;
    } catch (e) {
      WidgetLogger.error(TAG, `load error: ${JSON.stringify(e)}`);
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
