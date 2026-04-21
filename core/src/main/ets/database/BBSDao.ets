import { relationalStore } from '@kit.ArkData';
import { RdbManager } from './RdbManager';
import { RsReader } from './RsReader';
import { TableName, CommonCol, AccountCol, GameRoleCol, ACCOUNT_TABLE, GAME_ROLE_TABLE } from './TableSchema';
import { AccountRow } from '../models/AccountRow';
import { GameRoleRow } from '../models/GameRoleRow';
import { GameId } from '../constants/GameId';

// ─────────────────────────────────────────────
// AccountDao：操作 account_table
// ─────────────────────────────────────────────
export class AccountDao {

  /**
   * 使用 INSERT OR REPLACE 实现 upsert（按 username 唯一键）
   * 注意：当 id > 0 时改用 UPDATE，避免 INSERT OR REPLACE 触发 ON DELETE CASCADE 级联删除角色数据
   */
  async upsert(row: AccountRow): Promise<void> {
    if (row.id > 0) {
      try {
        await RdbManager.updateRows(
          TableName.ACCOUNT,
          ACCOUNT_TABLE.columnNames().filter(c => c !== CommonCol.ID),
          [row.username, row.cookie, row.isActive, row.createTime, row.updateTime,
           row.uid, row.nickname, row.avatarUrl, row.introduce, row.rawJson],
          [CommonCol.ID],
          [row.id]
        );
      } catch (e) {
        throw new Error(`AccountDao.upsert(update) failed: ${e instanceof Error ? e.message : e}`);
      }
      return;
    }
    const idVal: relationalStore.ValueType = null;
    try {
      await RdbManager.upsertRow(TableName.ACCOUNT, ACCOUNT_TABLE.columnNames(), [
        idVal, row.username, row.cookie, row.isActive, row.createTime, row.updateTime,
        row.uid, row.nickname, row.avatarUrl, row.introduce, row.rawJson
      ]);
    } catch (e) {
      throw new Error(`AccountDao.upsert failed: ${e instanceof Error ? e.message : e}`);
    }
  }

  /**
   * 查询所有账号
   */
  async findAll(): Promise<AccountRow[]> {
    const predicates = new relationalStore.RdbPredicates(TableName.ACCOUNT);
    try {
      return await RdbManager.queryAll(predicates, ACCOUNT_TABLE.columnNames(), (rs) => AccountDao.mapRow(rs));
    } catch (e) {
      throw new Error(`AccountDao.findAll failed: ${e instanceof Error ? e.message : e}`);
    }
  }

  /**
   * 按 id 查询
   */
  async findById(id: number): Promise<AccountRow | null> {
    const predicates = new relationalStore.RdbPredicates(TableName.ACCOUNT);
    predicates.equalTo(CommonCol.ID, id);
    try {
      return await RdbManager.queryFirst(predicates, ACCOUNT_TABLE.columnNames(), (rs) => AccountDao.mapRow(rs));
    } catch (e) {
      throw new Error(`AccountDao.findById failed: ${e instanceof Error ? e.message : e}`);
    }
  }

  /**
   * 按 username 查询
   */
  async findByUsername(username: string): Promise<AccountRow | null> {
    const predicates = new relationalStore.RdbPredicates(TableName.ACCOUNT);
    predicates.equalTo(AccountCol.USERNAME, username);
    try {
      return await RdbManager.queryFirst(predicates, ACCOUNT_TABLE.columnNames(), (rs) => AccountDao.mapRow(rs));
    } catch (e) {
      throw new Error(`AccountDao.findByUsername failed: ${e instanceof Error ? e.message : e}`);
    }
  }

  /**
   * 按 uid 查询（米游社 UID）
   */
  async findByUid(uid: string): Promise<AccountRow | null> {
    const predicates = new relationalStore.RdbPredicates(TableName.ACCOUNT);
    predicates.equalTo(AccountCol.UID, uid);
    try {
      return await RdbManager.queryFirst(predicates, ACCOUNT_TABLE.columnNames(), (rs) => AccountDao.mapRow(rs));
    } catch (e) {
      throw new Error(`AccountDao.findByUid failed: ${e instanceof Error ? e.message : e}`);
    }
  }

  /**
   * INSERT OR IGNORE：username 不存在时插入新行，已存在时跳过
   */
  async insertOrIgnore(username: string, cookie: string, now: number): Promise<void> {
    try {
      await RdbManager.executeSql(
        `INSERT OR IGNORE INTO account_table (username, cookie, is_active, create_time, update_time, uid, nickname, avatar_url, introduce, raw_json) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`,
        [username, cookie, 1, now, now, username, '', '', '', '']
      );
    } catch (e) {
      throw new Error(`AccountDao.insertOrIgnore failed: ${e instanceof Error ? e.message : e}`);
    }
  }

  /**
   * 仅更新 cookie 和 update_time（按 username 匹配）
   */
  async updateCookie(username: string, cookie: string, now: number): Promise<void> {
    try {
      await RdbManager.executeSql(
        `UPDATE account_table SET cookie = ?, update_time = ? WHERE username = ?`,
        [cookie, now, username]
      );
    } catch (e) {
      throw new Error(`AccountDao.updateCookie failed: ${e instanceof Error ? e.message : e}`);
    }
  }

  /**
   * 按 id 删除
   */
  async deleteById(id: number): Promise<void> {
    const predicates = new relationalStore.RdbPredicates(TableName.ACCOUNT);
    predicates.equalTo(CommonCol.ID, id);
    try {
      await RdbManager.deleteRows(predicates);
    } catch (e) {
      throw new Error(`AccountDao.deleteById failed: ${e instanceof Error ? e.message : e}`);
    }
  }

  /**
   * 将 ResultSet 当前行映射为 AccountRow
   */
  private static mapRow(rs: relationalStore.ResultSet): AccountRow {
    try {
      const r = new RsReader(rs);
      const row = new AccountRow();
      row.id         = r.num(CommonCol.ID);
      row.username   = r.str(AccountCol.USERNAME);
      row.cookie     = r.str(AccountCol.COOKIE);
      row.isActive   = r.num(AccountCol.IS_ACTIVE);
      row.createTime = r.num(AccountCol.CREATE_TIME);
      row.updateTime = r.num(CommonCol.UPDATE_TIME);
      row.uid        = r.str(AccountCol.UID);
      row.nickname   = r.str(AccountCol.NICKNAME);
      row.avatarUrl  = r.str(AccountCol.AVATAR_URL);
      row.introduce  = r.str(AccountCol.INTRODUCE);
      row.rawJson    = r.str(AccountCol.RAW_JSON);
      return row;
    } catch (e) {
      throw new Error(`AccountDao.mapRow failed: ${e instanceof Error ? e.message : e}`);
    }
  }
}

// ─────────────────────────────────────────────
// GameRoleDao：操作 game_role_table
// ─────────────────────────────────────────────
export class GameRoleDao {

  /**
   * 批量 upsert（INSERT OR REPLACE INTO）
   */
  async upsertAll(rows: GameRoleRow[]): Promise<void> {
    if (rows.length === 0) {
      return;
    }
    const columns = GAME_ROLE_TABLE.columnNames();
    try {
      for (let i = 0; i < rows.length; i++) {
        const row = rows[i];
        const idVal: relationalStore.ValueType = row.id > 0 ? row.id : null;
        await RdbManager.upsertRow(TableName.GAME_ROLE, columns, [
          idVal, row.accountId, row.gameId, row.gameBiz, row.gameType, row.roleId,
          row.nickname, row.level, row.server, row.regionName,
          row.isChosen, row.isPublic, row.bgImageUrl, row.statsJson
        ]);
      }
    } catch (e) {
      throw new Error(`GameRoleDao.upsertAll failed: ${e instanceof Error ? e.message : e}`);
    }
  }

  /**
   * 按 accountId 查询所有游戏角色
   */
  async findByAccountId(accountId: string): Promise<GameRoleRow[]> {
    const predicates = new relationalStore.RdbPredicates(TableName.GAME_ROLE);
    predicates.equalTo(CommonCol.ACCOUNT_ID, accountId);
    try {
      return await RdbManager.queryAll(predicates, GAME_ROLE_TABLE.columnNames(), (rs) => GameRoleDao.mapRow(rs));
    } catch (e) {
      throw new Error(`GameRoleDao.findByAccountId failed: ${e instanceof Error ? e.message : e}`);
    }
  }

  /**
   * 按 accountId + gameId 查询
   */
  async findByAccountAndGame(accountId: string, gameId: GameId): Promise<GameRoleRow[]> {
    const predicates = new relationalStore.RdbPredicates(TableName.GAME_ROLE);
    predicates.equalTo(CommonCol.ACCOUNT_ID, accountId);
    predicates.and();
    predicates.equalTo(GameRoleCol.GAME_ID, gameId);
    try {
      return await RdbManager.queryAll(predicates, GAME_ROLE_TABLE.columnNames(), (rs) => GameRoleDao.mapRow(rs));
    } catch (e) {
      throw new Error(`GameRoleDao.findByAccountAndGame failed: ${e instanceof Error ? e.message : e}`);
    }
  }

  /**
   * 按 accountId 删除所有游戏角色
   */
  async deleteByAccountId(accountId: string): Promise<void> {
    const predicates = new relationalStore.RdbPredicates(TableName.GAME_ROLE);
    predicates.equalTo(CommonCol.ACCOUNT_ID, accountId);
    try {
      await RdbManager.deleteRows(predicates);
    } catch (e) {
      throw new Error(`GameRoleDao.deleteByAccountId failed: ${e instanceof Error ? e.message : e}`);
    }
  }

  /**
   * 将 ResultSet 当前行映射为 GameRoleRow
   */
  private static mapRow(rs: relationalStore.ResultSet): GameRoleRow {
    try {
      const r = new RsReader(rs);
      const row = new GameRoleRow();
      row.id         = r.num(CommonCol.ID);
      row.accountId  = r.str(CommonCol.ACCOUNT_ID);
      row.gameId     = r.str(GameRoleCol.GAME_ID) as GameId;
      row.gameBiz    = r.str(GameRoleCol.GAME_BIZ);
      row.gameType   = r.num(GameRoleCol.GAME_TYPE);
      row.roleId     = r.str(GameRoleCol.ROLE_ID);
      row.nickname   = r.str(GameRoleCol.NICKNAME);
      row.level      = r.num(GameRoleCol.LEVEL);
      row.server     = r.str(GameRoleCol.SERVER);
      row.regionName = r.str(GameRoleCol.REGION_NAME);
      row.isChosen   = r.num(GameRoleCol.IS_CHOSEN);
      row.isPublic   = r.num(GameRoleCol.IS_PUBLIC);
      row.bgImageUrl = r.str(GameRoleCol.BG_IMAGE_URL);
      row.statsJson  = r.str(GameRoleCol.STATS_JSON);
      return row;
    } catch (e) {
      throw new Error(`GameRoleDao.mapRow failed: ${e instanceof Error ? e.message : e}`);
    }
  }
}
