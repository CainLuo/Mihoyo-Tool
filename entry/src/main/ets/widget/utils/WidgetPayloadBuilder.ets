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
import { WidgetDataStore, WidgetSlotRef } from '../models/WidgetDataStore';
import { WidgetConfig, WidgetSize, getMaxSlots } from '../models/WidgetConfig';

/**
 * 角色 Payload
 */
export class WidgetRolePayloadItem {
  roleId: string = '';
  nickname: string = '';
  server: string = '';
  rawJson: string = '';
  /** Widget API 原始响应 JSON（绝区零专用，用于 note_list 等额外数据） */
  widgetRawJson: string = '';
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
    const payload = new WidgetPayload();
    const size = config?.size ?? WidgetSize.SIZE_2x2;
    const maxSlots = getMaxSlots(size);
    payload.widgetSize = size;

    // 无数据时返回空 payload
    if (!dataStore.hasData) {
      return payload;
    }

    // 选择要显示的 slots
    const slotKeys = WidgetPayloadBuilder.selectSlotKeys(config, dataStore, maxSlots);

    // 构建 payload
    payload.accounts = WidgetPayloadBuilder.buildAccountPayloads(slotKeys, dataStore, maxSlots);

    return payload;
  }

  // ── 私有方法：Slot 选择 ────────────────────────────────────────────────────────

  /**
   * 统一 slot 选择入口
   *
   * 优先级：用户配置 > 预配置 > 默认 fallback
   */
  private static selectSlotKeys(
    config: WidgetConfig | null,
    dataStore: WidgetDataStore,
    maxSlots: number
  ): string[] {
    // 1. 用户配置的 slots
    if (config !== null && config.slots.length > 0) {
      return WidgetPayloadBuilder.extractSlotKeys(config.slots);
    }

    // 2. 预配置的 slots
    const formName = config?.formName ?? '';
    const presetKey = WidgetPayloadBuilder.formNameToPresetKey(formName);
    if (presetKey.length > 0) {
      const presetSlots = dataStore.getPresetSlots(presetKey);
      if (presetSlots.length > 0) {
        return presetSlots;
      }
    }

    // 3. 默认 fallback
    return WidgetPayloadBuilder.getDefaultSlotKeys(dataStore, maxSlots, formName);
  }

  /**
   * 从 WidgetSlotRef[] 提取 slotKey[]
   */
  private static extractSlotKeys(slots: WidgetSlotRef[]): string[] {
    const result: string[] = [];
    for (let i = 0; i < slots.length; i++) {
      result.push(slots[i].key);
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

  // ── 私有方法：Payload 构建 ──────────────────────────────────────────────────────

  /**
   * 构建账号 Payload 数组
   */
  private static buildAccountPayloads(
    slotKeys: string[],
    dataStore: WidgetDataStore,
    maxSlots: number
  ): WidgetAccountPayloadItem[] {
    const accountMap: Map<string, WidgetAccountPayloadItem> = new Map();

    for (let i = 0; i < slotKeys.length && i < maxSlots; i++) {
      const slotKey = slotKeys[i];
      const parts = slotKey.split('/');
      if (parts.length !== 2) {
        continue;
      }
      const accountId = parts[0];
      const roleId = parts[1];

      const slotData = dataStore.getRole(accountId, roleId);
      if (slotData === null) {
        continue;
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
      rolePayload.widgetRawJson = slotData.widgetRawJson;
      gamePayload.roles.push(rolePayload);
    }

    return WidgetPayloadBuilder.mapToArray(accountMap);
  }

  // ── 公开方法：辅助工具 ──────────────────────────────────────────────────────────

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

  // ── 私有方法：工具函数 ──────────────────────────────────────────────────────────

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
