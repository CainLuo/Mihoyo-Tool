export enum GenshinApiPath {
  /** 实时便笺 */
  DAILY_NOTE = '/game_record/app/genshin/api/dailyNote',
  /** Widget 实时便笺（无 1034，需要 stoken Cookie） */
  DAILY_NOTE_WIDGET = '/game_record/app/genshin/aapi/widget/v2',
  /** 角色列表 */
  CHARACTER_LIST = '/game_record/app/genshin/api/character/list',
  /** 角色详情 */
  CHARACTER_DETAIL = '/game_record/app/genshin/api/character/detail',
  /** 养成材料批量计算 */
  BATCH_COMPUTE = '/event/e20200928calculate/v3/batch_compute',
}
