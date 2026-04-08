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
import { StarRailApiService } from '../network/StarRailApiService';

interface StarRailEquipItem {
  id: number;
  name: string;
  level: number;
  rank: number;
  rarity: number;
  icon: string;
}

interface StarRailAvatarItem {
  id: number;
  name: string;
  rarity: number;
  level: number;
  rank: number;
  base_type: number;
  element: string;
  element_id: number;
  icon: string;
  figure_path: string;
  is_chosen: boolean;
  equip: StarRailEquipItem | null;
}

interface StarRailAvatarListData {
  list: StarRailAvatarItem[];
  avatar_list: StarRailAvatarItem[];
}

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

  /** 拉取角色列表 → 解析 → 写 DB */
  async syncAvatarList(accountId: number, roleUid: string, server: string, cookie: string): Promise<void> {
    await this.markSyncing(accountId, roleUid, SyncDataType.STARRAIL_AVATAR_BASIC);
    try {
      const resp = await (this.getService() as StarRailApiService).getAvatarBasic(roleUid, server, cookie);
      const rows = StarRailRepository.parseAvatarBasic(accountId, roleUid, resp);
      await this.upsertAvatarList(accountId, roleUid, rows);
    } catch (error) {
      const msg = this.toErrorMessage(error);
      await this.markFailed(accountId, roleUid, SyncDataType.STARRAIL_AVATAR_BASIC, msg);
      throw new Error(msg);
    }
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

  /** 拉取便笺 → 写 DB */
  async syncDailyNote(accountId: number, roleUid: string, server: string, cookie: string): Promise<void> {
    await this.markSyncing(accountId, roleUid, SyncDataType.STARRAIL_DAILY_NOTE);
    try {
      const resp = await (this.getService() as StarRailApiService).getDailyNote(roleUid, server, cookie);
      const respData = resp as Record<string, object>;
      const dataObj = respData['data'] !== undefined ? respData['data'] : resp;
      const row = new StarRailDailyNoteRow();
      row.accountId = accountId;
      row.roleUid = roleUid;
      row.rawJson = JSON.stringify(dataObj);
      row.updateTime = Math.floor(Date.now() / 1000);
      await this.upsertDailyNote(accountId, roleUid, row);
    } catch (error) {
      const msg = this.toErrorMessage(error);
      await this.markFailed(accountId, roleUid, SyncDataType.STARRAIL_DAILY_NOTE, msg);
      throw new Error(msg);
    }
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

  // ── 解析方法 ─────────────────────────────────────────────────

  static parseAvatarBasic(accountId: number, roleUid: string, resp: object): StarRailAvatarBasicRow[] {
    const result: StarRailAvatarBasicRow[] = [];
    try {
      const respRecord = resp as Record<string, object>;
      const dataObj = respRecord['data'] !== undefined ? respRecord['data'] : resp;
      const data = dataObj as StarRailAvatarListData;
      const list = data.avatar_list !== undefined ? data.avatar_list : data.list;
      if (!list || list.length === 0) { return result; }
      for (let i = 0; i < list.length; i++) {
        const item = list[i];
        const equip = item.equip;
        const row = new StarRailAvatarBasicRow();
        row.accountId = accountId;
        row.roleUid = roleUid;
        row.avatarId = `${item.id}`;
        row.name = item.name;
        row.rarity = item.rarity;
        row.level = item.level;
        row.rank = item.rank;
        row.baseType = item.base_type;
        row.elementId = item.element_id;
        row.element = item.element ?? `${item.element_id}`;
        row.icon = item.icon;
        row.figurePath = item.figure_path;
        row.isChosen = item.is_chosen ? 1 : 0;
        row.equipId = equip ? `${equip.id}` : '';
        row.equipName = equip ? equip.name : '';
        row.equipLevel = equip ? equip.level : 0;
        row.equipRank = equip ? equip.rank : 0;
        row.equipRarity = equip ? equip.rarity : 0;
        row.equipIconUrl = equip ? equip.icon : '';
        row.rawJson = JSON.stringify(item);
        row.updateTime = Math.floor(Date.now() / 1000);
        result[result.length] = row;
      }
    } catch (_) {}
    return result;
  }
}
