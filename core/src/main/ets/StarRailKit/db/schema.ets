import { TableName } from '../../db/TableName';
import { CommonCol, ComputeStateCol, ColumnDef, TableDef, IndexDef, FK_ACCOUNT } from '../../db/TableSchema';
import { MaterialBagCol, MaterialTargetConfigCol } from '../../common/material/db/schema';

/**
 * starrail_avatar_basic 专属列名。
 * 存储星穹铁道角色的基础属性和当前装备光锥的摘要信息。
 */
export enum StarRailAvatarBasicCol {
  /** 角色名称 */
  NAME         = 'name',
  /** 属性（如 'Fire'=火，'Ice'=冰） */
  ELEMENT      = 'element',
  /** 稀有度（4=四星，5=五星） */
  RARITY       = 'rarity',
  /** 角色等级（1-80） */
  LEVEL        = 'level',
  /** 星魂数量（0-6，对应原神命座） */
  RANK         = 'rank',
  /** 命途类型枚举值（米游社内部分类） */
  BASE_TYPE    = 'base_type',
  /** 光锥 ID */
  EQUIP_ID     = 'equip_id',
  /** 光锥名称 */
  EQUIP_NAME   = 'equip_name',
  /** 光锥稀有度（3-5） */
  EQUIP_RARITY = 'equip_rarity',
  /** 光锥等级（1-80） */
  EQUIP_LEVEL  = 'equip_level',
  /** 光锥叠影等级（1-5，对应原神精炼） */
  EQUIP_RANK   = 'equip_rank',
  /** 光锥图标 URL */
  EQUIP_ICON_URL = 'equip_icon_url',
  /** 是否被选中（0=否，1=是） */
  IS_CHOSEN    = 'is_chosen',
  /** 角色头像图片 URL */
  ICON         = 'icon',
  /** 角色立绘图片路径 */
  FIGURE_PATH  = 'figure_path',
  /** 属性 ID（米游社内部枚举值） */
  ELEMENT_ID   = 'element_id',
}

/**
 * starrail_daily_note 专属列名。
 * 存储星穹铁道实时便笺的各项数值，每个角色（roleUid）只保留一条最新记录。
 */
export enum StarRailDailyNoteCol {
  /** 当前开拓力数量 */
  CURRENT_STAMINA          = 'current_stamina',
  /** 开拓力上限（通常为 240） */
  MAX_STAMINA              = 'max_stamina',
  /** 开拓力完全恢复所需秒数 */
  STAMINA_RECOVER_TIME     = 'stamina_recover_time',
  /** 开拓力满时的 Unix 时间戳 */
  STAMINA_FULL_TS          = 'stamina_full_ts',
  /** 当前后备开拓力数量（溢出时存入，上限 2400） */
  CURRENT_RESERVE_STAMINA  = 'current_reserve_stamina',
  /** 当前派遣中的角色数量 */
  ACCEPTED_EXPEDITION_NUM  = 'accepted_expedition_num',
  /** 派遣槽位上限 */
  TOTAL_EXPEDITION_NUM     = 'total_expedition_num',
  /** 当前实训积分 */
  CURRENT_TRAIN_SCORE      = 'current_train_score',
  /** 实训积分上限（通常为 500） */
  MAX_TRAIN_SCORE          = 'max_train_score',
  /** 当前模拟宇宙积分 */
  CURRENT_ROGUE_SCORE      = 'current_rogue_score',
  /** 模拟宇宙积分上限 */
  MAX_ROGUE_SCORE          = 'max_rogue_score',
  /** 本周已完成的历战余响次数 */
  WEEKLY_COCOON_CNT        = 'weekly_cocoon_cnt',
  /** 历战余响每周上限 */
  WEEKLY_COCOON_LIMIT      = 'weekly_cocoon_limit',
  /** 本周差分宇宙已获积分 */
  ROGUE_TOURN_WEEKLY_CUR   = 'rogue_tourn_weekly_cur',
  /** 差分宇宙每周积分上限 */
  ROGUE_TOURN_WEEKLY_MAX   = 'rogue_tourn_weekly_max',
  /** 本周黄金与机械已完成次数 */
  GRID_FIGHT_WEEKLY_CUR    = 'grid_fight_weekly_cur',
  /** 黄金与机械每周上限 */
  GRID_FIGHT_WEEKLY_MAX    = 'grid_fight_weekly_max',
}

/**
 * starrail_avatar_info 专属列名。
 * 存储星穹铁道角色的完整配装数据，每个角色（avatarId）只保留一条最新记录。
 */
export enum StarRailAvatarInfoCol {
  /** 光锥 ID */
  EQUIP_ID        = 'equip_id',
  /** 光锥等级 */
  EQUIP_LEVEL     = 'equip_level',
  /** 光锥叠影等级 */
  EQUIP_RANK      = 'equip_rank',
  /** 遗器 ID 列表（JSON 数组字符串） */
  RELIC_IDS       = 'relic_ids',
  /** 行迹树节点激活状态 JSON */
  SKILL_TREE_JSON = 'skill_tree_json',
}

/**
 * starrail_avatar_compute 专属列名。
 * 存储星穹铁道角色养成计算的材料消耗数据。
 */
export enum StarRailAvatarComputeCol {
  /** 角色本体升级所需材料 JSON */
  AVATAR_CONSUME_JSON    = 'avatar_consume_json',
  /** 技能升级所需材料 JSON */
  SKILL_CONSUME_JSON     = 'skill_consume_json',
  /** 光锥升级所需材料 JSON */
  EQUIPMENT_CONSUME_JSON = 'equipment_consume_json',
}

// ── 表 7：starrail_avatar_basic ──────────────────────────────
export const STARRAIL_AVATAR_BASIC_TABLE = new TableDef(TableName.STARRAIL_AVATAR_BASIC, [
  new ColumnDef(CommonCol.ID,         'INTEGER', 'PRIMARY KEY AUTOINCREMENT'),
  new ColumnDef(CommonCol.ACCOUNT_ID, 'TEXT', 'NOT NULL'),
  new ColumnDef(CommonCol.ROLE_UID,   'TEXT',    'NOT NULL'),
  new ColumnDef(CommonCol.AVATAR_ID,  'TEXT',    'NOT NULL'),
  new ColumnDef('name',         'TEXT'),
  new ColumnDef('element',      'TEXT'),
  new ColumnDef('rarity',       'INTEGER'),
  new ColumnDef('level',        'INTEGER'),
  new ColumnDef('rank',         'INTEGER'),
  new ColumnDef('base_type',    'INTEGER'),
  new ColumnDef('equip_id',     'TEXT'),
  new ColumnDef('equip_name',   'TEXT'),
  new ColumnDef('equip_rarity', 'INTEGER'),
  new ColumnDef('equip_level',  'INTEGER'),
  new ColumnDef('equip_rank',   'INTEGER'),
  new ColumnDef('equip_icon_url', 'TEXT'),
  new ColumnDef('is_chosen',    'INTEGER', 'DEFAULT 0'),
  new ColumnDef('icon',         'TEXT'),
  new ColumnDef('figure_path',  'TEXT'),
  new ColumnDef('element_id',   'INTEGER'),
  new ColumnDef(CommonCol.RAW_JSON,    'TEXT',    'NOT NULL'),
  new ColumnDef(CommonCol.UPDATE_TIME, 'INTEGER'),
], FK_ACCOUNT);

// ── 表 8：starrail_daily_note ────────────────────────────────
export const STARRAIL_DAILY_NOTE_TABLE = new TableDef(TableName.STARRAIL_DAILY_NOTE, [
  new ColumnDef(CommonCol.ID,         'INTEGER', 'PRIMARY KEY AUTOINCREMENT'),
  new ColumnDef(CommonCol.ACCOUNT_ID, 'TEXT', 'NOT NULL'),
  new ColumnDef(CommonCol.ROLE_UID,   'TEXT',    'NOT NULL'),
  new ColumnDef('current_stamina',         'INTEGER'),
  new ColumnDef('max_stamina',             'INTEGER'),
  new ColumnDef('stamina_recover_time',    'INTEGER'),
  new ColumnDef('stamina_full_ts',         'INTEGER'),
  new ColumnDef('current_reserve_stamina', 'INTEGER'),
  new ColumnDef('accepted_expedition_num', 'INTEGER'),
  new ColumnDef('total_expedition_num',    'INTEGER'),
  new ColumnDef('current_train_score',     'INTEGER'),
  new ColumnDef('max_train_score',         'INTEGER'),
  new ColumnDef('current_rogue_score',     'INTEGER'),
  new ColumnDef('max_rogue_score',         'INTEGER'),
  new ColumnDef('weekly_cocoon_cnt',       'INTEGER'),
  new ColumnDef('weekly_cocoon_limit',     'INTEGER'),
  new ColumnDef('rogue_tourn_weekly_cur',  'INTEGER'),
  new ColumnDef('rogue_tourn_weekly_max',  'INTEGER'),
  new ColumnDef('grid_fight_weekly_cur',   'INTEGER'),
  new ColumnDef('grid_fight_weekly_max',   'INTEGER'),
  new ColumnDef(CommonCol.RAW_JSON,    'TEXT',    'NOT NULL'),
  new ColumnDef(CommonCol.UPDATE_TIME, 'INTEGER'),
], FK_ACCOUNT);

// ── 表 9：starrail_avatar_info ───────────────────────────────
export const STARRAIL_AVATAR_INFO_TABLE = new TableDef(TableName.STARRAIL_AVATAR_INFO, [
  new ColumnDef(CommonCol.ID,         'INTEGER', 'PRIMARY KEY AUTOINCREMENT'),
  new ColumnDef(CommonCol.ACCOUNT_ID, 'TEXT', 'NOT NULL'),
  new ColumnDef(CommonCol.ROLE_UID,   'TEXT',    'NOT NULL'),
  new ColumnDef(CommonCol.AVATAR_ID,  'TEXT',    'NOT NULL'),
  new ColumnDef('equip_id',        'TEXT'),
  new ColumnDef('equip_level',     'INTEGER'),
  new ColumnDef('equip_rank',      'INTEGER'),
  new ColumnDef('relic_ids',       'TEXT'),
  new ColumnDef('skill_tree_json', 'TEXT'),
  new ColumnDef(CommonCol.RAW_JSON,    'TEXT',    'NOT NULL'),
  new ColumnDef(CommonCol.UPDATE_TIME, 'INTEGER'),
], FK_ACCOUNT);

// ── 表 10：starrail_avatar_compute ───────────────────────────
export const STARRAIL_AVATAR_COMPUTE_TABLE = new TableDef(TableName.STARRAIL_AVATAR_COMPUTE, [
  new ColumnDef(CommonCol.ID,         'INTEGER', 'PRIMARY KEY AUTOINCREMENT'),
  new ColumnDef(CommonCol.ACCOUNT_ID, 'TEXT', 'NOT NULL'),
  new ColumnDef(CommonCol.ROLE_UID,   'TEXT',    'NOT NULL'),
  new ColumnDef(CommonCol.AVATAR_ID,  'TEXT',    'NOT NULL'),
  new ColumnDef('avatar_consume_json',    'TEXT'),
  new ColumnDef('skill_consume_json',     'TEXT'),
  new ColumnDef('equipment_consume_json', 'TEXT'),
  new ColumnDef(CommonCol.RAW_JSON,       'TEXT',    "DEFAULT ''"),
  new ColumnDef(CommonCol.UPDATE_TIME, 'INTEGER'),
  // v7 新增（ALTER TABLE ADD COLUMN 追加在末尾，定义顺序与之保持一致）
  new ColumnDef(ComputeStateCol.TARGET_REACHED, 'INTEGER', 'DEFAULT 0'),
], FK_ACCOUNT);

// ── 表 18：starrail_material_bag（星穹铁道材料背包）──────────────
export const STARRAIL_MATERIAL_BAG_TABLE = new TableDef(TableName.STARRAIL_MATERIAL_BAG, [
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

// ── 表 21：starrail_material_target_config（星穹铁道养成目标配置）────────────
export const STARRAIL_MATERIAL_TARGET_CONFIG_TABLE = new TableDef(TableName.STARRAIL_MATERIAL_TARGET_CONFIG, [
  new ColumnDef(CommonCol.ID,         'INTEGER', 'PRIMARY KEY AUTOINCREMENT'),
  new ColumnDef(CommonCol.ACCOUNT_ID, 'TEXT',    'NOT NULL'),
  new ColumnDef(CommonCol.ROLE_UID,   'TEXT',    'NOT NULL'),
  new ColumnDef(MaterialTargetConfigCol.CONFIG_JSON, 'TEXT', "DEFAULT ''"),
  new ColumnDef(CommonCol.UPDATE_TIME, 'INTEGER'),
], FK_ACCOUNT);

export const IDX_STARRAIL_AVATAR_BASIC_UNIQUE = new IndexDef('idx_starrail_avatar_basic_unique',  TableName.STARRAIL_AVATAR_BASIC, [CommonCol.ACCOUNT_ID, CommonCol.ROLE_UID, CommonCol.AVATAR_ID], true);
export const IDX_STARRAIL_AVATAR_BASIC_TYPE = new IndexDef('idx_starrail_avatar_basic_type',    TableName.STARRAIL_AVATAR_BASIC, [CommonCol.ACCOUNT_ID, CommonCol.ROLE_UID, 'base_type']);
export const IDX_STARRAIL_AVATAR_BASIC_ELEMENT = new IndexDef('idx_starrail_avatar_basic_element', TableName.STARRAIL_AVATAR_BASIC, [CommonCol.ACCOUNT_ID, CommonCol.ROLE_UID, 'element']);
export const IDX_STARRAIL_DAILY_NOTE_UNIQUE = new IndexDef('idx_starrail_daily_note_unique', TableName.STARRAIL_DAILY_NOTE, [CommonCol.ACCOUNT_ID, CommonCol.ROLE_UID], true);
export const IDX_STARRAIL_AVATAR_INFO_UNIQUE = new IndexDef('idx_starrail_avatar_info_unique', TableName.STARRAIL_AVATAR_INFO, [CommonCol.ACCOUNT_ID, CommonCol.ROLE_UID, CommonCol.AVATAR_ID], true);
export const IDX_STARRAIL_AVATAR_COMPUTE_UNIQUE = new IndexDef('idx_starrail_avatar_compute_unique', TableName.STARRAIL_AVATAR_COMPUTE, [CommonCol.ACCOUNT_ID, CommonCol.ROLE_UID, CommonCol.AVATAR_ID], true);
export const IDX_STARRAIL_MATERIAL_BAG_UNIQUE = new IndexDef('idx_starrail_material_bag_unique', TableName.STARRAIL_MATERIAL_BAG, [CommonCol.ACCOUNT_ID, CommonCol.ROLE_UID, MaterialBagCol.MATERIAL_ID], true);
export const IDX_STARRAIL_MATERIAL_TARGET_CONFIG_UNIQUE = new IndexDef('idx_starrail_material_target_config_unique', TableName.STARRAIL_MATERIAL_TARGET_CONFIG, [CommonCol.ACCOUNT_ID, CommonCol.ROLE_UID], true);

export const STARRAIL_INDEXES: IndexDef[] = [
  IDX_STARRAIL_AVATAR_BASIC_UNIQUE,
  IDX_STARRAIL_AVATAR_BASIC_TYPE,
  IDX_STARRAIL_AVATAR_BASIC_ELEMENT,
  IDX_STARRAIL_DAILY_NOTE_UNIQUE,
  IDX_STARRAIL_AVATAR_INFO_UNIQUE,
  IDX_STARRAIL_AVATAR_COMPUTE_UNIQUE,
  IDX_STARRAIL_MATERIAL_BAG_UNIQUE,
  IDX_STARRAIL_MATERIAL_TARGET_CONFIG_UNIQUE,
];
