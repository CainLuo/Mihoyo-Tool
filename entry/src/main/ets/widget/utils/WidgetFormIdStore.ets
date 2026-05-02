/**
 * WidgetFormIdStore — formId 持久化存储工具
 *
 * 每个 formId 对应一条 Preferences 记录：
 *   key:   `form_${formId}`
 *   value: JSON.stringify(WidgetConfig)
 *
 * 注意：此文件不能 import 任何含 backgroundTaskManager 的模块。
 */

import { preferences } from '@kit.ArkData';
import { common } from '@kit.AbilityKit';
import { Logger } from 'core';

const TAG = 'WidgetFormIdStore';
const STORE_NAME = 'widget_form_ids';
const KEY_PREFIX = 'form_';

/** 单张卡片的配置 */
export interface WidgetConfig {
  /** 米游社账号 UID */
  accountId: string;
  /** 选中的游戏列表，如 ['genshin', 'starrail'] */
  selectedGames: string[];
  /** 卡片模板名，如 'widget_1x2_genshin' */
  formName: string;
}

export class WidgetFormIdStore {
  private static store: preferences.Preferences | null = null;

  /**
   * 初始化 Preferences 存储
   * 可在 EntryFormAbility（FormExtensionContext）和 UIAbility（UIAbilityContext）中调用
   * 两个进程共享相同的文件沙箱，Preferences 文件路径相同，数据互通
   *
   * @param context  当前进程的 Context
   * @param forceReload  是否强制重新从文件加载（主进程推送前调用，确保读到最新 formId）
   */
  static async init(context: common.Context, forceReload: boolean = false): Promise<void> {
    if (WidgetFormIdStore.store !== null && !forceReload) {
      return;
    }
    try {
      WidgetFormIdStore.store = await preferences.getPreferences(context, STORE_NAME);
    } catch (e) {
      Logger.error(TAG, `init failed: ${JSON.stringify(e)}`);
    }
  }

  /** 保存 formId 和对应配置 */
  static async save(formId: string, config: WidgetConfig): Promise<void> {
    const store = WidgetFormIdStore.store;
    if (!store) {
      Logger.error(TAG, 'save: store not initialized');
      return;
    }
    try {
      await store.put(KEY_PREFIX + formId, JSON.stringify(config));
      await store.flush();
      Logger.info(TAG, `saved formId=${formId}, accountId=${config.accountId}`);
    } catch (e) {
      Logger.error(TAG, `save failed: ${JSON.stringify(e)}`);
    }
  }

  /** 删除 formId */
  static async remove(formId: string): Promise<void> {
    const store = WidgetFormIdStore.store;
    if (!store) {
      return;
    }
    try {
      await store.delete(KEY_PREFIX + formId);
      await store.flush();
      Logger.info(TAG, `removed formId=${formId}`);
    } catch (e) {
      Logger.error(TAG, `remove failed: ${JSON.stringify(e)}`);
    }
  }

  /** 获取单个 formId 的配置，不存在返回 null */
  static getConfig(formId: string): WidgetConfig | null {
    const store = WidgetFormIdStore.store;
    if (!store) {
      return null;
    }
    try {
      const raw = store.getSync(KEY_PREFIX + formId, '') as string;
      if (!raw) {
        return null;
      }
      return JSON.parse(raw) as WidgetConfig;
    } catch (e) {
      Logger.error(TAG, `getConfig failed: ${JSON.stringify(e)}`);
      return null;
    }
  }

  /** 获取所有已保存的 formId 列表 */
  static getAllFormIds(): string[] {
    const store = WidgetFormIdStore.store;
    if (!store) {
      return [];
    }
    try {
      const allKeys = store.getAllSync();
      const formIds: string[] = [];
      const keys = Object.keys(allKeys);
      for (let i = 0; i < keys.length; i++) {
        const key = keys[i];
        if (key.startsWith(KEY_PREFIX)) {
          formIds.push(key.slice(KEY_PREFIX.length));
        }
      }
      return formIds;
    } catch (e) {
      Logger.error(TAG, `getAllFormIds failed: ${JSON.stringify(e)}`);
      return [];
    }
  }

  /** 获取指定账号下的所有 formId */
  static getFormIdsByAccount(accountId: string): string[] {
    const allIds = WidgetFormIdStore.getAllFormIds();
    const result: string[] = [];
    for (let i = 0; i < allIds.length; i++) {
      const formId = allIds[i];
      const config = WidgetFormIdStore.getConfig(formId);
      if (config !== null && config.accountId === accountId) {
        result.push(formId);
      }
    }
    return result;
  }
}
