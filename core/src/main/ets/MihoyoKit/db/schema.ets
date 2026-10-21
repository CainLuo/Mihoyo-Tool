import { TableName } from '../../db/TableName';
import { CommonCol, ColumnDef, TableDef, IndexDef, FK_ACCOUNT } from '../../db/TableSchema';

/**
 * account_table 专属列名。
 * 对应 AccountRow 模型字段，存储米游社账号的登录凭证和基础信息。
 */
export enum AccountCol {
  /** 米游社用户名（唯一键，用于 upsert 冲突检测） */
  USERNAME    = 'username',
  /** 登录 Cookie（手机号/二维码登录包含 stoken；Cookie 登录存原始字符串） */
  COOKIE      = 'cookie',
  /** 是否为当前激活账号（1=激活，0=未激活） */
  IS_ACTIVE   = 'is_active',
  /** 账号创建时间戳（Unix 秒） */
  CREATE_TIME = 'create_time',
  /** 米游社 UID（通行证 UID） */
  UID         = 'uid',
  /** 米游社昵称 */
  NICKNAME    = 'nickname',
  /** 米游社头像 URL */
  AVATAR_URL  = 'avatar_url',
  /** 米游社个人简介 */
  INTRODUCE   = 'introduce',
  /** 原始 API 响应 JSON（来自 getUserFullInfo） */
  RAW_JSON    = 'raw_json',
}

/**
 * game_role_table 专属列名。
 * 对应 GameRoleRow 模型字段，存储各游戏绑定角色的基础信息。
 */
export enum GameRoleCol {
  /** 游戏标识符（如 'hk4e_cn'=原神国服，'hkrpg_cn'=星铁国服，'nap_cn'=绝区零国服） */
  GAME_ID      = 'game_id',
  /** 游戏业务标识（如 'hk4e_cn'，与 game_id 通常相同） */
  GAME_BIZ     = 'game_biz',
  /** 游戏类型枚举值（米游社内部分类） */
  GAME_TYPE    = 'game_type',
  /** 游戏角色 UID（游戏内唯一标识） */
  ROLE_ID      = 'role_id',
  /** 游戏内昵称 */
  NICKNAME     = 'nickname',
  /** 角色等级 */
  LEVEL        = 'level',
  /** 服务器标识（如 'cn_gf01'=官服，'cn_qd01'=渠道服） */
  SERVER       = 'server',
  /** 服务器显示名称（如 '天空岛'） */
  REGION_NAME  = 'region_name',
  /** 是否为当前选中角色（1=选中，0=未选中） */
  IS_CHOSEN    = 'is_chosen',
  /** 战绩是否公开（1=公开，0=不公开） */
  IS_PUBLIC    = 'is_public',
  /** 角色卡片背景图 URL */
  BG_IMAGE_URL = 'bg_image_url',
  /** 角色统计数据 JSON（用于 My 页面展示格子数据） */
  STATS_JSON   = 'stats_json',
}

// ── 表 1：account_table ──────────────────────────────────────
export const ACCOUNT_TABLE = new TableDef(TableName.ACCOUNT, [
  new ColumnDef(CommonCol.ID,          'INTEGER', 'PRIMARY KEY AUTOINCREMENT'),
  new ColumnDef('username',    'TEXT',    'UNIQUE NOT NULL'),
  new ColumnDef('cookie',      'TEXT',    'NOT NULL'),
  new ColumnDef('is_active',   'INTEGER', 'DEFAULT 0'),
  new ColumnDef('create_time', 'INTEGER'),
  new ColumnDef(CommonCol.UPDATE_TIME, 'INTEGER'),
  new ColumnDef('uid',         'TEXT',    "UNIQUE NOT NULL DEFAULT ''"),
  new ColumnDef('nickname',    'TEXT',    "DEFAULT ''"),
  new ColumnDef('avatar_url',  'TEXT',    "DEFAULT ''"),
  new ColumnDef('introduce',   'TEXT',    "DEFAULT ''"),
  new ColumnDef('raw_json',    'TEXT',    "DEFAULT ''"),
]);

// ── 表 2：game_role_table ────────────────────────────────────
export const GAME_ROLE_TABLE = new TableDef(TableName.GAME_ROLE, [
  new ColumnDef(CommonCol.ID,           'INTEGER', 'PRIMARY KEY AUTOINCREMENT'),
  new ColumnDef(CommonCol.ACCOUNT_ID,   'TEXT', 'NOT NULL'),
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

export const IDX_GAME_ROLE_ACCOUNT = new IndexDef('idx_game_role_account', TableName.GAME_ROLE, [CommonCol.ACCOUNT_ID]);
export const IDX_GAME_ROLE_UNIQUE = new IndexDef('idx_game_role_unique',  TableName.GAME_ROLE, [CommonCol.ACCOUNT_ID, 'game_id', 'role_id'], true);

export const MIHOYO_INDEXES: IndexDef[] = [
  IDX_GAME_ROLE_ACCOUNT,
  IDX_GAME_ROLE_UNIQUE,
];
