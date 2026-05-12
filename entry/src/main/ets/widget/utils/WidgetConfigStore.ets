/**
 * WidgetConfigStore.ets — Widget 配置存储管理器
 *
 * 负责将每个 Widget 的配置持久化到 Preferences
 * 存储位置：Preferences 文件名 widget_configs，Key form_{formId}
 */

import { preferences } from '@kit.ArkData';
import { common } from '@kit.AbilityKit';
import { WidgetConfig } from '../models/WidgetConfig';

const TAG = 'WIDGET';
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
    } catch (e) {
      // 静默处理错误
    }
  }

  /**
   * 保存 Widget 配置
   */
  static async saveConfig(config: WidgetConfig): Promise<boolean> {
    if (WidgetConfigStore.prefs === null) {
      return false;
    }
    try {
      const key = getConfigKey(config.formId);
      const json = config.toJson();
      await WidgetConfigStore.prefs.put(key, json);
      await WidgetConfigStore.prefs.flush();
      return true;
    } catch (e) {
      // 静默处理错误
      return false;
    }
  }

  /**
   * 加载 Widget 配置
   * @returns WidgetConfig 实例，失败时返回空配置
   */
  static async loadConfig(formId: string): Promise<WidgetConfig> {
    if (WidgetConfigStore.prefs === null) {
      return new WidgetConfig();
    }
    try {
      const key = getConfigKey(formId);
      const json = await WidgetConfigStore.prefs.get(key, '') as string;
      if (json.length === 0) {
        return new WidgetConfig();
      }
      const config = WidgetConfig.fromJson(json);
      config.formId = formId;
      return config;
    } catch (e) {
      // 静默处理错误
      return new WidgetConfig();
    }
  }

  /**
   * 删除 Widget 配置
   */
  static async deleteConfig(formId: string): Promise<boolean> {
    if (WidgetConfigStore.prefs === null) {
      return false;
    }
    try {
      const key = getConfigKey(formId);
      await WidgetConfigStore.prefs.delete(key);
      await WidgetConfigStore.prefs.flush();
      return true;
    } catch (e) {
      // 静默处理错误
      return false;
    }
  }

  /**
   * 获取所有 Widget 配置
   */
  static async getAllConfigs(): Promise<WidgetConfig[]> {
    if (WidgetConfigStore.prefs === null) {
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
      return configs;
    } catch (e) {
      // 静默处理错误
      return [];
    }
  }
}
