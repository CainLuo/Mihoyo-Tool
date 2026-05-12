/**
 * WidgetPayloadBuilder.ets — Widget Payload 构建器
 *
 * 从 WidgetDataStore + WidgetConfig 构建传递给 Widget 组件的 LocalStorage payload。
 *
 * v1.1 设计规范（design.md）：
 * - 输出单一 JSON payload，包含完整的 accounts 结构
 * - 每个 account 包含 games 数组，每个 game 包含 roles 数组
 * - 每个 role 包含 roleId、nickname、server、rawJson
 */

import { Logger } from 'core';
import { WidgetDataStore } from '../models/WidgetDataStore';
import { WidgetConfig, WidgetSize, getMaxSlots } from '../models/WidgetConfig';
import { WidgetSlotRef } from '../models/WidgetDataStore';

const TAG = 'WIDGET';

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
  accounts: WidgetAccountPayloadItem[] = [];
}

/**
 * Widget Payload 构建结果
 */
export class WidgetPayload {
  /** Widget 尺寸 */
  widgetSize: string = '';
  /** 账号数据 */
  accounts: WidgetAccountPayloadItem[] = [];

  /**
   * 转换为 LocalStorage 格式的 Record
   *
   * 输出格式（符合 design.md 规范）：
   * {
   *   "payload": "{\"version\":1,\"updatedAt\":1715040000,\"accounts\":[...]}"
   * }
   */
  toLocalStorageRecord(): Record<string, string> {
    const payloadItem = new WidgetPayloadItem();
    payloadItem.version = 1;
    payloadItem.updatedAt = Math.floor(Date.now() / 1000);
    payloadItem.accounts = this.accounts;

    const payloadJson = JSON.stringify(payloadItem);
    const record: Record<string, string> = {};
    record['payload'] = payloadJson;
    
    Logger.info(TAG, `[WIDGET_DEBUG] toLocalStorageRecord: payload json length=${payloadJson.length}`);
    Logger.info(TAG, `[WIDGET_DEBUG] toLocalStorageRecord: payload preview (first 500 chars)=${payloadJson.substring(0, 500)}`);
    
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
    Logger.info(TAG, `[WIDGET_DEBUG] buildPayload: start config=${config !== null ? 'has config' : 'null'} dataStore.accounts=${dataStore.accounts.length}`);
    const payload = new WidgetPayload();

    // 确定尺寸
    const size = config?.size ?? WidgetSize.SIZE_2x2;
    const maxSlots = getMaxSlots(size);
    payload.widgetSize = size;

    // 无数据时返回空 payload
    if (dataStore.accounts.length === 0) {
      Logger.info(TAG, '[WIDGET_DEBUG] buildPayload: no accounts, returning empty payload');
      return payload;
    }

    // 确定要显示的 slots
    let slots: WidgetSlotRef[] = [];

    if (config !== null && config.slots.length > 0) {
      // 使用用户配置的 slots
      slots = config.slots;
    } else {
      // 默认行为：取第一个账号的前 N 个角色（根据 formName 过滤游戏类型）
      const formName = config?.formName ?? '';
      slots = WidgetPayloadBuilder.getDefaultSlots(dataStore, maxSlots, formName);
    }

    // 按 accountId 分组 slots
    const accountMap: Map<string, WidgetAccountPayloadItem> = new Map();

    Logger.info(TAG, `[WIDGET_DEBUG] buildPayload: processing ${slots.length} slots (max=${maxSlots})`);
    for (let i = 0; i < slots.length && i < maxSlots; i++) {
      const slotRef = slots[i];
      const role = dataStore.getRole(slotRef.accountId, slotRef.gameId, slotRef.roleId);

      if (role === null) {
        Logger.warn(TAG, `[WIDGET_DEBUG] buildPayload: role not found ${slotRef.accountId}/${slotRef.gameId}/${slotRef.roleId}`);
        continue;
      }

      Logger.info(TAG, `[WIDGET_DEBUG] buildPayload: slot[${i}] accountId=${slotRef.accountId} gameId=${slotRef.gameId} roleId=${slotRef.roleId} rawJsonLen=${role.rawJson.length}`);

      // 获取或创建账号 Payload
      let accountPayload = accountMap.get(slotRef.accountId);
      if (accountPayload === undefined) {
        accountPayload = new WidgetAccountPayloadItem();
        accountPayload.accountId = slotRef.accountId;
        accountPayload.accountName = slotRef.accountName;
        accountMap.set(slotRef.accountId, accountPayload);
      }

      // 查找或创建游戏 Payload
      let gamePayload: WidgetGamePayloadItem | undefined;
      for (const g of accountPayload.games) {
        if (g.gameId === slotRef.gameId) {
          gamePayload = g;
          break;
        }
      }
      if (gamePayload === undefined) {
        gamePayload = new WidgetGamePayloadItem();
        gamePayload.gameId = slotRef.gameId;
        accountPayload.games.push(gamePayload);
      }

      // 添加角色
      const rolePayload = new WidgetRolePayloadItem();
      rolePayload.roleId = slotRef.roleId;
      rolePayload.nickname = role.nickname;
      rolePayload.server = role.server;
      rolePayload.rawJson = role.rawJson;
      gamePayload.roles.push(rolePayload);
    }

    // 转换为数组
    payload.accounts = Array.from(accountMap.values());
    Logger.info(TAG, `[WIDGET_DEBUG] buildPayload: done, payload.accounts=${payload.accounts.length}`);

    return payload;
  }

  /**
   * 获取默认 slots（第一个账号的前 N 个角色）
   *
   * 对于 1x2 模板，根据 formName 过滤游戏类型：
   * - 'widget_1x2_genshin' → 只返回原神角色
   * - 'widget_1x2_starrail' → 只返回星铁角色
   * - 'widget_1x2_zzz' → 只返回绝区零角色
   */
  private static getDefaultSlots(dataStore: WidgetDataStore, maxSlots: number, formName: string): WidgetSlotRef[] {
    const slots: WidgetSlotRef[] = [];
    const firstAccount = dataStore.firstAccount;

    if (firstAccount === null) {
      return slots;
    }

    // 从 formName 提取游戏类型
    const targetGameId = WidgetPayloadBuilder.gameIdFromFormName(formName);
    const filterByGame = targetGameId.length > 0;

    // 遍历第一个账号的所有游戏和角色
    for (let i = 0; i < firstAccount.games.length && slots.length < maxSlots; i++) {
      const game = firstAccount.games[i];
      
      // 如果需要过滤游戏类型，跳过不匹配的游戏
      if (filterByGame && game.gameId !== targetGameId) {
        continue;
      }
      
      for (let j = 0; j < game.roles.length && slots.length < maxSlots; j++) {
        const role = game.roles[j];
        const slot = new WidgetSlotRef();
        slot.accountId = firstAccount.accountId;
        slot.accountName = firstAccount.accountName;
        slot.gameId = game.gameId;
        slot.roleId = role.roleId;
        slot.nickname = role.nickname;
        slot.server = role.server;
        slots.push(slot);
      }
    }

    return slots;
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
   *
   * @param formId Widget 实例 ID
   * @param size Widget 尺寸字符串
   * @param dataStore 全局数据存储
   * @returns LocalStorage 格式的 Record
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

    // 构建默认配置（FormExtension 不读取用户配置，直接使用默认行为）
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
   *
   * 返回格式化的列表，包含账号名、游戏名、角色名等信息
   */
  static getAllSlotOptions(dataStore: WidgetDataStore): WidgetSlotRef[] {
    return dataStore.getAllSlots();
  }
}
