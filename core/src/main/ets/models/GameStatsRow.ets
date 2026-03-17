/**
 * GameStatsRow.ets
 *
 * game_stats 表的行数据模型。
 *
 * ArkTS 注意事项：
 *   arkts-no-untyped-obj-literals 规则要求对象字面量只能对应 class，不能对应 interface。
 *   GameStatsRow / ScoredEntity 均定义为 class，DAO 层用 new 实例化后逐字段赋值。
 */

/**
 * game_stats 表行模型
 */
export class GameStatsRow {
  id: number = 0;
  gameId: string = '';
  roleUid: string = '';
  entityId: string = '';
  statKey: string = '';
  statValue: number = 0;
  updateTime: number = 0;
}

/**
 * 带角色名称的统计结果（JOIN 查询结果）
 * 用于统计排行页展示
 */
export class ScoredEntity {
  entityId: string = '';
  name: string = '';
  rarity: number = 0;
  level: number = 0;
  extraText1: string = '';
  statKey: string = '';
  statValue: number = 0;
}

/**
 * stat_key 枚举常量
 */
export class StatKey {
  static readonly RELIC_SCORE: string = 'relic_score';
  static readonly IS_GRADUATED: string = 'is_graduated';
  static readonly CRIT_RATE: string = 'crit_rate';
  static readonly CRIT_DMG: string = 'crit_dmg';
  static readonly PITY_COUNT: string = 'pity_count';
  static readonly UP_PITY_COUNT: string = 'up_pity_count';
}
