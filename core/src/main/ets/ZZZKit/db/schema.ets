import { TableName } from '../../db/TableName';
import { CommonCol, ComputeStateCol, ColumnDef, TableDef, IndexDef, FK_ACCOUNT } from '../../db/TableSchema';
import { MaterialBagCol, MaterialTargetConfigCol } from '../../common/material/db/schema';

/**
 * zzz_avatar_basic 专属列名。
 * 存储绝区零代理人的基础属性信息。
 * 注意：rarity 字段为 TEXT 类型（存储 'S' 或 'A'），与原神/星铁的 INTEGER 不同。
 * awakenState 字段在数据库中以 TEXT 存储，读取时需转换为 number。
 */
export enum ZZZAvatarBasicCol {
  /** 代理人名称（米游社 i18n 格式） */
  NAME_MI18N        = 'name_mi18n',
  /** 代理人全名（米游社 i18n 格式） */
  FULL_NAME_MI18N   = 'full_name_mi18n',
  /** 属性类型枚举值（如 200=电，201=以太） */
  ELEMENT_TYPE      = 'element_type',
  /** 副属性类型枚举值 */
  SUB_ELEMENT_TYPE  = 'sub_element_type',
  /** 职业类型枚举值（如 1=强攻，2=击破） */
  AVATAR_PROFESSION = 'avatar_profession',
  /** 稀有度字符串（'S' 或 'A'） */
  RARITY            = 'rarity',
  /** 代理人等级（1-60） */
  LEVEL             = 'level',
  /** 影画数量（0-6，对应原神命座） */
  RANK              = 'rank',
  /** 阵营名称（米游社 i18n 格式） */
  CAMP_NAME_MI18N   = 'camp_name_mi18n',
  /** 阵营图标路径 */
  GROUP_ICON_PATH   = 'group_icon_path',
  /** 空洞图标路径 */
  HOLLOW_ICON_PATH  = 'hollow_icon_path',
  /** 代理人方形头像 URL */
  ROLE_SQUARE_URL   = 'role_square_url',
  /** 觉醒状态（存储为 TEXT，读取时 parseInt 转 number） */
  AWAKEN_STATE      = 'awaken_state',
  /** 是否被选中（0=否，1=是） */
  IS_CHOSEN         = 'is_chosen',
}

/**
 * zzz_daily_note 专属列名。
 * 存储绝区零实时便笺的各项数值，每个角色（roleUid）只保留一条最新记录。
 */
export enum ZZZDailyNoteCol {
  /** 当前电量数值 */
  ENERGY_CURRENT   = 'energy_current',
  /** 电量上限（通常为 240） */
  ENERGY_MAX       = 'energy_max',
  /** 电量完全恢复所需秒数 */
  ENERGY_RESTORE   = 'energy_restore',
  /** 当前活跃度数值 */
  VITALITY_CURRENT = 'vitality_current',
  /** 活跃度上限 */
  VITALITY_MAX     = 'vitality_max',
  /** 录像店营业状态（'SaleStateDoing'=营业中，'SaleStateDone'=已结算，'SaleStateNo'=未开启） */
  VHS_SALE_STATE   = 'vhs_sale_state',
  /** 刮刮卡状态（'CardSignDone'=已完成，'CardSignNo'=未完成） */
  CARD_SIGN        = 'card_sign',
}

/**
 * zzz_avatar_info 专属列名。
 * 存储绝区零代理人的完整配装数据，每个代理人（avatarId）只保留一条最新记录。
 */
export enum ZZZAvatarInfoCol {
  /** 音擎（武器）ID */
  WEAPON_ID             = 'weapon_id',
  /** 音擎等级 */
  WEAPON_LEVEL          = 'weapon_level',
  /** 音擎精炼等级（1-5） */
  WEAPON_STAR           = 'weapon_star',
  /** 驱动盘 ID 列表（JSON 数组字符串） */
  EQUIP_IDS             = 'equip_ids',
  /** 技能等级 JSON（键为技能 ID，值为等级） */
  SKILL_LEVELS_JSON     = 'skill_levels_json',
  /** 代理人竖版立绘 URL */
  VERTICAL_PAINTING_URL = 'vertical_painting_url',
}

/**
 * zzz_avatar_compute 专属列名。
 * 存储绝区零代理人养成计算的材料消耗数据。
 */
export enum ZZZAvatarComputeCol {
  /** 代理人本体升级所需材料 JSON */
  AVATAR_CONSUME_JSON = 'avatar_consume_json',
  /** 音擎升级所需材料 JSON */
  WEAPON_CONSUME_JSON = 'weapon_consume_json',
  /** 技能升级所需材料 JSON */
  SKILL_CONSUME_JSON  = 'skill_consume_json',
}

/**
 * zzz_buddy 专属列名。
 * 存储绝区零邦布的基础信息，每个邦布（buddyId）只保留一条最新记录。
 */
export enum ZZZBuddyCol {
  /** 邦布 ID（米游社内部 ID） */
  BUDDY_ID            = 'buddy_id',
  /** 邦布名称 */
  NAME                = 'name',
  /** 稀有度（'S' 或 'A'） */
  RARITY              = 'rarity',
  /** 邦布等级（1-60） */
  LEVEL               = 'level',
  /** 精炼等级（1-5，对应 API 的 star 字段） */
  STAR                = 'star',
  /** 邦布方形图标 URL */
  BANGBOO_SQUARE_URL  = 'bangboo_square_url',
}

// ── 表 11：zzz_avatar_basic ──────────────────────────────────
export const ZZZ_AVATAR_BASIC_TABLE = new TableDef(TableName.ZZZ_AVATAR_BASIC, [
  new ColumnDef(CommonCol.ID,         'INTEGER', 'PRIMARY KEY AUTOINCREMENT'),
  new ColumnDef(CommonCol.ACCOUNT_ID, 'TEXT', 'NOT NULL'),
  new ColumnDef(CommonCol.ROLE_UID,   'TEXT',    'NOT NULL'),
  new ColumnDef(CommonCol.AVATAR_ID,  'TEXT',    'NOT NULL'),
  new ColumnDef('name_mi18n',        'TEXT'),
  new ColumnDef('full_name_mi18n',   'TEXT'),
  new ColumnDef('element_type',      'INTEGER'),
  new ColumnDef('sub_element_type',  'INTEGER'),
  new ColumnDef('avatar_profession', 'INTEGER'),
  new ColumnDef('rarity',            'TEXT'),
  new ColumnDef('level',             'INTEGER'),
  new ColumnDef('rank',              'INTEGER'),
  new ColumnDef('camp_name_mi18n',   'TEXT'),
  new ColumnDef('group_icon_path',   'TEXT'),
  new ColumnDef('hollow_icon_path',  'TEXT'),
  new ColumnDef('role_square_url',   'TEXT'),
  new ColumnDef('awaken_state',      'TEXT'),
  new ColumnDef('is_chosen',         'INTEGER', 'DEFAULT 0'),
  new ColumnDef(CommonCol.RAW_JSON,    'TEXT',    'NOT NULL'),
  new ColumnDef(CommonCol.UPDATE_TIME, 'INTEGER'),
], FK_ACCOUNT);

// ── 表 12：zzz_daily_note ────────────────────────────────────
export const ZZZ_DAILY_NOTE_TABLE = new TableDef(TableName.ZZZ_DAILY_NOTE, [
  new ColumnDef(CommonCol.ID,         'INTEGER', 'PRIMARY KEY AUTOINCREMENT'),
  new ColumnDef(CommonCol.ACCOUNT_ID, 'TEXT', 'NOT NULL'),
  new ColumnDef(CommonCol.ROLE_UID,   'TEXT',    'NOT NULL'),
  new ColumnDef('energy_current',   'INTEGER'),
  new ColumnDef('energy_max',       'INTEGER'),
  new ColumnDef('energy_restore',   'INTEGER'),
  new ColumnDef('vitality_current', 'INTEGER'),
  new ColumnDef('vitality_max',     'INTEGER'),
  new ColumnDef('vhs_sale_state',   'TEXT'),
  new ColumnDef('card_sign',        'TEXT'),
  new ColumnDef(CommonCol.RAW_JSON,    'TEXT',    'NOT NULL'),
  new ColumnDef('widget_raw_json',     'TEXT',    "DEFAULT ''"),
  new ColumnDef(CommonCol.UPDATE_TIME, 'INTEGER'),
], FK_ACCOUNT);

// ── 表 13：zzz_avatar_info ───────────────────────────────────
export const ZZZ_AVATAR_INFO_TABLE = new TableDef(TableName.ZZZ_AVATAR_INFO, [
  new ColumnDef(CommonCol.ID,         'INTEGER', 'PRIMARY KEY AUTOINCREMENT'),
  new ColumnDef(CommonCol.ACCOUNT_ID, 'TEXT', 'NOT NULL'),
  new ColumnDef(CommonCol.ROLE_UID,   'TEXT',    'NOT NULL'),
  new ColumnDef(CommonCol.AVATAR_ID,  'TEXT',    'NOT NULL'),
  new ColumnDef('weapon_id',             'TEXT'),
  new ColumnDef('weapon_level',          'INTEGER'),
  new ColumnDef('weapon_star',           'INTEGER'),
  new ColumnDef('equip_ids',             'TEXT'),
  new ColumnDef('skill_levels_json',     'TEXT'),
  new ColumnDef('vertical_painting_url', 'TEXT'),
  new ColumnDef(CommonCol.RAW_JSON,    'TEXT',    'NOT NULL'),
  new ColumnDef(CommonCol.UPDATE_TIME, 'INTEGER'),
], FK_ACCOUNT);

// ── 表 14：zzz_avatar_compute ────────────────────────────────
export const ZZZ_AVATAR_COMPUTE_TABLE = new TableDef(TableName.ZZZ_AVATAR_COMPUTE, [
  new ColumnDef(CommonCol.ID,         'INTEGER', 'PRIMARY KEY AUTOINCREMENT'),
  new ColumnDef(CommonCol.ACCOUNT_ID, 'TEXT', 'NOT NULL'),
  new ColumnDef(CommonCol.ROLE_UID,   'TEXT',    'NOT NULL'),
  new ColumnDef(CommonCol.AVATAR_ID,  'TEXT',    'NOT NULL'),
  new ColumnDef('avatar_consume_json', 'TEXT'),
  new ColumnDef('weapon_consume_json', 'TEXT'),
  new ColumnDef('skill_consume_json',  'TEXT'),
  new ColumnDef(CommonCol.RAW_JSON,    'TEXT',    "DEFAULT ''"),
  new ColumnDef(CommonCol.UPDATE_TIME, 'INTEGER'),
  // v7 新增（ALTER TABLE ADD COLUMN 追加在末尾，定义顺序与之保持一致）
  new ColumnDef(ComputeStateCol.TARGET_REACHED, 'INTEGER', 'DEFAULT 0'),
], FK_ACCOUNT);

// ── 表 15：zzz_buddy ─────────────────────────────────────────
export const ZZZ_BUDDY_TABLE = new TableDef(TableName.ZZZ_BUDDY, [
  new ColumnDef(CommonCol.ID,         'INTEGER', 'PRIMARY KEY AUTOINCREMENT'),
  new ColumnDef(CommonCol.ACCOUNT_ID, 'TEXT',    'NOT NULL'),
  new ColumnDef(CommonCol.ROLE_UID,   'TEXT',    'NOT NULL'),
  new ColumnDef('buddy_id',           'TEXT',    'NOT NULL'),
  new ColumnDef('name',               'TEXT'),
  new ColumnDef('rarity',             'TEXT'),
  new ColumnDef('level',              'INTEGER'),
  new ColumnDef('star',               'INTEGER'),
  new ColumnDef('bangboo_square_url', 'TEXT'),
  new ColumnDef(CommonCol.RAW_JSON,    'TEXT',    'NOT NULL'),
  new ColumnDef(CommonCol.UPDATE_TIME, 'INTEGER'),
], FK_ACCOUNT);

// ── 表 19：zzz_material_bag（绝区零材料背包）─────────────────────
export const ZZZ_MATERIAL_BAG_TABLE = new TableDef(TableName.ZZZ_MATERIAL_BAG, [
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

// ── 表 22：zzz_material_target_config（绝区零养成目标配置）──────────────────
export const ZZZ_MATERIAL_TARGET_CONFIG_TABLE = new TableDef(TableName.ZZZ_MATERIAL_TARGET_CONFIG, [
  new ColumnDef(CommonCol.ID,         'INTEGER', 'PRIMARY KEY AUTOINCREMENT'),
  new ColumnDef(CommonCol.ACCOUNT_ID, 'TEXT',    'NOT NULL'),
  new ColumnDef(CommonCol.ROLE_UID,   'TEXT',    'NOT NULL'),
  new ColumnDef(MaterialTargetConfigCol.CONFIG_JSON, 'TEXT', "DEFAULT ''"),
  new ColumnDef(CommonCol.UPDATE_TIME, 'INTEGER'),
], FK_ACCOUNT);

export const IDX_ZZZ_AVATAR_BASIC_UNIQUE = new IndexDef('idx_zzz_avatar_basic_unique',     TableName.ZZZ_AVATAR_BASIC, [CommonCol.ACCOUNT_ID, CommonCol.ROLE_UID, CommonCol.AVATAR_ID], true);
export const IDX_ZZZ_AVATAR_BASIC_ELEMENT = new IndexDef('idx_zzz_avatar_basic_element',    TableName.ZZZ_AVATAR_BASIC, [CommonCol.ACCOUNT_ID, CommonCol.ROLE_UID, 'element_type']);
export const IDX_ZZZ_AVATAR_BASIC_PROFESSION = new IndexDef('idx_zzz_avatar_basic_profession', TableName.ZZZ_AVATAR_BASIC, [CommonCol.ACCOUNT_ID, CommonCol.ROLE_UID, 'avatar_profession']);
export const IDX_ZZZ_DAILY_NOTE_UNIQUE = new IndexDef('idx_zzz_daily_note_unique', TableName.ZZZ_DAILY_NOTE, [CommonCol.ACCOUNT_ID, CommonCol.ROLE_UID], true);
export const IDX_ZZZ_AVATAR_INFO_UNIQUE = new IndexDef('idx_zzz_avatar_info_unique', TableName.ZZZ_AVATAR_INFO, [CommonCol.ACCOUNT_ID, CommonCol.ROLE_UID, CommonCol.AVATAR_ID], true);
export const IDX_ZZZ_AVATAR_COMPUTE_UNIQUE = new IndexDef('idx_zzz_avatar_compute_unique', TableName.ZZZ_AVATAR_COMPUTE, [CommonCol.ACCOUNT_ID, CommonCol.ROLE_UID, CommonCol.AVATAR_ID], true);
export const IDX_ZZZ_BUDDY_UNIQUE = new IndexDef('idx_zzz_buddy_unique', TableName.ZZZ_BUDDY, [CommonCol.ACCOUNT_ID, CommonCol.ROLE_UID, 'buddy_id'], true);
export const IDX_ZZZ_MATERIAL_BAG_UNIQUE = new IndexDef('idx_zzz_material_bag_unique', TableName.ZZZ_MATERIAL_BAG, [CommonCol.ACCOUNT_ID, CommonCol.ROLE_UID, MaterialBagCol.MATERIAL_ID], true);
export const IDX_ZZZ_MATERIAL_TARGET_CONFIG_UNIQUE = new IndexDef('idx_zzz_material_target_config_unique', TableName.ZZZ_MATERIAL_TARGET_CONFIG, [CommonCol.ACCOUNT_ID, CommonCol.ROLE_UID], true);

export const ZZZ_INDEXES: IndexDef[] = [
  IDX_ZZZ_AVATAR_BASIC_UNIQUE,
  IDX_ZZZ_AVATAR_BASIC_ELEMENT,
  IDX_ZZZ_AVATAR_BASIC_PROFESSION,
  IDX_ZZZ_DAILY_NOTE_UNIQUE,
  IDX_ZZZ_AVATAR_INFO_UNIQUE,
  IDX_ZZZ_AVATAR_COMPUTE_UNIQUE,
  IDX_ZZZ_BUDDY_UNIQUE,
  IDX_ZZZ_MATERIAL_BAG_UNIQUE,
  IDX_ZZZ_MATERIAL_TARGET_CONFIG_UNIQUE,
];
