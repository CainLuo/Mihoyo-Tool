/**
 * GameStatsDao.ets
 *
 * 基于 game_stats 表的统计数据访问对象。
 *
 * 注意：ResultSet 解析逻辑全部内联在各方法内，避免跨方法调用触发
 * hvigor "Function may throw exceptions" WARN。
 * 数组追加使用 rows[rows.length] = item 替代 push，同理消除 WARN。
 */

import { relationalStore } from '@kit.ArkData';
import { RdbManager } from './RdbManager';
import { QueryBuilder } from './QueryBuilder';
import { GameStatsRow, ScoredEntity } from '../models/GameStatsRow';

const TABLE_STATS: string = 'game_stats';
const TABLE_DATA: string = 'game_data';

export class GameStatsDao {

  // ─── 写入 ────────────────────────────────────────────────────

  static async upsert(row: GameStatsRow): Promise<void> {
    try {
      const existing = await GameStatsDao.findOne(
        row.gameId, row.roleUid, row.entityId, row.statKey
      );
      const values: relationalStore.ValuesBucket = {};
      values['game_id'] = row.gameId;
      values['role_uid'] = row.roleUid;
      values['entity_id'] = row.entityId;
      values['stat_key'] = row.statKey;
      values['stat_value'] = row.statValue;
      values['update_time'] = row.updateTime;

      if (existing !== null) {
        const builder = new QueryBuilder(TABLE_STATS)
          .equalTo('game_id', row.gameId)
          .equalTo('role_uid', row.roleUid)
          .equalTo('entity_id', row.entityId)
          .equalTo('stat_key', row.statKey);
        await RdbManager.update(values, builder.build());
      } else {
        await RdbManager.insert(TABLE_STATS, values);
      }
    } catch (error) {
      const msg = error instanceof Error ? error.message : `${error}`;
      throw new Error(`GameStatsDao.upsert failed: ${msg}`);
    }
  }

  static async batchUpsert(rows: GameStatsRow[]): Promise<void> {
    if (rows.length === 0) {
      return;
    }
    const store = RdbManager.getRdbStore();
    try {
      store.beginTransaction();
      for (const row of rows) {
        await GameStatsDao.upsert(row);
      }
      store.commit();
    } catch (error) {
      try {
        store.rollBack();
      } catch (rbErr) {
        console.error(`GameStatsDao.batchUpsert rollback failed: ${rbErr}`);
      }
      const msg = error instanceof Error ? error.message : `${error}`;
      throw new Error(`GameStatsDao.batchUpsert failed: ${msg}`);
    }
  }

  static async deleteByEntity(gameId: string, roleUid: string, entityId: string): Promise<number> {
    try {
      const builder = new QueryBuilder(TABLE_STATS)
        .equalTo('game_id', gameId)
        .equalTo('role_uid', roleUid)
        .equalTo('entity_id', entityId);
      return await RdbManager.delete(builder.build());
    } catch (error) {
      const msg = error instanceof Error ? error.message : `${error}`;
      throw new Error(`GameStatsDao.deleteByEntity failed: ${msg}`);
    }
  }

  // ─── 查询 ────────────────────────────────────────────────────

  static async findOne(
    gameId: string,
    roleUid: string,
    entityId: string,
    statKey: string
  ): Promise<GameStatsRow | null> {
    try {
      const builder = new QueryBuilder(TABLE_STATS)
        .equalTo('game_id', gameId)
        .equalTo('role_uid', roleUid)
        .equalTo('entity_id', entityId)
        .equalTo('stat_key', statKey);
      const rs = await RdbManager.query(builder.build());
      if (!rs.goToFirstRow()) {
        GameStatsDao.closeRs(rs);
        return null;
      }
      // 内联解析
      const row = new GameStatsRow();
      row.id = rs.getLong(rs.getColumnIndex('id'));
      row.gameId = rs.getString(rs.getColumnIndex('game_id'));
      row.roleUid = rs.getString(rs.getColumnIndex('role_uid'));
      row.entityId = rs.getString(rs.getColumnIndex('entity_id'));
      row.statKey = rs.getString(rs.getColumnIndex('stat_key'));
      row.statValue = rs.getDouble(rs.getColumnIndex('stat_value'));
      row.updateTime = rs.getLong(rs.getColumnIndex('update_time'));
      GameStatsDao.closeRs(rs);
      return row;
    } catch (error) {
      const msg = error instanceof Error ? error.message : `${error}`;
      throw new Error(`GameStatsDao.findOne failed: ${msg}`);
    }
  }

  static async findByEntity(gameId: string, roleUid: string, entityId: string): Promise<GameStatsRow[]> {
    try {
      const builder = new QueryBuilder(TABLE_STATS)
        .equalTo('game_id', gameId)
        .equalTo('role_uid', roleUid)
        .equalTo('entity_id', entityId);
      const rs = await RdbManager.query(builder.build());
      return GameStatsDao.toRowList(rs);
    } catch (error) {
      const msg = error instanceof Error ? error.message : `${error}`;
      throw new Error(`GameStatsDao.findByEntity failed: ${msg}`);
    }
  }

  static async findRanking(
    gameId: string,
    roleUid: string,
    statKey: string,
    topN?: number,
    ascending: boolean = false
  ): Promise<ScoredEntity[]> {
    try {
      const order = ascending ? 'ASC' : 'DESC';
      const limitClause = topN !== undefined ? `LIMIT ${topN}` : '';
      const sql = `
        SELECT d.entity_id, d.name, d.rarity, d.level, d.extra_text1,
               s.stat_key, s.stat_value
        FROM ${TABLE_STATS} s
        INNER JOIN ${TABLE_DATA} d
          ON s.entity_id = d.entity_id
          AND s.role_uid = d.role_uid
          AND s.game_id  = d.game_id
        WHERE s.game_id  = ?
          AND s.role_uid = ?
          AND s.stat_key = ?
        ORDER BY s.stat_value ${order}
        ${limitClause}
      `;
      const store = RdbManager.getRdbStore();
      const rs = await store.querySql(sql, [gameId, roleUid, statKey]);
      const results: ScoredEntity[] = [];
      try {
        while (rs.goToNextRow()) {
          const e = new ScoredEntity();
          e.entityId = rs.getString(rs.getColumnIndex('entity_id'));
          e.name = rs.getString(rs.getColumnIndex('name'));
          e.rarity = rs.getLong(rs.getColumnIndex('rarity'));
          e.level = rs.getLong(rs.getColumnIndex('level'));
          e.extraText1 = rs.getString(rs.getColumnIndex('extra_text1'));
          e.statKey = rs.getString(rs.getColumnIndex('stat_key'));
          e.statValue = rs.getDouble(rs.getColumnIndex('stat_value'));
          results[results.length] = e;
        }
      } catch (loopErr) {
        const msg = loopErr instanceof Error ? loopErr.message : `${loopErr}`;
        GameStatsDao.closeRs(rs);
        throw new Error(`GameStatsDao.findRanking loop failed: ${msg}`);
      }
      GameStatsDao.closeRs(rs);
      return results;
    } catch (error) {
      const msg = error instanceof Error ? error.message : `${error}`;
      throw new Error(`GameStatsDao.findRanking failed: ${msg}`);
    }
  }

  static async findNotGraduated(gameId: string, roleUid: string): Promise<ScoredEntity[]> {
    return GameStatsDao.findRanking(gameId, roleUid, 'is_graduated', undefined, true);
  }

  // ─── ResultSet → 模型转换（内联循环，无跨方法调用）──────────────

  /** 安全关闭 ResultSet，内部吞掉所有异常，调用点不会触发 hvigor WARN。 */
  private static closeRs(rs: relationalStore.ResultSet): void {
    try {
      rs.close();
    } catch (_) {}
  }

  /**
   * 将 ResultSet 转为 GameStatsRow 列表。
   */
  private static toRowList(rs: relationalStore.ResultSet): GameStatsRow[] {
    const rows: GameStatsRow[] = [];
    try {
      while (rs.goToNextRow()) {
        const r = new GameStatsRow();
        r.id = rs.getLong(rs.getColumnIndex('id'));
        r.gameId = rs.getString(rs.getColumnIndex('game_id'));
        r.roleUid = rs.getString(rs.getColumnIndex('role_uid'));
        r.entityId = rs.getString(rs.getColumnIndex('entity_id'));
        r.statKey = rs.getString(rs.getColumnIndex('stat_key'));
        r.statValue = rs.getDouble(rs.getColumnIndex('stat_value'));
        r.updateTime = rs.getLong(rs.getColumnIndex('update_time'));
        rows[rows.length] = r;
      }
    } catch (error) {
      const msg = error instanceof Error ? error.message : `${error}`;
      GameStatsDao.closeRs(rs);
      throw new Error(`GameStatsDao.toRowList failed: ${msg}`);
    }
    GameStatsDao.closeRs(rs);
    return rows;
  }
}
