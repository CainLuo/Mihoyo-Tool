/**
 * SyncMetaDao.ets
 *
 * 基于 sync_meta 表的数据访问对象。
 * 负责记录每个 (game_id, role_uid, data_type) 的同步状态和时间戳，
 * 供 Repository 层在 sync 前后调用，实现跨重启的持久化调度。
 *
 * 典型用法（在 DailyNoteRepository 中）：
 *   // 同步开始前
 *   await SyncMetaDao.markSyncing(gameId, roleUid, DataType.DAILY_NOTE);
 *   // 同步成功后
 *   await SyncMetaDao.markSuccess(gameId, roleUid, DataType.DAILY_NOTE);
 *   // 同步失败后
 *   await SyncMetaDao.markFailed(gameId, roleUid, DataType.DAILY_NOTE, errorMsg);
 *
 * 查询上次同步时间（用于判断是否需要重新同步）：
 *   const meta = await SyncMetaDao.find(gameId, roleUid, DataType.DAILY_NOTE);
 *   const needSync = meta === null || (now - meta.lastSyncTime) > 1800;
 */

import { relationalStore } from '@kit.ArkData';
import { RdbManager } from './RdbManager';
import { QueryBuilder } from './QueryBuilder';
import { SyncMetaRow, SyncStatus } from '../models/SyncMetaRow';

const TABLE_NAME: string = 'sync_meta';

export class SyncMetaDao {

  /**
   * 查询指定 (game_id, role_uid, data_type) 的同步元数据。
   * 返回 null 表示从未同步过。
   */
  static async find(
    gameId: string,
    roleUid: string,
    dataType: string
  ): Promise<SyncMetaRow | null> {
    try {
      const builder = new QueryBuilder(TABLE_NAME)
        .equalTo('game_id', gameId)
        .equalTo('role_uid', roleUid)
        .equalTo('data_type', dataType);
      const rs = await RdbManager.query(builder.build());
      if (!rs.goToFirstRow()) {
        SyncMetaDao.closeRs(rs);
        return null;
      }
      const row = new SyncMetaRow();
      row.id = rs.getLong(rs.getColumnIndex('id'));
      row.gameId = rs.getString(rs.getColumnIndex('game_id'));
      row.roleUid = rs.getString(rs.getColumnIndex('role_uid'));
      row.dataType = rs.getString(rs.getColumnIndex('data_type'));
      row.lastSyncTime = rs.getLong(rs.getColumnIndex('last_sync_time'));
      row.syncStatus = rs.getString(rs.getColumnIndex('sync_status')) as SyncStatus;
      row.errorMsg = rs.getString(rs.getColumnIndex('error_msg'));
      SyncMetaDao.closeRs(rs);
      return row;
    } catch (error) {
      const msg = error instanceof Error ? error.message : `${error}`;
      throw new Error(`SyncMetaDao.find failed: ${msg}`);
    }
  }

  /**
   * 标记为"同步中"，在发起网络请求前调用。
   * last_sync_time 不更新（保留上次成功时间，供 UI 展示）。
   */
  static async markSyncing(
    gameId: string,
    roleUid: string,
    dataType: string
  ): Promise<void> {
    await SyncMetaDao.upsertStatus(gameId, roleUid, dataType, 'syncing', 0, '');
  }

  /**
   * 标记为"同步成功"，更新 last_sync_time 为当前时间。
   */
  static async markSuccess(
    gameId: string,
    roleUid: string,
    dataType: string
  ): Promise<void> {
    const now = Math.floor(Date.now() / 1000);
    await SyncMetaDao.upsertStatus(gameId, roleUid, dataType, 'success', now, '');
  }

  /**
   * 标记为"同步失败"，更新 last_sync_time 为当前时间，记录错误信息。
   * last_sync_time 仍然更新，避免失败后立即重试。
   */
  static async markFailed(
    gameId: string,
    roleUid: string,
    dataType: string,
    errorMsg: string
  ): Promise<void> {
    const now = Math.floor(Date.now() / 1000);
    await SyncMetaDao.upsertStatus(gameId, roleUid, dataType, 'failed', now, errorMsg);
  }

  /**
   * 判断是否需要重新同步。
   * 返回 true 的条件：从未同步过，或上次同步距今超过 intervalSeconds 秒。
   * 注意：sync_status = 'syncing' 时也返回 false，避免并发重复同步。
   *
   * @param intervalSeconds 同步间隔，默认 1800（30 分钟）
   */
  static async needsSync(
    gameId: string,
    roleUid: string,
    dataType: string,
    intervalSeconds: number = 1800
  ): Promise<boolean> {
    try {
      const meta = await SyncMetaDao.find(gameId, roleUid, dataType);
      if (meta === null) {
        return true;
      }
      if (meta.syncStatus === 'syncing') {
        return false;
      }
      const now = Math.floor(Date.now() / 1000);
      return (now - meta.lastSyncTime) >= intervalSeconds;
    } catch (error) {
      // 查询失败时保守返回 true，让上层决定是否同步
      return true;
    }
  }

  // ─── 私有方法 ────────────────────────────────────────────────

  /**
   * upsert sync_meta 行：存在则更新，不存在则插入。
   * updateTime = 0 时不更新 last_sync_time（用于 markSyncing）。
   */
  private static async upsertStatus(
    gameId: string,
    roleUid: string,
    dataType: string,
    status: SyncStatus,
    lastSyncTime: number,
    errorMsg: string
  ): Promise<void> {
    try {
      const existing = await SyncMetaDao.find(gameId, roleUid, dataType);
      const values: relationalStore.ValuesBucket = {};
      values['game_id'] = gameId;
      values['role_uid'] = roleUid;
      values['data_type'] = dataType;
      values['sync_status'] = status;
      values['error_msg'] = errorMsg;
      // lastSyncTime = 0 表示不更新（markSyncing 场景）
      if (lastSyncTime > 0) {
        values['last_sync_time'] = lastSyncTime;
      } else if (existing !== null) {
        values['last_sync_time'] = existing.lastSyncTime;
      } else {
        values['last_sync_time'] = 0;
      }

      if (existing !== null) {
        const builder = new QueryBuilder(TABLE_NAME)
          .equalTo('game_id', gameId)
          .equalTo('role_uid', roleUid)
          .equalTo('data_type', dataType);
        await RdbManager.update(values, builder.build());
      } else {
        await RdbManager.insert(TABLE_NAME, values);
      }
    } catch (error) {
      const msg = error instanceof Error ? error.message : `${error}`;
      throw new Error(`SyncMetaDao.upsertStatus failed: ${msg}`);
    }
  }

  private static closeRs(rs: relationalStore.ResultSet): void {
    try {
      rs.close();
    } catch (_) {}
  }
}
