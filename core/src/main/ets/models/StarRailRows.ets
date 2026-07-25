/**
 * StarRailRows.ets
 *
 * 崩坏：星穹铁道游戏数据数据库行模型，对应四张星铁专用表：
 *   starrail_avatar_basic   — 角色基础列表
 *   starrail_daily_note     — 实时便笺
 *   starrail_avatar_info    — 角色详情
 *   starrail_avatar_compute — 角色养成计算
 */

export class StarRailAvatarBasicRow {
  /** 本地数据库自增 ID */
  id: number = 0;
  /** 所属账号 ID（外键） */
  accountId: string = '';
  /** 游戏角色 UID */
  roleUid: string = '';
  /** 角色 ID（字符串，如 '1001'） */
  avatarId: string = '';
  /** 角色名称 */
  name: string = '';
  /** 元素属性字符串（如 'Fire'、'Ice'） */
  element: string = '';
  /** 星级（4 或 5） */
  rarity: number = 0;
  /** 角色等级（1-80） */
  level: number = 0;
  /** 星魂数（0-6） */
  rank: number = 0;
  /** 命途类型数字（米游社内部字段） */
  baseType: number = 0;
  /** 装备的光锥 ID */
  equipId: string = '';
  /** 光锥名称 */
  equipName: string = '';
  /** 光锥星级 */
  equipRarity: number = 0;
  /** 光锥等级（1-80） */
  equipLevel: number = 0;
  /** 光锥叠影等级（1-5） */
  equipRank: number = 0;
  /** 光锥图标 URL */
  equipIconUrl: string = '';
  /** 是否被选中（0=否，1=是） */
  isChosen: number = 0;
  /** 角色头像图标 URL */
  icon: string = '';
  /** 角色立绘大图 URL（figure_path） */
  figurePath: string = '';
  /** 元素属性 ID（数字，用于图标映射） */
  elementId: number = 0;
  /** 原始 API 响应 JSON（来自 avatar/basic 接口） */
  rawJson: string = '';
  /** 数据更新时间（Unix 秒） */
  updateTime: number = 0;
}

export class StarRailDailyNoteRow {
  /** 本地数据库自增 ID */
  id: number = 0;
  /** 所属账号 ID（外键） */
  accountId: string = '';
  /** 游戏角色 UID */
  roleUid: string = '';
  /** 当前开拓力 */
  currentStamina: number = 0;
  /** 开拓力上限（通常为 300） */
  maxStamina: number = 0;
  /** 开拓力恢复至上限所需秒数（0 表示已满） */
  staminaRecoverTime: number = 0;
  /** 开拓力满时的 Unix 时间戳 */
  staminaFullTs: number = 0;
  /** 当前后备开拓力 */
  currentReserveStamina: number = 0;
  /** 当前进行中的派遣数 */
  acceptedExpeditionNum: number = 0;
  /** 派遣槽位上限 */
  totalExpeditionNum: number = 0;
  /** 当前实训积分 */
  currentTrainScore: number = 0;
  /** 实训积分上限 */
  maxTrainScore: number = 0;
  /** 当前模拟宇宙积分 */
  currentRogueScore: number = 0;
  /** 模拟宇宙积分上限 */
  maxRogueScore: number = 0;
  /** 本周已完成的历战余响次数 */
  weeklyCocoonCnt: number = 0;
  /** 历战余响每周上限 */
  weeklyCocoonLimit: number = 0;
  /** 差分宇宙本周当前积分 */
  rogueTournWeeklyCur: number = 0;
  /** 差分宇宙本周积分上限 */
  rogueTournWeeklyMax: number = 0;
  /** 地城演习本周当前次数 */
  gridFightWeeklyCur: number = 0;
  /** 地城演习本周次数上限 */
  gridFightWeeklyMax: number = 0;
  /** 原始 API 响应 JSON（来自 note 接口） */
  rawJson: string = '';
  /** 数据更新时间（Unix 秒） */
  updateTime: number = 0;
}

export class StarRailAvatarInfoRow {
  /** 本地数据库自增 ID */
  id: number = 0;
  /** 所属账号 ID（外键） */
  accountId: string = '';
  /** 游戏角色 UID */
  roleUid: string = '';
  /** 角色 ID */
  avatarId: string = '';
  /** 装备的光锥 ID */
  equipId: string = '';
  /** 光锥等级 */
  equipLevel: number = 0;
  /** 光锥叠影等级 */
  equipRank: number = 0;
  /** 遗器 ID 列表（逗号分隔） */
  relicIds: string = '';
  /** 行迹节点状态 JSON 字符串 */
  skillTreeJson: string = '';
  /** 原始 API 响应 JSON（来自 avatar/info 接口） */
  rawJson: string = '';
  /** 数据更新时间（Unix 秒） */
  updateTime: number = 0;
}

export class StarRailAvatarComputeRow {
  /** 本地数据库自增 ID */
  id: number = 0;
  /** 所属账号 ID（外键） */
  accountId: string = '';
  /** 游戏角色 UID */
  roleUid: string = '';
  /** 角色 ID */
  avatarId: string = '';
  /** 角色本体养成消耗 JSON */
  avatarConsumeJson: string = '';
  /** 技能养成消耗 JSON */
  skillConsumeJson: string = '';
  /** 光锥养成消耗 JSON */
  equipmentConsumeJson: string = '';
  /** 完整 API 响应 JSON（v2.0.0 新增） */
  rawJson: string = '';
  /** 数据更新时间（Unix 秒） */
  updateTime: number = 0;
}

// ─── API 响应解析用 interface（供 StarRailRepository 内部使用）──

/** 星铁光锥信息（来自 avatar/basic API 响应） */
export interface StarRailEquipItem {
  /** 光锥 ID */
  id: number;
  /** 光锥名称 */
  name: string;
  /** 光锥等级（1-80） */
  level: number;
  /** 叠影等级（1-5） */
  rank: number;
  /** 星级（3-5） */
  rarity: number;
  /** 光锥图标 URL */
  icon: string;
}

/** 星铁角色信息（来自 avatar/basic API 响应） */
export interface StarRailAvatarItem {
  /** 角色 ID */
  id: number;
  /** 角色名称 */
  name: string;
  /** 星级（4 或 5） */
  rarity: number;
  /** 角色等级（1-80） */
  level: number;
  /** 星魂数（0-6） */
  rank: number;
  /** 命途类型数字 */
  base_type: number;
  /** 元素属性字符串（如 'Fire'、'Ice'） */
  element: string;
  /** 元素属性 ID */
  element_id: number;
  /** 角色头像图标 URL */
  icon: string;
  /** 角色立绘大图 URL */
  figure_path: string;
  /** 是否被选中 */
  is_chosen: boolean;
  /** 装备的光锥（可为 null） */
  equip: StarRailEquipItem | null;
}

/** 星铁角色列表 API 响应 data 字段结构（兼容 list 和 avatar_list 两种字段名） */
export interface StarRailAvatarListData {
  list: StarRailAvatarItem[];
  avatar_list: StarRailAvatarItem[];
}
