/**
 * TableSchema — 数据库表结构定义
 *
 * 每个 TableDef 描述一张表的名称和列定义，
 * 通过 buildCreateTableSql() 生成 CREATE TABLE IF NOT EXISTS SQL。
 * 避免在 RdbManagerV2 中直接硬编码 DDL 字符串。
 */

/** 表名枚举 — 所有表名的唯一来源，禁止在其他地方直接写表名字符串 */
export enum TableName {
  ACCOUNT                  = 'account_table',
  GAME_ROLE                = 'game_role_table',
  GENSHIN_CHARACTER_LIST   = 'genshin_character_list',
  GENSHIN_DAILY_NOTE       = 'genshin_daily_note',
  GENSHIN_CHARACTER_DETAIL = 'genshin_character_detail',
  GENSHIN_CHARACTER_COMPUTE = 'genshin_character_compute',
  STARRAIL_AVATAR_BASIC    = 'starrail_avatar_basic',
  STARRAIL_DAILY_NOTE      = 'starrail_daily_note',
  STARRAIL_AVATAR_INFO     = 'starrail_avatar_info',
  STARRAIL_AVATAR_COMPUTE  = 'starrail_avatar_compute',
  ZZZ_AVATAR_BASIC         = 'zzz_avatar_basic',
  ZZZ_DAILY_NOTE           = 'zzz_daily_note',
  ZZZ_AVATAR_INFO          = 'zzz_avatar_info',
  ZZZ_AVATAR_COMPUTE       = 'zzz_avatar_compute',
  SYNC_META                = 'sync_meta',
}

/** 公共列名枚举 — 跨多张表复用的列名 */
export enum CommonCol {
  ID          = 'id',
  ACCOUNT_ID  = 'account_id',
  ROLE_UID    = 'role_uid',
  AVATAR_ID   = 'avatar_id',
  RAW_JSON    = 'raw_json',
  UPDATE_TIME = 'update_time',
  DATA_TYPE   = 'data_type',
}

/** 单列定义 */
export class ColumnDef {
  name: string;
  type: string;
  constraints: string;

  constructor(name: string, type: string, constraints: string = '') {
    this.name = name;
    this.type = type;
    this.constraints = constraints;
  }
}

/** 表定义 */
export class TableDef {
  tableName: TableName;
  columns: ColumnDef[];
  /** 外键约束（可选，追加在列定义之后） */
  foreignKey: string;

  constructor(tableName: TableName, columns: ColumnDef[], foreignKey: string = '') {
    this.tableName = tableName;
    this.columns = columns;
    this.foreignKey = foreignKey;
  }

  /** 生成 CREATE TABLE IF NOT EXISTS SQL */
  buildCreateSql(): string {
    const colDefs: string[] = [];
    for (let i = 0; i < this.columns.length; i++) {
      const col = this.columns[i];
      const def = col.constraints.length > 0
        ? `${col.name} ${col.type} ${col.constraints}`
        : `${col.name} ${col.type}`;
      colDefs.push(def);
    }
    if (this.foreignKey.length > 0) {
      colDefs.push(this.foreignKey);
    }
    return `CREATE TABLE IF NOT EXISTS ${this.tableName} (\n  ${colDefs.join(',\n  ')}\n)`;
  }

  /** 返回所有列名数组，供 DAO 的 upsertRow/queryFirst/queryAll 使用 */
  columnNames(): string[] {
    const names: string[] = [];
    for (let i = 0; i < this.columns.length; i++) {
      names.push(this.columns[i].name);
    }
    return names;
  }
}

// ── 公共外键约束模板 ──────────────────────────────────────────
const FK_ACCOUNT = 'FOREIGN KEY (account_id) REFERENCES account_table(id) ON DELETE CASCADE';

// ── 表 1：account_table ──────────────────────────────────────
export const ACCOUNT_TABLE = new TableDef(TableName.ACCOUNT, [
  new ColumnDef(CommonCol.ID,          'INTEGER', 'PRIMARY KEY AUTOINCREMENT'),
  new ColumnDef('username',    'TEXT',    'UNIQUE NOT NULL'),
  new ColumnDef('cookie',      'TEXT',    'NOT NULL'),
  new ColumnDef('stoken',      'TEXT',    "DEFAULT ''"),
  new ColumnDef('stuid',       'TEXT',    "DEFAULT ''"),
  new ColumnDef('mid',         'TEXT',    "DEFAULT ''"),
  new ColumnDef('is_active',   'INTEGER', 'DEFAULT 0'),
  new ColumnDef('create_time', 'INTEGER'),
  new ColumnDef(CommonCol.UPDATE_TIME, 'INTEGER'),
  new ColumnDef('uid',         'TEXT',    "DEFAULT ''"),
  new ColumnDef('nickname',    'TEXT',    "DEFAULT ''"),
  new ColumnDef('avatar_url',  'TEXT',    "DEFAULT ''"),
  new ColumnDef('introduce',   'TEXT',    "DEFAULT ''"),
]);

// ── 表 2：game_role_table ────────────────────────────────────
export const GAME_ROLE_TABLE = new TableDef(TableName.GAME_ROLE, [
  new ColumnDef(CommonCol.ID,           'INTEGER', 'PRIMARY KEY AUTOINCREMENT'),
  new ColumnDef(CommonCol.ACCOUNT_ID,   'INTEGER', 'NOT NULL'),
  new ColumnDef('game_id',      'TEXT',    'NOT NULL'),
  new ColumnDef('game_biz',     'TEXT',    "DEFAULT ''"),
  new ColumnDef('game_type',    'INTEGER', 'DEFAULT 0'),
  new ColumnDef('role_id',      'TEXT',    'NOT NULL'),
  new ColumnDef('nickname',     'TEXT',    "DEFAULT ''"),
  new ColumnDef('level',        'INTEGER', 'DEFAULT 0'),
  new ColumnDef('server',       'TEXT',    "DEFAULT ''"),
  new ColumnDef('region_name',  'TEXT',    "DEFAULT ''"),
  new ColumnDef('is_chosen',    'INTEGER', 'DEFAULT 0'),
  new ColumnDef('is_public',    'INTEGER', 'DEFAULT 0'),
  new ColumnDef('bg_image_url', 'TEXT',    "DEFAULT ''"),
  new ColumnDef('stats_json',   'TEXT',    "DEFAULT ''"),
], FK_ACCOUNT);

// ── 表 3：genshin_character_list ─────────────────────────────
export const GENSHIN_CHARACTER_LIST_TABLE = new TableDef(TableName.GENSHIN_CHARACTER_LIST, [
  new ColumnDef(CommonCol.ID,         'INTEGER', 'PRIMARY KEY AUTOINCREMENT'),
  new ColumnDef(CommonCol.ACCOUNT_ID, 'INTEGER', 'NOT NULL'),
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
  new ColumnDef('icon',                      'TEXT'),
  new ColumnDef('side_icon',                 'TEXT'),
  new ColumnDef(CommonCol.RAW_JSON,    'TEXT',    'NOT NULL'),
  new ColumnDef(CommonCol.UPDATE_TIME, 'INTEGER'),
], FK_ACCOUNT);

// ── 表 4：genshin_daily_note ─────────────────────────────────
export const GENSHIN_DAILY_NOTE_TABLE = new TableDef(TableName.GENSHIN_DAILY_NOTE, [
  new ColumnDef(CommonCol.ID,         'INTEGER', 'PRIMARY KEY AUTOINCREMENT'),
  new ColumnDef(CommonCol.ACCOUNT_ID, 'INTEGER', 'NOT NULL'),
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
  new ColumnDef(CommonCol.ACCOUNT_ID, 'INTEGER', 'NOT NULL'),
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

// ── 表 6：genshin_character_compute ──────────────────────────
export const GENSHIN_CHARACTER_COMPUTE_TABLE = new TableDef(TableName.GENSHIN_CHARACTER_COMPUTE, [
  new ColumnDef(CommonCol.ID,         'INTEGER', 'PRIMARY KEY AUTOINCREMENT'),
  new ColumnDef(CommonCol.ACCOUNT_ID, 'INTEGER', 'NOT NULL'),
  new ColumnDef(CommonCol.ROLE_UID,   'TEXT',    'NOT NULL'),
  new ColumnDef(CommonCol.AVATAR_ID,  'TEXT',    'NOT NULL'),
  new ColumnDef('avatar_consume_json', 'TEXT'),
  new ColumnDef('skill_consume_json',  'TEXT'),
  new ColumnDef('weapon_consume_json', 'TEXT'),
  new ColumnDef(CommonCol.UPDATE_TIME, 'INTEGER'),
], FK_ACCOUNT);

// ── 表 7：starrail_avatar_basic ──────────────────────────────
export const STARRAIL_AVATAR_BASIC_TABLE = new TableDef(TableName.STARRAIL_AVATAR_BASIC, [
  new ColumnDef(CommonCol.ID,         'INTEGER', 'PRIMARY KEY AUTOINCREMENT'),
  new ColumnDef(CommonCol.ACCOUNT_ID, 'INTEGER', 'NOT NULL'),
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
  new ColumnDef('icon',         'TEXT'),
  new ColumnDef('figure_path',  'TEXT'),
  new ColumnDef('element_id',   'INTEGER'),
  new ColumnDef(CommonCol.RAW_JSON,    'TEXT',    'NOT NULL'),
  new ColumnDef(CommonCol.UPDATE_TIME, 'INTEGER'),
], FK_ACCOUNT);

// ── 表 8：starrail_daily_note ────────────────────────────────
export const STARRAIL_DAILY_NOTE_TABLE = new TableDef(TableName.STARRAIL_DAILY_NOTE, [
  new ColumnDef(CommonCol.ID,         'INTEGER', 'PRIMARY KEY AUTOINCREMENT'),
  new ColumnDef(CommonCol.ACCOUNT_ID, 'INTEGER', 'NOT NULL'),
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
  new ColumnDef(CommonCol.ACCOUNT_ID, 'INTEGER', 'NOT NULL'),
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
  new ColumnDef(CommonCol.ACCOUNT_ID, 'INTEGER', 'NOT NULL'),
  new ColumnDef(CommonCol.ROLE_UID,   'TEXT',    'NOT NULL'),
  new ColumnDef(CommonCol.AVATAR_ID,  'TEXT',    'NOT NULL'),
  new ColumnDef('avatar_consume_json',    'TEXT'),
  new ColumnDef('skill_consume_json',     'TEXT'),
  new ColumnDef('equipment_consume_json', 'TEXT'),
  new ColumnDef(CommonCol.UPDATE_TIME, 'INTEGER'),
], FK_ACCOUNT);

// ── 表 11：zzz_avatar_basic ──────────────────────────────────
export const ZZZ_AVATAR_BASIC_TABLE = new TableDef(TableName.ZZZ_AVATAR_BASIC, [
  new ColumnDef(CommonCol.ID,         'INTEGER', 'PRIMARY KEY AUTOINCREMENT'),
  new ColumnDef(CommonCol.ACCOUNT_ID, 'INTEGER', 'NOT NULL'),
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
  new ColumnDef(CommonCol.RAW_JSON,    'TEXT',    'NOT NULL'),
  new ColumnDef(CommonCol.UPDATE_TIME, 'INTEGER'),
], FK_ACCOUNT);

// ── 表 12：zzz_daily_note ────────────────────────────────────
export const ZZZ_DAILY_NOTE_TABLE = new TableDef(TableName.ZZZ_DAILY_NOTE, [
  new ColumnDef(CommonCol.ID,         'INTEGER', 'PRIMARY KEY AUTOINCREMENT'),
  new ColumnDef(CommonCol.ACCOUNT_ID, 'INTEGER', 'NOT NULL'),
  new ColumnDef(CommonCol.ROLE_UID,   'TEXT',    'NOT NULL'),
  new ColumnDef('energy_current',   'INTEGER'),
  new ColumnDef('energy_max',       'INTEGER'),
  new ColumnDef('energy_restore',   'INTEGER'),
  new ColumnDef('vitality_current', 'INTEGER'),
  new ColumnDef('vitality_max',     'INTEGER'),
  new ColumnDef('vhs_sale_state',   'TEXT'),
  new ColumnDef('card_sign',        'TEXT'),
  new ColumnDef(CommonCol.RAW_JSON,    'TEXT',    'NOT NULL'),
  new ColumnDef(CommonCol.UPDATE_TIME, 'INTEGER'),
], FK_ACCOUNT);

// ── 表 13：zzz_avatar_info ───────────────────────────────────
export const ZZZ_AVATAR_INFO_TABLE = new TableDef(TableName.ZZZ_AVATAR_INFO, [
  new ColumnDef(CommonCol.ID,         'INTEGER', 'PRIMARY KEY AUTOINCREMENT'),
  new ColumnDef(CommonCol.ACCOUNT_ID, 'INTEGER', 'NOT NULL'),
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
  new ColumnDef(CommonCol.ACCOUNT_ID, 'INTEGER', 'NOT NULL'),
  new ColumnDef(CommonCol.ROLE_UID,   'TEXT',    'NOT NULL'),
  new ColumnDef(CommonCol.AVATAR_ID,  'TEXT',    'NOT NULL'),
  new ColumnDef('avatar_consume_json', 'TEXT'),
  new ColumnDef('weapon_consume_json', 'TEXT'),
  new ColumnDef('skill_consume_json',  'TEXT'),
  new ColumnDef(CommonCol.UPDATE_TIME, 'INTEGER'),
], FK_ACCOUNT);

// ── 表 15：sync_meta ─────────────────────────────────────────
export const SYNC_META_TABLE = new TableDef(TableName.SYNC_META, [
  new ColumnDef(CommonCol.ID,         'INTEGER', 'PRIMARY KEY AUTOINCREMENT'),
  new ColumnDef(CommonCol.ACCOUNT_ID, 'INTEGER', 'NOT NULL'),
  new ColumnDef(CommonCol.ROLE_UID,   'TEXT',    'NOT NULL'),
  new ColumnDef(CommonCol.DATA_TYPE,  'TEXT',    'NOT NULL'),
  new ColumnDef('last_sync_time', 'INTEGER'),
  new ColumnDef('sync_status',    'TEXT'),
  new ColumnDef('error_msg',      'TEXT'),
], FK_ACCOUNT);

/** 所有 15 张表的有序列表，供 RdbManagerV2.createTables() 使用 */
export const ALL_TABLES: TableDef[] = [
  ACCOUNT_TABLE,
  GAME_ROLE_TABLE,
  GENSHIN_CHARACTER_LIST_TABLE,
  GENSHIN_DAILY_NOTE_TABLE,
  GENSHIN_CHARACTER_DETAIL_TABLE,
  GENSHIN_CHARACTER_COMPUTE_TABLE,
  STARRAIL_AVATAR_BASIC_TABLE,
  STARRAIL_DAILY_NOTE_TABLE,
  STARRAIL_AVATAR_INFO_TABLE,
  STARRAIL_AVATAR_COMPUTE_TABLE,
  ZZZ_AVATAR_BASIC_TABLE,
  ZZZ_DAILY_NOTE_TABLE,
  ZZZ_AVATAR_INFO_TABLE,
  ZZZ_AVATAR_COMPUTE_TABLE,
  SYNC_META_TABLE,
];

// ── 索引定义 ─────────────────────────────────────────────────

/** 单个索引定义 */
export class IndexDef {
  indexName: string;
  tableName: TableName;
  columns: string[];
  unique: boolean;

  constructor(indexName: string, tableName: TableName, columns: string[], unique: boolean = false) {
    this.indexName = indexName;
    this.tableName = tableName;
    this.columns = columns;
    this.unique = unique;
  }

  buildCreateSql(): string {
    const uniqueStr = this.unique ? 'UNIQUE ' : '';
    return `CREATE ${uniqueStr}INDEX IF NOT EXISTS ${this.indexName} ON ${this.tableName}(${this.columns.join(', ')})`;
  }
}

/** 所有索引的有序列表 */
export const ALL_INDEXES: IndexDef[] = [
  // game_role_table
  new IndexDef('idx_game_role_account', TableName.GAME_ROLE, [CommonCol.ACCOUNT_ID]),
  new IndexDef('idx_game_role_unique',  TableName.GAME_ROLE, [CommonCol.ACCOUNT_ID, 'game_id', 'role_id'], true),
  // genshin_character_list
  new IndexDef('idx_genshin_char_list_unique',  TableName.GENSHIN_CHARACTER_LIST, [CommonCol.ACCOUNT_ID, CommonCol.ROLE_UID, CommonCol.AVATAR_ID], true),
  new IndexDef('idx_genshin_char_list_element', TableName.GENSHIN_CHARACTER_LIST, [CommonCol.ACCOUNT_ID, CommonCol.ROLE_UID, 'element']),
  new IndexDef('idx_genshin_char_list_rarity',  TableName.GENSHIN_CHARACTER_LIST, [CommonCol.ACCOUNT_ID, CommonCol.ROLE_UID, 'rarity']),
  // genshin_daily_note
  new IndexDef('idx_genshin_daily_note_unique', TableName.GENSHIN_DAILY_NOTE, [CommonCol.ACCOUNT_ID, CommonCol.ROLE_UID], true),
  // genshin_character_detail
  new IndexDef('idx_genshin_char_detail_unique', TableName.GENSHIN_CHARACTER_DETAIL, [CommonCol.ACCOUNT_ID, CommonCol.ROLE_UID, CommonCol.AVATAR_ID], true),
  // genshin_character_compute
  new IndexDef('idx_genshin_char_compute_unique', TableName.GENSHIN_CHARACTER_COMPUTE, [CommonCol.ACCOUNT_ID, CommonCol.ROLE_UID, CommonCol.AVATAR_ID], true),
  // starrail_avatar_basic
  new IndexDef('idx_starrail_avatar_basic_unique',  TableName.STARRAIL_AVATAR_BASIC, [CommonCol.ACCOUNT_ID, CommonCol.ROLE_UID, CommonCol.AVATAR_ID], true),
  new IndexDef('idx_starrail_avatar_basic_type',    TableName.STARRAIL_AVATAR_BASIC, [CommonCol.ACCOUNT_ID, CommonCol.ROLE_UID, 'base_type']),
  new IndexDef('idx_starrail_avatar_basic_element', TableName.STARRAIL_AVATAR_BASIC, [CommonCol.ACCOUNT_ID, CommonCol.ROLE_UID, 'element']),
  // starrail_daily_note
  new IndexDef('idx_starrail_daily_note_unique', TableName.STARRAIL_DAILY_NOTE, [CommonCol.ACCOUNT_ID, CommonCol.ROLE_UID], true),
  // starrail_avatar_info
  new IndexDef('idx_starrail_avatar_info_unique', TableName.STARRAIL_AVATAR_INFO, [CommonCol.ACCOUNT_ID, CommonCol.ROLE_UID, CommonCol.AVATAR_ID], true),
  // starrail_avatar_compute
  new IndexDef('idx_starrail_avatar_compute_unique', TableName.STARRAIL_AVATAR_COMPUTE, [CommonCol.ACCOUNT_ID, CommonCol.ROLE_UID, CommonCol.AVATAR_ID], true),
  // zzz_avatar_basic
  new IndexDef('idx_zzz_avatar_basic_unique',     TableName.ZZZ_AVATAR_BASIC, [CommonCol.ACCOUNT_ID, CommonCol.ROLE_UID, CommonCol.AVATAR_ID], true),
  new IndexDef('idx_zzz_avatar_basic_element',    TableName.ZZZ_AVATAR_BASIC, [CommonCol.ACCOUNT_ID, CommonCol.ROLE_UID, 'element_type']),
  new IndexDef('idx_zzz_avatar_basic_profession', TableName.ZZZ_AVATAR_BASIC, [CommonCol.ACCOUNT_ID, CommonCol.ROLE_UID, 'avatar_profession']),
  // zzz_daily_note
  new IndexDef('idx_zzz_daily_note_unique', TableName.ZZZ_DAILY_NOTE, [CommonCol.ACCOUNT_ID, CommonCol.ROLE_UID], true),
  // zzz_avatar_info
  new IndexDef('idx_zzz_avatar_info_unique', TableName.ZZZ_AVATAR_INFO, [CommonCol.ACCOUNT_ID, CommonCol.ROLE_UID, CommonCol.AVATAR_ID], true),
  // zzz_avatar_compute
  new IndexDef('idx_zzz_avatar_compute_unique', TableName.ZZZ_AVATAR_COMPUTE, [CommonCol.ACCOUNT_ID, CommonCol.ROLE_UID, CommonCol.AVATAR_ID], true),
  // sync_meta
  new IndexDef('idx_sync_meta_unique', TableName.SYNC_META, [CommonCol.ACCOUNT_ID, CommonCol.ROLE_UID, CommonCol.DATA_TYPE], true),
];
