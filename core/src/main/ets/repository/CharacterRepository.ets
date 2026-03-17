/**
 * CharacterRepository.ets
 *
 * 角色数据 Repository，封装所有角色相关的查询语义。
 * entry 模块调用此类，完全不感知底层 SQL 和 DAO 细节。
 *
 * 使用示例（entry 模块）：
 *   import { CharacterRepository } from 'core';
 *   const list = await CharacterRepository.findAll('genshin', '123456789');
 *   const detail = await CharacterRepository.findById('genshin', '123456789', '10000120');
 *   const top10 = await CharacterRepository.findTopByRelicScore('genshin', '123456789', 10);
 */

import { GameDataDao } from '../database/GameDataDao';
import { GameStatsDao } from '../database/GameStatsDao';
import { QueryBuilder } from '../database/QueryBuilder';
import { GameDataSummary, GameDataRow, DataType } from '../models/GameDataRow';
import { ScoredEntity, StatKey } from '../models/GameStatsRow';

export class CharacterRepository {

  /**
   * 查询角色摘要列表（不含 raw_json），按稀有度+等级降序。
   * 适用于角色列表页，性能最优。
   *
   * @param gameId  游戏标识
   * @param roleUid 游戏内 UID
   */
  static async findAll(
    gameId: string,
    roleUid: string
  ): Promise<GameDataSummary[]> {
    // 先按 rarity 降序，再按 level 降序
    const builder = new QueryBuilder('game_data')
      .equalTo('game_id', gameId)
      .equalTo('role_uid', roleUid)
      .equalTo('data_type', DataType.CHARACTER)
      .orderByDesc('rarity')
      .columns(['entity_id', 'name', 'rarity', 'level', 'extra_int1', 'extra_int2', 'extra_text1', 'update_time',
        'game_id', 'role_uid', 'data_type', 'id']);
    const rows = await GameDataDao.findByBuilder(builder);
    return rows as GameDataSummary[];
  }

  /**
   * 查询单个角色完整数据（含 raw_json）。
   * 适用于角色详情页，按需加载。
   *
   * @returns 找到返回 GameDataRow，未找到返回 null
   */
  static async findById(
    gameId: string,
    roleUid: string,
    entityId: string
  ): Promise<GameDataRow | null> {
    return GameDataDao.findOne(gameId, roleUid, DataType.CHARACTER, entityId);
  }

  /**
   * 按元素属性过滤角色（不含 raw_json）。
   * extra_text1 存储元素属性（"Electro" / "Pyro" 等）。
   *
   * @param element 元素名称，如 "Electro"
   */
  static async findByElement(
    gameId: string,
    roleUid: string,
    element: string
  ): Promise<GameDataSummary[]> {
    return GameDataDao.findSummaries(
      gameId, roleUid, DataType.CHARACTER, 'level', true
    ).then(rows => rows.filter(r => r.extraText1 === element));
  }

  /**
   * 按稀有度过滤角色（不含 raw_json）。
   *
   * @param rarity 稀有度，如 5
   */
  static async findByRarity(
    gameId: string,
    roleUid: string,
    rarity: number
  ): Promise<GameDataSummary[]> {
    const builder = new QueryBuilder('game_data')
      .equalTo('game_id', gameId)
      .equalTo('role_uid', roleUid)
      .equalTo('data_type', DataType.CHARACTER)
      .equalTo('rarity', rarity)
      .orderByDesc('level')
      .columns(['entity_id', 'name', 'rarity', 'level', 'extra_int1', 'extra_int2', 'extra_text1', 'update_time',
        'game_id', 'role_uid', 'data_type', 'id']);
    const rows = await GameDataDao.findByBuilder(builder);
    return rows as GameDataSummary[];
  }

  /**
   * 按装备分排行，返回前 N 名角色。
   * 直接查 game_stats 表，不需要 parse JSON，性能极佳。
   *
   * @param topN 返回前 N 名，不传则返回全部
   */
  static async findTopByRelicScore(
    gameId: string,
    roleUid: string,
    topN?: number
  ): Promise<ScoredEntity[]> {
    return GameStatsDao.findRanking(gameId, roleUid, StatKey.RELIC_SCORE, topN);
  }

  /**
   * 查询未毕业的角色列表。
   * is_graduated = 0 表示未毕业。
   */
  static async findNotGraduated(
    gameId: string,
    roleUid: string
  ): Promise<ScoredEntity[]> {
    return GameStatsDao.findNotGraduated(gameId, roleUid);
  }

  /**
   * 按名称搜索角色（跨游戏）。
   *
   * @param keyword 搜索关键词
   * @param gameId  可选，限定游戏
   */
  static async search(
    keyword: string,
    gameId?: string
  ): Promise<GameDataSummary[]> {
    return GameDataDao.searchByName(keyword, gameId, DataType.CHARACTER);
  }

  /**
   * 全量写入角色数据（网络拉取后调用）。
   * 在单个事务中完成，保证原子性。
   *
   * @param rows 角色数据数组
   */
  static async saveAll(rows: GameDataRow[]): Promise<void> {
    return GameDataDao.batchUpsert(rows);
  }

  /**
   * 清空指定游戏+用户的所有角色数据。
   * 切换账号时调用。
   */
  static async clearAll(gameId: string, roleUid: string): Promise<void> {
    await GameDataDao.deleteByType(gameId, roleUid, DataType.CHARACTER);
  }
}
