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
 *
 * 适用范围说明：
 *   relic_score    - 原神圣遗物评分 / 星铁遗器评分 / 绝区零驱动盘评分
 *   is_graduated   - 是否毕业（1=是, 0=否）
 *   crit_rate      - 暴击率(%)，原神/星铁/绝区零通用
 *   crit_dmg       - 暴击伤害(%)，原神/星铁/绝区零通用
 *   pity_count     - 当前保底计数，所有抽卡游戏
 *   up_pity_count  - 大保底计数(0或1)，所有抽卡游戏
 *   anomaly_mastery - 异常精通，绝区零专用
 *   break_effect   - 击破特攻(%)，星铁专用
 */
export class StatKey {
  static readonly RELIC_SCORE: string = 'relic_score';
  static readonly IS_GRADUATED: string = 'is_graduated';
  static readonly CRIT_RATE: string = 'crit_rate';
  static readonly CRIT_DMG: string = 'crit_dmg';
  static readonly PITY_COUNT: string = 'pity_count';
  static readonly UP_PITY_COUNT: string = 'up_pity_count';
  /** 绝区零：异常精通 */
  static readonly ANOMALY_MASTERY: string = 'anomaly_mastery';
  /** 星铁：击破特攻 */
  static readonly BREAK_EFFECT: string = 'break_effect';
}
