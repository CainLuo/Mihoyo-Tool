/**
 * StarRailDBManager — 星穹铁道 DB 操作统一管理
 *
 * 封装所有星穹铁道相关表的 CRUD 操作：
 * - starrail_avatar_basic：角色基础信息
 * - starrail_daily_note：实时便笺
 * - starrail_avatar_info：角色详情
 * - starrail_avatar_compute：养成计算
 * - sync_meta：同步状态（通过 SyncMetaDao）
 *
 * 所有写入操作使用事务，保证数据一致性。
 * Repository 层通过此类访问 DB，不直接调用 DAO。
 */
import {
  StarRailAvatarBasicDao,
  StarRailDailyNoteDao,
  StarRailAvatarInfoDao,
  StarRailAvatarComputeDao
} from './StarRailDao';
import { SyncMetaDao } from './SyncMetaDao';
import {
  StarRailAvatarBasicRow,
  StarRailDailyNoteRow,
  StarRailAvatarInfoRow,
  StarRailAvatarComputeRow
} from '../models/StarRailRows';
import { MaterialBagRow } from '../models/MaterialBagRow';
import { SyncMetaRow } from '../models/SyncMetaRow';
import { RdbManager } from './RdbManager';
import { SyncDataType } from '../constants/SyncDataType';
import { MaterialBagRepository } from '../repository/MaterialBagRepository';
import { GameId } from '../constants/GameId';

export class StarRailDBManager {
  private avatarBasicDao: StarRailAvatarBasicDao = new StarRailAvatarBasicDao();
  private dailyNoteDao: StarRailDailyNoteDao = new StarRailDailyNoteDao();
  private avatarInfoDao: StarRailAvatarInfoDao = new StarRailAvatarInfoDao();
  private avatarComputeDao: StarRailAvatarComputeDao = new StarRailAvatarComputeDao();
  private syncMetaDao: SyncMetaDao = new SyncMetaDao();
  private materialBagRepo: MaterialBagRepository = new MaterialBagRepository();

  // ── 角色基础列表 ──────────────────────────────────────────────

  /**
   * 查询指定账号和角色的所有星穹铁道角色基础信息。
   */
  async getAvatarList(accountId: string, roleUid: string): Promise<StarRailAvatarBasicRow[]> {
    return this.avatarBasicDao.findAll(accountId, roleUid);
  }

  /**
   * 批量写入星穹铁道角色基础信息，同时更新 sync_meta 状态为 success。
   * 使用事务，保证数据一致性。
   */
  async upsertAvatarListWithSync(accountId: string, roleUid: string, rows: StarRailAvatarBasicRow[]): Promise<void> {
    if (rows.length === 0) {
      return;
    }
    await RdbManager.runInTransaction(async () => {
      await this.avatarBasicDao.upsertAll(rows);
      await this.syncMetaDao.updateStatus(accountId, roleUid, SyncDataType.STARRAIL_AVATAR_BASIC, 'success');
    });
  }

  /**
   * 批量写入星穹铁道角色基础信息（不更新 sync_meta）。
   */
  async upsertAvatarList(rows: StarRailAvatarBasicRow[]): Promise<void> {
    if (rows.length === 0) {
      return;
    }
    await RdbManager.runInTransaction(async () => {
      await this.avatarBasicDao.upsertAll(rows);
    });
  }

  /**
   * 删除指定账号和角色的所有星穹铁道角色基础信息记录。
   */
  async deleteAvatarList(accountId: string, roleUid: string): Promise<void> {
    await this.avatarBasicDao.deleteAll(accountId, roleUid);
  }

  // ── sync_meta 状态管理 ────────────────────────────────────────

  /**
   * 检查是否需要同步（距离上次同步超过阈值）。
   */
  async needsSync(accountId: string, roleUid: string, dataType: string): Promise<boolean> {
    const meta: SyncMetaRow | null = await this.syncMetaDao.findOne(accountId, roleUid, dataType);
    if (meta === null) {
      return true;
    }
    const now = Math.floor(Date.now() / 1000);
    const threshold = 300; // 5 分钟
    return now - meta.lastSyncTime > threshold;
  }

  /**
   * 获取上次同步时间。
   */
  async getLastSyncTime(accountId: string, roleUid: string, dataType: string): Promise<number> {
    const meta: SyncMetaRow | null = await this.syncMetaDao.findOne(accountId, roleUid, dataType);
    if (meta === null) {
      return 0;
    }
    return meta.lastSyncTime;
  }

  /**
   * 标记为 syncing 状态。
   */
  async markSyncing(accountId: string, roleUid: string, dataType: string): Promise<void> {
    await this.syncMetaDao.updateStatus(accountId, roleUid, dataType, 'syncing');
  }

  /**
   * 标记为 success 状态，更新 lastSyncTime。
   */
  async markSuccess(accountId: string, roleUid: string, dataType: string): Promise<void> {
    await this.syncMetaDao.updateStatus(accountId, roleUid, dataType, 'success');
  }

  /**
   * 标记为 failed 状态，记录错误信息。
   */
  async markFailed(accountId: string, roleUid: string, dataType: string, errorMsg: string): Promise<void> {
    await this.syncMetaDao.updateStatus(accountId, roleUid, dataType, 'failed', errorMsg);
  }

  // ── 实时便笺 ──────────────────────────────────────────────────

  /**
   * 查询指定角色的星穹铁道实时便笺。
   */
  async getDailyNote(accountId: string, roleUid: string): Promise<StarRailDailyNoteRow | null> {
    return this.dailyNoteDao.findOne(accountId, roleUid);
  }

  /**
   * 写入星穹铁道实时便笺，同时更新 sync_meta 状态为 success。
   */
  async upsertDailyNoteWithSync(accountId: string, roleUid: string, row: StarRailDailyNoteRow): Promise<void> {
    await RdbManager.runInTransaction(async () => {
      await this.dailyNoteDao.upsert(row);
      await this.syncMetaDao.updateStatus(accountId, roleUid, SyncDataType.STARRAIL_DAILY_NOTE, 'success');
    });
  }

  /**
   * 写入星穹铁道实时便笺（不更新 sync_meta）。
   */
  async upsertDailyNote(row: StarRailDailyNoteRow): Promise<void> {
    await RdbManager.runInTransaction(async () => {
      await this.dailyNoteDao.upsert(row);
    });
  }

  /**
   * 删除指定角色的星穹铁道实时便笺记录。
   */
  async deleteDailyNote(accountId: string, roleUid: string): Promise<void> {
    await this.dailyNoteDao.deleteOne(accountId, roleUid);
  }

  // ── 角色详情 ──────────────────────────────────────────────────

  /**
   * 按 avatarId 查询星穹铁道角色详情。
   */
  async getAvatarDetail(accountId: string, roleUid: string, avatarId: string): Promise<StarRailAvatarInfoRow | null> {
    return this.avatarInfoDao.findByAvatarId(accountId, roleUid, avatarId);
  }

  /**
   * 批量写入星穹铁道角色详情，同时更新 sync_meta 状态为 success。
   */
  async upsertAvatarDetailsWithSync(accountId: string, roleUid: string, rows: StarRailAvatarInfoRow[]): Promise<void> {
    if (rows.length === 0) {
      return;
    }
    await RdbManager.runInTransaction(async () => {
      await this.avatarInfoDao.upsertAll(rows);
      await this.syncMetaDao.updateStatus(accountId, roleUid, SyncDataType.STARRAIL_AVATAR_INFO, 'success');
    });
  }

  /**
   * 批量写入星穹铁道角色详情（不更新 sync_meta）。
   */
  async upsertAvatarDetails(rows: StarRailAvatarInfoRow[]): Promise<void> {
    if (rows.length === 0) {
      return;
    }
    await RdbManager.runInTransaction(async () => {
      await this.avatarInfoDao.upsertAll(rows);
    });
  }

  /**
   * 删除指定账号和角色的所有星穹铁道角色详情记录。
   */
  async deleteAvatarDetails(accountId: string, roleUid: string): Promise<void> {
    await this.avatarInfoDao.deleteAll(accountId, roleUid);
  }

  // ── 养成计算 ──────────────────────────────────────────────────

  /**
   * 按 avatarId 查询星穹铁道角色养成计算数据。
   */
  async getAvatarCompute(accountId: string, roleUid: string, avatarId: string): Promise<StarRailAvatarComputeRow | null> {
    return this.avatarComputeDao.findByAvatarId(accountId, roleUid, avatarId);
  }

  /**
   * 查询指定账号和角色的所有星穹铁道养成计算记录。
   */
  async getAllComputeData(accountId: string, roleUid: string): Promise<StarRailAvatarComputeRow[]> {
    return this.avatarComputeDao.findAll(accountId, roleUid);
  }

  /**
   * 写入星穹铁道角色养成计算数据，同时更新 sync_meta 状态为 success，并写入材料背包。
   */
  async upsertAvatarComputeWithSync(
    accountId: string,
    roleUid: string,
    row: StarRailAvatarComputeRow,
    materialRows: MaterialBagRow[]
  ): Promise<void> {
    await RdbManager.runInTransaction(async () => {
      await this.avatarComputeDao.upsert(row);
      // 写入材料背包
      if (materialRows.length > 0) {
        await this.materialBagRepo.upsertMaterials(accountId, roleUid, materialRows, GameId.STARRAIL);
      }
      await this.syncMetaDao.updateStatus(accountId, roleUid, SyncDataType.STARRAIL_AVATAR_COMPUTE, 'success');
    });
  }

  /**
   * 写入星穹铁道角色养成计算数据（不更新 sync_meta，不写入材料背包）。
   */
  async upsertAvatarCompute(row: StarRailAvatarComputeRow): Promise<void> {
    await RdbManager.runInTransaction(async () => {
      await this.avatarComputeDao.upsert(row);
    });
  }

  /**
   * 删除指定角色的星穹铁道养成计算记录。
   */
  async deleteAvatarCompute(accountId: string, roleUid: string, avatarId: string): Promise<void> {
    await this.avatarComputeDao.deleteAll(accountId, roleUid);
  }

  /**
   * 删除指定账号和角色的所有星穹铁道养成计算记录。
   */
  async deleteAllAvatarCompute(accountId: string, roleUid: string): Promise<void> {
    await this.avatarComputeDao.deleteAll(accountId, roleUid);
  }
}
