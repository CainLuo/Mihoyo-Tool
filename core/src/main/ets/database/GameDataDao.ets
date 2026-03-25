/**
 * GameDataDao.ets
 *
 * 基于 game_data 表的通用数据访问对象（DAO）。
 * 所有对 game_data 表的读写操作都经过此类，业务层不直接操作 RdbManager。
 *
 * 注意：所有 RDB 调用均包裹 try-catch，满足 ArkTS 异常处理规范。
 * ResultSet 解析逻辑全部内联在各 list/findOne 方法内，避免跨方法调用触发
 * hvigor "Function may throw exceptions" WARN。
 */

import { relationalStore } from '@kit.ArkData';
import { RdbManager } from './RdbManager';
import { QueryBuilder } from './QueryBuilder';
import { GameDataRow, GameDataSummary } from '../models/GameDataRow';

const TABLE_NAME: string = 'game_data';

const SUMMARY_COLUMNS: string[] = [
  'id', 'game_id', 'role_uid', 'data_type', 'entity_id',
  'name', 'rarity', 'level', 'extra_int1', 'extra_int2',
  'extra_text1', 'update_time'
];

/** findDistinctGameRoles 返回的行模型 */
export class GameRolePair {
  gameId: string = '';
  roleUid: string = '';
}

export class GameDataDao {

  // ─── 写入 ────────────────────────────────────────────────────

  static async upsert(row: GameDataRow): Promise<void> {
    try {
      const existing = await GameDataDao.findOne(
        row.gameId, row.roleUid, row.dataType, row.entityId
      );
      const values = GameDataDao.toValuesBucket(row);
      if (existing !== null) {
        const builder = new QueryBuilder(TABLE_NAME)
          .equalTo('game_id', row.gameId)
          .equalTo('role_uid', row.roleUid)
          .equalTo('data_type', row.dataType)
          .equalTo('entity_id', row.entityId);
        await RdbManager.update(values, builder.build());
      } else {
        await RdbManager.insert(TABLE_NAME, values);
      }
    } catch (error) {
      const msg = error instanceof Error ? error.message : `${error}`;
      throw new Error(`GameDataDao.upsert failed: ${msg}`);
    }
  }

  static async batchUpsert(rows: GameDataRow[]): Promise<void> {
    if (rows.length === 0) {
      return;
    }
    const store = RdbManager.getRdbStore();
    try {
      store.beginTransaction();
      for (let i = 0; i < rows.length; i++) {
        await GameDataDao.upsert(rows[i]);
      }
      store.commit();
    } catch (error) {
      try {
        store.rollBack();
      } catch (rbErr) {
        console.error(`GameDataDao.batchUpsert rollback failed: ${rbErr}`);
      }
      const msg = error instanceof Error ? error.message : `${error}`;
      throw new Error(`GameDataDao.batchUpsert failed: ${msg}`);
    }
  }

  static async deleteByType(gameId: string, roleUid: string, dataType: string): Promise<number> {
    try {
      const builder = new QueryBuilder(TABLE_NAME)
        .equalTo('game_id', gameId)
        .equalTo('role_uid', roleUid)
        .equalTo('data_type', dataType);
      return await RdbManager.delete(builder.build());
    } catch (error) {
      const msg = error instanceof Error ? error.message : `${error}`;
      throw new Error(`GameDataDao.deleteByType failed: ${msg}`);
    }
  }

  static async deleteOne(gameId: string, roleUid: string, dataType: string, entityId: string): Promise<number> {
    try {
      const builder = new QueryBuilder(TABLE_NAME)
        .equalTo('game_id', gameId)
        .equalTo('role_uid', roleUid)
        .equalTo('data_type', dataType)
        .equalTo('entity_id', entityId);
      return await RdbManager.delete(builder.build());
    } catch (error) {
      const msg = error instanceof Error ? error.message : `${error}`;
      throw new Error(`GameDataDao.deleteOne failed: ${msg}`);
    }
  }

  // ─── 查询（列表，不含 raw_json）────────────────────────────────

  static async count(gameId: string, roleUid: string, dataType: string): Promise<number> {
    try {
      const builder = new QueryBuilder(TABLE_NAME)
        .equalTo('game_id', gameId)
        .equalTo('role_uid', roleUid)
        .equalTo('data_type', dataType)
        .columns(['id']);
      const rs = await RdbManager.query(builder.build(), ['id']);
      let n = 0;
      while (rs.goToNextRow()) {
        n++;
      }
      try { rs.close(); } catch (_) {}
      return n;
    } catch (error) {
      const msg = error instanceof Error ? error.message : `${error}`;
      throw new Error(`GameDataDao.count failed: ${msg}`);
    }
  }

  static async findSummaries(
    gameId: string,
    roleUid: string,
    dataType: string,
    orderField: string = 'level',
    orderDesc: boolean = true
  ): Promise<GameDataSummary[]> {
    try {
      const builder = new QueryBuilder(TABLE_NAME)
        .equalTo('game_id', gameId)
        .equalTo('role_uid', roleUid)
        .equalTo('data_type', dataType)
        .columns(SUMMARY_COLUMNS);
      if (orderDesc) {
        builder.orderByDesc(orderField);
      } else {
        builder.orderByAsc(orderField);
      }
      const rs = await RdbManager.query(builder.build(), builder.getColumns());
      return GameDataDao.toSummaryList(rs);
    } catch (error) {
      const msg = error instanceof Error ? error.message : `${error}`;
      throw new Error(`GameDataDao.findSummaries failed: ${msg}`);
    }
  }

  static async searchByName(keyword: string, gameId?: string, dataType?: string): Promise<GameDataSummary[]> {
    try {
      const builder = new QueryBuilder(TABLE_NAME)
        .like('name', `%${keyword}%`)
        .columns(SUMMARY_COLUMNS);
      if (gameId !== undefined) {
        builder.and().equalTo('game_id', gameId);
      }
      if (dataType !== undefined) {
        builder.and().equalTo('data_type', dataType);
      }
      builder.orderByDesc('rarity');
      const rs = await RdbManager.query(builder.build(), builder.getColumns());
      return GameDataDao.toSummaryList(rs);
    } catch (error) {
      const msg = error instanceof Error ? error.message : `${error}`;
      throw new Error(`GameDataDao.searchByName failed: ${msg}`);
    }
  }

  /**
   * 查询指定 data_type 下所有不重复的 (game_id, role_uid) 组合。
   * 用于 Characters 页面构建游戏 Tab 列表（当 game_role_table 为空时的 fallback）。
   */
  static async findDistinctGameRoles(dataType: string): Promise<GameRolePair[]> {
    try {
      const builder = new QueryBuilder(TABLE_NAME)
        .equalTo('data_type', dataType)
        .columns(['game_id', 'role_uid']);
      const rs = await RdbManager.query(builder.build(), ['game_id', 'role_uid']);
      const seen: Map<string, boolean> = new Map<string, boolean>();
      const result: GameRolePair[] = [];
      try {
        while (rs.goToNextRow()) {
          const gameId = rs.getString(rs.getColumnIndex('game_id'));
          const roleUid = rs.getString(rs.getColumnIndex('role_uid'));
          const key = gameId + '|' + roleUid;
          if (!seen.has(key)) {
            seen.set(key, true);
            const pair = new GameRolePair();
            pair.gameId = gameId;
            pair.roleUid = roleUid;
            result[result.length] = pair;
          }
        }
      } catch (parseErr) {
        const msg = parseErr instanceof Error ? parseErr.message : `${parseErr}`;
        GameDataDao.closeRs(rs);
        throw new Error(msg);
      }
      GameDataDao.closeRs(rs);
      return result;
    } catch (error) {
      const msg = error instanceof Error ? error.message : `${error}`;
      throw new Error(`GameDataDao.findDistinctGameRoles failed: ${msg}`);
    }
  }

  static async findActiveActivities(nowSeconds?: number): Promise<GameDataSummary[]> {
    try {
      const now = nowSeconds ?? Math.floor(Date.now() / 1000);
      const builder = new QueryBuilder(TABLE_NAME)
        .equalTo('data_type', 'activity')
        .greaterThan('extra_int2', now)
        .orderByAsc('extra_int1')
        .columns(SUMMARY_COLUMNS);
      const rs = await RdbManager.query(builder.build(), builder.getColumns());
      return GameDataDao.toSummaryList(rs);
    } catch (error) {
      const msg = error instanceof Error ? error.message : `${error}`;
      throw new Error(`GameDataDao.findActiveActivities failed: ${msg}`);
    }
  }

  // ─── 查询（详情，含 raw_json）──────────────────────────────────

  static async findOne(
    gameId: string,
    roleUid: string,
    dataType: string,
    entityId: string
  ): Promise<GameDataRow | null> {
    try {
      const builder = new QueryBuilder(TABLE_NAME)
        .equalTo('game_id', gameId)
        .equalTo('role_uid', roleUid)
        .equalTo('data_type', dataType)
        .equalTo('entity_id', entityId);
      const rs = await RdbManager.query(builder.build());
      if (!rs.goToFirstRow()) {
        GameDataDao.closeRs(rs);
        return null;
      }
      // 内联解析，避免跨方法调用触发 hvigor WARN
      const row = new GameDataRow();
      row.id = rs.getLong(rs.getColumnIndex('id'));
      row.gameId = rs.getString(rs.getColumnIndex('game_id'));
      row.roleUid = rs.getString(rs.getColumnIndex('role_uid'));
      row.dataType = rs.getString(rs.getColumnIndex('data_type'));
      row.entityId = rs.getString(rs.getColumnIndex('entity_id'));
      row.name = rs.getString(rs.getColumnIndex('name'));
      row.rarity = rs.getLong(rs.getColumnIndex('rarity'));
      row.level = rs.getLong(rs.getColumnIndex('level'));
      row.extraInt1 = rs.getLong(rs.getColumnIndex('extra_int1'));
      row.extraInt2 = rs.getLong(rs.getColumnIndex('extra_int2'));
      row.extraText1 = rs.getString(rs.getColumnIndex('extra_text1'));
      row.rawJson = rs.getString(rs.getColumnIndex('raw_json'));
      row.updateTime = rs.getLong(rs.getColumnIndex('update_time'));
      GameDataDao.closeRs(rs);
      return row;
    } catch (error) {
      const msg = error instanceof Error ? error.message : `${error}`;
      throw new Error(`GameDataDao.findOne failed: ${msg}`);
    }
  }

  static async findAll(
    gameId: string,
    roleUid: string,
    dataType: string,
    limitCount?: number,
    offsetCount?: number
  ): Promise<GameDataRow[]> {
    try {
      const builder = new QueryBuilder(TABLE_NAME)
        .equalTo('game_id', gameId)
        .equalTo('role_uid', roleUid)
        .equalTo('data_type', dataType)
        .orderByDesc('level');
      if (limitCount !== undefined) {
        builder.limit(limitCount);
      }
      if (offsetCount !== undefined) {
        builder.offset(offsetCount);
      }
      const rs = await RdbManager.query(builder.build());
      return GameDataDao.toRowList(rs);
    } catch (error) {
      const msg = error instanceof Error ? error.message : `${error}`;
      throw new Error(`GameDataDao.findAll failed: ${msg}`);
    }
  }

  static async findByBuilder(builder: QueryBuilder): Promise<GameDataRow[]> {
    try {
      const rs = await RdbManager.query(builder.build(), builder.getColumns());
      return GameDataDao.toRowList(rs);
    } catch (error) {
      const msg = error instanceof Error ? error.message : `${error}`;
      throw new Error(`GameDataDao.findByBuilder failed: ${msg}`);
    }
  }

  static async findSummariesByBuilder(builder: QueryBuilder): Promise<GameDataSummary[]> {
    try {
      const rs = await RdbManager.query(builder.build(), builder.getColumns());
      return GameDataDao.toSummaryList(rs);
    } catch (error) {
      const msg = error instanceof Error ? error.message : `${error}`;
      throw new Error(`GameDataDao.findSummariesByBuilder failed: ${msg}`);
    }
  }

  // ─── ResultSet → 模型转换（内联循环，无跨方法调用）──────────────

  /** 安全关闭 ResultSet，内部吞掉所有异常，调用点不会触发 hvigor WARN。 */
  private static closeRs(rs: relationalStore.ResultSet): void {
    try {
      rs.close();
    } catch (_) {}
  }

  /**
   * 将 ResultSet 转为 GameDataRow 列表（含 raw_json）。
   */
  private static toRowList(rs: relationalStore.ResultSet): GameDataRow[] {
    const rows: GameDataRow[] = [];
    try {
      while (rs.goToNextRow()) {
        const r = new GameDataRow();
        r.id = rs.getLong(rs.getColumnIndex('id'));
        r.gameId = rs.getString(rs.getColumnIndex('game_id'));
        r.roleUid = rs.getString(rs.getColumnIndex('role_uid'));
        r.dataType = rs.getString(rs.getColumnIndex('data_type'));
        r.entityId = rs.getString(rs.getColumnIndex('entity_id'));
        r.name = rs.getString(rs.getColumnIndex('name'));
        r.rarity = rs.getLong(rs.getColumnIndex('rarity'));
        r.level = rs.getLong(rs.getColumnIndex('level'));
        r.extraInt1 = rs.getLong(rs.getColumnIndex('extra_int1'));
        r.extraInt2 = rs.getLong(rs.getColumnIndex('extra_int2'));
        r.extraText1 = rs.getString(rs.getColumnIndex('extra_text1'));
        r.rawJson = rs.getString(rs.getColumnIndex('raw_json'));
        r.updateTime = rs.getLong(rs.getColumnIndex('update_time'));
        rows[rows.length] = r;
      }
    } catch (error) {
      const msg = error instanceof Error ? error.message : `${error}`;
      GameDataDao.closeRs(rs);
      throw new Error(`GameDataDao.toRowList failed: ${msg}`);
    }
    GameDataDao.closeRs(rs);
    return rows;
  }

  /**
   * 将 ResultSet 转为 GameDataSummary 列表（不含 raw_json）。
   */
  private static toSummaryList(rs: relationalStore.ResultSet): GameDataSummary[] {
    const rows: GameDataSummary[] = [];
    try {
      while (rs.goToNextRow()) {
        const s = new GameDataSummary();
        s.id = rs.getLong(rs.getColumnIndex('id'));
        s.gameId = rs.getString(rs.getColumnIndex('game_id'));
        s.roleUid = rs.getString(rs.getColumnIndex('role_uid'));
        s.dataType = rs.getString(rs.getColumnIndex('data_type'));
        s.entityId = rs.getString(rs.getColumnIndex('entity_id'));
        s.name = rs.getString(rs.getColumnIndex('name'));
        s.rarity = rs.getLong(rs.getColumnIndex('rarity'));
        s.level = rs.getLong(rs.getColumnIndex('level'));
        s.extraInt1 = rs.getLong(rs.getColumnIndex('extra_int1'));
        s.extraInt2 = rs.getLong(rs.getColumnIndex('extra_int2'));
        s.extraText1 = rs.getString(rs.getColumnIndex('extra_text1'));
        s.updateTime = rs.getLong(rs.getColumnIndex('update_time'));
        rows[rows.length] = s;
      }
    } catch (error) {
      const msg = error instanceof Error ? error.message : `${error}`;
      GameDataDao.closeRs(rs);
      throw new Error(`GameDataDao.toSummaryList failed: ${msg}`);
    }
    GameDataDao.closeRs(rs);
    return rows;
  }

  private static toValuesBucket(row: GameDataRow): relationalStore.ValuesBucket {
    const bucket: relationalStore.ValuesBucket = {};
    bucket['game_id'] = row.gameId;
    bucket['role_uid'] = row.roleUid;
    bucket['data_type'] = row.dataType;
    bucket['entity_id'] = row.entityId;
    bucket['name'] = row.name;
    bucket['rarity'] = row.rarity;
    bucket['level'] = row.level;
    bucket['extra_int1'] = row.extraInt1;
    bucket['extra_int2'] = row.extraInt2;
    bucket['extra_text1'] = row.extraText1;
    bucket['raw_json'] = row.rawJson;
    bucket['update_time'] = row.updateTime;
    return bucket;
  }
}
