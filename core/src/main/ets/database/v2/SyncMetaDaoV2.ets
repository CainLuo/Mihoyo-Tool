/**
 * SyncMetaDaoV2 — sync_meta 表的 DAO
 *
 * sync_meta 表记录每个角色（account_id + role_uid）每种数据类型（data_type）
 * 的最后同步时间和同步状态，供 Repository 层判断是否需要重新同步。
 *
 * data_type 的值与 TableName enum 对齐（如 'genshin_character_list'），
 * 通过 SyncDataType（即 TableName 的别名）引用，禁止直接写字符串。
 */
import { relationalStore } from '@kit.ArkData';
import { RdbManagerV2 } from './RdbManagerV2';
import { TableName, CommonCol, SyncMetaCol, SYNC_META_TABLE } from './TableSchema';
import { SyncMetaRow } from '../../models/v2/SyncMetaRow';

// ─────────────────────────────────────────────
// SyncMetaDaoV2：操作 sync_meta
// ─────────────────────────────────────────────
export class SyncMetaDaoV2 {

  /**
   * INSERT OR REPLACE
   */
  async upsert(row: SyncMetaRow): Promise<void> {
    const idVal: relationalStore.ValueType = row.id > 0 ? row.id : null;
    try {
      await RdbManagerV2.upsertRow(TableName.SYNC_META, SYNC_META_TABLE.columnNames(), [
        idVal, row.accountId, row.roleUid, row.dataType,
        row.lastSyncTime, row.syncStatus, row.errorMsg
      ]);
    } catch (e) {
      throw new Error(`SyncMetaDaoV2.upsert failed: ${e instanceof Error ? e.message : e}`);
    }
  }

  /**
   * 查询单条同步状态记录
   */
  async findOne(accountId: number, roleUid: string, dataType: string): Promise<SyncMetaRow | null> {
    const predicates = new relationalStore.RdbPredicates(TableName.SYNC_META);
    predicates.equalTo(CommonCol.ACCOUNT_ID, accountId);
    predicates.and();
    predicates.equalTo(CommonCol.ROLE_UID, roleUid);
    predicates.and();
    predicates.equalTo(CommonCol.DATA_TYPE, dataType);
    try {
      return await RdbManagerV2.queryFirst(predicates, SYNC_META_TABLE.columnNames(), (rs) => SyncMetaDaoV2.mapRow(rs));
    } catch (e) {
      throw new Error(`SyncMetaDaoV2.findOne failed: ${e instanceof Error ? e.message : e}`);
    }
  }

  /**
   * 更新同步状态。
   * - status='syncing'：标记同步开始，不更新 last_sync_time
   * - status='success'：标记同步成功，同时将 last_sync_time 更新为当前 Unix 秒
   * - status='failed'：标记同步失败，记录错误信息，不更新 last_sync_time
   *
   * 若记录不存在（UPDATE 0 行），不抛异常，由调用方决定是否先 upsert。
   *
   * @param accountId 米游社账号 ID
   * @param roleUid   游戏角色 UID
   * @param dataType  数据类型（使用 SyncDataType enum 值）
   * @param status    同步状态字符串（'syncing' | 'success' | 'failed'）
   * @param errorMsg  失败时的错误信息（可选，默认为空字符串）
   */
  async updateStatus(
    accountId: number,
    roleUid: string,
    dataType: string,
    status: string,
    errorMsg?: string
  ): Promise<void> {
    const now = Math.floor(Date.now() / 1000);
    const msg = errorMsg !== undefined ? errorMsg : '';
    const whereCols = [CommonCol.ACCOUNT_ID, CommonCol.ROLE_UID, CommonCol.DATA_TYPE];
    const whereVals: Array<relationalStore.ValueType> = [accountId, roleUid, dataType];
    try {
      if (status === 'success') {
        await RdbManagerV2.updateRows(TableName.SYNC_META,
          [SyncMetaCol.SYNC_STATUS, SyncMetaCol.ERROR_MSG, SyncMetaCol.LAST_SYNC_TIME],
          [status, msg, now],
          whereCols, whereVals
        );
      } else {
        await RdbManagerV2.updateRows(TableName.SYNC_META,
          [SyncMetaCol.SYNC_STATUS, SyncMetaCol.ERROR_MSG],
          [status, msg],
          whereCols, whereVals
        );
      }
    } catch (e) {
      throw new Error(`SyncMetaDaoV2.updateStatus failed: ${e instanceof Error ? e.message : e}`);
    }
  }

  /** 将 ResultSet 当前行映射为 SyncMetaRow */
  private static mapRow(rs: relationalStore.ResultSet): SyncMetaRow {
    try {
      const row = new SyncMetaRow();
      const idVal = rs.getValue(rs.getColumnIndex(CommonCol.ID));
      row.id = typeof idVal === 'number' ? idVal : 0;
      const accountIdVal = rs.getValue(rs.getColumnIndex(CommonCol.ACCOUNT_ID));
      row.accountId = typeof accountIdVal === 'number' ? accountIdVal : 0;
      const roleUidVal = rs.getValue(rs.getColumnIndex(CommonCol.ROLE_UID));
      row.roleUid = typeof roleUidVal === 'string' ? roleUidVal : '';
      const dataTypeVal = rs.getValue(rs.getColumnIndex(CommonCol.DATA_TYPE));
      row.dataType = typeof dataTypeVal === 'string' ? dataTypeVal : '';
      const lastSyncTimeVal = rs.getValue(rs.getColumnIndex(SyncMetaCol.LAST_SYNC_TIME));
      row.lastSyncTime = typeof lastSyncTimeVal === 'number' ? lastSyncTimeVal : 0;
      const syncStatusVal = rs.getValue(rs.getColumnIndex(SyncMetaCol.SYNC_STATUS));
      row.syncStatus = typeof syncStatusVal === 'string' ? syncStatusVal : '';
      const errorMsgVal = rs.getValue(rs.getColumnIndex(SyncMetaCol.ERROR_MSG));
      row.errorMsg = typeof errorMsgVal === 'string' ? errorMsgVal : '';
      return row;
    } catch (e) {
      throw new Error(`SyncMetaDaoV2.mapRow failed: ${e instanceof Error ? e.message : e}`);
    }
  }
}
