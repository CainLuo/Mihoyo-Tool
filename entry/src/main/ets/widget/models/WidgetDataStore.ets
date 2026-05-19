/**
 * WidgetDataStore.ets — Widget 全局数据存储模型（v2）
 *
 * 存储结构（扁平化设计）：
 * {
 *   "version": 2,
 *   "updatedAt": 1779012632,
 *   "data": {
 *     "{accountId}": {
 *       "accountName": "CainLuo",
 *       "slots": {
 *         "{roleId}": { "gameId": "genshin", "nickname": "...", "rawJson": "..." }
 *       }
 *     }
 *   },
 *   "widgets": {
 *     "widget12": ["accountId/roleId"],
 *     "widget22": ["accountId/roleId", "accountId/roleId"],
 *     "form_12345678": ["accountId/roleId"]
 *   }
 * }
 *
 * 关键设计：
 * - data.{accountId}.slots.{roleId} 扁平存储，支持 O(1) 查询
 * - widgets 区分「预配置」（widget12/widget22等）和「已添加卡片」（form_xxx）
 * - 使用 "accountId/roleId" 作为全局唯一的 slot 标识
 */

import { hilog } from '@kit.PerformanceAnalysisKit';

const TAG = 'WIDGET';
const DOMAIN = 0xFF00;

// ── JSON 结构接口定义 ─────────────────────────────────────────────

/** Slot JSON 结构 */
interface WidgetSlotDataJson {
  gameId: string;
  nickname: string;
  server: string;
  serverName: string;
  level: number;
  rawJson: string;
}

/** Account JSON 结构 */
interface WidgetAccountDataJson {
  accountName: string;
  slots: Record<string, WidgetSlotDataJson>;
}

/** WidgetDataStore JSON 结构 */
interface WidgetDataStoreJson {
  version: number;
  updatedAt: number;
  data: Record<string, WidgetAccountDataJson>;
  widgets: Record<string, string[]>;
}

/** WidgetSlotRef JSON 结构 */
export interface WidgetSlotRefJson {
  accountId: string;
  accountName: string;
  gameId: string;
  roleId: string;
  nickname: string;
  server: string;
}

// ── 数据模型类 ─────────────────────────────────────────────────────

/**
 * 角色 Slot 数据（存储在 data.{accountId}.slots.{roleId} 中）
 */
export class WidgetSlotData {
  /** 游戏 ID（genshin/starrail/zzz） */
  gameId: string = '';
  /** 游戏内昵称 */
  nickname: string = '';
  /** 服务器大区标识（cn_gf01/prod_gf_cn） */
  server: string = '';
  /** 服务器名称（天空岛/星穹列车） */
  serverName: string = '';
  /** 冒险等级 */
  level: number = 0;
  /** DailyNote API 原始响应 JSON */
  rawJson: string = '';

  toJson(): WidgetSlotDataJson {
    const obj: WidgetSlotDataJson = {
      gameId: this.gameId,
      nickname: this.nickname,
      server: this.server,
      serverName: this.serverName,
      level: this.level,
      rawJson: this.rawJson,
    };
    return obj;
  }

  static fromJson(obj: WidgetSlotDataJson): WidgetSlotData {
    const d = new WidgetSlotData();
    d.gameId = obj.gameId;
    d.nickname = obj.nickname;
    d.server = obj.server;
    d.serverName = obj.serverName;
    d.level = obj.level;
    d.rawJson = obj.rawJson;
    return d;
  }
}

/**
 * 账号数据（存储在 data.{accountId} 中）
 */
export class WidgetAccountDataV2 {
  accountName: string = '';
  /** 角色列表，key 为 roleId */
  slots: Record<string, WidgetSlotData> = {};

  toJson(): WidgetAccountDataJson {
    const slotsJson: Record<string, WidgetSlotDataJson> = {};
    const keys = Object.keys(this.slots);
    for (let i = 0; i < keys.length; i++) {
      const roleId = keys[i];
      slotsJson[roleId] = this.slots[roleId].toJson();
    }
    const obj: WidgetAccountDataJson = {
      accountName: this.accountName,
      slots: slotsJson,
    };
    return obj;
  }

  static fromJson(obj: WidgetAccountDataJson): WidgetAccountDataV2 {
    const d = new WidgetAccountDataV2();
    d.accountName = obj.accountName;
    if (obj.slots !== undefined && obj.slots !== null) {
      const keys = Object.keys(obj.slots);
      for (let i = 0; i < keys.length; i++) {
        const roleId = keys[i];
        d.slots[roleId] = WidgetSlotData.fromJson(obj.slots[roleId]);
      }
    }
    return d;
  }
}

/**
 * Widget Slot 引用（三元组）
 * 用于配置页面选择和 widgets 配置存储
 */
export class WidgetSlotRef {
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

  toJson(): WidgetSlotRefJson {
    const obj: WidgetSlotRefJson = {
      accountId: this.accountId,
      accountName: this.accountName,
      gameId: this.gameId,
      roleId: this.roleId,
      nickname: this.nickname,
      server: this.server,
    };
    return obj;
  }

  static fromJson(obj: WidgetSlotRefJson): WidgetSlotRef {
    const d = new WidgetSlotRef();
    d.accountId = obj.accountId;
    d.accountName = obj.accountName;
    d.gameId = obj.gameId;
    d.roleId = obj.roleId;
    d.nickname = obj.nickname;
    d.server = obj.server;
    return d;
  }

  /**
   * 唯一标识符：accountId/roleId
   */
  get key(): string {
    return `${this.accountId}/${this.roleId}`;
  }
}

/**
 * Widget 全局数据存储（v2）
 */
export class WidgetDataStore {
  /** 数据版本号 */
  version: number = 2;
  /** 数据更新时间戳（秒） */
  updatedAt: number = 0;
  /** 所有账号数据，key 为 accountId */
  data: Record<string, WidgetAccountDataV2> = {};
  /** 各尺寸卡片的配置 */
  widgets: Record<string, string[]> = {};

  /**
   * 序列化为 JSON 字符串
   */
  toJson(): string {
    const dataJson: Record<string, WidgetAccountDataJson> = {};
    const accountIds = Object.keys(this.data);
    for (let i = 0; i < accountIds.length; i++) {
      const accountId = accountIds[i];
      dataJson[accountId] = this.data[accountId].toJson();
    }

    const obj: WidgetDataStoreJson = {
      version: this.version,
      updatedAt: this.updatedAt,
      data: dataJson,
      widgets: this.widgets,
    };
    return JSON.stringify(obj);
  }

  /**
   * 从 JSON 字符串反序列化
   */
  static fromJson(json: string): WidgetDataStore {
    const d = new WidgetDataStore();
    if (json.length === 0) {
      return d;
    }
    try {
      const obj: WidgetDataStoreJson = JSON.parse(json) as WidgetDataStoreJson;
      d.version = obj.version;
      d.updatedAt = obj.updatedAt;
      if (obj.data !== undefined && obj.data !== null) {
        const accountIds = Object.keys(obj.data);
        for (let i = 0; i < accountIds.length; i++) {
          const accountId = accountIds[i];
          d.data[accountId] = WidgetAccountDataV2.fromJson(obj.data[accountId]);
        }
      }
      if (obj.widgets !== undefined && obj.widgets !== null) {
        d.widgets = obj.widgets;
      }
    } catch (e) {
      hilog.error(DOMAIN, TAG, `[WIDGET_DEBUG] WidgetDataStore.fromJson failed: ${JSON.stringify(e)}`);
    }
    return d;
  }

  /**
   * 根据 accountId/roleId 获取角色数据（O(1) 查询）
   */
  getRole(accountId: string, roleId: string): WidgetSlotData | null {
    const account = this.data[accountId];
    if (account === undefined) {
      return null;
    }
    const slot = account.slots[roleId];
    if (slot === undefined) {
      return null;
    }
    return slot;
  }

  /**
   * 根据 slotKey（accountId/roleId）获取角色数据
   */
  getRoleByKey(slotKey: string): WidgetSlotData | null {
    const parts = slotKey.split('/');
    if (parts.length !== 2) {
      return null;
    }
    return this.getRole(parts[0], parts[1]);
  }

  /**
   * 获取账号名称
   */
  getAccountName(accountId: string): string {
    const account = this.data[accountId];
    if (account === undefined) {
      return '';
    }
    return account.accountName;
  }

  /**
   * 获取第一个账号 ID（用于 fallback）
   */
  get firstAccountId(): string | null {
    const keys = Object.keys(this.data);
    if (keys.length > 0) {
      return keys[0];
    }
    return null;
  }

  /**
   * 获取第一个账号的第一个角色（用于 fallback）
   */
  get firstSlot(): WidgetSlotData | null {
    const accountId = this.firstAccountId;
    if (accountId === null) {
      return null;
    }
    const account = this.data[accountId];
    const roleIds = Object.keys(account.slots);
    if (roleIds.length > 0) {
      return account.slots[roleIds[0]];
    }
    return null;
  }

  /**
   * 获取账号下的所有角色 key 列表
   */
  getSlotsByAccount(accountId: string): string[] {
    const account = this.data[accountId];
    if (account === undefined) {
      return [];
    }
    const roleIds = Object.keys(account.slots);
    const result: string[] = [];
    for (let i = 0; i < roleIds.length; i++) {
      result.push(`${accountId}/${roleIds[i]}`);
    }
    return result;
  }

  /**
   * 获取所有可用的 slot 列表（用于配置页面）
   */
  getAllSlotRefs(): WidgetSlotRef[] {
    const result: WidgetSlotRef[] = [];
    const accountIds = Object.keys(this.data);
    for (let i = 0; i < accountIds.length; i++) {
      const accountId = accountIds[i];
      const account = this.data[accountId];
      const roleIds = Object.keys(account.slots);
      for (let j = 0; j < roleIds.length; j++) {
        const roleId = roleIds[j];
        const slot = account.slots[roleId];
        const ref = new WidgetSlotRef();
        ref.accountId = accountId;
        ref.accountName = account.accountName;
        ref.gameId = slot.gameId;
        ref.roleId = roleId;
        ref.nickname = slot.nickname;
        ref.server = slot.server;
        result.push(ref);
      }
    }
    return result;
  }

  /**
   * 检查是否有数据
   */
  get hasData(): boolean {
    return Object.keys(this.data).length > 0;
  }

  /**
   * 获取预配置的 slots（如 widget12、widget22）
   */
  getPresetSlots(widgetName: string): string[] {
    const slots = this.widgets[widgetName];
    if (slots === undefined) {
      return [];
    }
    return slots;
  }

  /**
   * 设置预配置的 slots
   */
  setPresetSlots(widgetName: string, slots: string[]): void {
    this.widgets[widgetName] = slots;
  }

  /**
   * 获取已添加卡片的配置
   */
  getFormConfig(formId: string): string[] {
    const key = `form_${formId}`;
    return this.getPresetSlots(key);
  }

  /**
   * 设置已添加卡片的配置
   */
  setFormConfig(formId: string, slots: string[]): void {
    const key = `form_${formId}`;
    this.widgets[key] = slots;
  }

  /**
   * 更新指定角色的 rawJson
   */
  updateRoleRawJson(accountId: string, roleId: string, rawJson: string): void {
    const slot = this.getRole(accountId, roleId);
    if (slot !== null) {
      slot.rawJson = rawJson;
    }
  }
}
