/**
 * GachaRepository.ets
 *
 * 抽卡记录 Repository。
 * extra_int1 = 卡池类型，extra_int2 = 是否 UP（1=是, 0=否），extra_text1 = 物品类型
 * entity_id 使用抽卡流水号，倒序即为最新在前。
 */

import { GameDataDao } from '../database/GameDataDao';
import { GameStatsDao } from '../database/GameStatsDao';
import { QueryBuilder } from '../database/QueryBuilder';
import { GameDataSummary, GameDataRow, DataType } from '../models/GameDataRow';
import { GameStatsRow, StatKey } from '../models/GameStatsRow';

const GACHA_COLUMNS: string[] = [
  'id', 'game_id', 'role_uid', 'data_type', 'entity_id',
  'name', 'rarity', 'level', 'extra_int1', 'extra_int2',
  'extra_text1', 'update_time'
];

export class GachaRepository {

  /**
   * 查询指定卡池的抽卡记录，最新在前。
   *
   * @param gachaType 卡池类型（extra_int1），如原神 301=角色活动祈愿
   * @param limitCount 返回条数，默认全部
   */
  static async findByPool(
    gameId: string,
    roleUid: string,
    gachaType: number,
    limitCount?: number
  ): Promise<GameDataSummary[]> {
    const builder = new QueryBuilder('game_data')
      .equalTo('game_id', gameId)
      .equalTo('role_uid', roleUid)
      .equalTo('data_type', DataType.GACHA_RECORD)
      .equalTo('extra_int1', gachaType)
      .orderByDesc('entity_id');  // 流水号倒序 = 最新在前
    if (limitCount !== undefined) {
      builder.limit(limitCount);
    }
    builder.columns(GACHA_COLUMNS);
    return GameDataDao.findSummariesByBuilder(builder);
  }

  /**
   * 查询所有五星抽卡记录。
   */
  static async findFiveStars(
    gameId: string,
    roleUid: string
  ): Promise<GameDataSummary[]> {
    const builder = new QueryBuilder('game_data')
      .equalTo('game_id', gameId)
      .equalTo('role_uid', roleUid)
      .equalTo('data_type', DataType.GACHA_RECORD)
      .equalTo('rarity', 5)
      .orderByDesc('entity_id')
      .columns(GACHA_COLUMNS);
    return GameDataDao.findSummariesByBuilder(builder);
  }

  /**
   * 查询当前保底计数（从 game_stats 读取）。
   *
   * @param gachaType 卡池类型
   * @returns 保底计数，未找到返回 0
   */
  static async getPityCount(
    gameId: string,
    roleUid: string,
    gachaType: number
  ): Promise<number> {
    const entityId = `gacha_${gachaType}`;
    const row = await GameStatsDao.findOne(gameId, roleUid, entityId, StatKey.PITY_COUNT);
    return row?.statValue ?? 0;
  }

  /**
   * 查询是否处于大保底状态（从 game_stats 读取）。
   *
   * @returns true = 已触发大保底
   */
  static async isUpGuaranteed(
    gameId: string,
    roleUid: string,
    gachaType: number
  ): Promise<boolean> {
    const entityId = `gacha_${gachaType}`;
    const row = await GameStatsDao.findOne(gameId, roleUid, entityId, StatKey.UP_PITY_COUNT);
    return (row?.statValue ?? 0) === 1;
  }

  /**
   * 全量写入抽卡记录。
   */
  static async saveAll(rows: GameDataRow[]): Promise<void> {
    return GameDataDao.batchUpsert(rows);
  }

  /**
   * 写入保底统计数据。
   *
   * @param gachaType   卡池类型
   * @param pityCount   当前保底计数
   * @param upGuaranteed 是否大保底（true=1, false=0）
   */
  static async savePityStats(
    gameId: string,
    roleUid: string,
    gachaType: number,
    pityCount: number,
    upGuaranteed: boolean
  ): Promise<void> {
    const entityId = `gacha_${gachaType}`;
    const now = Math.floor(Date.now() / 1000);
    const pityRow = new GameStatsRow();
    pityRow.gameId = gameId;
    pityRow.roleUid = roleUid;
    pityRow.entityId = entityId;
    pityRow.statKey = StatKey.PITY_COUNT;
    pityRow.statValue = pityCount;
    pityRow.updateTime = now;

    const upRow = new GameStatsRow();
    upRow.gameId = gameId;
    upRow.roleUid = roleUid;
    upRow.entityId = entityId;
    upRow.statKey = StatKey.UP_PITY_COUNT;
    upRow.statValue = upGuaranteed ? 1 : 0;
    upRow.updateTime = now;
    await GameStatsDao.batchUpsert([pityRow, upRow]);
  }
}
