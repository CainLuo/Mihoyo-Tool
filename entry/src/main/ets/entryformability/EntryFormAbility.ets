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
import { WidgetPayloadBuilder } from '../widget/utils/WidgetPayloadBuilder';
import { WidgetConfig, WidgetSize, getMaxSlots } from '../widget/models/WidgetConfig';
import { WidgetDataStore } from '../widget/models/WidgetDataStore';

const TAG = 'EntryFormAbility';

export default class EntryFormAbility extends FormExtensionAbility {

  /**
   * 卡片被添加到桌面时触发
   * 1. 读取 want.parameters 中的 widgetConfig
   * 2. 保存 formId + 配置到 Preferences
   * 3. 立即返回初始数据
   */
  onAddForm(want: Want): formBindingData.FormBindingData {
    Logger.info(TAG, 'onAddForm');
    const formId = want.parameters?.[formInfo.FormParam.IDENTITY_KEY] as string ?? '';
    const formName = want.parameters?.[formInfo.FormParam.NAME_KEY] as string ?? '';
    const dimension = want.parameters?.[formInfo.FormParam.DIMENSION_KEY] as number ?? 2;
    const widgetConfigRaw = want.parameters?.['widgetConfig'] as string ?? '';

    Logger.info(TAG, `formId=${formId}, formName=${formName}, dimension=${dimension}`);

    // 解析配置
    let config: WidgetConfig | null = null;
    if (widgetConfigRaw.length > 0) {
      config = WidgetConfig.fromJson(widgetConfigRaw);
      config.formId = formId;
    }

    // 如果没有配置，使用默认行为
    if (config === null) {
      config = new WidgetConfig();
      config.formId = formId;
      config.size = this.dimensionToSize(dimension);
      config.slots = [];
    }

    // 异步初始化并保存配置
    this.initAndSave(formId, config);

    // 返回初始占位数据
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
    this.initStore().then(() => {
      WidgetConfigStore.deleteConfig(formId).catch((e: BusinessError) => {
        Logger.error(TAG, `remove formId failed: ${e.message}`);
      });
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

  /** 初始化 RdbManager 和 WidgetConfigStore */
  private async initStore(): Promise<void> {
    try {
      Logger.info(TAG, `initStore: databaseDir=${this.context.databaseDir}`);
      await RdbManager.init(this.context);
      Logger.info(TAG, 'initStore: RdbManager init success');
    } catch (e) {
      Logger.error(TAG, `RdbManager init failed: ${JSON.stringify(e)}`);
    }
    await WidgetConfigStore.init(this.context);
    await WidgetDataStoreManager.init(this.context);
  }

  /** 初始化、保存配置、推送数据 */
  private async initAndSave(formId: string, config: WidgetConfig): Promise<void> {
    await this.initStore();
    if (formId === '') {
      Logger.warn(TAG, 'initAndSave: missing formId, skip');
      return;
    }

    // 保存配置
    await WidgetConfigStore.saveConfig(config);

    // 如果全局数据为空，从 DB 构建
    let dataStore = await WidgetDataStoreManager.load();
    if (dataStore.accounts.length === 0) {
      dataStore = await WidgetDataStoreBuilder.buildFromDB();
      await WidgetDataStoreManager.save(dataStore);
    }

    // 推送更新
    await this.pushUpdateWithData(formId, config, dataStore);
  }

  /** 推送指定 formId 的最新数据 */
  private async pushUpdate(formId: string): Promise<void> {
    await this.initStore();
    const config = await WidgetConfigStore.loadConfig(formId);
    if (config === null) {
      Logger.warn(TAG, `pushUpdate: no config for formId=${formId}`);
      return;
    }
    const dataStore = await WidgetDataStoreManager.load();
    await this.pushUpdateWithData(formId, config, dataStore);
  }

  /** 使用指定配置和数据推送更新 */
  private async pushUpdateWithData(
    formId: string,
    config: WidgetConfig,
    dataStore: WidgetDataStore,
  ): Promise<void> {
    try {
      const payload = WidgetPayloadBuilder.buildPayload(config, dataStore);
      const record = payload.toLocalStorageRecord();
      const formBinding = formBindingData.createFormBindingData(record);
      await formProvider.updateForm(formId, formBinding);
      Logger.info(TAG, `pushUpdateWithData success: formId=${formId} slots=${payload.slotCount}`);
    } catch (e) {
      const err = e as BusinessError;
      Logger.error(TAG, `pushUpdateWithData failed: code=${err.code} msg=${err.message}`);
    }
  }

  /** 创建占位数据 */
  private createPlaceholderData(config: WidgetConfig): formBindingData.FormBindingData {
    const data: Record<string, string> = {};
    data['widgetSize'] = config.size;
    data['slotCount'] = '0';
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
