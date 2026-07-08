/**
 * EntryFormAbility — 卡片生命周期管理
 *
 * 重要约束（来自官方文档 FormKit-Notes.md 第 12.15 节）：
 * - FormExtensionAbility 不能导入 HSP 模块（core 是 HSP）
 * - FormExtension 进程与主应用进程内存隔离
 * - 数据共享只能通过 Preferences 传递
 *
 * 架构设计：
 * 1. 主应用（EntryAbility）负责从 core 模块读取数据，保存到 Preferences
 * 2. WidgetDataStoreBuilder 在主应用进程中调用，构建并保存数据
 * 3. EntryFormAbility 只从 Preferences 读取已保存的数据
 * 4. 所有涉及 core 模块的操作都在主应用进程中完成
 */

import { formBindingData, FormExtensionAbility, formInfo, formProvider } from '@kit.FormKit';
import { Want } from '@kit.AbilityKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { preferences } from '@kit.ArkData';
import { WidgetLogger } from '../widget/utils/WidgetLogger';
import { WidgetConfigStore } from '../widget/utils/WidgetConfigStore';
import { WidgetDataStoreManager } from '../widget/utils/WidgetDataStoreManager';
import { WidgetPayloadBuilder } from '../widget/utils/WidgetPayloadBuilder';
import { WidgetConfig, WidgetSize } from '../widget/models/WidgetConfig';
import { WidgetImageDownloader } from '../widget/utils/WidgetImageDownloader';
import { WidgetMockData } from '../widget/utils/WidgetMockData';
import { WidgetDataStore } from '../widget/models/WidgetDataStore';

const TAG = 'WIDGET';

export default class EntryFormAbility extends FormExtensionAbility {
  private prefs: preferences.Preferences | null = null;

  /**
   * 卡片被添加到桌面时触发
   *
   * 流程：
   * 1. 解析 want.parameters 获取卡片信息
   * 2. 同步读取 Preferences 中的配置和数据
   * 3. 构建 payload 并返回
   *
   * 重要：FormExtension 进程在 onAddForm() 返回后只有 10 秒存活时间，
   * 因此必须使用同步 API 读取数据并立即返回，不能依赖异步更新。
   */
  onAddForm(want: Want): formBindingData.FormBindingData {
    // 1. 解析 want 参数
    const formInfo = this.parseWantParameters(want);
    WidgetLogger.info(TAG, `onAddForm: formId=${formInfo.formId} formName=${formInfo.formName} size=${formInfo.width}x${formInfo.height}`);

    // 2. 初始化 Preferences（同步）
    this.initPreferencesSync();

    // 3. 加载配置
    const config = this.loadOrCreateConfig(formInfo);

    // 4. 加载数据
    const dataStore = WidgetDataStoreManager.loadSync(this.context);

    // 5. 构建并返回表单数据
    const formData = this.buildFormData(config, dataStore, formInfo);

    // 6. 异步保存配置（不阻塞返回）
    this.saveConfigAsync(formInfo.formId, config);

    return formData;
  }

  /**
   * 定时刷新触发
   */
  onUpdateForm(formId: string): void {
    this.pushUpdate(formId);
  }

  /**
   * 卡片被移除时触发
   */
  onRemoveForm(formId: string): void {
    WidgetConfigStore.deleteConfig(formId).catch((_e: BusinessError) => {
      // 静默处理错误
    });
  }

  /**
   * 卡片内点击刷新按钮触发
   */
  onFormEvent(formId: string, _message: string): void {
    this.pushUpdate(formId);
  }

  // ── 私有方法：参数解析 ──────────────────────────────────────────────────────

  /**
   * 解析 want.parameters 获取卡片信息
   */
  private parseWantParameters(want: Want): FormInfo {
    return {
      formId: want.parameters?.[formInfo.FormParam.IDENTITY_KEY] as string ?? '',
      formName: want.parameters?.[formInfo.FormParam.NAME_KEY] as string ?? '',
      dimension: want.parameters?.[formInfo.FormParam.DIMENSION_KEY] as number ?? 2,
      width: want.parameters?.[formInfo.FormParam.WIDTH_KEY] as number ?? 0,
      height: want.parameters?.[formInfo.FormParam.HEIGHT_KEY] as number ?? 0,
    };
  }

  // ── 私有方法：Preferences 初始化 ──────────────────────────────────────────────

  /**
   * 同步初始化 Preferences
   *
   * 关键：先清除缓存，确保读取到主应用进程写入的最新数据
   */
  private initPreferencesSync(): void {
    if (this.prefs !== null) {
      return;
    }

    try {
      preferences.removePreferencesFromCacheSync(this.context, { name: 'widget_configs' });
      this.prefs = preferences.getPreferencesSync(this.context, { name: 'widget_configs' });
    } catch (e) {
      WidgetLogger.warn(TAG, 'initPreferencesSync failed: ' + JSON.stringify(e));
    }
  }

  // ── 私有方法：配置加载 ────────────────────────────────────────────────────────

  /**
   * 加载或创建配置
   */
  private loadOrCreateConfig(formInfo: FormInfo): WidgetConfig {
    // 尝试加载用户配置
    if (formInfo.formName.length > 0) {
      const config = this.loadPendingConfig(formInfo.formName);
      if (config !== null) {
        config.formId = formInfo.formId;
        config.formName = formInfo.formName;
        return config;
      }
    }

    // 创建默认配置
    const config = new WidgetConfig();
    config.formId = formInfo.formId;
    config.formName = formInfo.formName;
    config.size = this.dimensionToSize(formInfo.dimension);
    config.slots = [];

    return config;
  }

  /**
   * 从 Preferences 加载 pending config
   */
  private loadPendingConfig(key: string): WidgetConfig | null {
    if (this.prefs === null) {
      return null;
    }

    try {
      const json = this.prefs.getSync(key, '') as string;
      if (json.length === 0) {
        return null;
      }
      return WidgetConfig.fromJson(json);
    } catch (e) {
      WidgetLogger.error(TAG, 'loadPendingConfig error: ' + JSON.stringify(e));
      return null;
    }
  }

  // ── 私有方法：表单数据构建 ────────────────────────────────────────────────────

  /**
   * 构建表单数据
   */
  private buildFormData(
    config: WidgetConfig,
    dataStore: WidgetDataStore,
    formInfo: FormInfo
  ): formBindingData.FormBindingData {
    // 数据为空时返回 Mock 数据
    if (!dataStore.hasData) {
      WidgetLogger.warn(TAG, 'dataStore is empty, using mock data');
      return this.buildMockFormData();
    }

    // 构建 payload
    const payload = WidgetPayloadBuilder.buildPayload(config, dataStore);
    payload.widgetWidth = formInfo.width;
    payload.widgetHeight = formInfo.height;

    // 读取派遣头像图片
    const formImages = WidgetImageDownloader.loadFormImagesSync(this.context, 'exp_avatar', 5);

    // 构建 FormData（手动合并，不能使用 spread 运算符）
    const record = payload.toLocalStorageRecord();
    const formDataObj: Record<string, Object> = {};
    const recordKeys = Object.keys(record);
    for (let i = 0; i < recordKeys.length; i++) {
      const key = recordKeys[i];
      formDataObj[key] = record[key] as Object;
    }
    formDataObj['formImages'] = formImages as Object;

    return formBindingData.createFormBindingData(formDataObj);
  }

  /**
   * 构建 Mock 表单数据（用于调试）
   */
  private buildMockFormData(): formBindingData.FormBindingData {
    const mockPayload = WidgetMockData.buildPayload();
    const mockRecord: Record<string, string> = { 'payload': mockPayload };
    return formBindingData.createFormBindingData(mockRecord);
  }

  // ── 私有方法：配置保存 ────────────────────────────────────────────────────────

  /**
   * 异步保存配置（不更新卡片，用于后续刷新）
   */
  private async saveConfigAsync(formId: string, config: WidgetConfig): Promise<void> {
    try {
      await WidgetConfigStore.init(this.context);
      await WidgetConfigStore.saveConfig(config);
    } catch (e) {
      const err = e as BusinessError;
      WidgetLogger.error(TAG, `saveConfigAsync error: code=${err.code} msg=${err.message}`);
    }
  }

  // ── 私有方法：更新推送 ────────────────────────────────────────────────────────

  /**
   * 推送指定 formId 的最新数据
   */
  private async pushUpdate(formId: string): Promise<void> {
    try {
      await WidgetConfigStore.init(this.context);
      await WidgetDataStoreManager.init(this.context);

      const config = await WidgetConfigStore.loadConfig(formId);
      if (config === null) {
        return;
      }

      const dataStore = await WidgetDataStoreManager.load();
      const payload = WidgetPayloadBuilder.buildPayload(config, dataStore);
      const record = payload.toLocalStorageRecord();

      const formBinding = formBindingData.createFormBindingData(record);
      await formProvider.updateForm(formId, formBinding);
    } catch (e) {
      const err = e as BusinessError;
      WidgetLogger.warn(TAG, `pushUpdate error: code=${err.code} msg=${err.message}`);
    }
  }

  // ── 私有方法：工具函数 ────────────────────────────────────────────────────────

  /**
   * dimension 转 WidgetSize
   */
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

/**
 * 表单信息结构
 */
interface FormInfo {
  formId: string;
  formName: string;
  dimension: number;
  width: number;
  height: number;
}
