import { TableName } from '../../db/TableName';
import { CommonCol, ComputeStateCol, ColumnDef, TableDef, IndexDef, FK_ACCOUNT } from '../../db/TableSchema';
import { MaterialBagCol, MaterialTargetConfigCol } from '../../common/material/db/schema';

/**
 * genshin_character_list 专属列名。
 * 存储原神角色列表的基础属性和当前装备武器的摘要信息。
 */
export enum GenshinCharListCol {
  /** 角色名称（中文，如 '纳西妲'） */
  NAME                      = 'name',
  /** 元素属性（如 'Dendro'=草，'Hydro'=水） */
  ELEMENT                   = 'element',
  /** 角色稀有度（4=四星，5=五星） */
  RARITY                    = 'rarity',
  /** 角色当前等级（1-90） */
  LEVEL                     = 'level',
  /** 好感度等级（0-10） */
  FETTER                    = 'fetter',
  /** 已激活命座数量（0-6） */
  ACTIVED_CONSTELLATION_NUM = 'actived_constellation_num',
  /** 武器类型枚举值（1=单手剑，2=双手剑，3=长柄，4=弓，5=法器） */
  WEAPON_TYPE               = 'weapon_type',
  /** 武器 ID（米游社内部 ID） */
  WEAPON_ID                 = 'weapon_id',
  /** 武器名称 */
  WEAPON_NAME               = 'weapon_name',
  /** 武器稀有度（3-5） */
  WEAPON_RARITY             = 'weapon_rarity',
  /** 武器等级（1-90） */
  WEAPON_LEVEL              = 'weapon_level',
  /** 武器精炼等级（1-5） */
  WEAPON_AFFIX_LEVEL        = 'weapon_affix_level',
  /** 武器图标 URL */
  WEAPON_ICON_URL           = 'weapon_icon_url',
  /** 角色立绘大图 URL */
  IMAGE                     = 'image',
  /** 是否被选中（0=否，1=是） */
  IS_CHOSEN                 = 'is_chosen',
  /** 角色头像图片 URL */
  ICON                      = 'icon',
  /** 角色侧面小图 URL（用于列表展示） */
  SIDE_ICON                 = 'side_icon',
}

/**
 * genshin_daily_note 专属列名。
 * 存储原神实时便笺的各项数值，每个角色（roleUid）只保留一条最新记录。
 */
export enum GenshinDailyNoteCol {
  /** 当前原粹树脂数量 */
  CURRENT_RESIN              = 'current_resin',
  /** 原粹树脂上限（通常为 200） */
  MAX_RESIN                  = 'max_resin',
  /** 树脂完全恢复所需秒数（0 表示已满） */
  RESIN_RECOVERY_TIME        = 'resin_recovery_time',
  /** 已完成的每日委托数量 */
  FINISHED_TASK_NUM          = 'finished_task_num',
  /** 每日委托总数（通常为 4） */
  TOTAL_TASK_NUM             = 'total_task_num',
  /** 剩余周本折扣次数 */
  REMAIN_RESIN_DISCOUNT_NUM  = 'remain_resin_discount_num',
  /** 当前派遣中的角色数量 */
  CURRENT_EXPEDITION_NUM     = 'current_expedition_num',
  /** 派遣槽位上限 */
  MAX_EXPEDITION_NUM         = 'max_expedition_num',
  /** 当前洞天宝钱数量 */
  CURRENT_HOME_COIN          = 'current_home_coin',
  /** 洞天宝钱上限 */
  MAX_HOME_COIN              = 'max_home_coin',
  /** 参量质变仪恢复剩余天数（0 表示可使用） */
  TRANSFORMER_RECOVERY_DAY   = 'transformer_recovery_day',
}

/**
 * genshin_character_detail 专属列名。
 * 存储原神角色的完整配装数据，每个角色（avatarId）只保留一条最新记录。
 */
export enum GenshinCharDetailCol {
  /** 武器 ID */
  WEAPON_ID          = 'weapon_id',
  /** 武器等级 */
  WEAPON_LEVEL       = 'weapon_level',
  /** 武器精炼等级 */
  WEAPON_AFFIX_LEVEL = 'weapon_affix_level',
  /** 圣遗物 ID 列表（JSON 数组字符串） */
  RELIC_IDS          = 'relic_ids',
  /** 技能等级 JSON（键为技能 ID，值为等级） */
  SKILL_LEVELS       = 'skill_levels',
}

/**
 * genshin_character_compute 专属列名（v4 起与 batch_compute API 字段一致）。
 * 每个角色（avatarId）只保留一条最新记录。
 * API：data.single_role_result[i]（单角色结果）/ data.items[i]（与请求 items 按顺序一一对应，不含 avatar_id）
 */
export enum GenshinCharComputeCol {
  /** items[i].avatar_consume：角色等级材料 */
  AVATAR_CONSUME_JSON       = 'avatar_consume_json',
  /** items[i].avatar_skill_consume：天赋材料合计（v4 由 skill_consume_json 更名） */
  AVATAR_SKILL_CONSUME_JSON = 'avatar_skill_consume_json',
  /** items[i].weapon_consume：武器材料 */
  WEAPON_CONSUME_JSON       = 'weapon_consume_json',
  /** items[i].skills_consume：按天赋拆分的材料（v4 新增） */
  SKILLS_CONSUME_JSON       = 'skills_consume_json',
  /** single_role_result[i].overall_consume：该角色合计材料，lack_num 为扣除背包（含合成）后的缺口（v4 新增） */
  OVERALL_CONSUME_JSON      = 'overall_consume_json',
}

/**
 * genshin_compute_summary 专属列名（v5 新增，与 batch_compute 顶层 data 字段一致）。
 * 每个 (account_id, role_uid) 一行，对应最近一次计算的整批结果。
 */
export enum GenshinComputeSummaryCol {
  /** 本批计算的角色 ID（逗号分隔，按请求顺序；API 不返回，取自请求参数） */
  AVATAR_IDS                    = 'avatar_ids',
  /** data.overall_consume：全部角色合计材料，lack_num 为扣除背包（含合成）后的真实总缺口 */
  OVERALL_CONSUME_JSON          = 'overall_consume_json',
  /** data.overall_material_consume：按来源分类的合计材料 */
  OVERALL_MATERIAL_CONSUME_JSON = 'overall_material_consume_json',
  /** data.available_material：接口返回的可用材料（只含部分材料，不是完整背包） */
  AVAILABLE_MATERIAL_JSON       = 'available_material_json',
  /** data.has_user_info：是否包含用户背包信息（1 / 0） */
  HAS_USER_INFO                 = 'has_user_info',
}

/**
 * genshin_calc_avatar 专属列名（v4 新增，与计算器 sync/avatar/list 的 data.list[] 字段一致）。
 * avatar_id 对应 API 的 id；skill_list / weapon / reliquary_list 为嵌套结构，以 JSON 存储。
 */
export enum GenshinCalcAvatarCol {
  /** 角色名称 */
  NAME                = 'name',
  /** 角色图标 */
  ICON                = 'icon',
  /** 武器类型 ID（1 单手剑 / 10 法器 / 11 双手剑 / 12 弓 / 13 长柄） */
  WEAPON_CAT_ID       = 'weapon_cat_id',
  /** 角色稀有度 */
  AVATAR_LEVEL        = 'avatar_level',
  /** 元素 ID（1 火 / 2 风 / 3 岩 / 4 草 / 5 雷 / 6 水 / 7 冰） */
  ELEMENT_ATTR_ID     = 'element_attr_id',
  /** 最高等级 */
  MAX_LEVEL           = 'max_level',
  /** 当前等级 */
  LEVEL_CURRENT       = 'level_current',
  /** 当前突破等级 */
  PROMOTE_LEVEL       = 'promote_level',
  /** 已激活命座数 */
  CONSTELLATION_NUM   = 'constellation_num',
  /** 好感等级 */
  FETTER_LEVEL        = 'fetter_level',
  /** skill_list（含 id / group_id / max_level / level_current） */
  SKILL_LIST_JSON     = 'skill_list_json',
  /** weapon（含 weapon_cat_id / weapon_level 星级 / max_level / level_current） */
  WEAPON_JSON         = 'weapon_json',
  /** reliquary_list */
  RELIQUARY_LIST_JSON = 'reliquary_list_json',
}

// ── 表 3：genshin_character_list ─────────────────────────────
export const GENSHIN_CHARACTER_LIST_TABLE = new TableDef(TableName.GENSHIN_CHARACTER_LIST, [
  new ColumnDef(CommonCol.ID,         'INTEGER', 'PRIMARY KEY AUTOINCREMENT'),
  new ColumnDef(CommonCol.ACCOUNT_ID, 'TEXT', 'NOT NULL'),
  new ColumnDef(CommonCol.ROLE_UID,   'TEXT',    'NOT NULL'),
  new ColumnDef(CommonCol.AVATAR_ID,  'TEXT',    'NOT NULL'),
  new ColumnDef('name',                      'TEXT'),
  new ColumnDef('element',                   'TEXT'),
  new ColumnDef('rarity',                    'INTEGER'),
  new ColumnDef('level',                     'INTEGER'),
  new ColumnDef('fetter',                    'INTEGER'),
  new ColumnDef('actived_constellation_num', 'INTEGER'),
  new ColumnDef('weapon_type',               'INTEGER'),
  new ColumnDef('weapon_id',                 'TEXT'),
  new ColumnDef('weapon_name',               'TEXT'),
  new ColumnDef('weapon_rarity',             'INTEGER'),
  new ColumnDef('weapon_level',              'INTEGER'),
  new ColumnDef('weapon_affix_level',        'INTEGER'),
  new ColumnDef('weapon_icon_url',           'TEXT'),
  new ColumnDef('image',                     'TEXT'),
  new ColumnDef('is_chosen',                 'INTEGER', 'DEFAULT 0'),
  new ColumnDef('icon',                      'TEXT'),
  new ColumnDef('side_icon',                 'TEXT'),
  new ColumnDef(CommonCol.RAW_JSON,    'TEXT',    'NOT NULL'),
  new ColumnDef(CommonCol.UPDATE_TIME, 'INTEGER'),
], FK_ACCOUNT);

// ── 表 4：genshin_daily_note ─────────────────────────────────
export const GENSHIN_DAILY_NOTE_TABLE = new TableDef(TableName.GENSHIN_DAILY_NOTE, [
  new ColumnDef(CommonCol.ID,         'INTEGER', 'PRIMARY KEY AUTOINCREMENT'),
  new ColumnDef(CommonCol.ACCOUNT_ID, 'TEXT', 'NOT NULL'),
  new ColumnDef(CommonCol.ROLE_UID,   'TEXT',    'NOT NULL'),
  new ColumnDef('current_resin',             'INTEGER'),
  new ColumnDef('max_resin',                 'INTEGER'),
  new ColumnDef('resin_recovery_time',       'INTEGER'),
  new ColumnDef('finished_task_num',         'INTEGER'),
  new ColumnDef('total_task_num',            'INTEGER'),
  new ColumnDef('remain_resin_discount_num', 'INTEGER'),
  new ColumnDef('current_expedition_num',    'INTEGER'),
  new ColumnDef('max_expedition_num',        'INTEGER'),
  new ColumnDef('current_home_coin',         'INTEGER'),
  new ColumnDef('max_home_coin',             'INTEGER'),
  new ColumnDef('transformer_recovery_day',  'INTEGER'),
  new ColumnDef(CommonCol.RAW_JSON,    'TEXT',    'NOT NULL'),
  new ColumnDef(CommonCol.UPDATE_TIME, 'INTEGER'),
], FK_ACCOUNT);

// ── 表 5：genshin_character_detail ───────────────────────────
export const GENSHIN_CHARACTER_DETAIL_TABLE = new TableDef(TableName.GENSHIN_CHARACTER_DETAIL, [
  new ColumnDef(CommonCol.ID,         'INTEGER', 'PRIMARY KEY AUTOINCREMENT'),
  new ColumnDef(CommonCol.ACCOUNT_ID, 'TEXT', 'NOT NULL'),
  new ColumnDef(CommonCol.ROLE_UID,   'TEXT',    'NOT NULL'),
  new ColumnDef(CommonCol.AVATAR_ID,  'TEXT',    'NOT NULL'),
  new ColumnDef('weapon_id',          'TEXT'),
  new ColumnDef('weapon_level',       'INTEGER'),
  new ColumnDef('weapon_affix_level', 'INTEGER'),
  new ColumnDef('relic_ids',          'TEXT'),
  new ColumnDef('skill_levels',       'TEXT'),
  new ColumnDef(CommonCol.RAW_JSON,    'TEXT',    'NOT NULL'),
  new ColumnDef(CommonCol.UPDATE_TIME, 'INTEGER'),
], FK_ACCOUNT);

// ── 表 6：genshin_character_compute（v4 重建，列名与 API 一致）────
export const GENSHIN_CHARACTER_COMPUTE_TABLE = new TableDef(TableName.GENSHIN_CHARACTER_COMPUTE, [
  new ColumnDef(CommonCol.ID,         'INTEGER', 'PRIMARY KEY AUTOINCREMENT'),
  new ColumnDef(CommonCol.ACCOUNT_ID, 'TEXT', 'NOT NULL'),
  new ColumnDef(CommonCol.ROLE_UID,   'TEXT',    'NOT NULL'),
  new ColumnDef(CommonCol.AVATAR_ID,  'TEXT',    'NOT NULL'),
  new ColumnDef(GenshinCharComputeCol.AVATAR_CONSUME_JSON,       'TEXT', "DEFAULT ''"),
  new ColumnDef(GenshinCharComputeCol.AVATAR_SKILL_CONSUME_JSON, 'TEXT', "DEFAULT ''"),
  new ColumnDef(GenshinCharComputeCol.WEAPON_CONSUME_JSON,       'TEXT', "DEFAULT ''"),
  new ColumnDef(GenshinCharComputeCol.SKILLS_CONSUME_JSON,       'TEXT', "DEFAULT ''"),
  new ColumnDef(GenshinCharComputeCol.OVERALL_CONSUME_JSON,      'TEXT', "DEFAULT ''"),
  new ColumnDef(CommonCol.RAW_JSON,    'TEXT',    "DEFAULT ''"),
  new ColumnDef(CommonCol.UPDATE_TIME, 'INTEGER'),
  // v7 新增（ALTER TABLE ADD COLUMN 追加在末尾，定义顺序与之保持一致）
  new ColumnDef(ComputeStateCol.TARGET_REACHED, 'INTEGER', 'DEFAULT 0'),
], FK_ACCOUNT);

// ── 表 24：genshin_compute_summary（v5 新增，整批计算合计）────────
export const GENSHIN_COMPUTE_SUMMARY_TABLE = new TableDef(TableName.GENSHIN_COMPUTE_SUMMARY, [
  new ColumnDef(CommonCol.ID,         'INTEGER', 'PRIMARY KEY AUTOINCREMENT'),
  new ColumnDef(CommonCol.ACCOUNT_ID, 'TEXT',    'NOT NULL'),
  new ColumnDef(CommonCol.ROLE_UID,   'TEXT',    'NOT NULL'),
  new ColumnDef(GenshinComputeSummaryCol.AVATAR_IDS,                    'TEXT',    "DEFAULT ''"),
  new ColumnDef(GenshinComputeSummaryCol.OVERALL_CONSUME_JSON,          'TEXT',    "DEFAULT ''"),
  new ColumnDef(GenshinComputeSummaryCol.OVERALL_MATERIAL_CONSUME_JSON, 'TEXT',    "DEFAULT ''"),
  new ColumnDef(GenshinComputeSummaryCol.AVAILABLE_MATERIAL_JSON,       'TEXT',    "DEFAULT ''"),
  new ColumnDef(GenshinComputeSummaryCol.HAS_USER_INFO,                 'INTEGER', 'DEFAULT 0'),
  new ColumnDef(CommonCol.RAW_JSON,    'TEXT',    "DEFAULT ''"),
  new ColumnDef(CommonCol.UPDATE_TIME, 'INTEGER'),
], FK_ACCOUNT);

// ── 表 23：genshin_calc_avatar（v4 新增，计算器同步角色）──────────
export const GENSHIN_CALC_AVATAR_TABLE = new TableDef(TableName.GENSHIN_CALC_AVATAR, [
  new ColumnDef(CommonCol.ID,         'INTEGER', 'PRIMARY KEY AUTOINCREMENT'),
  new ColumnDef(CommonCol.ACCOUNT_ID, 'TEXT',    'NOT NULL'),
  new ColumnDef(CommonCol.ROLE_UID,   'TEXT',    'NOT NULL'),
  new ColumnDef(CommonCol.AVATAR_ID,  'TEXT',    'NOT NULL'),
  new ColumnDef(GenshinCalcAvatarCol.NAME,                'TEXT',    "DEFAULT ''"),
  new ColumnDef(GenshinCalcAvatarCol.ICON,                'TEXT',    "DEFAULT ''"),
  new ColumnDef(GenshinCalcAvatarCol.WEAPON_CAT_ID,       'INTEGER', 'DEFAULT 0'),
  new ColumnDef(GenshinCalcAvatarCol.AVATAR_LEVEL,        'INTEGER', 'DEFAULT 0'),
  new ColumnDef(GenshinCalcAvatarCol.ELEMENT_ATTR_ID,     'INTEGER', 'DEFAULT 0'),
  new ColumnDef(GenshinCalcAvatarCol.MAX_LEVEL,           'INTEGER', 'DEFAULT 0'),
  new ColumnDef(GenshinCalcAvatarCol.LEVEL_CURRENT,       'INTEGER', 'DEFAULT 0'),
  new ColumnDef(GenshinCalcAvatarCol.PROMOTE_LEVEL,       'INTEGER', 'DEFAULT 0'),
  new ColumnDef(GenshinCalcAvatarCol.CONSTELLATION_NUM,   'INTEGER', 'DEFAULT 0'),
  new ColumnDef(GenshinCalcAvatarCol.FETTER_LEVEL,        'INTEGER', 'DEFAULT 0'),
  new ColumnDef(GenshinCalcAvatarCol.SKILL_LIST_JSON,     'TEXT',    "DEFAULT ''"),
  new ColumnDef(GenshinCalcAvatarCol.WEAPON_JSON,         'TEXT',    "DEFAULT ''"),
  new ColumnDef(GenshinCalcAvatarCol.RELIQUARY_LIST_JSON, 'TEXT',    "DEFAULT ''"),
  new ColumnDef(CommonCol.RAW_JSON,    'TEXT',    "DEFAULT ''"),
  new ColumnDef(CommonCol.UPDATE_TIME, 'INTEGER'),
], FK_ACCOUNT);

// ── 表 17：genshin_material_bag（原神材料背包）──────────────────
export const GENSHIN_MATERIAL_BAG_TABLE = new TableDef(TableName.GENSHIN_MATERIAL_BAG, [
  new ColumnDef(CommonCol.ID,              'INTEGER', 'PRIMARY KEY AUTOINCREMENT'),
  new ColumnDef(CommonCol.ACCOUNT_ID,      'TEXT',    'NOT NULL'),
  new ColumnDef(CommonCol.ROLE_UID,        'TEXT',    'NOT NULL'),
  new ColumnDef(MaterialBagCol.MATERIAL_ID,   'TEXT',    'NOT NULL'),
  new ColumnDef(MaterialBagCol.MATERIAL_NAME, 'TEXT',    'NOT NULL'),
  new ColumnDef(MaterialBagCol.MATERIAL_ICON, 'TEXT',    "DEFAULT ''"),
  new ColumnDef(MaterialBagCol.RARITY,        'TEXT',    "DEFAULT ''"),
  new ColumnDef(MaterialBagCol.COUNT,         'INTEGER', 'DEFAULT 0'),
  new ColumnDef(MaterialBagCol.SOURCE,        'TEXT',    "DEFAULT 'api'"),
  new ColumnDef(CommonCol.UPDATE_TIME, 'INTEGER'),
], FK_ACCOUNT);

// ── 表 20：genshin_material_target_config（原神养成目标配置）────────────────
export const GENSHIN_MATERIAL_TARGET_CONFIG_TABLE = new TableDef(TableName.GENSHIN_MATERIAL_TARGET_CONFIG, [
  new ColumnDef(CommonCol.ID,         'INTEGER', 'PRIMARY KEY AUTOINCREMENT'),
  new ColumnDef(CommonCol.ACCOUNT_ID, 'TEXT',    'NOT NULL'),
  new ColumnDef(CommonCol.ROLE_UID,   'TEXT',    'NOT NULL'),
  new ColumnDef(MaterialTargetConfigCol.CONFIG_JSON, 'TEXT', "DEFAULT ''"),
  new ColumnDef(CommonCol.UPDATE_TIME, 'INTEGER'),
], FK_ACCOUNT);

export const IDX_GENSHIN_CHAR_LIST_UNIQUE = new IndexDef('idx_genshin_char_list_unique',  TableName.GENSHIN_CHARACTER_LIST, [CommonCol.ACCOUNT_ID, CommonCol.ROLE_UID, CommonCol.AVATAR_ID], true);
export const IDX_GENSHIN_CHAR_LIST_ELEMENT = new IndexDef('idx_genshin_char_list_element', TableName.GENSHIN_CHARACTER_LIST, [CommonCol.ACCOUNT_ID, CommonCol.ROLE_UID, 'element']);
export const IDX_GENSHIN_CHAR_LIST_RARITY = new IndexDef('idx_genshin_char_list_rarity',  TableName.GENSHIN_CHARACTER_LIST, [CommonCol.ACCOUNT_ID, CommonCol.ROLE_UID, 'rarity']);
export const IDX_GENSHIN_DAILY_NOTE_UNIQUE = new IndexDef('idx_genshin_daily_note_unique', TableName.GENSHIN_DAILY_NOTE, [CommonCol.ACCOUNT_ID, CommonCol.ROLE_UID], true);
export const IDX_GENSHIN_CHAR_DETAIL_UNIQUE = new IndexDef('idx_genshin_char_detail_unique', TableName.GENSHIN_CHARACTER_DETAIL, [CommonCol.ACCOUNT_ID, CommonCol.ROLE_UID, CommonCol.AVATAR_ID], true);
export const IDX_GENSHIN_CHAR_COMPUTE_UNIQUE = new IndexDef('idx_genshin_char_compute_unique', TableName.GENSHIN_CHARACTER_COMPUTE, [CommonCol.ACCOUNT_ID, CommonCol.ROLE_UID, CommonCol.AVATAR_ID], true);
export const IDX_GENSHIN_CALC_AVATAR_UNIQUE = new IndexDef('idx_genshin_calc_avatar_unique', TableName.GENSHIN_CALC_AVATAR, [CommonCol.ACCOUNT_ID, CommonCol.ROLE_UID, CommonCol.AVATAR_ID], true);
export const IDX_GENSHIN_COMPUTE_SUMMARY_UNIQUE = new IndexDef('idx_genshin_compute_summary_unique', TableName.GENSHIN_COMPUTE_SUMMARY, [CommonCol.ACCOUNT_ID, CommonCol.ROLE_UID], true);
export const IDX_GENSHIN_MATERIAL_BAG_UNIQUE = new IndexDef('idx_genshin_material_bag_unique', TableName.GENSHIN_MATERIAL_BAG, [CommonCol.ACCOUNT_ID, CommonCol.ROLE_UID, MaterialBagCol.MATERIAL_ID], true);
export const IDX_GENSHIN_MATERIAL_TARGET_CONFIG_UNIQUE = new IndexDef('idx_genshin_material_target_config_unique', TableName.GENSHIN_MATERIAL_TARGET_CONFIG, [CommonCol.ACCOUNT_ID, CommonCol.ROLE_UID], true);

export const GENSHIN_INDEXES: IndexDef[] = [
  IDX_GENSHIN_CHAR_LIST_UNIQUE,
  IDX_GENSHIN_CHAR_LIST_ELEMENT,
  IDX_GENSHIN_CHAR_LIST_RARITY,
  IDX_GENSHIN_DAILY_NOTE_UNIQUE,
  IDX_GENSHIN_CHAR_DETAIL_UNIQUE,
  IDX_GENSHIN_CHAR_COMPUTE_UNIQUE,
  IDX_GENSHIN_CALC_AVATAR_UNIQUE,
  IDX_GENSHIN_COMPUTE_SUMMARY_UNIQUE,
  IDX_GENSHIN_MATERIAL_BAG_UNIQUE,
  IDX_GENSHIN_MATERIAL_TARGET_CONFIG_UNIQUE,
];
