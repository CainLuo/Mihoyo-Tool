/**
 * GenshinRows.ets
 *
 * 原神游戏数据数据库行模型，对应四张原神专用表：
 *   genshin_character_list    — 角色列表
 *   genshin_daily_note        — 实时便笺
 *   genshin_character_detail  — 角色详情
 *   genshin_character_compute — 角色养成计算
 */

export class GenshinCharacterListRow {
  /** 本地数据库自增 ID */
  id: number = 0;
  /** 所属账号 ID（外键） */
  accountId: string = '';
  /** 游戏角色 UID */
  roleUid: string = '';
  /** 角色 ID（字符串，如 '10000025'） */
  avatarId: string = '';
  /** 角色名称 */
  name: string = '';
  /** 元素属性（如 'Anemo'、'Hydro'） */
  element: string = '';
  /** 星级（4 或 5） */
  rarity: number = 0;
  /** 角色等级（1-90） */
  level: number = 0;
  /** 好感度（0-10） */
  fetter: number = 0;
  /** 已激活命座数（0-6） */
  activedConstellationNum: number = 0;
  /** 武器类型数字（米游社内部字段） */
  weaponType: number = 0;
  /** 武器 ID */
  weaponId: string = '';
  /** 武器名称 */
  weaponName: string = '';
  /** 武器星级 */
  weaponRarity: number = 0;
  /** 武器等级（1-90） */
  weaponLevel: number = 0;
  /** 武器精炼等级（1-5） */
  weaponAffixLevel: number = 0;
  /** 武器图标 URL */
  weaponIconUrl: string = '';
  /** 角色立绘大图 URL */
  image: string = '';
  /** 是否被选中（0=否，1=是） */
  isChosen: number = 0;
  /** 角色头像图标 URL */
  icon: string = '';
  /** 角色侧面图标 URL（用于角色卡片） */
  sideIcon: string = '';
  /** 原始 API 响应 JSON（来自 character/list 接口） */
  rawJson: string = '';
  /** 数据更新时间（Unix 秒） */
  updateTime: number = 0;
}

export class GenshinDailyNoteRow {
  /** 本地数据库自增 ID */
  id: number = 0;
  /** 所属账号 ID（外键） */
  accountId: string = '';
  /** 游戏角色 UID */
  roleUid: string = '';
  /** 当前原粹树脂 */
  currentResin: number = 0;
  /** 原粹树脂上限（通常为 200） */
  maxResin: number = 0;
  /** 树脂恢复至上限所需秒数（0 表示已满） */
  resinRecoveryTime: number = 0;
  /** 已完成的每日委托数 */
  finishedTaskNum: number = 0;
  /** 每日委托总数（通常为 4） */
  totalTaskNum: number = 0;
  /** 剩余周本折扣次数 */
  remainResinDiscountNum: number = 0;
  /** 当前派遣中的角色数 */
  currentExpeditionNum: number = 0;
  /** 派遣槽位上限 */
  maxExpeditionNum: number = 0;
  /** 当前洞天宝钱 */
  currentHomeCoin: number = 0;
  /** 洞天宝钱上限 */
  maxHomeCoin: number = 0;
  /** 参量质变仪恢复剩余天数（0 表示可使用） */
  transformerRecoveryDay: number = 0;
  /** 原始 API 响应 JSON（来自 dailyNote 接口） */
  rawJson: string = '';
  /** 数据更新时间（Unix 秒） */
  updateTime: number = 0;
}

export class GenshinCharacterDetailRow {
  /** 本地数据库自增 ID */
  id: number = 0;
  /** 所属账号 ID（外键） */
  accountId: string = '';
  /** 游戏角色 UID */
  roleUid: string = '';
  /** 角色 ID */
  avatarId: string = '';
  /** 武器 ID */
  weaponId: string = '';
  /** 武器等级 */
  weaponLevel: number = 0;
  /** 武器精炼等级 */
  weaponAffixLevel: number = 0;
  /** 圣遗物 ID 列表（逗号分隔） */
  relicIds: string = '';
  /** 技能等级 JSON 字符串 */
  skillLevels: string = '';
  /** 原始 API 响应 JSON（来自 character/detail 接口） */
  rawJson: string = '';
  /** 数据更新时间（Unix 秒） */
  updateTime: number = 0;
}

export class GenshinCharacterComputeRow {
  /** 本地数据库自增 ID */
  id: number = 0;
  /** 所属账号 ID（外键） */
  accountId: string = '';
  /** 游戏角色 UID */
  roleUid: string = '';
  /** 角色 ID */
  avatarId: string = '';
  /** API items[i].avatar_consume（原样 JSON） */
  avatarConsumeJson: string = '';
  /** API items[i].avatar_skill_consume（原样 JSON） */
  avatarSkillConsumeJson: string = '';
  /** API items[i].weapon_consume（原样 JSON） */
  weaponConsumeJson: string = '';
  /** API items[i].skills_consume（原样 JSON） */
  skillsConsumeJson: string = '';
  /** API single_role_result[i].overall_consume（原样 JSON，lack_num 为该角色的真实缺口；无单角色结果时为空） */
  overallConsumeJson: string = '';
  /** API 单角色结果原样 JSON：single_role_result[i]（无则为 items[i]） */
  rawJson: string = '';
  /** 数据更新时间（Unix 秒） */
  updateTime: number = 0;
}

/**
 * 原神养成计算整批合计行（genshin_compute_summary，DB v5 新增）
 * 字段与 batch_compute 顶层 data 一致；每个 (accountId, roleUid) 一行
 */
export class GenshinComputeSummaryRow {
  /** 本地数据库自增 ID */
  id: number = 0;
  /** 所属账号 ID（外键） */
  accountId: string = '';
  /** 游戏角色 UID */
  roleUid: string = '';
  /** 本批计算的角色 ID（逗号分隔，按请求顺序） */
  avatarIds: string = '';
  /** data.overall_consume（原样 JSON） */
  overallConsumeJson: string = '';
  /** data.overall_material_consume（原样 JSON） */
  overallMaterialConsumeJson: string = '';
  /** data.available_material（原样 JSON） */
  availableMaterialJson: string = '';
  /** data.has_user_info（1 / 0） */
  hasUserInfo: number = 0;
  /** data 原样 JSON */
  rawJson: string = '';
  /** 数据更新时间（Unix 秒） */
  updateTime: number = 0;
}

/**
 * 原神养成计算器角色行（genshin_calc_avatar，DB v4 新增）
 * 字段与计算器 sync/avatar/list 的 data.list[] 一致（avatarId ↔ id）
 */
export class GenshinCalcAvatarRow {
  /** 本地数据库自增 ID */
  id: number = 0;
  /** 所属账号 ID（外键） */
  accountId: string = '';
  /** 游戏角色 UID */
  roleUid: string = '';
  /** API id */
  avatarId: string = '';
  name: string = '';
  icon: string = '';
  weaponCatId: number = 0;
  /** API avatar_level：角色稀有度 */
  avatarLevel: number = 0;
  elementAttrId: number = 0;
  maxLevel: number = 0;
  levelCurrent: number = 0;
  promoteLevel: number = 0;
  constellationNum: number = 0;
  fetterLevel: number = 0;
  /** API skill_list（原样 JSON） */
  skillListJson: string = '';
  /** API weapon（原样 JSON） */
  weaponJson: string = '';
  /** API reliquary_list（原样 JSON） */
  reliquaryListJson: string = '';
  /** API data.list[i] 原样 JSON */
  rawJson: string = '';
  /** 数据更新时间（Unix 秒） */
  updateTime: number = 0;
}

// ─── API 响应解析用 interface（供 GenshinRepository 内部使用）────

/** 原神武器信息（来自 character/list API 响应） */
export interface GenshinWeaponItem {
  /** 武器 ID */
  id: number;
  /** 武器名称 */
  name: string;
  /** 武器等级（1-90） */
  level: number;
  /** 精炼等级（1-5） */
  affix_level: number;
  /** 星级（3-5） */
  rarity: number;
  /** 武器图标 URL */
  icon: string;
}

/** 原神角色信息（来自 character/list API 响应） */
export interface GenshinCharacterItem {
  /** 角色 ID */
  id: number;
  /** 角色名称 */
  name: string;
  /** 元素属性（如 'Anemo'、'Hydro'） */
  element: string;
  /** 星级（4 或 5） */
  rarity: number;
  /** 角色等级（1-90） */
  level: number;
  /** 好感度（0-10） */
  fetter: number;
  /** 已激活命座数（0-6） */
  actived_constellation_num: number;
  /** 角色立绘大图 URL */
  image: string;
  /** 是否被选中 */
  is_chosen: boolean;
  /** 角色头像图标 URL */
  icon: string;
  /** 角色侧面图标 URL */
  side_icon: string;
  /** 武器类型数字 */
  weapon_type: number;
  /** 装备的武器（可为 null） */
  weapon: GenshinWeaponItem | null;
}

/** 原神角色列表 API 响应 data 字段结构 */
export interface GenshinCharacterListData {
  list: GenshinCharacterItem[];
}
