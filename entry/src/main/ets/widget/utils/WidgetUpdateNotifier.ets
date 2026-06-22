/**
 * WidgetUpdateNotifier — Widget 更新通知器
 *
 * 负责：
 * 1. 遍历所有已安装的 Widget，推送更新
 * 2. 处理 Widget 已删除的情况（清理失效的 formId）
 *
 * 调用时机：
 * - 主应用数据同步完成后
 * - 后台定时刷新完成后
 */

import { formProvider, formBindingData } from '@kit.FormKit';
import { common } from '@kit.AbilityKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { preferences } from '@kit.ArkData';
import { Logger } from 'core';
import { WidgetConfigStore } from './WidgetConfigStore';
import { WidgetDataStoreManager } from './WidgetDataStoreManager';
import { WidgetPayloadBuilder } from './WidgetPayloadBuilder';
import { WidgetConfig } from '../models/WidgetConfig';
import { WidgetDataStore } from '../models/WidgetDataStore';

const TAG = 'WIDGET';

export class WidgetUpdateNotifier {
  /**
   * 通知所有已安装的 Widget 刷新
   *
   * 流程：
   * 1. 从 WidgetConfigStore 读取所有 Widget 配置
   * 2. 从 WidgetDataStoreManager 读取最新数据
   * 3. 遍历每个 Widget，构建 payload 并推送更新
   * 4. 处理已删除的 Widget（清理配置）
   *
   * @param context UIAbilityContext（用于初始化存储）
   */
  static async notifyAllWidgets(context: common.UIAbilityContext): Promise<void> {
    Logger.info(TAG, '[WIDGET_UPDATE] notifyAllWidgets: start');

    try {
      // 初始化存储
      await WidgetConfigStore.init(context);
      await WidgetDataStoreManager.init(context);

      // 获取所有 Widget 配置
      const configs = await WidgetConfigStore.getAllConfigs();
      Logger.info(TAG, `[WIDGET_UPDATE] notifyAllWidgets: found ${configs.length} widgets`);

      if (configs.length === 0) {
        Logger.info(TAG, '[WIDGET_UPDATE] notifyAllWidgets: no widgets to update');
        return;
      }

      // 读取最新数据
      const dataStore = await WidgetDataStoreManager.load();
      const accountCount = Object.keys(dataStore.data).length;
      Logger.info(TAG, `[WIDGET_UPDATE] notifyAllWidgets: dataStore has ${accountCount} accounts`);

      // 遍历每个 Widget 推送更新
      let successCount = 0;
      let removeCount = 0;

      for (let i = 0; i < configs.length; i++) {
        const config = configs[i];
        const success = await WidgetUpdateNotifier.pushUpdate(config, dataStore);

        if (success) {
          successCount++;
        } else {
          // Widget 可能已被删除，清理配置
          Logger.warn(TAG, `[WIDGET_UPDATE] notifyAllWidgets: widget ${config.formId} update failed, removing config`);
          await WidgetConfigStore.deleteConfig(config.formId);
          removeCount++;
        }
      }

      Logger.info(TAG, `[WIDGET_UPDATE] notifyAllWidgets: done, success=${successCount} removed=${removeCount}`);
    } catch (e) {
      const err = e as BusinessError;
      Logger.error(TAG, `[WIDGET_UPDATE] notifyAllWidgets error: code=${err.code} msg=${err.message}`);
    }
  }

  /**
   * 通知单个 Widget 刷新
   *
   * @param context UIAbilityContext
   * @param formId Widget 的 formId
   */
  static async notifyWidget(context: common.UIAbilityContext, formId: string): Promise<boolean> {
    Logger.info(TAG, `[WIDGET_UPDATE] notifyWidget: formId=${formId}`);

    try {
      await WidgetConfigStore.init(context);
      await WidgetDataStoreManager.init(context);

      const config = await WidgetConfigStore.loadConfig(formId);
      if (config === null || config.formId.length === 0) {
        Logger.warn(TAG, `[WIDGET_UPDATE] notifyWidget: config not found for ${formId}`);
        return false;
      }

      const dataStore = await WidgetDataStoreManager.load();
      return await WidgetUpdateNotifier.pushUpdate(config, dataStore);
    } catch (e) {
      const err = e as BusinessError;
      Logger.error(TAG, `[WIDGET_UPDATE] notifyWidget error: code=${err.code} msg=${err.message}`);
      return false;
    }
  }

  /**
   * 推送更新到单个 Widget
   *
   * @param config Widget 配置
   * @param dataStore 数据存储
   * @returns true 表示成功，false 表示 Widget 可能已删除
   */
  private static async pushUpdate(config: WidgetConfig, dataStore: WidgetDataStore): Promise<boolean> {
    try {
      // 构建 payload
      const payload = WidgetPayloadBuilder.buildPayload(config, dataStore);
      const record = payload.toLocalStorageRecord();

      // 推送更新
      const formBinding = formBindingData.createFormBindingData(record);
      await formProvider.updateForm(config.formId, formBinding);

      Logger.info(TAG, `[WIDGET_UPDATE] pushUpdate: success for ${config.formId}`);
      return true;
    } catch (e) {
      const err = e as BusinessError;

      // 错误码 401 表示 Widget 不存在（已被删除）
      // 错误码 16500050 表示 formId 不存在
      if (err.code === 401 || err.code === 16500050) {
        Logger.warn(TAG, `[WIDGET_UPDATE] pushUpdate: widget ${config.formId} not found (deleted)`);
        return false;
      }

      Logger.error(TAG, `[WIDGET_UPDATE] pushUpdate error for ${config.formId}: code=${err.code} msg=${err.message}`);
      return false;
    }
  }
}
