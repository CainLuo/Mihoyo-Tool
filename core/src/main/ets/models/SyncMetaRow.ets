/**
 * SyncMetaRow.ets
 *
 * sync_meta 表的行模型。
 * 记录每个 (game_id, role_uid, data_type) 组合的最后同步时间和状态，
 * 用于跨 App 重启的持久化同步调度（如 30 分钟自动刷新）。
 */

export type SyncStatus = 'success' | 'failed' | 'syncing';

export class SyncMetaRow {
  id: number = 0;
  gameId: string = '';
  roleUid: string = '';
  dataType: string = '';
  /** Unix 秒，上次同步完成（成功或失败）的时间戳 */
  lastSyncTime: number = 0;
  /** 'success' | 'failed' | 'syncing' */
  syncStatus: SyncStatus = 'success';
  /** 失败时的错误信息，成功时为空字符串 */
  errorMsg: string = '';
}
