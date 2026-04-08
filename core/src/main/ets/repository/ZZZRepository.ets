import { GameRepository } from './GameRepository';
import { SyncDataType } from '../constants/SyncDataType';
import {
  ZZZAvatarBasicDao,
  ZZZDailyNoteDao,
  ZZZAvatarInfoDao,
  ZZZAvatarComputeDao
} from '../database/ZZZDao';
import {
  ZZZAvatarBasicRow,
  ZZZDailyNoteRow,
  ZZZAvatarInfoRow,
  ZZZAvatarComputeRow
} from '../models/ZZZRows';
import { ZZZApiService } from '../network/ZZZApiService';

interface ZZZAvatarItem {
  id: number;
  name_mi18n: string;
  full_name_mi18n: string;
  rarity: string;
  level: number;
  rank: number;
  element_type: number;
  sub_element_type: number;
  avatar_profession: number;
  camp_name_mi18n: string;
  group_icon_path: string;
  hollow_icon_path: string;
  role_square_url: string;
  is_chosen: boolean;
  awaken_state: string;
}

interface ZZZAvatarListData {
  avatar_list: ZZZAvatarItem[];
}

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

  /** 拉取角色列表 → 解析 → 写 DB */
  async syncAvatarList(accountId: number, roleUid: string, server: string, cookie: string): Promise<void> {
    await this.markSyncing(accountId, roleUid, SyncDataType.ZZZ_AVATAR_BASIC);
    try {
      const resp = await (this.getService() as ZZZApiService).getAvatarBasic(roleUid, server, cookie);
      const rows = ZZZRepository.parseAvatarBasic(accountId, roleUid, resp);
      await this.upsertAvatarList(accountId, roleUid, rows);
    } catch (error) {
      const msg = this.toErrorMessage(error);
      await this.markFailed(accountId, roleUid, SyncDataType.ZZZ_AVATAR_BASIC, msg);
      throw new Error(msg);
    }
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

  /** 拉取便笺 → 写 DB */
  async syncDailyNote(accountId: number, roleUid: string, server: string, cookie: string): Promise<void> {
    await this.markSyncing(accountId, roleUid, SyncDataType.ZZZ_DAILY_NOTE);
    try {
      const resp = await (this.getService() as ZZZApiService).getDailyNote(roleUid, server, cookie);
      const respData = resp as Record<string, object>;
      const dataObj = respData['data'] !== undefined ? respData['data'] : resp;
      const row = new ZZZDailyNoteRow();
      row.accountId = accountId;
      row.roleUid = roleUid;
      row.rawJson = JSON.stringify(dataObj);
      row.updateTime = Math.floor(Date.now() / 1000);
      await this.upsertDailyNote(accountId, roleUid, row);
    } catch (error) {
      const msg = this.toErrorMessage(error);
      await this.markFailed(accountId, roleUid, SyncDataType.ZZZ_DAILY_NOTE, msg);
      throw new Error(msg);
    }
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

  // ── 解析方法 ─────────────────────────────────────────────────

  static parseAvatarBasic(accountId: number, roleUid: string, resp: object): ZZZAvatarBasicRow[] {
    const result: ZZZAvatarBasicRow[] = [];
    try {
      const respRecord = resp as Record<string, object>;
      const dataObj = respRecord['data'] !== undefined ? respRecord['data'] : resp;
      const data = dataObj as ZZZAvatarListData;
      const list = data.avatar_list;
      if (!list || list.length === 0) { return result; }
      for (let i = 0; i < list.length; i++) {
        const item = list[i];
        const row = new ZZZAvatarBasicRow();
        row.accountId = accountId;
        row.roleUid = roleUid;
        row.avatarId = `${item.id}`;
        row.nameMi18n = item.name_mi18n;
        row.fullNameMi18n = item.full_name_mi18n;
        row.rarity = item.rarity;
        row.level = item.level;
        row.rank = item.rank;
        row.elementType = item.element_type;
        row.subElementType = item.sub_element_type ?? 0;
        row.avatarProfession = item.avatar_profession;
        row.campNameMi18n = item.camp_name_mi18n ?? '';
        row.groupIconPath = item.group_icon_path ?? '';
        row.hollowIconPath = item.hollow_icon_path;
        row.roleSquareUrl = item.role_square_url;
        row.isChosen = item.is_chosen ? 1 : 0;
        row.awakenState = 0; // awaken_state 是字符串枚举，统一存 0（DB 存 TEXT，UI 从 rawJson 读取）
        row.rawJson = JSON.stringify(item);
        row.updateTime = Math.floor(Date.now() / 1000);
        result[result.length] = row;
      }
    } catch (_) {}
    return result;
  }
}
