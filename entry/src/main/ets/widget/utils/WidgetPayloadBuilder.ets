/**
 * WidgetPayloadBuilder.ets — Widget Payload 构建器
 *
 * 从 WidgetDataStore + WidgetConfig 构建传递给 Widget 组件的 LocalStorage payload。
 *
 * 职责：
 * 1. 根据 Widget 尺寸确定 slots 数量
 * 2. 从 WidgetConfig 读取用户选择的 slots，或使用默认行为
 * 3. 从 WidgetDataStore 提取对应的 rawJson
 * 4. 构建符合 Widget 组件预期的 LocalStorage 格式
 */

import { Logger } from 'core';
import { WidgetDataStore } from '../models/WidgetDataStore';
import { WidgetConfig, WidgetSize, getMaxSlots } from '../models/WidgetConfig';
import { WidgetSlotRef } from '../models/WidgetDataStore';

const TAG = 'WidgetPayloadBuilder';

/**
 * 单个 Slot 的完整数据（含 rawJson）
 */
export class WidgetSlotData {
  /** 米游社账号 UID */
  accountId: string = '';
  /** 账号昵称 */
  accountName: string = '';
  /** 游戏 ID */
  gameId: string = '';
  /** 游戏内 UID */
  roleId: string = '';
  /** 游戏内昵称 */
  nickname: string = '';
  /** 服务器大区标识 */
  server: string = '';
  /** API 原始响应 JSON 字符串 */
  rawJson: string = '';

  toJson(): string {
    return JSON.stringify({
      accountId: this.accountId,
      accountName: this.accountName,
      gameId: this.gameId,
      roleId: this.roleId,
      nickname: this.nickname,
      server: this.server,
      rawJson: this.rawJson,
    });
  }
}

/**
 * Widget Payload 构建结果
 */
export class WidgetPayload {
  /** Widget 尺寸 */
  widgetSize: string = '';
  /** Slot 数量 */
  slotCount: number = 0;
  /** Slot 数据数组 */
  slots: WidgetSlotData[] = [];

  /**
   * 转换为 LocalStorage 格式的 Record
   *
   * 输出格式：
   * {
   *   "widgetSize": "2x2",
   *   "slotCount": "2",
   *   "slot0Json": "{...}",
   *   "slot0GameId": "genshin",
   *   "slot1Json": "{...}",
   *   "slot1GameId": "genshin"
   * }
   */
  toLocalStorageRecord(): Record<string, string> {
    const record: Record<string, string> = {};
    record['widgetSize'] = this.widgetSize;
    record['slotCount'] = `${this.slotCount}`;

    for (let i = 0; i < this.slots.length; i++) {
      const slot = this.slots[i];
      record[`slot${i}Json`] = slot.toJson();
      record[`slot${i}GameId`] = slot.gameId;
    }

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

    // 确定尺寸和 slot 数量
    const size = config?.size ?? WidgetSize.SIZE_2x2;
    const maxSlots = getMaxSlots(size);
    payload.widgetSize = size;
    payload.slotCount = 0;

    // 无数据时返回空 payload
    if (dataStore.accounts.length === 0) {
      Logger.info(TAG, 'buildPayload: no data in store');
      return payload;
    }

    // 确定要显示的 slots
    let slots: WidgetSlotRef[] = [];

    if (config !== null && config.slots.length > 0) {
      // 使用用户配置的 slots
      slots = config.slots;
    } else {
      // 默认行为：取第一个账号的前 N 个角色
      slots = WidgetPayloadBuilder.getDefaultSlots(dataStore, maxSlots);
    }

    // 从 dataStore 提取每个 slot 的完整数据
    for (let i = 0; i < slots.length && i < maxSlots; i++) {
      const slotRef = slots[i];
      const role = dataStore.getRole(slotRef.accountId, slotRef.gameId, slotRef.roleId);

      if (role !== null) {
        const slotData = new WidgetSlotData();
        slotData.accountId = slotRef.accountId;
        slotData.accountName = slotRef.accountName;
        slotData.gameId = slotRef.gameId;
        slotData.roleId = slotRef.roleId;
        slotData.nickname = role.nickname;
        slotData.server = role.server;
        slotData.rawJson = role.rawJson;
        payload.slots.push(slotData);
      }
    }

    payload.slotCount = payload.slots.length;
    Logger.info(TAG, `buildPayload: size=${size}, slots=${payload.slotCount}`);

    return payload;
  }

  /**
   * 获取默认 slots（第一个账号的前 N 个角色）
   */
  private static getDefaultSlots(dataStore: WidgetDataStore, maxSlots: number): WidgetSlotRef[] {
    const slots: WidgetSlotRef[] = [];
    const firstAccount = dataStore.firstAccount;

    if (firstAccount === null) {
      return slots;
    }

    // 遍历第一个账号的所有游戏和角色
    for (let i = 0; i < firstAccount.games.length && slots.length < maxSlots; i++) {
      const game = firstAccount.games[i];
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
