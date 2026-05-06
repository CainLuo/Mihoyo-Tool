/**
 * WidgetConfigStore.ets — Widget 配置存储管理器
 *
 * 负责将每个 Widget 的配置持久化到 Preferences
 * 存储位置：Preferences 文件名 widget_configs，Key form_{formId}
 */

import { preferences } from '@kit.ArkData';
import { common } from '@kit.AbilityKit';
import { Logger } from 'core';
import { WidgetConfig } from '../models/WidgetConfig';

const TAG = 'WidgetConfigStore';
const PREFS_NAME = 'widget_configs';

/**
 * 获取配置存储的 Key
 */
function getConfigKey(formId: string): string {
  return `form_${formId}`;
}

export class WidgetConfigStore {
  private static prefs: preferences.Preferences | null = null;

  /**
   * 初始化 Preferences
   * 可在 UIAbility 或 FormExtensionAbility 中调用
   */
  static async init(context: common.Context): Promise<void> {
    try {
      WidgetConfigStore.prefs = await preferences.getPreferences(context, PREFS_NAME);
      Logger.info(TAG, 'init success');
    } catch (e) {
      Logger.error(TAG, `init failed: ${JSON.stringify(e)}`);
    }
  }

  /**
   * 保存 Widget 配置
   */
  static async saveConfig(config: WidgetConfig): Promise<boolean> {
    if (WidgetConfigStore.prefs === null) {
      Logger.error(TAG, 'saveConfig failed: prefs not initialized');
      return false;
    }
    try {
      const key = getConfigKey(config.formId);
      const json = config.toJson();
      await WidgetConfigStore.prefs.put(key, json);
      await WidgetConfigStore.prefs.flush();
      Logger.info(TAG, `saveConfig success: formId=${config.formId} slots=${config.slots.length}`);
      return true;
    } catch (e) {
      Logger.error(TAG, `saveConfig failed: ${JSON.stringify(e)}`);
      return false;
    }
  }

  /**
   * 加载 Widget 配置
   * @returns WidgetConfig 实例，失败时返回空配置
   */
  static async loadConfig(formId: string): Promise<WidgetConfig> {
    if (WidgetConfigStore.prefs === null) {
      Logger.error(TAG, 'loadConfig failed: prefs not initialized');
      return new WidgetConfig();
    }
    try {
      const key = getConfigKey(formId);
      const json = await WidgetConfigStore.prefs.get(key, '') as string;
      if (json.length === 0) {
        Logger.info(TAG, `loadConfig: no config found for formId=${formId}`);
        return new WidgetConfig();
      }
      const config = WidgetConfig.fromJson(json);
      config.formId = formId;
      Logger.info(TAG, `loadConfig success: formId=${formId} slots=${config.slots.length}`);
      return config;
    } catch (e) {
      Logger.error(TAG, `loadConfig failed: ${JSON.stringify(e)}`);
      return new WidgetConfig();
    }
  }

  /**
   * 删除 Widget 配置
   */
  static async deleteConfig(formId: string): Promise<boolean> {
    if (WidgetConfigStore.prefs === null) {
      Logger.error(TAG, 'deleteConfig failed: prefs not initialized');
      return false;
    }
    try {
      const key = getConfigKey(formId);
      await WidgetConfigStore.prefs.delete(key);
      await WidgetConfigStore.prefs.flush();
      Logger.info(TAG, `deleteConfig success: formId=${formId}`);
      return true;
    } catch (e) {
      Logger.error(TAG, `deleteConfig failed: ${JSON.stringify(e)}`);
      return false;
    }
  }

  /**
   * 获取所有 Widget 配置
   */
  static async getAllConfigs(): Promise<WidgetConfig[]> {
    if (WidgetConfigStore.prefs === null) {
      Logger.error(TAG, 'getAllConfigs failed: prefs not initialized');
      return [];
    }
    try {
      const all = await WidgetConfigStore.prefs.getAll();
      const configs: WidgetConfig[] = [];
      const keys = Object.keys(all);
      for (let i = 0; i < keys.length; i++) {
        const key = keys[i];
        if (key.startsWith('form_')) {
          const json = await WidgetConfigStore.prefs.get(key, '') as string;
          if (json.length > 0) {
            configs.push(WidgetConfig.fromJson(json));
          }
        }
      }
      Logger.info(TAG, `getAllConfigs success: ${configs.length} configs`);
      return configs;
    } catch (e) {
      Logger.error(TAG, `getAllConfigs failed: ${JSON.stringify(e)}`);
      return [];
    }
  }
}
