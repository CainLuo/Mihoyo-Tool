/**
 * WidgetPayloadBuilder.ets — Widget Payload 构建器
 *
 * 从 WidgetDataStore + WidgetConfig 构建传递给 Widget 组件的 LocalStorage payload。
 *
 * v2 设计规范：
 * - 使用扁平化 data 结构查询（O(1)）
 * - 支持预配置和已添加卡片配置
 * - 输出格式兼容 Widget 组件（accounts[].games[].roles[]）
 */

import { WidgetLog } from './WidgetLog';
import { WidgetDataStore, WidgetSlotData, WidgetSlotRef } from '../models/WidgetDataStore';
import { WidgetConfig, WidgetSize, getMaxSlots } from '../models/WidgetConfig';

/**
 * 角色 Payload
 */
export class WidgetRolePayloadItem {
  roleId: string = '';
  nickname: string = '';
  server: string = '';
  rawJson: string = '';
}

/**
 * 游戏 Payload
 */
export class WidgetGamePayloadItem {
  gameId: string = '';
  roles: WidgetRolePayloadItem[] = [];
}

/**
 * 账号 Payload
 */
export class WidgetAccountPayloadItem {
  accountId: string = '';
  accountName: string = '';
  games: WidgetGamePayloadItem[] = [];
}

/**
 * 完整的 Payload 结构
 */
export class WidgetPayloadItem {
  version: number = 1;
  updatedAt: number = 0;
  /** 卡片宽度（单位：vp，来自 FormParam.WIDTH_KEY） */
  widgetWidth: number = 0;
  /** 卡片高度（单位：vp，来自 FormParam.HEIGHT_KEY） */
  widgetHeight: number = 0;
  accounts: WidgetAccountPayloadItem[] = [];
}

/**
 * Widget Payload 构建结果
 */
export class WidgetPayload {
  /** Widget 尺寸 */
  widgetSize: string = '';
  /** 卡片宽度（vp） */
  widgetWidth: number = 0;
  /** 卡片高度（vp） */
  widgetHeight: number = 0;
  /** 账号数据 */
  accounts: WidgetAccountPayloadItem[] = [];

  /**
   * 转换为 LocalStorage 格式的 Record
   */
  toLocalStorageRecord(): Record<string, string> {
    const payloadItem = new WidgetPayloadItem();
    payloadItem.version = 1;
    payloadItem.updatedAt = Math.floor(Date.now() / 1000);
    payloadItem.widgetWidth = this.widgetWidth;
    payloadItem.widgetHeight = this.widgetHeight;
    payloadItem.accounts = this.accounts;

    const payloadJson = JSON.stringify(payloadItem);
    const record: Record<string, string> = {};
    record['payload'] = payloadJson;
    
    WidgetLog.info(`[WIDGET_DEBUG] toLocalStorageRecord: payload json length=${payloadJson.length} widgetWidth=${this.widgetWidth} widgetHeight=${this.widgetHeight}`);
    
    return record;
  }
}

export class WidgetPayloadBuilder {
  /**
   * 构建 Widget Payload
   *
   * @param config Widget 配置（可能为空，表示使用默认行为）
   * @param dataStore 全局数据存储
   * @returns WidgetPayload 构建结果
   */
  static buildPayload(config: WidgetConfig | null, dataStore: WidgetDataStore): WidgetPayload {
    WidgetLog.info(`[WIDGET_DEBUG] buildPayload: start config=${config !== null ? 'has config' : 'null'} dataStore.hasData=${dataStore.hasData}`);
    const payload = new WidgetPayload();

    // 确定尺寸
    const size = config?.size ?? WidgetSize.SIZE_2x2;
    const maxSlots = getMaxSlots(size);
    payload.widgetSize = size;

    // 无数据时返回空 payload
    if (!dataStore.hasData) {
      WidgetLog.info('[WIDGET_DEBUG] buildPayload: no accounts, returning empty payload');
      return payload;
    }

    // 确定要显示的 slot keys
    let slotKeys: string[] = [];

    // 🔬 调试：打印 dataStore.widgets 内容
    const widgetKeys = Object.keys(dataStore.widgets);
    WidgetLog.info(`[WIDGET_DEBUG] buildPayload: dataStore.widgets keys=${widgetKeys.length}`);
    for (let i = 0; i < widgetKeys.length; i++) {
      const key = widgetKeys[i];
      const slots = dataStore.widgets[key];
      WidgetLog.info(`[WIDGET_DEBUG] buildPayload:   widgets[${key}]=${slots.join(',')}`);
    }

    if (config !== null && config.slots.length > 0) {
      // 使用用户配置的 slots
      slotKeys = WidgetPayloadBuilder.extractSlotKeys(config.slots);
      WidgetLog.info(`[WIDGET_DEBUG] buildPayload: ✅ USING USER SLOTS from config count=${slotKeys.length}`);
      for (let i = 0; i < slotKeys.length; i++) {
        WidgetLog.info(`[WIDGET_DEBUG] buildPayload:   userSlot[${i}]=${slotKeys[i]}`);
      }
    } else {
      // 尝试从预配置读取
      const formName = config?.formName ?? '';
      const presetKey = WidgetPayloadBuilder.formNameToPresetKey(formName);
      
      WidgetLog.info(`[WIDGET_DEBUG] buildPayload: config is null or empty, trying preset formName=${formName} presetKey=${presetKey}`);
      
      if (presetKey.length > 0) {
        slotKeys = dataStore.getPresetSlots(presetKey);
        WidgetLog.info(`[WIDGET_DEBUG] buildPayload: getPresetSlots(${presetKey}) returned slots=${slotKeys.length}`);
        for (let i = 0; i < slotKeys.length; i++) {
          WidgetLog.info(`[WIDGET_DEBUG] buildPayload:   presetSlot[${i}]=${slotKeys[i]}`);
        }
      }
      
      // 如果预配置也为空，使用 fallback
      if (slotKeys.length === 0) {
        WidgetLog.warn(`[WIDGET_DEBUG] buildPayload: ⚠️ FALLBACK TO DEFAULT SLOTS`);
        slotKeys = WidgetPayloadBuilder.getDefaultSlotKeys(dataStore, maxSlots, formName);
      }
    }

    // 按 accountId 分组构建 payload
    const accountMap: Map<string, WidgetAccountPayloadItem> = new Map();

    WidgetLog.info(`[WIDGET_DEBUG] buildPayload: processing ${slotKeys.length} slots (max=${maxSlots})`);
    for (let i = 0; i < slotKeys.length && i < maxSlots; i++) {
      const slotKey = slotKeys[i];
      const parts = slotKey.split('/');
      if (parts.length !== 2) {
        WidgetLog.warn(`[WIDGET_DEBUG] buildPayload: invalid slotKey ${slotKey}`);
        continue;
      }
      const accountId = parts[0];
      const roleId = parts[1];

      const slotData = dataStore.getRole(accountId, roleId);
      if (slotData === null) {
        WidgetLog.warn(`[WIDGET_DEBUG] buildPayload: role not found ${slotKey}`);
        continue;
      }

      WidgetLog.info(`[WIDGET_DEBUG] buildPayload: slot[${i}] ${slotKey} gameId=${slotData.gameId} rawJsonLen=${slotData.rawJson.length}`);
      // 🔬 关键调试：打印 rawJson 内容，检查是否包含派遣和洞天宝钱字段
      if (slotData.rawJson.length > 0) {
        WidgetLog.info(`[WIDGET_DEBUG] buildPayload: rawJson preview=${slotData.rawJson.substring(0, Math.min(500, slotData.rawJson.length))}`);
        // 检查关键字段是否存在
        const hasExpedition = slotData.rawJson.includes('max_expedition_num');
        const hasHomeCoin = slotData.rawJson.includes('current_home_coin');
        WidgetLog.info(`[WIDGET_DEBUG] buildPayload: hasExpedition=${hasExpedition} hasHomeCoin=${hasHomeCoin}`);
      }

      // 获取或创建账号 Payload
      let accountPayload = accountMap.get(accountId);
      if (accountPayload === undefined) {
        accountPayload = new WidgetAccountPayloadItem();
        accountPayload.accountId = accountId;
        accountPayload.accountName = dataStore.getAccountName(accountId);
        accountMap.set(accountId, accountPayload);
      }

      // 查找或创建游戏 Payload
      let gamePayload: WidgetGamePayloadItem | undefined;
      for (const g of accountPayload.games) {
        if (g.gameId === slotData.gameId) {
          gamePayload = g;
          break;
        }
      }
      if (gamePayload === undefined) {
        gamePayload = new WidgetGamePayloadItem();
        gamePayload.gameId = slotData.gameId;
        accountPayload.games.push(gamePayload);
      }

      // 添加角色
      const rolePayload = new WidgetRolePayloadItem();
      rolePayload.roleId = roleId;
      rolePayload.nickname = slotData.nickname;
      rolePayload.server = slotData.server;
      rolePayload.rawJson = slotData.rawJson;
      gamePayload.roles.push(rolePayload);
    }

    // 转换为数组
    payload.accounts = WidgetPayloadBuilder.mapToArray(accountMap);
    WidgetLog.info(`[WIDGET_DEBUG] buildPayload: done, payload.accounts=${payload.accounts.length}`);

    return payload;
  }

  /**
   * 从 WidgetSlotRef[] 提取 slotKey[]
   */
  private static extractSlotKeys(slots: WidgetSlotRef[]): string[] {
    const result: string[] = [];
    for (let i = 0; i < slots.length; i++) {
      result.push(slots[i].key);
      WidgetLog.info(`[WIDGET_DEBUG] extractSlotKeys: slot[${i}] key=${slots[i].key} gameId=${slots[i].gameId} accountId=${slots[i].accountId} roleId=${slots[i].roleId}`);
    }
    return result;
  }

  /**
   * formName 转预配置 key
   * widget_1x2_genshin → widget12
   * widget_2x2 → widget22
   */
  private static formNameToPresetKey(formName: string): string {
    if (formName.startsWith('widget_1x2')) {
      return 'widget12';
    } else if (formName.startsWith('widget_2x2')) {
      return 'widget22';
    } else if (formName.startsWith('widget_2x4')) {
      return 'widget24';
    } else if (formName.startsWith('widget_4x4')) {
      return 'widget44';
    }
    return '';
  }

  /**
   * 获取默认 slot keys（第一个账号的前 N 个角色）
   */
  private static getDefaultSlotKeys(dataStore: WidgetDataStore, maxSlots: number, formName: string): string[] {
    const slotKeys: string[] = [];
    const firstAccountId = dataStore.firstAccountId;
    
    if (firstAccountId === null) {
      return slotKeys;
    }

    // 从 formName 提取游戏类型
    const targetGameId = WidgetPayloadBuilder.gameIdFromFormName(formName);
    const filterByGame = targetGameId.length > 0;

    // 获取第一个账号的所有角色
    const allSlotKeys = dataStore.getSlotsByAccount(firstAccountId);
    
    for (let i = 0; i < allSlotKeys.length && slotKeys.length < maxSlots; i++) {
      const slotKey = allSlotKeys[i];
      const slotData = dataStore.getRoleByKey(slotKey);
      
      if (slotData === null) {
        continue;
      }
      
      // 如果需要过滤游戏类型，跳过不匹配的游戏
      if (filterByGame && slotData.gameId !== targetGameId) {
        continue;
      }
      
      slotKeys.push(slotKey);
    }

    return slotKeys;
  }

  /**
   * 从 formName 提取游戏 ID
   */
  private static gameIdFromFormName(formName: string): string {
    if (formName === 'widget_1x2_genshin') {
      return 'genshin';
    } else if (formName === 'widget_1x2_starrail') {
      return 'starrail';
    } else if (formName === 'widget_1x2_zzz') {
      return 'zzz';
    }
    return '';
  }

  /**
   * 为 FormExtension 构建 LocalStorage 数据
   */
  static async buildForFormExtension(
    formId: string,
    size: string,
    dataStore: WidgetDataStore,
  ): Promise<Record<string, string>> {
    // 解析尺寸
    let widgetSize: WidgetSize;
    if (size === '1x2') {
      widgetSize = WidgetSize.SIZE_1x2;
    } else if (size === '2x4') {
      widgetSize = WidgetSize.SIZE_2x4;
    } else if (size === '4x4') {
      widgetSize = WidgetSize.SIZE_4x4;
    } else {
      widgetSize = WidgetSize.SIZE_2x2;
    }

    // 构建默认配置
    const config = new WidgetConfig();
    config.formId = formId;
    config.size = widgetSize;
    config.slots = [];

    // 构建 payload
    const payload = WidgetPayloadBuilder.buildPayload(config, dataStore);
    return payload.toLocalStorageRecord();
  }

  /**
   * 获取所有可用的 slot 选项（用于配置页面）
   */
  static getAllSlotOptions(dataStore: WidgetDataStore): WidgetSlotRef[] {
    return dataStore.getAllSlotRefs();
  }

  /**
   * Map 转数组
   */
  private static mapToArray(map: Map<string, WidgetAccountPayloadItem>): WidgetAccountPayloadItem[] {
    const result: WidgetAccountPayloadItem[] = [];
    const keys = WidgetPayloadBuilder.getMapKeys(map);
    for (let i = 0; i < keys.length; i++) {
      const value = map.get(keys[i]);
      if (value !== undefined) {
        result.push(value);
      }
    }
    return result;
  }

  /**
   * 获取 Map 的所有 key
   */
  private static getMapKeys(map: Map<string, WidgetAccountPayloadItem>): string[] {
    const keys: string[] = [];
    map.forEach((value: WidgetAccountPayloadItem, key: string) => {
      keys.push(key);
    });
    return keys;
  }
}
