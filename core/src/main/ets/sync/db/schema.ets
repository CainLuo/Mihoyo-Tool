import { TableName } from '../../db/TableName';
import { CommonCol, ColumnDef, TableDef, IndexDef, FK_ACCOUNT } from '../../db/TableSchema';

/**
 * sync_meta 表专属列名。
 * 记录每个角色每种数据类型的同步状态，供 Repository 层判断是否需要重新同步。
 */
export enum SyncMetaCol {
  /** 最后一次成功同步的 Unix 秒时间戳（0 表示从未同步） */
  LAST_SYNC_TIME = 'last_sync_time',
  /** 同步状态：'syncing'=同步中，'success'=成功，'failed'=失败 */
  SYNC_STATUS    = 'sync_status',
  /** 同步失败时的错误信息（成功时为空字符串） */
  ERROR_MSG      = 'error_msg',
}

// ── 表 16：sync_meta ─────────────────────────────────────────
export const SYNC_META_TABLE = new TableDef(TableName.SYNC_META, [
  new ColumnDef(CommonCol.ID,         'INTEGER', 'PRIMARY KEY AUTOINCREMENT'),
  new ColumnDef(CommonCol.ACCOUNT_ID, 'TEXT', 'NOT NULL'),
  new ColumnDef(CommonCol.ROLE_UID,   'TEXT',    'NOT NULL'),
  new ColumnDef(CommonCol.DATA_TYPE,  'TEXT',    'NOT NULL'),
  new ColumnDef('last_sync_time', 'INTEGER'),
  new ColumnDef('sync_status',    'TEXT'),
  new ColumnDef('error_msg',      'TEXT'),
], FK_ACCOUNT);

export const IDX_SYNC_META_UNIQUE = new IndexDef('idx_sync_meta_unique', TableName.SYNC_META, [CommonCol.ACCOUNT_ID, CommonCol.ROLE_UID, CommonCol.DATA_TYPE], true);

export const SYNC_INDEXES: IndexDef[] = [
  IDX_SYNC_META_UNIQUE,
];
