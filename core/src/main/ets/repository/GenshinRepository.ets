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
import { GenshinApiService } from '../network/GenshinApiService';

// ─── 解析用本地 interface ────────────────────────────────────────

interface GenshinWeaponItem {
  id: number;
  name: string;
  level: number;
  affix_level: number;
  rarity: number;
  icon: string;
}

interface GenshinCharacterItem {
  id: number;
  name: string;
  element: string;
  rarity: number;
  level: number;
  fetter: number;
  actived_constellation_num: number;
  image: string;
  is_chosen: boolean;
  icon: string;
  side_icon: string;
  weapon_type: number;
  weapon: GenshinWeaponItem | null;
}

interface GenshinCharacterListData {
  list: GenshinCharacterItem[];
}

export class GenshinRepository extends GameRepository {
  private characterListDao: GenshinCharacterListDao = new GenshinCharacterListDao();
  private dailyNoteDao: GenshinDailyNoteDao = new GenshinDailyNoteDao();
  private characterDetailDao: GenshinCharacterDetailDao = new GenshinCharacterDetailDao();
  private characterComputeDao: GenshinCharacterComputeDao = new GenshinCharacterComputeDao();

  // ── 角色列表 ──────────────────────────────────────────────────

  async getAvatarList(accountId: string, roleUid: string): Promise<GenshinCharacterListRow[]> {
    return this.characterListDao.findAll(accountId, roleUid);
  }

  async upsertAvatarList(accountId: string, roleUid: string, rows: GenshinCharacterListRow[]): Promise<void> {
    await this.runInTransaction(async () => {
      await this.characterListDao.upsertAll(rows);
      await this.markSuccess(accountId, roleUid, SyncDataType.GENSHIN_CHARACTER_LIST);
    });
  }

  async deleteAvatarList(accountId: string, roleUid: string): Promise<void> {
    await this.characterListDao.deleteAll(accountId, roleUid);
  }

  async needsAvatarListSync(accountId: string, roleUid: string): Promise<boolean> {
    return this.needsSync(accountId, roleUid, SyncDataType.GENSHIN_CHARACTER_LIST);
  }

  async markAvatarListSyncing(accountId: string, roleUid: string): Promise<void> {
    await this.markSyncing(accountId, roleUid, SyncDataType.GENSHIN_CHARACTER_LIST);
  }

  async markAvatarListFailed(accountId: string, roleUid: string, errorMsg: string): Promise<void> {
    await this.markFailed(accountId, roleUid, SyncDataType.GENSHIN_CHARACTER_LIST, errorMsg);
  }

  /**
   * 拉取角色列表 → 解析 → 写 DB（entry 层只需调用此方法）
   */
  async syncAvatarList(accountId: string, roleUid: string, server: string, cookie: string): Promise<void> {
    await this.markSyncing(accountId, roleUid, SyncDataType.GENSHIN_CHARACTER_LIST);
    try {
      const resp = await (this.getService() as GenshinApiService).getCharacterList(roleUid, server, cookie);
      const rows = GenshinRepository.parseCharacterList(accountId, roleUid, resp);
      await this.upsertAvatarList(accountId, roleUid, rows);
    } catch (error) {
      const msg = this.toErrorMessage(error);
      await this.markFailed(accountId, roleUid, SyncDataType.GENSHIN_CHARACTER_LIST, msg);
      throw new Error(msg);
    }
  }

  // ── 实时便笺 ──────────────────────────────────────────────────

  async getDailyNote(accountId: string, roleUid: string): Promise<GenshinDailyNoteRow | null> {
    return this.dailyNoteDao.findOne(accountId, roleUid);
  }

  async upsertDailyNote(accountId: string, roleUid: string, row: GenshinDailyNoteRow): Promise<void> {
    await this.runInTransaction(async () => {
      await this.dailyNoteDao.upsert(row);
      await this.markSuccess(accountId, roleUid, SyncDataType.GENSHIN_DAILY_NOTE);
    });
  }

  async needsDailyNoteSync(accountId: string, roleUid: string): Promise<boolean> {
    return this.needsSync(accountId, roleUid, SyncDataType.GENSHIN_DAILY_NOTE);
  }

  async markDailyNoteSyncing(accountId: string, roleUid: string): Promise<void> {
    await this.markSyncing(accountId, roleUid, SyncDataType.GENSHIN_DAILY_NOTE);
  }

  async markDailyNoteFailed(accountId: string, roleUid: string, errorMsg: string): Promise<void> {
    await this.markFailed(accountId, roleUid, SyncDataType.GENSHIN_DAILY_NOTE, errorMsg);
  }

  /**
   * 拉取便笺 → 写 DB（entry 层只需调用此方法）
   */
  async syncDailyNote(accountId: string, roleUid: string, server: string, cookie: string): Promise<void> {
    await this.markSyncing(accountId, roleUid, SyncDataType.GENSHIN_DAILY_NOTE);
    try {
      const resp = await (this.getService() as GenshinApiService).getDailyNote(roleUid, server, cookie);
      const respData = resp as Record<string, object>;
      const dataObj = respData['data'] !== undefined ? respData['data'] : resp;
      const d = dataObj as Record<string, object>;
      const row = new GenshinDailyNoteRow();
      row.accountId = accountId;
      row.roleUid = roleUid;
      row.rawJson = JSON.stringify(dataObj);
      row.updateTime = Math.floor(Date.now() / 1000);
      // 独立字段：从 API 响应直接读取，不硬编码上限值
      row.currentResin = Number(d['current_resin'] ?? 0);
      row.maxResin = Number(d['max_resin'] ?? 0);
      row.resinRecoveryTime = parseInt(`${d['resin_recovery_time'] ?? '0'}`) || 0;
      row.finishedTaskNum = Number(d['finished_task_num'] ?? 0);
      row.totalTaskNum = Number(d['total_task_num'] ?? 0);
      row.remainResinDiscountNum = Number(d['remain_resin_discount_num'] ?? 0);
      row.currentExpeditionNum = Number(d['current_expedition_num'] ?? 0);
      row.maxExpeditionNum = Number(d['max_expedition_num'] ?? 0);
      row.currentHomeCoin = Number(d['current_home_coin'] ?? 0);
      row.maxHomeCoin = Number(d['max_home_coin'] ?? 0);
      const transformer = d['transformer'] as Record<string, object> | null;
      if (transformer) {
        const rt = transformer['recovery_time'] as Record<string, object> | null;
        row.transformerRecoveryDay = rt ? Number(rt['Day'] ?? 0) : 0;
      }
      await this.upsertDailyNote(accountId, roleUid, row);
    } catch (error) {
      const msg = this.toErrorMessage(error);
      await this.markFailed(accountId, roleUid, SyncDataType.GENSHIN_DAILY_NOTE, msg);
      throw new Error(msg);
    }
  }

  // ── 角色详情 ──────────────────────────────────────────────────

  async getAvatarDetail(accountId: string, roleUid: string, avatarId: string): Promise<GenshinCharacterDetailRow | null> {
    return this.characterDetailDao.findByAvatarId(accountId, roleUid, avatarId);
  }

  async upsertAvatarDetails(accountId: string, roleUid: string, rows: GenshinCharacterDetailRow[]): Promise<void> {
    await this.runInTransaction(async () => {
      await this.characterDetailDao.upsertAll(rows);
      await this.markSuccess(accountId, roleUid, SyncDataType.GENSHIN_CHARACTER_DETAIL);
    });
  }

  async needsAvatarDetailSync(accountId: string, roleUid: string): Promise<boolean> {
    return this.needsSync(accountId, roleUid, SyncDataType.GENSHIN_CHARACTER_DETAIL);
  }

  async markAvatarDetailSyncing(accountId: string, roleUid: string): Promise<void> {
    await this.markSyncing(accountId, roleUid, SyncDataType.GENSHIN_CHARACTER_DETAIL);
  }

  async markAvatarDetailFailed(accountId: string, roleUid: string, errorMsg: string): Promise<void> {
    await this.markFailed(accountId, roleUid, SyncDataType.GENSHIN_CHARACTER_DETAIL, errorMsg);
  }

  /** 拉取角色详情（批量，传空数组拉取全部）→ 解析 → 写 DB */
  async syncAvatarDetail(accountId: string, roleUid: string, server: string, cookie: string): Promise<void> {
    await this.markSyncing(accountId, roleUid, SyncDataType.GENSHIN_CHARACTER_DETAIL);
    try {
      const resp = await (this.getService() as GenshinApiService).getCharacterDetail(roleUid, server, [], cookie);
      const rows = GenshinRepository.parseCharacterDetail(accountId, roleUid, resp);
      await this.upsertAvatarDetails(accountId, roleUid, rows);
    } catch (error) {
      const msg = this.toErrorMessage(error);
      await this.markFailed(accountId, roleUid, SyncDataType.GENSHIN_CHARACTER_DETAIL, msg);
      throw new Error(msg);
    }
  }

  static parseCharacterDetail(accountId: string, roleUid: string, resp: object): GenshinCharacterDetailRow[] {
    const result: GenshinCharacterDetailRow[] = [];
    try {
      const respRecord = resp as Record<string, object>;
      const dataObj = respRecord['data'] !== undefined ? respRecord['data'] : resp;
      const data = dataObj as Record<string, object>;
      const list = data['list'] as Record<string, object>[];
      if (!list || list.length === 0) { return result; }
      for (let i = 0; i < list.length; i++) {
        const item = list[i];
        const base = item['base'] as Record<string, object>;
        if (!base) { continue; }

        const row = new GenshinCharacterDetailRow();
        row.accountId = accountId;
        row.roleUid = roleUid;
        row.avatarId = `${base['id']}`;
        row.rawJson = JSON.stringify(item);
        row.updateTime = Math.floor(Date.now() / 1000);

        // 提取武器 id（用于快速查询索引）
        const weapon = item['weapon'] as Record<string, object> | null;
        if (weapon) {
          row.weaponId = `${weapon['id'] ?? ''}`;
          row.weaponLevel = Number(weapon['level'] ?? 0);
          row.weaponAffixLevel = Number(weapon['affix_level'] ?? 0);
        }

        // 提取圣遗物 id 列表（逗号分隔）
        const relics = item['relics'] as Record<string, object>[];
        if (relics && relics.length > 0) {
          const ids: string[] = [];
          for (let j = 0; j < relics.length; j++) {
            ids[ids.length] = `${relics[j]['id'] ?? ''}`;
          }
          row.relicIds = ids.join(',');
        }

        // 提取技能等级列表（逗号分隔）
        const skills = item['skills'] as Record<string, object>[];
        if (skills && skills.length > 0) {
          const levels: string[] = [];
          for (let j = 0; j < skills.length; j++) {
            levels[levels.length] = `${skills[j]['level_current'] ?? skills[j]['level'] ?? 0}`;
          }
          row.skillLevels = levels.join(',');
        }

        result[result.length] = row;
      }
    } catch (_) {}
    return result;
  }

  // ── 养成材料计算 ──────────────────────────────────────────────

  async getAvatarCompute(accountId: string, roleUid: string, avatarId: string): Promise<GenshinCharacterComputeRow | null> {
    return this.characterComputeDao.findByAvatarId(accountId, roleUid, avatarId);
  }

  async upsertAvatarCompute(accountId: string, roleUid: string, row: GenshinCharacterComputeRow): Promise<void> {
    await this.runInTransaction(async () => {
      await this.characterComputeDao.upsert(row);
      await this.markSuccess(accountId, roleUid, SyncDataType.GENSHIN_CHARACTER_COMPUTE);
    });
  }

  // ── 解析方法 ─────────────────────────────────────────────────

  static parseCharacterList(accountId: string, roleUid: string, resp: object): GenshinCharacterListRow[] {
    const result: GenshinCharacterListRow[] = [];
    try {
      const respRecord = resp as Record<string, object>;
      const dataObj = respRecord['data'] !== undefined ? respRecord['data'] : resp;
      const data = dataObj as GenshinCharacterListData;
      const list = data.list;
      if (!list || list.length === 0) { return result; }
      for (let i = 0; i < list.length; i++) {
        const item = list[i];
        const weapon = item.weapon;
        const row = new GenshinCharacterListRow();
        row.accountId = accountId;
        row.roleUid = roleUid;
        row.avatarId = `${item.id}`;
        row.name = item.name;
        row.element = item.element;
        row.rarity = item.rarity;
        row.level = item.level;
        row.fetter = item.fetter;
        row.activedConstellationNum = item.actived_constellation_num;
        row.image = item.image ?? '';
        row.isChosen = item.is_chosen ? 1 : 0;
        row.icon = item.icon;
        row.sideIcon = item.side_icon;
        row.weaponType = item.weapon_type;
        row.weaponId = weapon ? `${weapon.id}` : '';
        row.weaponName = weapon ? weapon.name : '';
        row.weaponLevel = weapon ? weapon.level : 0;
        row.weaponAffixLevel = weapon ? weapon.affix_level : 0;
        row.weaponRarity = weapon ? weapon.rarity : 0;
        row.weaponIconUrl = weapon ? weapon.icon : '';
        row.rawJson = JSON.stringify(item);
        row.updateTime = Math.floor(Date.now() / 1000);
        result[result.length] = row;
      }
    } catch (_) {}
    return result;
  }
}
