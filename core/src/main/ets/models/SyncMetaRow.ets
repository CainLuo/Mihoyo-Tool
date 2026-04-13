/**
 * SyncMetaRow.ets
 *
 * 同步状态元数据数据库行模型，对应 sync_meta 表。
 * 记录每个账号每个游戏角色每种数据类型的最后同步时间和状态。
 */
export class SyncMetaRow {
  /** 本地数据库自增 ID */
  id: number = 0;
  /** 所属账号 ID（外键，关联 account_table.id） */
  accountId: string = '';
  /** 游戏角色 UID */
  roleUid: string = '';
  /** 数据类型（对应 SyncDataType 枚举值，如 'genshin_daily_note'） */
  dataType: string = '';
  /** 最后同步成功时间（Unix 秒，0 表示从未同步） */
  lastSyncTime: number = 0;
  /** 同步状态（pending / syncing / success / failed） */
  syncStatus: string = '';
  /** 同步失败时的错误信息（成功时为空字符串） */
  errorMsg: string = '';
}
