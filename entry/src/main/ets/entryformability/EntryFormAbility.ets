/**
 * EntryFormAbility — 卡片生命周期管理
 *
 * 新架构：
 * 1. WidgetDataStore 存储所有账号的所有角色数据（rawJson）
 * 2. WidgetConfig 存储每个 Widget 选择的 slots（三元组）
 * 3. FormExtension 读取配置 + 数据，构建 payload
 */

import { formBindingData, FormExtensionAbility, formInfo, formProvider } from '@kit.FormKit';
import { Want } from '@kit.AbilityKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { RdbManager, Logger } from 'core';
import { WidgetConfigStore } from '../widget/utils/WidgetConfigStore';
import { WidgetDataStoreManager } from '../widget/utils/WidgetDataStoreManager';
import { WidgetDataStoreBuilder } from '../widget/utils/WidgetDataStoreBuilder';
import { WidgetPayloadBuilder, WidgetPayloadItem } from '../widget/utils/WidgetPayloadBuilder';
import { WidgetConfig, WidgetSize, getMaxSlots } from '../widget/models/WidgetConfig';
import { WidgetDataStore } from '../widget/models/WidgetDataStore';

const TAG = 'EntryFormAbility';

/** 全局缓存的数据，避免重复从 DB 读取 */
let gCachedDataStore: WidgetDataStore | null = null;

export default class EntryFormAbility extends FormExtensionAbility {

  /**
   * 卡片被添加到桌面时触发
   * 1. 读取 want.parameters 中的 widgetConfig
   * 2. 保存 formId + 配置到 Preferences
   * 3. 返回数据（优先使用缓存）
   */
  onAddForm(want: Want): formBindingData.FormBindingData {
    Logger.info(TAG, 'onAddForm');
    const formId = want.parameters?.[formInfo.FormParam.IDENTITY_KEY] as string ?? '';
    const formName = want.parameters?.[formInfo.FormParam.NAME_KEY] as string ?? '';
    const dimension = want.parameters?.[formInfo.FormParam.DIMENSION_KEY] as number ?? 2;
    const widgetConfigRaw = want.parameters?.['widgetConfig'] as string ?? '';

    Logger.info(TAG, `formId=${formId}, formName=${formName}, dimension=${dimension}, formName=${formName}`);

    // 解析配置
    let config: WidgetConfig | null = null;
    if (widgetConfigRaw.length > 0) {
      config = WidgetConfig.fromJson(widgetConfigRaw);
      config.formId = formId;
      config.formName = formName;
    }

    // 如果没有配置，使用默认行为
    if (config === null) {
      config = new WidgetConfig();
      config.formId = formId;
      config.formName = formName;
      config.size = this.dimensionToSize(dimension);
      config.slots = [];
    }

    // 同步初始化存储
    this.initStoreSync();

    // 保存配置
    WidgetConfigStore.saveConfig(config).then(() => {
      Logger.info(TAG, 'onAddForm: config saved');
    }).catch((e: BusinessError) => {
      Logger.error(TAG, `onAddForm: save config failed: ${e.message}`);
    });

    // 使用缓存数据或创建占位数据
    if (gCachedDataStore !== null && gCachedDataStore.accounts.length > 0) {
      Logger.info(TAG, `onAddForm: using cached data, accounts=${gCachedDataStore.accounts.length}`);
      const payload = WidgetPayloadBuilder.buildPayload(config, gCachedDataStore);
      const record = payload.toLocalStorageRecord();
      Logger.info(TAG, `onAddForm: payload preview=${record['payload'].substring(0, Math.min(300, record['payload'].length))}`);
      return formBindingData.createFormBindingData(record);
    }

    // 无缓存数据，返回占位数据，然后异步加载数据并更新
    Logger.info(TAG, 'onAddForm: no cache, loading data async');
    this.loadDataAndUpdate(formId, config);
    return this.createPlaceholderData(config);
  }

  /**
   * 定时刷新触发
   */
  onUpdateForm(formId: string): void {
    Logger.info(TAG, `onUpdateForm formId=${formId}`);
    this.pushUpdate(formId);
  }

  /**
   * 卡片被移除时触发
   */
  onRemoveForm(formId: string): void {
    Logger.info(TAG, `onRemoveForm formId=${formId}`);
    WidgetConfigStore.deleteConfig(formId).catch((e: BusinessError) => {
      Logger.error(TAG, `remove formId failed: ${e.message}`);
    });
  }

  /**
   * 卡片内点击刷新按钮触发
   */
  onFormEvent(formId: string, message: string): void {
    Logger.info(TAG, `onFormEvent formId=${formId}, message=${message}`);
    this.pushUpdate(formId);
  }

  // ── 私有方法 ──────────────────────────────────────────────────────

  /** 同步初始化存储（简化版） */
  private initStoreSync(): void {
    try {
      RdbManager.init(this.context).then(() => {
        Logger.info(TAG, 'initStoreSync: RdbManager init success');
      }).catch((e: BusinessError) => {
        Logger.error(TAG, `RdbManager init failed: ${e.message}`);
      });
    } catch (e) {
      const err = e as BusinessError;
      Logger.error(TAG, `RdbManager init exception: ${err.message}`);
    }
    WidgetConfigStore.init(this.context);
    WidgetDataStoreManager.init(this.context);
  }

  /** 异步加载数据并更新 Widget */
  private async loadDataAndUpdate(formId: string, config: WidgetConfig): Promise<void> {
    try {
      Logger.info(TAG, `loadDataAndUpdate: formId=${formId}`);
      
      // 加载或构建数据
      let dataStore = await WidgetDataStoreManager.load();
      Logger.info(TAG, `loadDataAndUpdate: loaded dataStore.accounts.length=${dataStore.accounts.length}`);
      
      if (dataStore.accounts.length === 0) {
        dataStore = await WidgetDataStoreBuilder.buildFromDB();
        Logger.info(TAG, `loadDataAndUpdate: buildFromDB done, accounts.length=${dataStore.accounts.length}`);
        await WidgetDataStoreManager.save(dataStore);
        
        // 更新缓存
        gCachedDataStore = dataStore;
      }

      // 构建并推送更新
      const payload = WidgetPayloadBuilder.buildPayload(config, dataStore);
      const record = payload.toLocalStorageRecord();
      const payloadJson = record['payload'];
      Logger.info(TAG, `loadDataAndUpdate: payload length=${payloadJson.length}`);
      Logger.info(TAG, `loadDataAndUpdate: payload preview=${payloadJson.substring(0, Math.min(500, payloadJson.length))}`);

      const formBinding = formBindingData.createFormBindingData(record);
      await formProvider.updateForm(formId, formBinding);
      Logger.info(TAG, `loadDataAndUpdate: updateForm success`);
    } catch (e) {
      const err = e as BusinessError;
      Logger.error(TAG, `loadDataAndUpdate failed: code=${err.code} msg=${err.message}`);
    }
  }

  /** 推送指定 formId 的最新数据 */
  private async pushUpdate(formId: string): Promise<void> {
    try {
      const config = await WidgetConfigStore.loadConfig(formId);
      if (config === null) {
        Logger.warn(TAG, `pushUpdate: no config for formId=${formId}`);
        return;
      }
      
      let dataStore = await WidgetDataStoreManager.load();
      if (dataStore.accounts.length === 0) {
        dataStore = await WidgetDataStoreBuilder.buildFromDB();
        await WidgetDataStoreManager.save(dataStore);
        gCachedDataStore = dataStore;
      }

      const payload = WidgetPayloadBuilder.buildPayload(config, dataStore);
      const record = payload.toLocalStorageRecord();
      const formBinding = formBindingData.createFormBindingData(record);
      await formProvider.updateForm(formId, formBinding);
      Logger.info(TAG, `pushUpdate success: formId=${formId}`);
    } catch (e) {
      const err = e as BusinessError;
      Logger.error(TAG, `pushUpdate failed: code=${err.code} msg=${err.message}`);
    }
  }

  /** 创建占位数据 */
  private createPlaceholderData(config: WidgetConfig): formBindingData.FormBindingData {
    const emptyPayload = new WidgetPayloadItem();
    emptyPayload.version = 1;
    emptyPayload.updatedAt = 0;
    emptyPayload.accounts = [];
    const data: Record<string, string> = {};
    data['payload'] = JSON.stringify(emptyPayload);
    return formBindingData.createFormBindingData(data);
  }

  /** dimension 转 WidgetSize */
  private dimensionToSize(dimension: number): WidgetSize {
    if (dimension === 1) {
      return WidgetSize.SIZE_1x2;
    } else if (dimension === 3) {
      return WidgetSize.SIZE_2x4;
    } else if (dimension === 4) {
      return WidgetSize.SIZE_4x4;
    }
    return WidgetSize.SIZE_2x2;
  }
}
