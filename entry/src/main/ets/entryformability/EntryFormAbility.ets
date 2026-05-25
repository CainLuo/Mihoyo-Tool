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
   * 1. 从 want.parameters 获取 formName（标准参数，可传递）
   * 2. 直接使用 formName 作为 key 读取配置（不依赖自定义参数）
   * 3. 使用同步 API 从 Preferences 读取 WidgetDataStore
   * 4. 构建并返回 payload（必须在方法返回前完成）
   * 5. 异步保存配置（用于后续刷新）
   *
   * 重要：FormExtension 进程在 onAddForm() 返回后只有 10 秒存活时间，
   * 因此必须使用同步 API 读取数据并立即返回，不能依赖异步更新。
   */
  onAddForm(want: Want): formBindingData.FormBindingData {
    const formId = want.parameters?.[formInfo.FormParam.IDENTITY_KEY] as string ?? '';
    const formName = want.parameters?.[formInfo.FormParam.NAME_KEY] as string ?? '';
    const dimension = want.parameters?.[formInfo.FormParam.DIMENSION_KEY] as number ?? 2;

    hilog.info(DOMAIN, TAG, '[WIDGET_DEBUG] ========== onAddForm START ==========');
    hilog.info(DOMAIN, TAG, '[WIDGET_DEBUG] onAddForm: formId=' + formId + ' formName=' + formName + ' dimension=' + dimension);

    // 同步初始化 Preferences（用于读取配置）
    if (this.prefs === null) {
      try {
        // 关键：先清除缓存，确保读取到主应用进程写入的最新数据
        // Preferences 在多进程间共享，但可能有缓存，需要清除缓存后重新读取
        preferences.removePreferencesFromCacheSync(this.context, { name: 'widget_configs' });
        hilog.info(DOMAIN, TAG, '[WIDGET_DEBUG] onAddForm: cache cleared');
        
        // 注意：getPreferencesSync 的参数格式是 { name: string }
        // 与 getPreferences(context, name) 不同
        this.prefs = preferences.getPreferencesSync(this.context, { name: 'widget_configs' });
        hilog.info(DOMAIN, TAG, '[WIDGET_DEBUG] onAddForm: prefs initialized');
        
        // 验证：列出 Preferences 中所有的 key
        const all = this.prefs.getAll();
        const keys = Object.keys(all);
        hilog.info(DOMAIN, TAG, '[WIDGET_DEBUG] onAddForm: prefs keys count=' + keys.length);
        for (let i = 0; i < keys.length; i++) {
          hilog.info(DOMAIN, TAG, '[WIDGET_DEBUG] onAddForm: prefs key[' + i + ']=' + keys[i]);
        }
      } catch (e) {
        hilog.warn(DOMAIN, TAG, '[WIDGET_DEBUG] onAddForm: failed to init prefs: ' + JSON.stringify(e));
      }
    }

    // 解析配置
    let config: WidgetConfig | null = null;
    
    // 关键修复：直接使用 formName 作为配置 key（与 complete() 保持一致）
    // formName 是标准参数，可以正确传递
    if (formName.length > 0) {
      hilog.info(DOMAIN, TAG, '[WIDGET_DEBUG] trying to load config with key=' + formName);
      config = this.loadPendingConfig(formName);
      if (config !== null) {
        config.formId = formId;
        config.formName = formName;
        hilog.info(DOMAIN, TAG, '[WIDGET_DEBUG] ✅ config loaded: size=' + config.size + ' slots=' + config.slots.length);
        // 打印每个 slot 的详细信息
        for (let i = 0; i < config.slots.length; i++) {
          const slot = config.slots[i];
          hilog.info(DOMAIN, TAG, '[WIDGET_DEBUG]   slot[' + i + ']: accountId=' + slot.accountId + ' gameId=' + slot.gameId + ' roleId=' + slot.roleId);
        }
        // 删除临时配置（已关联到 formId）
        this.deletePendingConfig(formName);
      } else {
        hilog.warn(DOMAIN, TAG, '[WIDGET_DEBUG] ⚠️ config NOT FOUND for key=' + formName);
      }
    } else {
      hilog.warn(DOMAIN, TAG, '[WIDGET_DEBUG] ⚠️ formName is EMPTY, cannot load config');
    }

    // 如果没有配置，使用默认行为
    if (config === null) {
      config = new WidgetConfig();
      config.formId = formId;
      config.formName = formName;
      config.size = this.dimensionToSize(dimension);
      config.slots = [];
      hilog.info(DOMAIN, TAG, '[WIDGET_DEBUG] using default config: size=' + config.size + ' formName=' + formName);
    }

    // ✅ 使用同步 API 读取 Preferences 中的数据
    // 注意：必须在 onAddForm() 返回前完成，不能依赖异步更新
    const dataStore = WidgetDataStoreManager.loadSync(this.context);
    const accountIds = Object.keys(dataStore.data);
    hilog.info(DOMAIN, TAG, '[WIDGET_DEBUG] loadSync: accounts=' + accountIds.length + ' version=' + dataStore.version);
    
    // 🔬 调试：打印 dataStore 的详细结构
    for (let i = 0; i < accountIds.length; i++) {
      const accountId = accountIds[i];
      const acc = dataStore.data[accountId];
      const roleIds = Object.keys(acc.slots);
      hilog.info(DOMAIN, TAG, '[WIDGET_DEBUG] dataStore.account[' + i + ']: accountId=' + accountId + ' roles=' + roleIds.length);
      for (let j = 0; j < roleIds.length; j++) {
        const roleId = roleIds[j];
        const slot = acc.slots[roleId];
        hilog.info(DOMAIN, TAG, '[WIDGET_DEBUG]   role[' + j + ']: roleId=' + roleId + ' gameId=' + slot.gameId + ' rawJsonLen=' + slot.rawJson.length);
      }
    }

    // 🔬 实验：如果数据为空，使用硬编码 mock 数据
    if (!dataStore.hasData) {
      hilog.warn(DOMAIN, TAG, `[WIDGET_DEBUG] ⚠️ EXPERIMENT: dataStore is empty, using MOCK data`);
      const mockPayload = this.buildMockPayload();
      hilog.info(DOMAIN, TAG, `[WIDGET_DEBUG] mockPayload len=${mockPayload.length}`);
      const mockRecord: Record<string, string> = { 'payload': mockPayload };
      return formBindingData.createFormBindingData(mockRecord);
    }

    // 构建 payload
    const payload = WidgetPayloadBuilder.buildPayload(config, dataStore);
    const record = payload.toLocalStorageRecord();
    
    const payloadStr = record['payload'] ?? '';
    hilog.info(DOMAIN, TAG, `[WIDGET_DEBUG] returning real data, payload len=${payloadStr.length}`);

    // 异步保存配置（用于后续刷新，不阻塞返回）
    hilog.info(DOMAIN, TAG, `[WIDGET_DEBUG] saveConfigAsync: calling with config.formId=` + config.formId + ` slots=` + config.slots.length);
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
      const accountIds = Object.keys(dataStore.data);
      hilog.info(DOMAIN, TAG, `[WIDGET_DEBUG] dataStore loaded: accounts=${accountIds.length} version=${dataStore.version}`);
      
      // 打印每个账号的角色信息
      for (let i = 0; i < accountIds.length; i++) {
        const accountId = accountIds[i];
        const acc = dataStore.data[accountId];
        const roleIds = Object.keys(acc.slots);
        hilog.info(DOMAIN, TAG, `[WIDGET_DEBUG] account[${i}]: id=${accountId} roles=${roleIds.length}`);
        for (let j = 0; j < roleIds.length; j++) {
          const roleId = roleIds[j];
          const slot = acc.slots[roleId];
          hilog.info(DOMAIN, TAG, `[WIDGET_DEBUG]   role[${j}]: roleId=${roleId} gameId=${slot.gameId} rawJsonLen=${slot.rawJson.length}`);
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
   * 🔬 实验：构建硬编码 mock payload
   * 
   * 用于验证：如果 Widget 能正常显示 mock 数据，说明问题在数据链路（loadSync 返回空）
   * 如果 Widget 仍然白屏，说明问题在 @LocalStorageProp 或 Widget 组件本身
   */
  private buildMockPayload(): string {
    // 手动构建 JSON 字符串，避免 ArkTS 严格模式的对象字面量限制
    // 包含完整的原神便笺数据（含派遣、洞天宝钱等字段）
    const rawJson = '{"current_resin":152,"max_resin":200,"resin_recovery_time":"22825","finished_task_num":0,"total_task_num":4,"is_extra_task_reward_received":false,"remain_resin_discount_num":3,"resin_discount_num_limit":3,"current_expedition_num":5,"max_expedition_num":5,"expeditions":[{"status":"Finished","remained_time":"0"},{"status":"Finished","remained_time":"0"},{"status":"Ongoing","remained_time":"12345"}],"current_home_coin":1230,"max_home_coin":2400,"home_coin_recovery_time":"139968","transformer":{"obtained":true,"recovery_time":{"Day":6,"Hour":0,"Minute":0,"Second":0,"reached":false}}}';
    const rawJsonEscaped = rawJson.replace(/"/g, '\\\\"');
    const mockPayload = '{"version":1,"updatedAt":' + Math.floor(Date.now() / 1000) + ',"accounts":[{"accountId":"mock_account_1","accountName":"测试账号","games":[{"gameId":"genshin","roles":[{"roleId":"123456789","nickname":"旅行者","server":"cn_gf01","rawJson":"' + rawJsonEscaped + '"}]}]}]}';
    
    hilog.info(DOMAIN, TAG, `[WIDGET_DEBUG] buildMockPayload: rawJson includes max_expedition_num=5, max_home_coin=2400`);
    return mockPayload;
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

  /**
   * 从 Preferences 加载 pending config
   */
  private loadPendingConfig(key: string): WidgetConfig | null {
    if (this.prefs === null) {
      hilog.warn(DOMAIN, TAG, '[WIDGET_DEBUG] loadPendingConfig: prefs is null');
      return null;
    }
    try {
      hilog.info(DOMAIN, TAG, '[WIDGET_DEBUG] loadPendingConfig: reading key=' + key);
      const json = this.prefs.getSync(key, '') as string;
      hilog.info(DOMAIN, TAG, '[WIDGET_DEBUG] loadPendingConfig: json.length=' + json.length);
      if (json.length === 0) {
        hilog.warn(DOMAIN, TAG, '[WIDGET_DEBUG] loadPendingConfig: json is empty');
        return null;
      }
      // 打印 json 内容前 200 字符
      hilog.info(DOMAIN, TAG, '[WIDGET_DEBUG] loadPendingConfig: json preview=' + json.substring(0, 200));
      const config = WidgetConfig.fromJson(json);
      hilog.info(DOMAIN, TAG, '[WIDGET_DEBUG] loadPendingConfig: parsed slots=' + config.slots.length);
      return config;
    } catch (e) {
      hilog.error(DOMAIN, TAG, '[WIDGET_DEBUG] loadPendingConfig error: ' + JSON.stringify(e));
      return null;
    }
  }

  /**
   * 删除 pending config
   */
  private deletePendingConfig(key: string): void {
    if (this.prefs === null) {
      return;
    }
    try {
      this.prefs.deleteSync(key);
      this.prefs.flush();
    } catch (e) {
      // 静默处理错误
    }
  }
}
