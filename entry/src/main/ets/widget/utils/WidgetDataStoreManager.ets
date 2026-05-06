/**
 * WidgetDataStoreManager.ets — Widget 全局数据存储管理器
 *
 * 负责将 WidgetDataStore 持久化到 Preferences
 * 存储位置：Preferences 文件名 widget_data_store，Key global_data
 */

import { preferences } from '@kit.ArkData';
import { common } from '@kit.AbilityKit';
import { Logger } from 'core';
import { WidgetDataStore } from '../models/WidgetDataStore';

const TAG = 'WidgetDataStoreManager';
const PREFS_NAME = 'widget_data_store';
const KEY_GLOBAL_DATA = 'global_data';

export class WidgetDataStoreManager {
  private static prefs: preferences.Preferences | null = null;

  /**
   * 初始化 Preferences
   * 可在 UIAbility 或 FormExtensionAbility 中调用
   */
  static async init(context: common.Context): Promise<void> {
    try {
      WidgetDataStoreManager.prefs = await preferences.getPreferences(context, PREFS_NAME);
      Logger.info(TAG, 'init success');
    } catch (e) {
      Logger.error(TAG, `init failed: ${JSON.stringify(e)}`);
    }
  }

  /**
   * 保存全局 Widget 数据
   */
  static async save(data: WidgetDataStore): Promise<boolean> {
    if (WidgetDataStoreManager.prefs === null) {
      Logger.error(TAG, 'save failed: prefs not initialized');
      return false;
    }
    try {
      const json = data.toJson();
      await WidgetDataStoreManager.prefs.put(KEY_GLOBAL_DATA, json);
      await WidgetDataStoreManager.prefs.flush();
      Logger.info(TAG, `save success: ${data.accounts.length} accounts, ${json.length} bytes`);
      return true;
    } catch (e) {
      Logger.error(TAG, `save failed: ${JSON.stringify(e)}`);
      return false;
    }
  }

  /**
   * 加载全局 Widget 数据
   * @returns WidgetDataStore 实例，失败时返回空对象
   */
  static async load(): Promise<WidgetDataStore> {
    if (WidgetDataStoreManager.prefs === null) {
      Logger.error(TAG, 'load failed: prefs not initialized');
      return new WidgetDataStore();
    }
    try {
      const json = await WidgetDataStoreManager.prefs.get(KEY_GLOBAL_DATA, '') as string;
      if (json.length === 0) {
        Logger.info(TAG, 'load: no data found, return empty');
        return new WidgetDataStore();
      }
      const data = WidgetDataStore.fromJson(json);
      Logger.info(TAG, `load success: ${data.accounts.length} accounts`);
      return data;
    } catch (e) {
      Logger.error(TAG, `load failed: ${JSON.stringify(e)}`);
      return new WidgetDataStore();
    }
  }

  /**
   * 清除全局 Widget 数据
   */
  static async clear(): Promise<boolean> {
    if (WidgetDataStoreManager.prefs === null) {
      Logger.error(TAG, 'clear failed: prefs not initialized');
      return false;
    }
    try {
      await WidgetDataStoreManager.prefs.delete(KEY_GLOBAL_DATA);
      await WidgetDataStoreManager.prefs.flush();
      Logger.info(TAG, 'clear success');
      return true;
    } catch (e) {
      Logger.error(TAG, `clear failed: ${JSON.stringify(e)}`);
      return false;
    }
  }
}
