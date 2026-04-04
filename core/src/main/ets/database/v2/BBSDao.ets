import { relationalStore } from '@kit.ArkData';
import { RdbManagerV2 } from './RdbManagerV2';
import { TableName, ACCOUNT_TABLE, GAME_ROLE_TABLE } from './TableSchema';
import { AccountRowV2 } from '../../models/v2/AccountRowV2';
import { GameRoleRowV2 } from '../../models/v2/GameRoleRowV2';

// ─────────────────────────────────────────────
// AccountDao：操作 account_table
// ─────────────────────────────────────────────
export class AccountDao {

  /**
   * 使用 INSERT OR REPLACE 实现 upsert（按 username 唯一键）
   */
  async upsert(row: AccountRowV2): Promise<void> {
    const idVal: relationalStore.ValueType = row.id > 0 ? row.id : null;
    try {
      await RdbManagerV2.upsertRow(TableName.ACCOUNT, ACCOUNT_TABLE.columnNames(), [
        idVal, row.username, row.cookie, row.stoken, row.stuid, row.mid,
        row.isActive, row.createTime, row.updateTime, row.uid, row.nickname,
        row.avatarUrl, row.introduce
      ]);
    } catch (e) {
      throw new Error(`AccountDao.upsert failed: ${e instanceof Error ? e.message : e}`);
    }
  }

  /**
   * 查询所有账号
   */
  async findAll(): Promise<AccountRowV2[]> {
    const predicates = new relationalStore.RdbPredicates(TableName.ACCOUNT);
    try {
      return await RdbManagerV2.queryAll(predicates, ACCOUNT_TABLE.columnNames(), (rs) => AccountDao.mapRow(rs));
    } catch (e) {
      throw new Error(`AccountDao.findAll failed: ${e instanceof Error ? e.message : e}`);
    }
  }

  /**
   * 按 id 查询
   */
  async findById(id: number): Promise<AccountRowV2 | null> {
    const predicates = new relationalStore.RdbPredicates(TableName.ACCOUNT);
    predicates.equalTo('id', id);
    try {
      return await RdbManagerV2.queryFirst(predicates, ACCOUNT_TABLE.columnNames(), (rs) => AccountDao.mapRow(rs));
    } catch (e) {
      throw new Error(`AccountDao.findById failed: ${e instanceof Error ? e.message : e}`);
    }
  }

  /**
   * 按 username 查询
   */
  async findByUsername(username: string): Promise<AccountRowV2 | null> {
    const predicates = new relationalStore.RdbPredicates(TableName.ACCOUNT);
    predicates.equalTo('username', username);
    try {
      return await RdbManagerV2.queryFirst(predicates, ACCOUNT_TABLE.columnNames(), (rs) => AccountDao.mapRow(rs));
    } catch (e) {
      throw new Error(`AccountDao.findByUsername failed: ${e instanceof Error ? e.message : e}`);
    }
  }

  /**
   * 按 id 删除
   */
  async deleteById(id: number): Promise<void> {
    const predicates = new relationalStore.RdbPredicates(TableName.ACCOUNT);
    predicates.equalTo('id', id);
    try {
      await RdbManagerV2.deleteRows(predicates);
    } catch (e) {
      throw new Error(`AccountDao.deleteById failed: ${e instanceof Error ? e.message : e}`);
    }
  }

  /**
   * 将 ResultSet 当前行映射为 AccountRowV2
   */
  private static mapRow(rs: relationalStore.ResultSet): AccountRowV2 {
    try {
      const row = new AccountRowV2();
      const idVal = rs.getValue(rs.getColumnIndex('id'));
      row.id = typeof idVal === 'number' ? idVal : 0;
      const usernameVal = rs.getValue(rs.getColumnIndex('username'));
      row.username = typeof usernameVal === 'string' ? usernameVal : '';
      const cookieVal = rs.getValue(rs.getColumnIndex('cookie'));
      row.cookie = typeof cookieVal === 'string' ? cookieVal : '';
      const stokenVal = rs.getValue(rs.getColumnIndex('stoken'));
      row.stoken = typeof stokenVal === 'string' ? stokenVal : '';
      const stuidVal = rs.getValue(rs.getColumnIndex('stuid'));
      row.stuid = typeof stuidVal === 'string' ? stuidVal : '';
      const midVal = rs.getValue(rs.getColumnIndex('mid'));
      row.mid = typeof midVal === 'string' ? midVal : '';
      const isActiveVal = rs.getValue(rs.getColumnIndex('is_active'));
      row.isActive = typeof isActiveVal === 'number' ? isActiveVal : 0;
      const createTimeVal = rs.getValue(rs.getColumnIndex('create_time'));
      row.createTime = typeof createTimeVal === 'number' ? createTimeVal : 0;
      const updateTimeVal = rs.getValue(rs.getColumnIndex('update_time'));
      row.updateTime = typeof updateTimeVal === 'number' ? updateTimeVal : 0;
      const uidVal = rs.getValue(rs.getColumnIndex('uid'));
      row.uid = typeof uidVal === 'string' ? uidVal : '';
      const nicknameVal = rs.getValue(rs.getColumnIndex('nickname'));
      row.nickname = typeof nicknameVal === 'string' ? nicknameVal : '';
      const avatarUrlVal = rs.getValue(rs.getColumnIndex('avatar_url'));
      row.avatarUrl = typeof avatarUrlVal === 'string' ? avatarUrlVal : '';
      const introduceVal = rs.getValue(rs.getColumnIndex('introduce'));
      row.introduce = typeof introduceVal === 'string' ? introduceVal : '';
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
  async upsertAll(rows: GameRoleRowV2[]): Promise<void> {
    if (rows.length === 0) {
      return;
    }
    const columns = GAME_ROLE_TABLE.columnNames();
    try {
      for (let i = 0; i < rows.length; i++) {
        const row = rows[i];
        const idVal: relationalStore.ValueType = row.id > 0 ? row.id : null;
        await RdbManagerV2.upsertRow(TableName.GAME_ROLE, columns, [
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
  async findByAccountId(accountId: number): Promise<GameRoleRowV2[]> {
    const predicates = new relationalStore.RdbPredicates(TableName.GAME_ROLE);
    predicates.equalTo('account_id', accountId);
    try {
      return await RdbManagerV2.queryAll(predicates, GAME_ROLE_TABLE.columnNames(), (rs) => GameRoleDao.mapRow(rs));
    } catch (e) {
      throw new Error(`GameRoleDao.findByAccountId failed: ${e instanceof Error ? e.message : e}`);
    }
  }

  /**
   * 按 accountId + gameId 查询
   */
  async findByAccountAndGame(accountId: number, gameId: string): Promise<GameRoleRowV2[]> {
    const predicates = new relationalStore.RdbPredicates(TableName.GAME_ROLE);
    predicates.equalTo('account_id', accountId);
    predicates.and();
    predicates.equalTo('game_id', gameId);
    try {
      return await RdbManagerV2.queryAll(predicates, GAME_ROLE_TABLE.columnNames(), (rs) => GameRoleDao.mapRow(rs));
    } catch (e) {
      throw new Error(`GameRoleDao.findByAccountAndGame failed: ${e instanceof Error ? e.message : e}`);
    }
  }

  /**
   * 按 accountId 删除所有游戏角色
   */
  async deleteByAccountId(accountId: number): Promise<void> {
    const predicates = new relationalStore.RdbPredicates(TableName.GAME_ROLE);
    predicates.equalTo('account_id', accountId);
    try {
      await RdbManagerV2.deleteRows(predicates);
    } catch (e) {
      throw new Error(`GameRoleDao.deleteByAccountId failed: ${e instanceof Error ? e.message : e}`);
    }
  }

  /**
   * 将 ResultSet 当前行映射为 GameRoleRowV2
   */
  private static mapRow(rs: relationalStore.ResultSet): GameRoleRowV2 {
    try {
      const row = new GameRoleRowV2();
      const idVal = rs.getValue(rs.getColumnIndex('id'));
      row.id = typeof idVal === 'number' ? idVal : 0;
      const accountIdVal = rs.getValue(rs.getColumnIndex('account_id'));
      row.accountId = typeof accountIdVal === 'number' ? accountIdVal : 0;
      const gameIdVal = rs.getValue(rs.getColumnIndex('game_id'));
      row.gameId = typeof gameIdVal === 'string' ? gameIdVal : '';
      const gameBizVal = rs.getValue(rs.getColumnIndex('game_biz'));
      row.gameBiz = typeof gameBizVal === 'string' ? gameBizVal : '';
      const gameTypeVal = rs.getValue(rs.getColumnIndex('game_type'));
      row.gameType = typeof gameTypeVal === 'number' ? gameTypeVal : 0;
      const roleIdVal = rs.getValue(rs.getColumnIndex('role_id'));
      row.roleId = typeof roleIdVal === 'string' ? roleIdVal : '';
      const nicknameVal = rs.getValue(rs.getColumnIndex('nickname'));
      row.nickname = typeof nicknameVal === 'string' ? nicknameVal : '';
      const levelVal = rs.getValue(rs.getColumnIndex('level'));
      row.level = typeof levelVal === 'number' ? levelVal : 0;
      const serverVal = rs.getValue(rs.getColumnIndex('server'));
      row.server = typeof serverVal === 'string' ? serverVal : '';
      const regionNameVal = rs.getValue(rs.getColumnIndex('region_name'));
      row.regionName = typeof regionNameVal === 'string' ? regionNameVal : '';
      const isChosenVal = rs.getValue(rs.getColumnIndex('is_chosen'));
      row.isChosen = typeof isChosenVal === 'number' ? isChosenVal : 0;
      const isPublicVal = rs.getValue(rs.getColumnIndex('is_public'));
      row.isPublic = typeof isPublicVal === 'number' ? isPublicVal : 0;
      const bgImageUrlVal = rs.getValue(rs.getColumnIndex('bg_image_url'));
      row.bgImageUrl = typeof bgImageUrlVal === 'string' ? bgImageUrlVal : '';
      const statsJsonVal = rs.getValue(rs.getColumnIndex('stats_json'));
      row.statsJson = typeof statsJsonVal === 'string' ? statsJsonVal : '';
      return row;
    } catch (e) {
      throw new Error(`GameRoleDao.mapRow failed: ${e instanceof Error ? e.message : e}`);
    }
  }
}
