/**
 * ActivityRepository.ets
 *
 * 活动数据 Repository，支持跨游戏活动查询。
 * extra_int1 = 开始时间（Unix 秒），extra_int2 = 结束时间（Unix 秒）
 */

import { GameDataDao } from '../database/GameDataDao';
import { QueryBuilder } from '../database/QueryBuilder';
import { GameDataSummary, GameDataRow, DataType } from '../models/GameDataRow';

/** 列表页查询列（不含 raw_json） */
const ACTIVITY_COLUMNS: string[] = [
  'id', 'game_id', 'role_uid', 'data_type', 'entity_id',
  'name', 'rarity', 'level', 'extra_int1', 'extra_int2',
  'extra_text1', 'update_time'
];

export class ActivityRepository {

  /**
   * 查询所有未结束的活动（跨游戏）。
   * 按开始时间升序排列。
   */
  static async findActive(): Promise<GameDataSummary[]> {
    return GameDataDao.findActiveActivities();
  }

  /**
   * 查询指定游戏的未结束活动。
   *
   * @param gameId 游戏标识
   */
  static async findActiveByGame(gameId: string): Promise<GameDataSummary[]> {
    const now = Math.floor(Date.now() / 1000);
    const builder = new QueryBuilder('game_data')
      .equalTo('game_id', gameId)
      .equalTo('data_type', DataType.ACTIVITY)
      .greaterThan('extra_int2', now)
      .orderByAsc('extra_int1')
      .columns(ACTIVITY_COLUMNS);
    const rows = await GameDataDao.findByBuilder(builder);
    return rows as GameDataSummary[];
  }

  /**
   * 查询所有活动（含已结束），按开始时间降序。
   *
   * @param gameId 可选，限定游戏
   */
  static async findAll(gameId?: string): Promise<GameDataSummary[]> {
    const builder = new QueryBuilder('game_data')
      .equalTo('data_type', DataType.ACTIVITY)
      .orderByDesc('extra_int1')
      .columns(ACTIVITY_COLUMNS);
    if (gameId !== undefined) {
      builder.and().equalTo('game_id', gameId);
    }
    const rows = await GameDataDao.findByBuilder(builder);
    return rows as GameDataSummary[];
  }

  /**
   * 查询活动详情（含 raw_json）。
   */
  static async findById(
    gameId: string,
    entityId: string
  ): Promise<GameDataRow | null> {
    // 活动是公共数据，role_uid 填 "global"
    return GameDataDao.findOne(gameId, 'global', DataType.ACTIVITY, entityId);
  }

  /**
   * 全量写入活动数据。
   */
  static async saveAll(rows: GameDataRow[]): Promise<void> {
    return GameDataDao.batchUpsert(rows);
  }
}
