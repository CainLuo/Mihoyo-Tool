import { GameRepository } from './GameRepository';
import { SyncDataType } from '../constants/SyncDataType';
import {
  ZZZAvatarBasicDao,
  ZZZDailyNoteDao,
  ZZZAvatarInfoDao,
  ZZZAvatarComputeDao,
  ZZZBuddyDao
} from '../database/ZZZDao';
import {
  ZZZAvatarBasicRow,
  ZZZDailyNoteRow,
  ZZZAvatarInfoRow,
  ZZZAvatarComputeRow,
  ZZZBuddyRow,
  ZZZAvatarItem,
  ZZZAvatarListData,
} from '../models/ZZZRows';
import { ZZZApiService } from '../network/ZZZApiService';

export class ZZZRepository extends GameRepository {
  private avatarBasicDao: ZZZAvatarBasicDao = new ZZZAvatarBasicDao();
  private dailyNoteDao: ZZZDailyNoteDao = new ZZZDailyNoteDao();
  private avatarInfoDao: ZZZAvatarInfoDao = new ZZZAvatarInfoDao();
  private avatarComputeDao: ZZZAvatarComputeDao = new ZZZAvatarComputeDao();
  private buddyDao: ZZZBuddyDao = new ZZZBuddyDao();

  // ── 角色基础列表 ──────────────────────────────────────────────

  async getAvatarList(accountId: string, roleUid: string): Promise<ZZZAvatarBasicRow[]> {
    return this.avatarBasicDao.findAll(accountId, roleUid);
  }

  async upsertAvatarList(accountId: string, roleUid: string, rows: ZZZAvatarBasicRow[]): Promise<void> {
    await this.runInTransaction(async () => {
      await this.avatarBasicDao.upsertAll(rows);
      await this.markSuccess(accountId, roleUid, SyncDataType.ZZZ_AVATAR_BASIC);
    });
  }

  async deleteAvatarList(accountId: string, roleUid: string): Promise<void> {
    await this.avatarBasicDao.deleteAll(accountId, roleUid);
  }

  async needsAvatarListSync(accountId: string, roleUid: string): Promise<boolean> {
    return this.needsSync(accountId, roleUid, SyncDataType.ZZZ_AVATAR_BASIC);
  }

  async markAvatarListSyncing(accountId: string, roleUid: string): Promise<void> {
    await this.markSyncing(accountId, roleUid, SyncDataType.ZZZ_AVATAR_BASIC);
  }

  async markAvatarListFailed(accountId: string, roleUid: string, errorMsg: string): Promise<void> {
    await this.markFailed(accountId, roleUid, SyncDataType.ZZZ_AVATAR_BASIC, errorMsg);
  }

  /** 拉取角色列表 → 解析 → 写 DB */
  async syncAvatarList(accountId: string, roleUid: string, server: string, cookie: string): Promise<void> {
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

  async getDailyNote(accountId: string, roleUid: string): Promise<ZZZDailyNoteRow | null> {
    return this.dailyNoteDao.findOne(accountId, roleUid);
  }

  async upsertDailyNote(accountId: string, roleUid: string, row: ZZZDailyNoteRow): Promise<void> {
    await this.runInTransaction(async () => {
      await this.dailyNoteDao.upsert(row);
      await this.markSuccess(accountId, roleUid, SyncDataType.ZZZ_DAILY_NOTE);
    });
  }

  async needsDailyNoteSync(accountId: string, roleUid: string): Promise<boolean> {
    return this.needsSync(accountId, roleUid, SyncDataType.ZZZ_DAILY_NOTE);
  }

  async markDailyNoteSyncing(accountId: string, roleUid: string): Promise<void> {
    await this.markSyncing(accountId, roleUid, SyncDataType.ZZZ_DAILY_NOTE);
  }

  async markDailyNoteFailed(accountId: string, roleUid: string, errorMsg: string): Promise<void> {
    await this.markFailed(accountId, roleUid, SyncDataType.ZZZ_DAILY_NOTE, errorMsg);
  }

  /** 拉取便笺 → 写 DB */
  async syncDailyNote(accountId: string, roleUid: string, server: string, cookie: string): Promise<void> {
    await this.markSyncing(accountId, roleUid, SyncDataType.ZZZ_DAILY_NOTE);
    try {
      const resp = await (this.getService() as ZZZApiService).getDailyNote(roleUid, server, cookie);
      const respData = resp as Record<string, object>;
      const dataObj = respData['data'] !== undefined ? respData['data'] : resp;
      const d = dataObj as Record<string, object>;
      const row = new ZZZDailyNoteRow();
      row.accountId = accountId;
      row.roleUid = roleUid;
      row.rawJson = JSON.stringify(dataObj);
      row.updateTime = Math.floor(Date.now() / 1000);
      // 独立字段：从 API 响应直接读取，不硬编码上限值
      const energy = d['energy'] as Record<string, object> | null;
      if (energy) {
        const progress = energy['progress'] as Record<string, object> | null;
        if (progress) {
          row.energyCurrent = Number(progress['current'] ?? 0);
          row.energyMax = Number(progress['max'] ?? 0);
        }
        row.energyRestore = Number(energy['restore'] ?? 0);
      }
      const vitality = d['vitality'] as Record<string, object> | null;
      if (vitality) {
        row.vitalityCurrent = Number(vitality['current'] ?? 0);
        row.vitalityMax = Number(vitality['max'] ?? 0);
      }
      const vhsSale = d['vhs_sale'] as Record<string, object> | null;
      row.vhsSaleState = vhsSale ? `${vhsSale['sale_state'] ?? ''}` : '';
      row.cardSign = `${d['card_sign'] ?? ''}`;
      await this.upsertDailyNote(accountId, roleUid, row);
    } catch (error) {
      const msg = this.toErrorMessage(error);
      await this.markFailed(accountId, roleUid, SyncDataType.ZZZ_DAILY_NOTE, msg);
      throw new Error(msg);
    }
  }

  // ── 角色详情 ──────────────────────────────────────────────────

  async getAvatarDetail(accountId: string, roleUid: string, avatarId: string): Promise<ZZZAvatarInfoRow | null> {
    return this.avatarInfoDao.findByAvatarId(accountId, roleUid, avatarId);
  }

  async upsertAvatarDetails(accountId: string, roleUid: string, rows: ZZZAvatarInfoRow[]): Promise<void> {
    await this.runInTransaction(async () => {
      await this.avatarInfoDao.upsertAll(rows);
      await this.markSuccess(accountId, roleUid, SyncDataType.ZZZ_AVATAR_INFO);
    });
  }

  async needsAvatarDetailSync(accountId: string, roleUid: string): Promise<boolean> {
    return this.needsSync(accountId, roleUid, SyncDataType.ZZZ_AVATAR_INFO);
  }

  async markAvatarDetailSyncing(accountId: string, roleUid: string): Promise<void> {
    await this.markSyncing(accountId, roleUid, SyncDataType.ZZZ_AVATAR_INFO);
  }

  async markAvatarDetailFailed(accountId: string, roleUid: string, errorMsg: string): Promise<void> {
    await this.markFailed(accountId, roleUid, SyncDataType.ZZZ_AVATAR_INFO, errorMsg);
  }

  /** 拉取代理人详情 → 解析 → 写 DB。avatarId 为空时传空数组（mock 环境一次拿全部） */
  async syncAvatarInfo(accountId: string, roleUid: string, server: string, cookie: string, avatarId?: string): Promise<void> {
    await this.markSyncing(accountId, roleUid, SyncDataType.ZZZ_AVATAR_INFO);
    try {
      const idList = avatarId ? [avatarId] : [];
      const resp = await (this.getService() as ZZZApiService).getAvatarInfo(roleUid, server, idList, cookie);
      const rows = ZZZRepository.parseAvatarInfo(accountId, roleUid, resp);
      await this.upsertAvatarDetails(accountId, roleUid, rows);
    } catch (error) {
      const msg = this.toErrorMessage(error);
      await this.markFailed(accountId, roleUid, SyncDataType.ZZZ_AVATAR_INFO, msg);
      throw new Error(msg);
    }
  }

  static parseAvatarInfo(accountId: string, roleUid: string, resp: object): ZZZAvatarInfoRow[] {
    const result: ZZZAvatarInfoRow[] = [];
    try {
      const respRecord = resp as Record<string, object>;
      const dataObj = respRecord['data'] !== undefined ? respRecord['data'] : resp;
      const data = dataObj as ZZZAvatarListData;
      const list = data.avatar_list;
      if (!list || list.length === 0) { return result; }
      for (let i = 0; i < list.length; i++) {
        const item = list[i];
        const row = new ZZZAvatarInfoRow();
        row.accountId = accountId;
        row.roleUid = roleUid;
        row.avatarId = `${item.id}`;
        row.rawJson = JSON.stringify(item);
        row.updateTime = Math.floor(Date.now() / 1000);
        result[result.length] = row;
      }
    } catch (_) {}
    return result;
  }

  // ── 养成材料计算 ──────────────────────────────────────────────

  async getAvatarCompute(accountId: string, roleUid: string, avatarId: string): Promise<ZZZAvatarComputeRow | null> {
    return this.avatarComputeDao.findByAvatarId(accountId, roleUid, avatarId);
  }

  async upsertAvatarCompute(accountId: string, roleUid: string, row: ZZZAvatarComputeRow): Promise<void> {
    await this.runInTransaction(async () => {
      await this.avatarComputeDao.upsert(row);
      await this.markSuccess(accountId, roleUid, SyncDataType.ZZZ_AVATAR_COMPUTE);
    });
  }

  async needsAvatarComputeSync(accountId: string, roleUid: string): Promise<boolean> {
    return this.needsSync(accountId, roleUid, SyncDataType.ZZZ_AVATAR_COMPUTE);
  }

  async markAvatarComputeSyncing(accountId: string, roleUid: string): Promise<void> {
    await this.markSyncing(accountId, roleUid, SyncDataType.ZZZ_AVATAR_COMPUTE);
  }

  async markAvatarComputeFailed(accountId: string, roleUid: string, errorMsg: string): Promise<void> {
    await this.markFailed(accountId, roleUid, SyncDataType.ZZZ_AVATAR_COMPUTE, errorMsg);
  }

  // ── 解析方法 ─────────────────────────────────────────────────

  static parseAvatarBasic(accountId: string, roleUid: string, resp: object): ZZZAvatarBasicRow[] {
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

  // ── 邦布列表 ──────────────────────────────────────────────────

  async getBuddyList(accountId: string, roleUid: string): Promise<ZZZBuddyRow[]> {
    return this.buddyDao.findAll(accountId, roleUid);
  }

  async upsertBuddyList(accountId: string, roleUid: string, rows: ZZZBuddyRow[]): Promise<void> {
    await this.runInTransaction(async () => {
      await this.buddyDao.upsertAll(rows);
      await this.markSuccess(accountId, roleUid, SyncDataType.ZZZ_BUDDY);
    });
  }

  async deleteBuddyList(accountId: string, roleUid: string): Promise<void> {
    await this.buddyDao.deleteAll(accountId, roleUid);
  }

  async needsBuddyListSync(accountId: string, roleUid: string): Promise<boolean> {
    return this.needsSync(accountId, roleUid, SyncDataType.ZZZ_BUDDY);
  }

  /** 拉取邦布列表 → 解析 → 写 DB */
  async syncBuddyList(accountId: string, roleUid: string, server: string, cookie: string): Promise<void> {
    await this.markSyncing(accountId, roleUid, SyncDataType.ZZZ_BUDDY);
    try {
      const resp = await (this.getService() as ZZZApiService).getBuddyList(roleUid, server, cookie);
      const rows = ZZZRepository.parseBuddyList(accountId, roleUid, resp);
      await this.upsertBuddyList(accountId, roleUid, rows);
    } catch (error) {
      const msg = this.toErrorMessage(error);
      await this.markFailed(accountId, roleUid, SyncDataType.ZZZ_BUDDY, msg);
      throw new Error(msg);
    }
  }

  static parseBuddyList(accountId: string, roleUid: string, resp: object): ZZZBuddyRow[] {
    const result: ZZZBuddyRow[] = [];
    try {
      const respRecord = resp as Record<string, object>;
      const dataObj = respRecord['data'] !== undefined ? respRecord['data'] : resp;
      const data = dataObj as Record<string, object>;
      const list = data['list'] as Record<string, object>[];
      if (!list || list.length === 0) { return result; }
      for (let i = 0; i < list.length; i++) {
        const item = list[i];
        const row = new ZZZBuddyRow();
        row.accountId        = accountId;
        row.roleUid          = roleUid;
        row.buddyId          = `${item['id'] ?? ''}`;
        row.name             = `${item['name'] ?? ''}`;
        row.rarity           = `${item['rarity'] ?? ''}`;
        row.level            = Number(item['level'] ?? 0);
        row.star             = Number(item['star'] ?? 0);
        row.bangbooSquareUrl = `${item['bangboo_square_url'] ?? ''}`;
        row.rawJson          = JSON.stringify(item);
        row.updateTime       = Math.floor(Date.now() / 1000);
        result[result.length] = row;
      }
    } catch (_) {}
    return result;
  }
}