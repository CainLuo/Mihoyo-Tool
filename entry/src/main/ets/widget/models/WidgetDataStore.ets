/**
 * WidgetDataStore.ets — Widget 全局数据存储模型
 *
 * 所有 Widget 共享的一份数据，包含所有账号所有游戏角色的便签 rawJson。
 * 存储位置：Preferences 文件名 widget_data_store，Key global_data
 */

import { WidgetAccount } from './WidgetAccount';
import { WidgetGame } from './WidgetGame';
import { WidgetRole } from './WidgetRole';

/** WidgetDataStore JSON 结构 */
interface WidgetDataStoreJson {
  version: number;
  updatedAt: number;
  accounts: Object[];
}

/** WidgetSlotRef JSON 结构 */
interface WidgetSlotRefJson {
  accountId: string;
  accountName: string;
  gameId: string;
  roleId: string;
  nickname: string;
  server: string;
}

/**
 * Widget 全局数据存储
 */
export class WidgetDataStore {
  /** 数据版本号，用于迁移 */
  version: number = 1;
  /** 数据更新时间戳（秒） */
  updatedAt: number = 0;
  /** 账号列表 */
  accounts: WidgetAccount[] = [];

  toJson(): string {
    const obj: WidgetDataStoreJson = {
      version: this.version,
      updatedAt: this.updatedAt,
      accounts: this.accounts.map((a) => a.toJson()),
    };
    return JSON.stringify(obj);
  }

  static fromJson(json: string): WidgetDataStore {
    const d = new WidgetDataStore();
    if (json.length === 0) {
      return d;
    }
    try {
      const obj = JSON.parse(json) as Record<string, Object>;
      if (obj['version'] !== undefined) { d.version = obj['version'] as number; }
      if (obj['updatedAt'] !== undefined) { d.updatedAt = obj['updatedAt'] as number; }
      if (obj['accounts'] !== undefined) {
        const accountsArr = obj['accounts'] as Object[];
        for (let i = 0; i < accountsArr.length; i++) {
          d.accounts.push(WidgetAccount.fromJson(accountsArr[i] as Record<string, Object>));
        }
      }
    } catch (_e) {
      // 解析失败返回默认值，不崩溃
    }
    return d;
  }

  /**
   * 根据 accountId 获取账号数据
   */
  getAccount(accountId: string): WidgetAccount | null {
    for (let i = 0; i < this.accounts.length; i++) {
      if (this.accounts[i].accountId === accountId) {
        return this.accounts[i];
      }
    }
    return null;
  }

  /**
   * 根据三元组获取角色数据
   */
  getRole(accountId: string, gameId: string, roleId: string): WidgetRole | null {
    const account = this.getAccount(accountId);
    if (account === null) {
      return null;
    }
    const game = account.getGame(gameId);
    if (game === null) {
      return null;
    }
    for (let i = 0; i < game.roles.length; i++) {
      if (game.roles[i].roleId === roleId) {
        return game.roles[i];
      }
    }
    return null;
  }

  /**
   * 获取第一个账号（用于默认显示）
   */
  get firstAccount(): WidgetAccount | null {
    if (this.accounts.length > 0) {
      return this.accounts[0];
    }
    return null;
  }

  /**
   * 获取所有可用的 slot 列表（用于配置页面）
   */
  getAllSlots(): WidgetSlotRef[] {
    const slots: WidgetSlotRef[] = [];
    for (let i = 0; i < this.accounts.length; i++) {
      const account = this.accounts[i];
      for (let j = 0; j < account.games.length; j++) {
        const game = account.games[j];
        for (let k = 0; k < game.roles.length; k++) {
          const role = game.roles[k];
          const slot = new WidgetSlotRef();
          slot.accountId = account.accountId;
          slot.accountName = account.accountName;
          slot.gameId = game.gameId;
          slot.roleId = role.roleId;
          slot.nickname = role.nickname;
          slot.server = role.server;
          slots.push(slot);
        }
      }
    }
    return slots;
  }

  /**
   * 更新指定角色的 rawJson
   */
  updateRoleRawJson(accountId: string, gameId: string, roleId: string, rawJson: string): void {
    const role = this.getRole(accountId, gameId, roleId);
    if (role !== null) {
      role.rawJson = rawJson;
    }
  }
}

/**
 * Widget Slot 引用（三元组）
 * 用于配置页面选择和 WidgetConfig 存储
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

  static fromJson(obj: Record<string, Object>): WidgetSlotRef {
    const d = new WidgetSlotRef();
    if (obj['accountId'] !== undefined) { d.accountId = obj['accountId'] as string; }
    if (obj['accountName'] !== undefined) { d.accountName = obj['accountName'] as string; }
    if (obj['gameId'] !== undefined) { d.gameId = obj['gameId'] as string; }
    if (obj['roleId'] !== undefined) { d.roleId = obj['roleId'] as string; }
    if (obj['nickname'] !== undefined) { d.nickname = obj['nickname'] as string; }
    if (obj['server'] !== undefined) { d.server = obj['server'] as string; }
    return d;
  }

  /**
   * 唯一标识符：accountId_gameId_roleId
   */
  get key(): string {
    return `${this.accountId}_${this.gameId}_${this.roleId}`;
  }
}
