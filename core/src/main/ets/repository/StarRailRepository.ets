import { GameRepository } from './GameRepository';
import { SyncDataType } from '../constants/SyncDataType';
import {
  StarRailAvatarBasicDao,
  StarRailDailyNoteDao,
  StarRailAvatarInfoDao,
  StarRailAvatarComputeDao
} from '../database/StarRailDao';
import {
  StarRailAvatarBasicRow,
  StarRailDailyNoteRow,
  StarRailAvatarInfoRow,
  StarRailAvatarComputeRow
} from '../models/StarRailRows';

export class StarRailRepository extends GameRepository {
  private avatarBasicDao: StarRailAvatarBasicDao = new StarRailAvatarBasicDao();
  private dailyNoteDao: StarRailDailyNoteDao = new StarRailDailyNoteDao();
  private avatarInfoDao: StarRailAvatarInfoDao = new StarRailAvatarInfoDao();
  private avatarComputeDao: StarRailAvatarComputeDao = new StarRailAvatarComputeDao();

  // ── 角色基础列表 ──────────────────────────────────────────────

  async getAvatarList(accountId: number, roleUid: string): Promise<StarRailAvatarBasicRow[]> {
    return this.avatarBasicDao.findAll(accountId, roleUid);
  }

  async upsertAvatarList(accountId: number, roleUid: string, rows: StarRailAvatarBasicRow[]): Promise<void> {
    await this.runInTransaction(async () => {
      await this.avatarBasicDao.upsertAll(rows);
      await this.markSuccess(accountId, roleUid, SyncDataType.STARRAIL_AVATAR_BASIC);
    });
  }

  async deleteAvatarList(accountId: number, roleUid: string): Promise<void> {
    await this.avatarBasicDao.deleteAll(accountId, roleUid);
  }

  async needsAvatarListSync(accountId: number, roleUid: string): Promise<boolean> {
    return this.needsSync(accountId, roleUid, SyncDataType.STARRAIL_AVATAR_BASIC);
  }

  async markAvatarListSyncing(accountId: number, roleUid: string): Promise<void> {
    await this.markSyncing(accountId, roleUid, SyncDataType.STARRAIL_AVATAR_BASIC);
  }

  async markAvatarListFailed(accountId: number, roleUid: string, errorMsg: string): Promise<void> {
    await this.markFailed(accountId, roleUid, SyncDataType.STARRAIL_AVATAR_BASIC, errorMsg);
  }

  // ── 实时便笺 ──────────────────────────────────────────────────

  async getDailyNote(accountId: number, roleUid: string): Promise<StarRailDailyNoteRow | null> {
    return this.dailyNoteDao.findOne(accountId, roleUid);
  }

  async upsertDailyNote(accountId: number, roleUid: string, row: StarRailDailyNoteRow): Promise<void> {
    await this.runInTransaction(async () => {
      await this.dailyNoteDao.upsert(row);
      await this.markSuccess(accountId, roleUid, SyncDataType.STARRAIL_DAILY_NOTE);
    });
  }

  async needsDailyNoteSync(accountId: number, roleUid: string): Promise<boolean> {
    return this.needsSync(accountId, roleUid, SyncDataType.STARRAIL_DAILY_NOTE);
  }

  async markDailyNoteSyncing(accountId: number, roleUid: string): Promise<void> {
    await this.markSyncing(accountId, roleUid, SyncDataType.STARRAIL_DAILY_NOTE);
  }

  async markDailyNoteFailed(accountId: number, roleUid: string, errorMsg: string): Promise<void> {
    await this.markFailed(accountId, roleUid, SyncDataType.STARRAIL_DAILY_NOTE, errorMsg);
  }

  // ── 角色详情 ──────────────────────────────────────────────────

  async getAvatarDetail(accountId: number, roleUid: string, avatarId: string): Promise<StarRailAvatarInfoRow | null> {
    return this.avatarInfoDao.findByAvatarId(accountId, roleUid, avatarId);
  }

  async upsertAvatarDetails(accountId: number, roleUid: string, rows: StarRailAvatarInfoRow[]): Promise<void> {
    await this.runInTransaction(async () => {
      await this.avatarInfoDao.upsertAll(rows);
      await this.markSuccess(accountId, roleUid, SyncDataType.STARRAIL_AVATAR_INFO);
    });
  }

  async needsAvatarDetailSync(accountId: number, roleUid: string): Promise<boolean> {
    return this.needsSync(accountId, roleUid, SyncDataType.STARRAIL_AVATAR_INFO);
  }

  async markAvatarDetailSyncing(accountId: number, roleUid: string): Promise<void> {
    await this.markSyncing(accountId, roleUid, SyncDataType.STARRAIL_AVATAR_INFO);
  }

  async markAvatarDetailFailed(accountId: number, roleUid: string, errorMsg: string): Promise<void> {
    await this.markFailed(accountId, roleUid, SyncDataType.STARRAIL_AVATAR_INFO, errorMsg);
  }

  // ── 养成材料计算 ──────────────────────────────────────────────

  async getAvatarCompute(accountId: number, roleUid: string, avatarId: string): Promise<StarRailAvatarComputeRow | null> {
    return this.avatarComputeDao.findByAvatarId(accountId, roleUid, avatarId);
  }

  async upsertAvatarCompute(accountId: number, roleUid: string, row: StarRailAvatarComputeRow): Promise<void> {
    await this.runInTransaction(async () => {
      await this.avatarComputeDao.upsert(row);
      await this.markSuccess(accountId, roleUid, SyncDataType.STARRAIL_AVATAR_COMPUTE);
    });
  }

  async needsAvatarComputeSync(accountId: number, roleUid: string): Promise<boolean> {
    return this.needsSync(accountId, roleUid, SyncDataType.STARRAIL_AVATAR_COMPUTE);
  }

  async markAvatarComputeSyncing(accountId: number, roleUid: string): Promise<void> {
    await this.markSyncing(accountId, roleUid, SyncDataType.STARRAIL_AVATAR_COMPUTE);
  }

  async markAvatarComputeFailed(accountId: number, roleUid: string, errorMsg: string): Promise<void> {
    await this.markFailed(accountId, roleUid, SyncDataType.STARRAIL_AVATAR_COMPUTE, errorMsg);
  }
}
