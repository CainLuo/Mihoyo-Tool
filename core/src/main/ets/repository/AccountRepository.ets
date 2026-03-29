/**
 * AccountRepository.ets
 *
 * 账号 + 游戏角色数据 Repository。
 * 封装 account_table 和 game_role_table 的所有读写操作。
 *
 * 使用示例（entry 模块）：
 *   import { AccountRepository, AccountRow, GameRoleRow } from 'core';
 *   const accounts = await AccountRepository.findAllAccounts();
 *   const roles = await AccountRepository.findRolesByAccountId(1);
 */

import { relationalStore } from '@kit.ArkData';
import { RdbManager } from '../database/RdbManager';

// ─── 数据模型 ────────────────────────────────────────────────────

/** account_table 行模型 */
export class AccountRow {
  id: number = 0;
  username: string = '';
  cookie: string = '';
  isActive: boolean = false;
  createTime: number = 0;
  updateTime: number = 0;
  /** 米游社昵称（来自 bbs 账号详情接口） */
  nickname: string = '';
  /** 米游社头像 URL */
  avatarUrl: string = '';
}

/** game_role_table 行模型 */
export class GameRoleRow {
  id: number = 0;
  accountId: number = 0;
  gameId: string = '';
  roleId: string = '';
  nickname: string = '';
  level: number = 0;
  server: string = '';
  /** 游戏背景图 URL（来自 background_image_v2） */
  bgImageUrl: string = '';
  /** 游戏内统计数据 JSON 字符串（来自 data 字段，格式：[{name,value}]） */
  statsJson: string = '';
}

/** 账号 + 角色列表的配对结构（替代 Map，规避 ArkTS Map 迭代限制） */
export class AccountWithRoles {
  account: AccountRow = new AccountRow();
  roles: GameRoleRow[] = [];

  constructor(account: AccountRow, roles: GameRoleRow[]) {
    this.account = account;
    this.roles = roles;
  }
}

export class AccountRepository {

  // ── 账号 CRUD ────────────────────────────────────────────────

  /** 查询所有账号 */
  static async findAllAccounts(): Promise<AccountRow[]> {
    try {
      const predicates = new relationalStore.RdbPredicates('account_table');
      const rs = await RdbManager.query(predicates);
      return AccountRepository.toAccountList(rs);
    } catch (error) {
      const msg = error instanceof Error ? error.message : `${error}`;
      throw new Error(`AccountRepository.findAllAccounts failed: ${msg}`);
    }
  }

  /** 查询当前激活账号（is_active = 1） */
  static async findActiveAccount(): Promise<AccountRow | null> {
    try {
      const predicates = new relationalStore.RdbPredicates('account_table')
        .equalTo('is_active', 1);
      const rs = await RdbManager.query(predicates);
      if (!rs.goToFirstRow()) {
        rs.close();
        return null;
      }
      const row = AccountRepository.readAccountRow(rs);
      rs.close();
      return row;
    } catch (error) {
      const msg = error instanceof Error ? error.message : `${error}`;
      throw new Error(`AccountRepository.findActiveAccount failed: ${msg}`);
    }
  }

  /** 新增账号，返回新行 id */
  static async insertAccount(username: string, cookie: string): Promise<number> {
    try {
      const now = Math.floor(Date.now() / 1000);
      const values: relationalStore.ValuesBucket = {};
      values['username'] = username;
      values['cookie'] = cookie;
      values['is_active'] = 0;
      values['create_time'] = now;
      values['update_time'] = now;
      return await RdbManager.insert('account_table', values);
    } catch (error) {
      const msg = error instanceof Error ? error.message : `${error}`;
      throw new Error(`AccountRepository.insertAccount failed: ${msg}`);
    }
  }

  /** 更新账号 nickname 和 avatarUrl */
  static async updateNicknameAndAvatar(accountId: number, nickname: string, avatarUrl: string): Promise<void> {
    try {
      const values: relationalStore.ValuesBucket = {};
      values['nickname'] = nickname;
      values['avatar_url'] = avatarUrl;
      const predicates = new relationalStore.RdbPredicates('account_table').equalTo('id', accountId);
      await RdbManager.update(values, predicates);
    } catch (error) {
      const msg = error instanceof Error ? error.message : `${error}`;
      throw new Error(`AccountRepository.updateNicknameAndAvatar failed: ${msg}`);
    }
  }

  /** 更新账号 cookie */
  static async updateCookie(accountId: number, cookie: string): Promise<void> {
    try {
      const now = Math.floor(Date.now() / 1000);
      const values: relationalStore.ValuesBucket = {};
      values['cookie'] = cookie;
      values['update_time'] = now;
      const predicates = new relationalStore.RdbPredicates('account_table')
        .equalTo('id', accountId);
      await RdbManager.update(values, predicates);
    } catch (error) {
      const msg = error instanceof Error ? error.message : `${error}`;
      throw new Error(`AccountRepository.updateCookie failed: ${msg}`);
    }
  }

  /** 设置激活账号（先全部置 0，再激活指定 id） */
  static async setActiveAccount(accountId: number): Promise<void> {
    try {
      const clearValues: relationalStore.ValuesBucket = {};
      clearValues['is_active'] = 0;
      await RdbManager.update(clearValues, new relationalStore.RdbPredicates('account_table'));

      const setValues: relationalStore.ValuesBucket = {};
      setValues['is_active'] = 1;
      const predicates = new relationalStore.RdbPredicates('account_table')
        .equalTo('id', accountId);
      await RdbManager.update(setValues, predicates);
    } catch (error) {
      const msg = error instanceof Error ? error.message : `${error}`;
      throw new Error(`AccountRepository.setActiveAccount failed: ${msg}`);
    }
  }

  /** 删除账号（同时删除其所有游戏角色） */
  static async deleteAccount(accountId: number): Promise<void> {
    try {
      await RdbManager.delete(
        new relationalStore.RdbPredicates('game_role_table').equalTo('account_id', accountId)
      );
      await RdbManager.delete(
        new relationalStore.RdbPredicates('account_table').equalTo('id', accountId)
      );
    } catch (error) {
      const msg = error instanceof Error ? error.message : `${error}`;
      throw new Error(`AccountRepository.deleteAccount failed: ${msg}`);
    }
  }

  // ── 游戏角色 CRUD ────────────────────────────────────────────

  /** 查询指定账号下的所有游戏角色 */
  static async findRolesByAccountId(accountId: number): Promise<GameRoleRow[]> {
    try {
      const predicates = new relationalStore.RdbPredicates('game_role_table')
        .equalTo('account_id', accountId);
      const rs = await RdbManager.query(predicates);
      return AccountRepository.toRoleList(rs);
    } catch (error) {
      const msg = error instanceof Error ? error.message : `${error}`;
      throw new Error(`AccountRepository.findRolesByAccountId failed: ${msg}`);
    }
  }

  /** 查询所有账号及其游戏角色（一次性加载首页所需数据） */
  static async findAllAccountsWithRoles(): Promise<AccountWithRoles[]> {
    try {
      const accounts = await AccountRepository.findAllAccounts();
      const result: AccountWithRoles[] = [];
      for (const account of accounts) {
        const roles = await AccountRepository.findRolesByAccountId(account.id);
        result[result.length] = new AccountWithRoles(account, roles);
      }
      return result;
    } catch (error) {
      const msg = error instanceof Error ? error.message : `${error}`;
      throw new Error(`AccountRepository.findAllAccountsWithRoles failed: ${msg}`);
    }
  }

  /** 批量写入游戏角色（先删后插，保证与服务端同步） */
  static async replaceRoles(accountId: number, roles: GameRoleRow[]): Promise<void> {
    try {
      await RdbManager.delete(
        new relationalStore.RdbPredicates('game_role_table').equalTo('account_id', accountId)
      );
      const valuesList: relationalStore.ValuesBucket[] = [];
      for (const role of roles) {
        const v: relationalStore.ValuesBucket = {};
        try {
          v['account_id'] = accountId;
          v['game_id'] = role.gameId;
          v['role_id'] = role.roleId;
          v['nickname'] = role.nickname;
          v['level'] = role.level;
          v['server'] = role.server;
          v['bg_image_url'] = role.bgImageUrl;
          v['stats_json'] = role.statsJson;
        } catch (fieldErr) {
          const msg = fieldErr instanceof Error ? fieldErr.message : `${fieldErr}`;
          throw new Error(`AccountRepository.replaceRoles build bucket failed: ${msg}`);
        }
        valuesList[valuesList.length] = v;
      }
      if (valuesList.length > 0) {
        await RdbManager.batchInsert('game_role_table', valuesList);
      }
    } catch (error) {
      const msg = error instanceof Error ? error.message : `${error}`;
      throw new Error(`AccountRepository.replaceRoles failed: ${msg}`);
    }
  }

  // ── ResultSet 解析 ───────────────────────────────────────────

  private static toAccountList(rs: relationalStore.ResultSet): AccountRow[] {
    const rows: AccountRow[] = [];
    try {
      while (rs.goToNextRow()) {
        rows[rows.length] = AccountRepository.readAccountRow(rs);
      }
      rs.close();
    } catch (error) {
      try { rs.close(); } catch (_e) {}
      const msg = error instanceof Error ? error.message : `${error}`;
      throw new Error(`AccountRepository.toAccountList failed: ${msg}`);
    }
    return rows;
  }

  private static readAccountRow(rs: relationalStore.ResultSet): AccountRow {
    const row = new AccountRow();
    try {
      row.id = rs.getLong(rs.getColumnIndex('id'));
      row.username = rs.getString(rs.getColumnIndex('username'));
      row.cookie = rs.getString(rs.getColumnIndex('cookie'));
      row.isActive = rs.getLong(rs.getColumnIndex('is_active')) === 1;
      row.createTime = rs.getLong(rs.getColumnIndex('create_time'));
      row.updateTime = rs.getLong(rs.getColumnIndex('update_time'));
      try { row.nickname = rs.getString(rs.getColumnIndex('nickname')); } catch (_) {}
      try { row.avatarUrl = rs.getString(rs.getColumnIndex('avatar_url')); } catch (_) {}
    } catch (error) {
      const msg = error instanceof Error ? error.message : `${error}`;
      throw new Error(`readAccountRow failed: ${msg}`);
    }
    return row;
  }

  private static toRoleList(rs: relationalStore.ResultSet): GameRoleRow[] {
    const rows: GameRoleRow[] = [];
    try {
      while (rs.goToNextRow()) {
        const row = new GameRoleRow();
        row.id = rs.getLong(rs.getColumnIndex('id'));
        row.accountId = rs.getLong(rs.getColumnIndex('account_id'));
        row.gameId = rs.getString(rs.getColumnIndex('game_id'));
        row.roleId = rs.getString(rs.getColumnIndex('role_id'));
        row.nickname = rs.getString(rs.getColumnIndex('nickname'));
        row.level = rs.getLong(rs.getColumnIndex('level'));
        row.server = rs.getString(rs.getColumnIndex('server'));
        try { row.bgImageUrl = rs.getString(rs.getColumnIndex('bg_image_url')); } catch (_) {}
        try { row.statsJson = rs.getString(rs.getColumnIndex('stats_json')); } catch (_) {}
        rows[rows.length] = row;
      }
      rs.close();
    } catch (error) {
      try { rs.close(); } catch (_e) {}
      const msg = error instanceof Error ? error.message : `${error}`;
      throw new Error(`AccountRepository.toRoleList failed: ${msg}`);
    }
    return rows;
  }
}
