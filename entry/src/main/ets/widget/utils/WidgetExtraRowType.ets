/**
 * WidgetExtraRowType.ets — 额外信息行类型枚举
 *
 * 用于原神和星铁的额外信息优先级排序。
 * 绝区零直接使用 API 返回的 note_list 字段，不需要此枚举。
 *
 * 注意：
 * - 枚举值必须与 WidgetDataHelper.parseExtraRows() 中使用的 label 字符串一致
 * - 新增类型时，需同步更新 WidgetExtraRowConfig 的优先级配置
 */

/**
 * 额外信息行类型枚举
 */
export enum ExtraRowType {
  // ── 原神 ──
  /** 探索派遣 */
  GENSHIN_EXPEDITION = 'expedition',
  /** 洞天宝钱 */
  GENSHIN_HOME_COIN = 'home_coin',
  /** 每日委托 */
  GENSHIN_DAILY_TASK = 'daily_task',
  /** 参量质变仪 */
  GENSHIN_TRANSFORMER = 'transformer',
  /** 周活跃进度 */
  GENSHIN_WEEK_ACTIVE = 'week_active',

  // ── 星铁 ──
  /** 委托派遣 */
  STARRAIL_EXPEDITION = 'starrail_expedition',
  /** 每日实训/周期积分 */
  STARRAIL_TRAIN_SCORE = 'train_score',
  /** 模拟宇宙积分 */
  STARRAIL_ROGUE_TOURN = 'rogue_tourn',
}
