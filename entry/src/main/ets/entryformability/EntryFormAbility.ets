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
import { hilog } from '@kit.PerformanceAnalysisKit';
import { WidgetConfigStore } from '../widget/utils/WidgetConfigStore';
import { WidgetDataStoreManager } from '../widget/utils/WidgetDataStoreManager';
import { WidgetPayloadBuilder } from '../widget/utils/WidgetPayloadBuilder';
import { WidgetConfig, WidgetSize, getMaxSlots } from '../widget/models/WidgetConfig';

const TAG = 'WIDGET';
const DOMAIN = 0xFF00;

/** Preferences 文件名 */
const PREFS_NAME = 'widget_prefs';

export default class EntryFormAbility extends FormExtensionAbility {
  private prefs: preferences.Preferences | null = null;

  /**
   * 卡片被添加到桌面时触发
   *
   * 流程：
   * 1. 读取 want.parameters 中的 widgetConfig
   * 2. 使用同步 API 从 Preferences 读取 WidgetDataStore
   * 3. 构建并返回 payload（必须在方法返回前完成）
   * 4. 异步保存配置（用于后续刷新）
   *
   * 重要：FormExtension 进程在 onAddForm() 返回后只有 10 秒存活时间，
   * 因此必须使用同步 API 读取数据并立即返回，不能依赖异步更新。
   */
  onAddForm(want: Want): formBindingData.FormBindingData {
    const formId = want.parameters?.[formInfo.FormParam.IDENTITY_KEY] as string ?? '';
    const formName = want.parameters?.[formInfo.FormParam.NAME_KEY] as string ?? '';
    const dimension = want.parameters?.[formInfo.FormParam.DIMENSION_KEY] as number ?? 2;
    const widgetConfigRaw = want.parameters?.['widgetConfig'] as string ?? '';

    hilog.info(DOMAIN, TAG, `[WIDGET_DEBUG] onAddForm: formId=${formId} formName=${formName} dimension=${dimension} configLen=${widgetConfigRaw.length}`);

    // 解析配置
    let config: WidgetConfig | null = null;
    if (widgetConfigRaw.length > 0) {
      config = WidgetConfig.fromJson(widgetConfigRaw);
      config.formId = formId;
      config.formName = formName;
      hilog.info(DOMAIN, TAG, `[WIDGET_DEBUG] config parsed: size=${config.size} slots=${config.slots.length}`);
    }

    // 如果没有配置，使用默认行为
    if (config === null) {
      config = new WidgetConfig();
      config.formId = formId;
      config.formName = formName;
      config.size = this.dimensionToSize(dimension);
      config.slots = [];
      hilog.info(DOMAIN, TAG, `[WIDGET_DEBUG] using default config: size=${config.size}`);
    }

    // ✅ 使用同步 API 读取 Preferences 中的数据
    // 注意：必须在 onAddForm() 返回前完成，不能依赖异步更新
    const dataStore = WidgetDataStoreManager.loadSync(this.context);
    hilog.info(DOMAIN, TAG, `[WIDGET_DEBUG] loadSync: accounts=${dataStore.accounts.length}`);

    // 构建 payload
    const payload = WidgetPayloadBuilder.buildPayload(config, dataStore);
    const record = payload.toLocalStorageRecord();
    
    const payloadStr = record['payload'] ?? '';
    hilog.info(DOMAIN, TAG, `[WIDGET_DEBUG] returning real data, payload len=${payloadStr.length}`);

    // 异步保存配置（用于后续刷新，不阻塞返回）
    this.saveConfigAsync(formId, config);

    // 立即返回真实数据
    return formBindingData.createFormBindingData(record);
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
    WidgetConfigStore.deleteConfig(formId).catch((e: BusinessError) => {
      // 静默处理错误
    });
  }

  /**
   * 卡片内点击刷新按钮触发
   */
  onFormEvent(formId: string, message: string): void {
    this.pushUpdate(formId);
  }

  // ── 私有方法 ──────────────────────────────────────────────────────

  /**
   * 初始化 Preferences
   * 注意：不能调用 CoreInitializer，不能导入 core 模块
   */
  private async initPreferences(): Promise<void> {
    if (this.prefs !== null) {
      return;
    }
    try {
      this.prefs = await preferences.getPreferences(this.context, PREFS_NAME);
    } catch (e) {
      // 静默处理错误
      const err = e as BusinessError;
      hilog.debug(DOMAIN, TAG, `[WIDGET_DEBUG] initPreferences error: code=${err.code} msg=${err.message}`);
    }
  }

  /**
   * 异步保存配置（不更新卡片，用于后续刷新）
   */
  private async saveConfigAsync(formId: string, config: WidgetConfig): Promise<void> {
    try {
      await WidgetConfigStore.init(this.context);
      await WidgetConfigStore.saveConfig(config);
      hilog.info(DOMAIN, TAG, `[WIDGET_DEBUG] saveConfigAsync: config saved for formId=${formId}`);
    } catch (e) {
      const err = e as BusinessError;
      hilog.error(DOMAIN, TAG, `[WIDGET_DEBUG] saveConfigAsync error: code=${err.code} msg=${err.message}`);
    }
  }

  /**
   * 异步保存配置并更新卡片
   */
  private async saveConfigAndUpdate(formId: string, config: WidgetConfig): Promise<void> {
    hilog.info(DOMAIN, TAG, `[WIDGET_DEBUG] saveConfigAndUpdate start: formId=${formId}`);
    try {
      // 初始化存储
      await this.initPreferences();
      await WidgetConfigStore.init(this.context);
      await WidgetDataStoreManager.init(this.context);
      hilog.info(DOMAIN, TAG, `[WIDGET_DEBUG] storage initialized`);

      // 保存配置
      await WidgetConfigStore.saveConfig(config);
      hilog.info(DOMAIN, TAG, `[WIDGET_DEBUG] config saved`);

      // 从 Preferences 读取已保存的数据（由主应用构建）
      const dataStore = await WidgetDataStoreManager.load();
      hilog.info(DOMAIN, TAG, `[WIDGET_DEBUG] dataStore loaded: accounts=${dataStore.accounts.length}`);
      
      // 打印每个账号的游戏和角色信息
      for (let i = 0; i < dataStore.accounts.length; i++) {
        const acc = dataStore.accounts[i];
        hilog.info(DOMAIN, TAG, `[WIDGET_DEBUG] account[${i}]: id=${acc.accountId} games=${acc.games.length}`);
        for (let j = 0; j < acc.games.length; j++) {
          const game = acc.games[j];
          hilog.info(DOMAIN, TAG, `[WIDGET_DEBUG]   game[${j}]: id=${game.gameId} roles=${game.roles.length}`);
          for (let k = 0; k < game.roles.length; k++) {
            const role = game.roles[k];
            hilog.info(DOMAIN, TAG, `[WIDGET_DEBUG]     role[${k}]: roleId=${role.roleId} rawJsonLen=${role.rawJson.length}`);
          }
        }
      }

      // 构建 payload
      const payload = WidgetPayloadBuilder.buildPayload(config, dataStore);
      const record = payload.toLocalStorageRecord();
      hilog.info(DOMAIN, TAG, `[WIDGET_DEBUG] payload built, record keys=${Object.keys(record).length}`);
      
      // 打印 payload 内容
      const payloadStr = record['payload'] ?? '';
      hilog.info(DOMAIN, TAG, `[WIDGET_DEBUG] payload len=${payloadStr.length}`);
      // 打印 payload 的 JSON 结构
      try {
        // 定义 payload 对象的类型
        interface PayloadRole {
          roleId: string;
          rawJson?: string;
        }
        
        interface PayloadGame {
          gameId: string;
          roles?: PayloadRole[];
        }
        
        interface PayloadAccount {
          accountId: string;
          games?: PayloadGame[];
        }
        
        interface PayloadObject {
          version?: number;
          updatedAt?: number;
          accounts?: PayloadAccount[];
        }
        
        const payloadObj: PayloadObject = JSON.parse(payloadStr);
        const accounts = payloadObj.accounts || [];
        hilog.info(DOMAIN, TAG, `[WIDGET_DEBUG] payload structure: version=${payloadObj.version || 0} updatedAt=${payloadObj.updatedAt || 0} accounts=${accounts.length}`);
        for (let i = 0; i < accounts.length; i++) {
          const acc = accounts[i];
          const games = acc.games || [];
          hilog.info(DOMAIN, TAG, `[WIDGET_DEBUG]   payload account[${i}]: id=${acc.accountId} games=${games.length}`);
          for (let j = 0; j < games.length; j++) {
            const game = games[j];
            const roles = game.roles || [];
            hilog.info(DOMAIN, TAG, `[WIDGET_DEBUG]     payload game[${j}]: id=${game.gameId} roles=${roles.length}`);
            for (let k = 0; k < roles.length; k++) {
              const role = roles[k];
              hilog.info(DOMAIN, TAG, `[WIDGET_DEBUG]       payload role[${k}]: roleId=${role.roleId} rawJsonLen=${role.rawJson?.length || 0}`);
            }
          }
        }
      } catch (e) {
        const err = e as BusinessError;
        hilog.warn(DOMAIN, TAG, `[WIDGET_DEBUG] payload JSON parse failed: code=${err.code} msg=${err.message}`);
      }

      // 推送更新
      const formBinding = formBindingData.createFormBindingData(record);
      await formProvider.updateForm(formId, formBinding);
      hilog.info(DOMAIN, TAG, `[WIDGET_DEBUG] formProvider.updateForm done`);
    } catch (e) {
      const err = e as BusinessError;
      hilog.error(DOMAIN, TAG, `[WIDGET_DEBUG] saveConfigAndUpdate error: code=${err.code} msg=${err.message}`);
    }
  }

  /**
   * 推送指定 formId 的最新数据
   */
  private async pushUpdate(formId: string): Promise<void> {
    try {
      // 初始化存储
      await this.initPreferences();
      await WidgetConfigStore.init(this.context);
      await WidgetDataStoreManager.init(this.context);

      // 读取配置
      const config = await WidgetConfigStore.loadConfig(formId);
      if (config === null) {
        return;
      }

      // 从 Preferences 读取已保存的数据
      const dataStore = await WidgetDataStoreManager.load();

      // 构建 payload
      const payload = WidgetPayloadBuilder.buildPayload(config, dataStore);
      const record = payload.toLocalStorageRecord();

      // 推送更新
      const formBinding = formBindingData.createFormBindingData(record);
      await formProvider.updateForm(formId, formBinding);
    } catch (e) {
      // 静默处理错误
      const err = e as BusinessError;
      hilog.debug(DOMAIN, TAG, `[WIDGET_DEBUG] pushUpdate error: code=${err.code} msg=${err.message}`);
    }
  }

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
