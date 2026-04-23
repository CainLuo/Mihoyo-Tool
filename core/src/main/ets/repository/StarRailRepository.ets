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
  StarRailAvatarComputeRow,
  StarRailEquipItem,
  StarRailAvatarItem,
  StarRailAvatarListData,
} from '../models/StarRailRows';
import { StarRailApiService } from '../network/StarRailApiService';
import { AuthExpiredError } from '../errors/ApiErrors';
import { CookieRefreshCoordinator } from '../cookie/CookieRefreshCoordinator';
import { CoreInitializer } from '../CoreInitializer';
import { BBSRepository } from './BBSRepository';

export class StarRailRepository extends GameRepository {
  private avatarBasicDao: StarRailAvatarBasicDao = new StarRailAvatarBasicDao();
  private dailyNoteDao: StarRailDailyNoteDao = new StarRailDailyNoteDao();
  private avatarInfoDao: StarRailAvatarInfoDao = new StarRailAvatarInfoDao();
  private avatarComputeDao: StarRailAvatarComputeDao = new StarRailAvatarComputeDao();

  // ── 角色基础列表 ──────────────────────────────────────────────

  async getAvatarList(accountId: string, roleUid: string): Promise<StarRailAvatarBasicRow[]> {
    return this.avatarBasicDao.findAll(accountId, roleUid);
  }

  async upsertAvatarList(accountId: string, roleUid: string, rows: StarRailAvatarBasicRow[]): Promise<void> {
    await this.runInTransaction(async () => {
      await this.avatarBasicDao.upsertAll(rows);
      await this.markSuccess(accountId, roleUid, SyncDataType.STARRAIL_AVATAR_BASIC);
    });
  }

  async deleteAvatarList(accountId: string, roleUid: string): Promise<void> {
    await this.avatarBasicDao.deleteAll(accountId, roleUid);
  }

  async needsAvatarListSync(accountId: string, roleUid: string): Promise<boolean> {
    return this.needsSync(accountId, roleUid, SyncDataType.STARRAIL_AVATAR_BASIC);
  }

  async markAvatarListSyncing(accountId: string, roleUid: string): Promise<void> {
    await this.markSyncing(accountId, roleUid, SyncDataType.STARRAIL_AVATAR_BASIC);
  }

  async markAvatarListFailed(accountId: string, roleUid: string, errorMsg: string): Promise<void> {
    await this.markFailed(accountId, roleUid, SyncDataType.STARRAIL_AVATAR_BASIC, errorMsg);
  }

  /** 拉取角色列表 → 解析 → 写 DB */
  async syncAvatarList(accountId: string, roleUid: string, server: string, cookie: string): Promise<void> {
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

  async getDailyNote(accountId: string, roleUid: string): Promise<StarRailDailyNoteRow | null> {
    return this.dailyNoteDao.findOne(accountId, roleUid);
  }

  async upsertDailyNote(accountId: string, roleUid: string, row: StarRailDailyNoteRow): Promise<void> {
    await this.runInTransaction(async () => {
      await this.dailyNoteDao.upsert(row);
      await this.markSuccess(accountId, roleUid, SyncDataType.STARRAIL_DAILY_NOTE);
    });
  }

  async needsDailyNoteSync(accountId: string, roleUid: string): Promise<boolean> {
    return this.needsSync(accountId, roleUid, SyncDataType.STARRAIL_DAILY_NOTE);
  }

  async getDailyNoteLastSyncTime(accountId: string, roleUid: string): Promise<number> {
    return this.getLastSyncTime(accountId, roleUid, SyncDataType.STARRAIL_DAILY_NOTE);
  }

  async markDailyNoteSyncing(accountId: string, roleUid: string): Promise<void> {
    await this.markSyncing(accountId, roleUid, SyncDataType.STARRAIL_DAILY_NOTE);
  }

  async markDailyNoteFailed(accountId: string, roleUid: string, errorMsg: string): Promise<void> {
    await this.markFailed(accountId, roleUid, SyncDataType.STARRAIL_DAILY_NOTE, errorMsg);
  }

  /** 拉取便笺 → 写 DB */
  async syncDailyNote(accountId: string, roleUid: string, server: string, cookie: string, geetestChallenge?: string): Promise<void> {
    await this.markSyncing(accountId, roleUid, SyncDataType.STARRAIL_DAILY_NOTE);
    try {
      await this.doSyncDailyNote(accountId, roleUid, server, cookie, geetestChallenge);
    } catch (error) {
      if (error instanceof AuthExpiredError) {
        try {
          const newCookie = await CookieRefreshCoordinator.instance.refreshWithLock(
            accountId,
            cookie,
            CoreInitializer.bbsRepository,
          );
          await this.doSyncDailyNote(accountId, roleUid, server, newCookie);
          return;
        } catch (refreshError) {
          const msg = this.toErrorMessage(refreshError);
          await this.markFailed(accountId, roleUid, SyncDataType.STARRAIL_DAILY_NOTE, msg);
          if (refreshError instanceof AuthExpiredError) {
            throw refreshError;
          }
          throw new AuthExpiredError(msg);
        }
      }
      const msg = this.toErrorMessage(error);
      await this.markFailed(accountId, roleUid, SyncDataType.STARRAIL_DAILY_NOTE, msg);
      throw new Error(msg);
    }
  }

  private async doSyncDailyNote(accountId: string, roleUid: string, server: string, cookie: string, geetestChallenge?: string): Promise<void> {
    const resp = await (this.getService() as StarRailApiService).getDailyNote(roleUid, server, cookie, geetestChallenge);
    const respData = resp as Record<string, object>;
    const retcodeStr = `${respData['retcode'] ?? ''}`;
    if (retcodeStr === '-100' || retcodeStr === '10001' || retcodeStr === '-10001') {
      throw new AuthExpiredError(`retcode=${retcodeStr}`);
    }
    if (retcodeStr === '1034' || retcodeStr === '10035') {
      // 1034/10035：尝试降级到 Widget API（无 Geetest 验证）
      const widgetCookie = BBSRepository.buildWidgetCookie(cookie);
      if (widgetCookie.length > 0) {
        await this.doSyncDailyNoteWidget(accountId, roleUid, widgetCookie);
        // Widget 降级成功，标记为 success
        await this.markSuccess(accountId, roleUid, SyncDataType.STARRAIL_DAILY_NOTE);
        return;
      }
      throw new Error(`retcode=${retcodeStr}: Geetest verification required and no widget cookie available`);
    }
    if (respData['data'] === null || respData['data'] === undefined) {
      throw new Error(`retcode=${retcodeStr}: ${respData['message'] ?? 'no data'}`);
    }
    const dataObj = respData['data'] !== undefined ? respData['data'] : resp;
    const row = this.parseStarRailDailyNoteData(accountId, roleUid, dataObj);
    await this.upsertDailyNote(accountId, roleUid, row);
  }

  /**
   * Widget API 降级同步便笺（星铁 /aapi/widget）
   * Widget 返回字段是普通便笺的子集，只更新有对应字段的数据
   */
  private async doSyncDailyNoteWidget(accountId: string, roleUid: string, widgetCookie: string): Promise<void> {
    const resp = await (this.getService() as StarRailApiService).getDailyNoteWidget(widgetCookie);
    const respData = resp as Record<string, object>;
    const retcodeStr = `${respData['retcode'] ?? ''}`;
    if (retcodeStr !== '0' && retcodeStr !== '') {
      throw new Error(`Widget API failed: retcode=${retcodeStr}: ${respData['message'] ?? 'no data'}`);
    }
    if (respData['data'] === null || respData['data'] === undefined) {
      throw new Error(`Widget API: no data`);
    }
    const dataObj = respData['data'] !== undefined ? respData['data'] : resp;
    const row = this.parseStarRailDailyNoteData(accountId, roleUid, dataObj);
    await this.upsertDailyNote(accountId, roleUid, row);
  }

  private parseStarRailDailyNoteData(accountId: string, roleUid: string, dataObj: object): StarRailDailyNoteRow {
    const d = dataObj as Record<string, object>;
    const row = new StarRailDailyNoteRow();
    row.accountId = accountId;
    row.roleUid = roleUid;
    row.rawJson = JSON.stringify(dataObj);
    row.updateTime = Math.floor(Date.now() / 1000);
    row.currentStamina = Number(d['current_stamina'] ?? 0);
    row.maxStamina = Number(d['max_stamina'] ?? 0);
    row.staminaRecoverTime = Number(d['stamina_recover_time'] ?? 0);
    row.staminaFullTs = Number(d['stamina_full_ts'] ?? 0);
    row.currentReserveStamina = Number(d['current_reserve_stamina'] ?? 0);
    row.acceptedExpeditionNum = Number(d['accepted_epedition_num'] ?? 0);
    row.totalExpeditionNum = Number(d['total_expedition_num'] ?? 0);
    row.currentTrainScore = Number(d['current_train_score'] ?? 0);
    row.maxTrainScore = Number(d['max_train_score'] ?? 0);
    row.currentRogueScore = Number(d['current_rogue_score'] ?? 0);
    row.maxRogueScore = Number(d['max_rogue_score'] ?? 0);
    row.weeklyCocoonCnt = Number(d['weekly_cocoon_cnt'] ?? 0);
    row.weeklyCocoonLimit = Number(d['weekly_cocoon_limit'] ?? 0);
    row.rogueTournWeeklyCur = Number(d['rogue_tourn_weekly_cur'] ?? 0);
    row.rogueTournWeeklyMax = Number(d['rogue_tourn_weekly_max'] ?? 0);
    row.gridFightWeeklyCur = Number(d['grid_fight_weekly_cur'] ?? 0);
    row.gridFightWeeklyMax = Number(d['grid_fight_weekly_max'] ?? 0);
    return row;
  }

  // ── 角色详情 ──────────────────────────────────────────────────

  async getAvatarDetail(accountId: string, roleUid: string, avatarId: string): Promise<StarRailAvatarInfoRow | null> {
    return this.avatarInfoDao.findByAvatarId(accountId, roleUid, avatarId);
  }

  async upsertAvatarDetails(accountId: string, roleUid: string, rows: StarRailAvatarInfoRow[]): Promise<void> {
    await this.runInTransaction(async () => {
      await this.avatarInfoDao.upsertAll(rows);
      await this.markSuccess(accountId, roleUid, SyncDataType.STARRAIL_AVATAR_INFO);
    });
  }

  async needsAvatarDetailSync(accountId: string, roleUid: string): Promise<boolean> {
    return this.needsSync(accountId, roleUid, SyncDataType.STARRAIL_AVATAR_INFO);
  }

  async markAvatarDetailSyncing(accountId: string, roleUid: string): Promise<void> {
    await this.markSyncing(accountId, roleUid, SyncDataType.STARRAIL_AVATAR_INFO);
  }

  async markAvatarDetailFailed(accountId: string, roleUid: string, errorMsg: string): Promise<void> {
    await this.markFailed(accountId, roleUid, SyncDataType.STARRAIL_AVATAR_INFO, errorMsg);
  }

  /** 拉取角色详情列表 → 解析 → 写 DB（批量，使用 id=0 拉取全部） */
  async syncAvatarInfo(accountId: string, roleUid: string, server: string, cookie: string): Promise<void> {
    await this.markSyncing(accountId, roleUid, SyncDataType.STARRAIL_AVATAR_INFO);
    try {
      const resp = await (this.getService() as StarRailApiService).getAvatarInfo(roleUid, server, '0', cookie);
      const rows = StarRailRepository.parseAvatarInfo(accountId, roleUid, resp);
      await this.upsertAvatarDetails(accountId, roleUid, rows);
    } catch (error) {
      const msg = this.toErrorMessage(error);
      await this.markFailed(accountId, roleUid, SyncDataType.STARRAIL_AVATAR_INFO, msg);
      throw new Error(msg);
    }
  }

  static parseAvatarInfo(accountId: string, roleUid: string, resp: object): StarRailAvatarInfoRow[] {
    const result: StarRailAvatarInfoRow[] = [];
    try {
      const respRecord = resp as Record<string, object>;
      const dataObj = respRecord['data'] !== undefined ? respRecord['data'] : resp;
      const data = dataObj as StarRailAvatarListData;
      const list = data.avatar_list !== undefined ? data.avatar_list : data.list;
      if (!list || list.length === 0) { return result; }
      for (let i = 0; i < list.length; i++) {
        const item = list[i];
        const row = new StarRailAvatarInfoRow();
        row.accountId = accountId;
        row.roleUid = roleUid;
        row.avatarId = `${item.id}`;
        row.equipId = item.equip ? `${item.equip.id}` : '';
        row.equipLevel = item.equip ? item.equip.level : 0;
        row.equipRank = item.equip ? item.equip.rank : 0;
        row.rawJson = JSON.stringify(item);
        row.updateTime = Math.floor(Date.now() / 1000);
        result[result.length] = row;
      }
    } catch (_) {}
    return result;
  }

  // ── 养成材料计算 ──────────────────────────────────────────────

  async getAvatarCompute(accountId: string, roleUid: string, avatarId: string): Promise<StarRailAvatarComputeRow | null> {
    return this.avatarComputeDao.findByAvatarId(accountId, roleUid, avatarId);
  }

  async upsertAvatarCompute(accountId: string, roleUid: string, row: StarRailAvatarComputeRow): Promise<void> {
    await this.runInTransaction(async () => {
      await this.avatarComputeDao.upsert(row);
      await this.markSuccess(accountId, roleUid, SyncDataType.STARRAIL_AVATAR_COMPUTE);
    });
  }

  async needsAvatarComputeSync(accountId: string, roleUid: string): Promise<boolean> {
    return this.needsSync(accountId, roleUid, SyncDataType.STARRAIL_AVATAR_COMPUTE);
  }

  async markAvatarComputeSyncing(accountId: string, roleUid: string): Promise<void> {
    await this.markSyncing(accountId, roleUid, SyncDataType.STARRAIL_AVATAR_COMPUTE);
  }

  async markAvatarComputeFailed(accountId: string, roleUid: string, errorMsg: string): Promise<void> {
    await this.markFailed(accountId, roleUid, SyncDataType.STARRAIL_AVATAR_COMPUTE, errorMsg);
  }

  // ── 解析方法 ─────────────────────────────────────────────────

  static parseAvatarBasic(accountId: string, roleUid: string, resp: object): StarRailAvatarBasicRow[] {
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
