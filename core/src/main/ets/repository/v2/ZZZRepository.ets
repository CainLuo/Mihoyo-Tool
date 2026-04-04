import { GameRepository } from './GameRepository';
import { SyncDataType } from '../../constants/SyncDataType';
import {
  ZZZAvatarBasicDao,
  ZZZDailyNoteDao,
  ZZZAvatarInfoDao,
  ZZZAvatarComputeDao
} from '../../database/v2/ZZZDao';
import {
  ZZZAvatarBasicRow,
  ZZZDailyNoteRow,
  ZZZAvatarInfoRow,
  ZZZAvatarComputeRow
} from '../../models/v2/ZZZRows';

export class ZZZRepository extends GameRepository {
  private avatarBasicDao: ZZZAvatarBasicDao = new ZZZAvatarBasicDao();
  private dailyNoteDao: ZZZDailyNoteDao = new ZZZDailyNoteDao();
  private avatarInfoDao: ZZZAvatarInfoDao = new ZZZAvatarInfoDao();
  private avatarComputeDao: ZZZAvatarComputeDao = new ZZZAvatarComputeDao();

  // ── 角色基础列表 ──────────────────────────────────────────────

  async getAvatarList(accountId: number, roleUid: string): Promise<ZZZAvatarBasicRow[]> {
    return this.avatarBasicDao.findAll(accountId, roleUid);
  }

  async upsertAvatarList(accountId: number, roleUid: string, rows: ZZZAvatarBasicRow[]): Promise<void> {
    await this.runInTransaction(async () => {
      await this.avatarBasicDao.upsertAll(rows);
      await this.markSuccess(accountId, roleUid, SyncDataType.ZZZ_AVATAR_BASIC);
    });
  }

  async deleteAvatarList(accountId: number, roleUid: string): Promise<void> {
    await this.avatarBasicDao.deleteAll(accountId, roleUid);
  }

  async needsAvatarListSync(accountId: number, roleUid: string): Promise<boolean> {
    return this.needsSync(accountId, roleUid, SyncDataType.ZZZ_AVATAR_BASIC);
  }

  async markAvatarListSyncing(accountId: number, roleUid: string): Promise<void> {
    await this.markSyncing(accountId, roleUid, SyncDataType.ZZZ_AVATAR_BASIC);
  }

  async markAvatarListFailed(accountId: number, roleUid: string, errorMsg: string): Promise<void> {
    await this.markFailed(accountId, roleUid, SyncDataType.ZZZ_AVATAR_BASIC, errorMsg);
  }

  // ── 实时便笺 ──────────────────────────────────────────────────

  async getDailyNote(accountId: number, roleUid: string): Promise<ZZZDailyNoteRow | null> {
    return this.dailyNoteDao.findOne(accountId, roleUid);
  }

  async upsertDailyNote(accountId: number, roleUid: string, row: ZZZDailyNoteRow): Promise<void> {
    await this.runInTransaction(async () => {
      await this.dailyNoteDao.upsert(row);
      await this.markSuccess(accountId, roleUid, SyncDataType.ZZZ_DAILY_NOTE);
    });
  }

  async needsDailyNoteSync(accountId: number, roleUid: string): Promise<boolean> {
    return this.needsSync(accountId, roleUid, SyncDataType.ZZZ_DAILY_NOTE);
  }

  async markDailyNoteSyncing(accountId: number, roleUid: string): Promise<void> {
    await this.markSyncing(accountId, roleUid, SyncDataType.ZZZ_DAILY_NOTE);
  }

  async markDailyNoteFailed(accountId: number, roleUid: string, errorMsg: string): Promise<void> {
    await this.markFailed(accountId, roleUid, SyncDataType.ZZZ_DAILY_NOTE, errorMsg);
  }

  // ── 角色详情 ──────────────────────────────────────────────────

  async getAvatarDetail(accountId: number, roleUid: string, avatarId: string): Promise<ZZZAvatarInfoRow | null> {
    return this.avatarInfoDao.findByAvatarId(accountId, roleUid, avatarId);
  }

  async upsertAvatarDetails(accountId: number, roleUid: string, rows: ZZZAvatarInfoRow[]): Promise<void> {
    await this.runInTransaction(async () => {
      await this.avatarInfoDao.upsertAll(rows);
      await this.markSuccess(accountId, roleUid, SyncDataType.ZZZ_AVATAR_INFO);
    });
  }

  async needsAvatarDetailSync(accountId: number, roleUid: string): Promise<boolean> {
    return this.needsSync(accountId, roleUid, SyncDataType.ZZZ_AVATAR_INFO);
  }

  async markAvatarDetailSyncing(accountId: number, roleUid: string): Promise<void> {
    await this.markSyncing(accountId, roleUid, SyncDataType.ZZZ_AVATAR_INFO);
  }

  async markAvatarDetailFailed(accountId: number, roleUid: string, errorMsg: string): Promise<void> {
    await this.markFailed(accountId, roleUid, SyncDataType.ZZZ_AVATAR_INFO, errorMsg);
  }

  // ── 养成材料计算 ──────────────────────────────────────────────

  async getAvatarCompute(accountId: number, roleUid: string, avatarId: string): Promise<ZZZAvatarComputeRow | null> {
    return this.avatarComputeDao.findByAvatarId(accountId, roleUid, avatarId);
  }

  async upsertAvatarCompute(accountId: number, roleUid: string, row: ZZZAvatarComputeRow): Promise<void> {
    await this.runInTransaction(async () => {
      await this.avatarComputeDao.upsert(row);
      await this.markSuccess(accountId, roleUid, SyncDataType.ZZZ_AVATAR_COMPUTE);
    });
  }

  async needsAvatarComputeSync(accountId: number, roleUid: string): Promise<boolean> {
    return this.needsSync(accountId, roleUid, SyncDataType.ZZZ_AVATAR_COMPUTE);
  }

  async markAvatarComputeSyncing(accountId: number, roleUid: string): Promise<void> {
    await this.markSyncing(accountId, roleUid, SyncDataType.ZZZ_AVATAR_COMPUTE);
  }

  async markAvatarComputeFailed(accountId: number, roleUid: string, errorMsg: string): Promise<void> {
    await this.markFailed(accountId, roleUid, SyncDataType.ZZZ_AVATAR_COMPUTE, errorMsg);
  }
}
