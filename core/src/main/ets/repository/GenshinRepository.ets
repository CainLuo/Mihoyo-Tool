import { GameRepository } from './GameRepository';
import { SyncDataType } from '../constants/SyncDataType';
import {
  GenshinCharacterListDao,
  GenshinDailyNoteDao,
  GenshinCharacterDetailDao,
  GenshinCharacterComputeDao
} from '../database/GenshinDao';
import {
  GenshinCharacterListRow,
  GenshinDailyNoteRow,
  GenshinCharacterDetailRow,
  GenshinCharacterComputeRow
} from '../models/GenshinRows';

export class GenshinRepository extends GameRepository {
  private characterListDao: GenshinCharacterListDao = new GenshinCharacterListDao();
  private dailyNoteDao: GenshinDailyNoteDao = new GenshinDailyNoteDao();
  private characterDetailDao: GenshinCharacterDetailDao = new GenshinCharacterDetailDao();
  private characterComputeDao: GenshinCharacterComputeDao = new GenshinCharacterComputeDao();

  // ── 角色列表 ──────────────────────────────────────────────────

  /**
   * 获取角色列表（先返回 DB 缓存，若超过同步阈值则触发后台网络请求）
   * 注意：网络请求和 DB 写入逻辑在 ViewModel 层触发，Repository 只提供 DB 读写接口
   */
  async getAvatarList(accountId: number, roleUid: string): Promise<GenshinCharacterListRow[]> {
    return this.characterListDao.findAll(accountId, roleUid);
  }

  async upsertAvatarList(accountId: number, roleUid: string, rows: GenshinCharacterListRow[]): Promise<void> {
    await this.runInTransaction(async () => {
      await this.characterListDao.upsertAll(rows);
      await this.markSuccess(accountId, roleUid, SyncDataType.GENSHIN_CHARACTER_LIST);
    });
  }

  async deleteAvatarList(accountId: number, roleUid: string): Promise<void> {
    await this.characterListDao.deleteAll(accountId, roleUid);
  }

  async needsAvatarListSync(accountId: number, roleUid: string): Promise<boolean> {
    return this.needsSync(accountId, roleUid, SyncDataType.GENSHIN_CHARACTER_LIST);
  }

  async markAvatarListSyncing(accountId: number, roleUid: string): Promise<void> {
    await this.markSyncing(accountId, roleUid, SyncDataType.GENSHIN_CHARACTER_LIST);
  }

  async markAvatarListFailed(accountId: number, roleUid: string, errorMsg: string): Promise<void> {
    await this.markFailed(accountId, roleUid, SyncDataType.GENSHIN_CHARACTER_LIST, errorMsg);
  }

  // ── 实时便笺 ──────────────────────────────────────────────────

  async getDailyNote(accountId: number, roleUid: string): Promise<GenshinDailyNoteRow | null> {
    return this.dailyNoteDao.findOne(accountId, roleUid);
  }

  async upsertDailyNote(accountId: number, roleUid: string, row: GenshinDailyNoteRow): Promise<void> {
    await this.runInTransaction(async () => {
      await this.dailyNoteDao.upsert(row);
      await this.markSuccess(accountId, roleUid, SyncDataType.GENSHIN_DAILY_NOTE);
    });
  }

  async needsDailyNoteSync(accountId: number, roleUid: string): Promise<boolean> {
    return this.needsSync(accountId, roleUid, SyncDataType.GENSHIN_DAILY_NOTE);
  }

  async markDailyNoteSyncing(accountId: number, roleUid: string): Promise<void> {
    await this.markSyncing(accountId, roleUid, SyncDataType.GENSHIN_DAILY_NOTE);
  }

  async markDailyNoteFailed(accountId: number, roleUid: string, errorMsg: string): Promise<void> {
    await this.markFailed(accountId, roleUid, SyncDataType.GENSHIN_DAILY_NOTE, errorMsg);
  }

  // ── 角色详情 ──────────────────────────────────────────────────

  async getAvatarDetail(accountId: number, roleUid: string, avatarId: string): Promise<GenshinCharacterDetailRow | null> {
    return this.characterDetailDao.findByAvatarId(accountId, roleUid, avatarId);
  }

  async upsertAvatarDetails(accountId: number, roleUid: string, rows: GenshinCharacterDetailRow[]): Promise<void> {
    await this.runInTransaction(async () => {
      await this.characterDetailDao.upsertAll(rows);
      await this.markSuccess(accountId, roleUid, SyncDataType.GENSHIN_CHARACTER_DETAIL);
    });
  }

  async needsAvatarDetailSync(accountId: number, roleUid: string): Promise<boolean> {
    return this.needsSync(accountId, roleUid, SyncDataType.GENSHIN_CHARACTER_DETAIL);
  }

  async markAvatarDetailSyncing(accountId: number, roleUid: string): Promise<void> {
    await this.markSyncing(accountId, roleUid, SyncDataType.GENSHIN_CHARACTER_DETAIL);
  }

  async markAvatarDetailFailed(accountId: number, roleUid: string, errorMsg: string): Promise<void> {
    await this.markFailed(accountId, roleUid, SyncDataType.GENSHIN_CHARACTER_DETAIL, errorMsg);
  }

  // ── 养成材料计算 ──────────────────────────────────────────────

  async getAvatarCompute(accountId: number, roleUid: string, avatarId: string): Promise<GenshinCharacterComputeRow | null> {
    return this.characterComputeDao.findByAvatarId(accountId, roleUid, avatarId);
  }

  async upsertAvatarCompute(accountId: number, roleUid: string, row: GenshinCharacterComputeRow): Promise<void> {
    await this.runInTransaction(async () => {
      await this.characterComputeDao.upsert(row);
      await this.markSuccess(accountId, roleUid, SyncDataType.GENSHIN_CHARACTER_COMPUTE);
    });
  }
}
