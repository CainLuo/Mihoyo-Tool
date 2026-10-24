export enum StarRailApiPath {
  /** 实时便笺（需要有效的 x-rpc-device_fp） */
  DAILY_NOTE = '/game_record/app/hkrpg/api/note',
  /** Widget 实时便笺（无 1034，需要 stoken Cookie） */
  DAILY_NOTE_WIDGET = '/game_record/app/hkrpg/aapi/widget',
  /** 角色列表 */
  AVATAR_BASIC = '/game_record/app/hkrpg/api/avatar/basic',
  /** 角色详情 */
  AVATAR_INFO = '/game_record/app/hkrpg/api/avatar/info',
  /** 养成材料计算 */
  COMPUTE = '/event/rpgcalc/compute',
}
