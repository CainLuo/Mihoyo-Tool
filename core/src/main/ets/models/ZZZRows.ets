/**
 * ZZZRows.ets
 *
 * 绝区零游戏数据数据库行模型，对应五张绝区零专用表：
 *   zzz_avatar_basic   — 代理人基础列表
 *   zzz_daily_note     — 实时便笺
 *   zzz_avatar_info    — 代理人详情
 *   zzz_avatar_compute — 代理人养成计算
 *   zzz_buddy          — 邦布列表
 */

export class ZZZAvatarBasicRow {
  /** 本地数据库自增 ID */
  id: number = 0;
  /** 所属账号 ID（外键） */
  accountId: string = '';
  /** 游戏角色 UID */
  roleUid: string = '';
  /** 代理人 ID（字符串，如 '1011'） */
  avatarId: string = '';
  /** 代理人名称（i18n key） */
  nameMi18n: string = '';
  /** 代理人全名（i18n key） */
  fullNameMi18n: string = '';
  /** 属性类型数字（200=电，210=以太，等） */
  elementType: number = 0;
  /** 副属性类型数字 */
  subElementType: number = 0;
  /** 职业类型数字（1=强攻，2=击破，3=异常，4=支援，5=防护） */
  avatarProfession: number = 0;
  /** 稀有度（'S' 或 'A'） */
  rarity: string = '';
  /** 代理人等级（1-60） */
  level: number = 0;
  /** 影画数（0-6） */
  rank: number = 0;
  /** 阵营名称（i18n key） */
  campNameMi18n: string = '';
  /** 阵营图标 URL */
  groupIconPath: string = '';
  /** 空洞图标 URL */
  hollowIconPath: string = '';
  /** 代理人方形图标 URL（用于角色卡片） */
  roleSquareUrl: string = '';
  /** 觉醒状态（DB 存 TEXT，读取时 parseInt 转 number；0=未知/不可见） */
  awakenState: number = 0;
  /** 是否被选中（0=否，1=是） */
  isChosen: number = 0;
  /** 原始 API 响应 JSON（来自 avatar/basic 接口） */
  rawJson: string = '';
  /** 数据更新时间（Unix 秒） */
  updateTime: number = 0;
}

export class ZZZDailyNoteRow {
  /** 本地数据库自增 ID */
  id: number = 0;
  /** 所属账号 ID（外键） */
  accountId: string = '';
  /** 游戏角色 UID */
  roleUid: string = '';
  /** 当前电量 */
  energyCurrent: number = 0;
  /** 电量上限（通常为 240） */
  energyMax: number = 0;
  /** 电量恢复至上限所需秒数（0 表示已满） */
  energyRestore: number = 0;
  /** 当前活跃度 */
  vitalityCurrent: number = 0;
  /** 活跃度上限（通常为 400） */
  vitalityMax: number = 0;
  /** 录像店营业状态（'SaleStateDoing'=营业中，'SaleStateDone'=已结算，'SaleStateNo'=未开启） */
  vhsSaleState: string = '';
  /** 刮刮卡状态（'CardSignDone'=已完成，'CardSignNo'=未完成） */
  cardSign: string = '';
  /** 原始 API 响应 JSON（来自 zzz/note 接口） */
  rawJson: string = '';
  /** 数据更新时间（Unix 秒） */
  updateTime: number = 0;
}

export class ZZZAvatarInfoRow {
  /** 本地数据库自增 ID */
  id: number = 0;
  /** 所属账号 ID（外键） */
  accountId: string = '';
  /** 游戏角色 UID */
  roleUid: string = '';
  /** 代理人 ID */
  avatarId: string = '';
  /** 装备的音擎 ID */
  weaponId: string = '';
  /** 音擎等级（1-60） */
  weaponLevel: number = 0;
  /** 音擎精炼等级（1-5，对应 star 字段） */
  weaponStar: number = 0;
  /** 驱动盘 ID 列表（逗号分隔，最多 6 件） */
  equipIds: string = '';
  /** 技能等级 JSON 字符串 */
  skillLevelsJson: string = '';
  /** 代理人竖版立绘 URL */
  verticalPaintingUrl: string = '';
  /** 原始 API 响应 JSON（来自 avatar/info 接口） */
  rawJson: string = '';
  /** 数据更新时间（Unix 秒） */
  updateTime: number = 0;
}

export class ZZZAvatarComputeRow {
  /** 本地数据库自增 ID */
  id: number = 0;
  /** 所属账号 ID（外键） */
  accountId: string = '';
  /** 游戏角色 UID */
  roleUid: string = '';
  /** 代理人 ID */
  avatarId: string = '';
  /** 代理人本体养成消耗 JSON */
  avatarConsumeJson: string = '';
  /** 音擎养成消耗 JSON */
  weaponConsumeJson: string = '';
  /** 技能养成消耗 JSON */
  skillConsumeJson: string = '';
  /** 数据更新时间（Unix 秒） */
  updateTime: number = 0;
}

export class ZZZBuddyRow {
  /** 本地数据库自增 ID */
  id: number = 0;
  /** 所属账号 ID（外键） */
  accountId: string = '';
  /** 游戏角色 UID */
  roleUid: string = '';
  /** 邦布 ID */
  buddyId: string = '';
  /** 邦布名称 */
  name: string = '';
  /** 稀有度（'S' 或 'A'） */
  rarity: string = '';
  /** 邦布等级（1-60） */
  level: number = 0;
  /** 精炼等级（1-5，对应 star 字段） */
  star: number = 0;
  /** 邦布方形图标 URL */
  bangbooSquareUrl: string = '';
  /** 原始 API 响应 JSON */
  rawJson: string = '';
  /** 数据更新时间（Unix 秒） */
  updateTime: number = 0;
}

// ─── API 响应解析用 interface（供 ZZZRepository 内部使用）────────

/** 绝区零代理人信息（来自 avatar/basic API 响应） */
export interface ZZZAvatarItem {
  /** 代理人 ID */
  id: number;
  /** 代理人名称（i18n key） */
  name_mi18n: string;
  /** 代理人全名（i18n key） */
  full_name_mi18n: string;
  /** 稀有度（'S' 或 'A'） */
  rarity: string;
  /** 代理人等级（1-60） */
  level: number;
  /** 影画数（0-6） */
  rank: number;
  /** 属性类型数字（200=电，210=以太，等） */
  element_type: number;
  /** 副属性类型数字 */
  sub_element_type: number;
  /** 职业类型数字（1=强攻，2=击破，3=异常，4=支援，5=防护） */
  avatar_profession: number;
  /** 阵营名称（i18n key） */
  camp_name_mi18n: string;
  /** 阵营图标 URL */
  group_icon_path: string;
  /** 空洞图标 URL */
  hollow_icon_path: string;
  /** 代理人方形图标 URL */
  role_square_url: string;
  /** 是否被选中 */
  is_chosen: boolean;
  /** 觉醒状态字符串枚举 */
  awaken_state: string;
}

/** 绝区零代理人列表 API 响应 data 字段结构 */
export interface ZZZAvatarListData {
  avatar_list: ZZZAvatarItem[];
}
