export enum ZZZApiPath {
  /** 实时便笺 */
  DAILY_NOTE = '/event/game_record_zzz/api/zzz/note',
  /** Widget 实时便笺（无 1034，需要 stoken Cookie） */
  DAILY_NOTE_WIDGET = '/event/game_record_zzz/api/zzz/widget',
  /** 代理人列表 */
  AVATAR_BASIC = '/event/game_record_zzz/api/zzz/avatar/basic',
  /** 代理人详情 */
  AVATAR_INFO = '/event/game_record_zzz/api/zzz/avatar/info',
  /** 邦布列表 */
  BUDDY_LIST = '/event/game_record_zzz/api/zzz/buddy/info',
  /** 养成材料计算 */
  COMPUTE = '/event/nap_cultivate_tool/avatar_calc',
}
