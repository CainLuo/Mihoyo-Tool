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
import { AuthExpiredError } from '../errors/ApiErrors';
import { CookieRefreshCoordinator } from '../cookie/CookieRefreshCoordinator';
import { CoreInitializer } from '../CoreInitializer';
import { BBSRepository } from './BBSRepository';
import { MaterialBagRepository } from './MaterialBagRepository';
import { MaterialBagRow } from '../models/MaterialBagRow';
import { ZZZComputeParser, ZZZMaterialItem } from '../parsers/zzz/ZZZComputeParser';
import { GameId } from '../constants/GameId';
import { Logger } from '../utils/Logger';
import { ApiErrorHandler } from '../utils/ApiErrorHandler';

export class ZZZRepository extends GameRepository {
  private avatarBasicDao: ZZZAvatarBasicDao = new ZZZAvatarBasicDao();
  private dailyNoteDao: ZZZDailyNoteDao = new ZZZDailyNoteDao();
  private avatarInfoDao: ZZZAvatarInfoDao = new ZZZAvatarInfoDao();
  private avatarComputeDao: ZZZAvatarComputeDao = new ZZZAvatarComputeDao();
  private buddyDao: ZZZBuddyDao = new ZZZBuddyDao();
  private materialBagRepo: MaterialBagRepository = new MaterialBagRepository();

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
      ApiErrorHandler.checkResponse(resp);
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

  async getDailyNoteLastSyncTime(accountId: string, roleUid: string): Promise<number> {
    return this.getLastSyncTime(accountId, roleUid, SyncDataType.ZZZ_DAILY_NOTE);
  }

  async markDailyNoteSyncing(accountId: string, roleUid: string): Promise<void> {
    await this.markSyncing(accountId, roleUid, SyncDataType.ZZZ_DAILY_NOTE);
  }

  async markDailyNoteFailed(accountId: string, roleUid: string, errorMsg: string): Promise<void> {
    await this.markFailed(accountId, roleUid, SyncDataType.ZZZ_DAILY_NOTE, errorMsg);
  }

  /** 拉取便笺 → 写 DB */
  async syncDailyNote(accountId: string, roleUid: string, server: string, cookie: string, geetestChallenge?: string): Promise<void> {
    await this.markSyncing(accountId, roleUid, SyncDataType.ZZZ_DAILY_NOTE);
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
          await this.markFailed(accountId, roleUid, SyncDataType.ZZZ_DAILY_NOTE, msg);
          if (refreshError instanceof AuthExpiredError) {
            throw refreshError;
          }
          throw new AuthExpiredError(msg);
        }
      }
      const msg = this.toErrorMessage(error);
      await this.markFailed(accountId, roleUid, SyncDataType.ZZZ_DAILY_NOTE, msg);
      throw new Error(msg);
    }
  }

  private async doSyncDailyNote(accountId: string, roleUid: string, server: string, cookie: string, geetestChallenge?: string): Promise<void> {
    const resp = await (this.getService() as ZZZApiService).getDailyNote(roleUid, server, cookie, geetestChallenge);
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
        await this.markSuccess(accountId, roleUid, SyncDataType.ZZZ_DAILY_NOTE);
        return;
      }
      throw new Error(`retcode=${retcodeStr}: Geetest verification required and no widget cookie available`);
    }
    if (respData['data'] === null || respData['data'] === undefined) {
      throw new Error(`retcode=${retcodeStr}: ${respData['message'] ?? 'no data'}`);
    }
    const dataObj = respData['data'] !== undefined ? respData['data'] : resp;
    // Note API 数据存储到 rawJson
    const row = this.parseZZZDailyNoteData(accountId, roleUid, dataObj, false);
    await this.upsertDailyNote(accountId, roleUid, row);
  }

  /**
   * Widget API 同步便笺（绝区零 /api/zzz/widget）
   * 
   * 特点：
   * - 无风控，可高频调用
   * - 含 note_list 字段（预格式化的额外信息）
   * - 只更新 widgetRawJson 和基础字段，不影响 rawJson
   */
  async syncDailyNoteWidget(accountId: string, roleUid: string, widgetCookie: string): Promise<void> {
    await this.markSyncing(accountId, roleUid, SyncDataType.ZZZ_DAILY_NOTE);
    try {
      await this.doSyncDailyNoteWidget(accountId, roleUid, widgetCookie);
      await this.markSuccess(accountId, roleUid, SyncDataType.ZZZ_DAILY_NOTE);
    } catch (error) {
      const msg = this.toErrorMessage(error);
      await this.markFailed(accountId, roleUid, SyncDataType.ZZZ_DAILY_NOTE, msg);
      throw new Error(msg);
    }
  }

  /**
   * Widget API 内部同步逻辑（降级和公开方法共用）
   * Widget 返回字段是普通便笺的子集，只更新有对应字段的数据
   */
  private async doSyncDailyNoteWidget(accountId: string, roleUid: string, widgetCookie: string): Promise<void> {
    const resp = await (this.getService() as ZZZApiService).getDailyNoteWidget(widgetCookie);
    const respData = resp as Record<string, object>;
    const retcodeStr = `${respData['retcode'] ?? ''}`;
    if (retcodeStr !== '0' && retcodeStr !== '') {
      throw new Error(`Widget API failed: retcode=${retcodeStr}: ${respData['message'] ?? 'no data'}`);
    }
    if (respData['data'] === null || respData['data'] === undefined) {
      throw new Error(`Widget API: no data`);
    }
    const dataObj = respData['data'] !== undefined ? respData['data'] : resp;
    // Widget API 数据存储到 widgetRawJson
    const row = this.parseZZZDailyNoteData(accountId, roleUid, dataObj, true);
    await this.upsertDailyNote(accountId, roleUid, row);
  }

  private parseZZZDailyNoteData(accountId: string, roleUid: string, dataObj: object, isWidget: boolean = false): ZZZDailyNoteRow {
    const d = dataObj as Record<string, object>;
    const row = new ZZZDailyNoteRow();
    row.accountId = accountId;
    row.roleUid = roleUid;
    // isWidget=true 时存储到 widgetRawJson，否则存储到 rawJson
    if (isWidget) {
      row.widgetRawJson = JSON.stringify(dataObj);
    } else {
      row.rawJson = JSON.stringify(dataObj);
    }
    row.updateTime = Math.floor(Date.now() / 1000);
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
    return row;
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
      ApiErrorHandler.checkResponse(resp);
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

  /**
   * 拉取单角色养成计算 → 解析 → 写 DB
   * 同时写入材料背包数据（从 user_owns_materials）
   * @param avatarId 角色 ID
   * @param avatarLevel 目标等级
   * @param avatarCurrentLevel 当前等级
   * @param avatarCurrentPromotes 当前突破阶段
   * @param skills 技能参数数组
   * @param uid 游戏 UID
   * @param region 服务器（如 'prod_gf_cn'）
   * @param cookie 登录 Cookie
   */
  async syncAvatarCompute(
    accountId: string,
    roleUid: string,
    avatarId: string,
    avatarLevel: number,
    avatarCurrentLevel: number,
    avatarCurrentPromotes: number,
    skills: object[],
    uid: string,
    region: string,
    cookie: string
  ): Promise<ZZZAvatarComputeRow> {
    await this.markSyncing(accountId, roleUid, SyncDataType.ZZZ_AVATAR_COMPUTE);
    try {
      const resp = await (this.getService() as ZZZApiService).compute(
        avatarId, avatarLevel, avatarCurrentLevel, avatarCurrentPromotes, skills, uid, region, cookie
      );
      ApiErrorHandler.checkResponse(resp);
      const row = ZZZRepository.parseComputeResult(accountId, roleUid, avatarId, resp);

      // 解析材料背包数据
      const dataObj = (resp as Record<string, object>)['data'] ?? resp;
      const rawJson = JSON.stringify(dataObj);
      const computeData = ZZZComputeParser.parse(rawJson);

      // 合并 consume 数据中的材料信息
      const materialRows = this.buildMaterialRows(
        accountId,
        roleUid,
        computeData.avatarConsume,
        computeData.skillConsume,
        computeData.weaponConsume,
        computeData.userOwnsMaterials
      );

      await this.runInTransaction(async () => {
        await this.avatarComputeDao.upsert(row);
        // 写入材料背包
        if (materialRows.length > 0) {
          await this.materialBagRepo.upsertMaterials(accountId, roleUid, materialRows, GameId.ZZZ);
        }
        await this.markSuccess(accountId, roleUid, SyncDataType.ZZZ_AVATAR_COMPUTE);
      });
      return row;
    } catch (error) {
      const msg = this.toErrorMessage(error);
      await this.markFailed(accountId, roleUid, SyncDataType.ZZZ_AVATAR_COMPUTE, msg);
      throw new Error(msg);
    }
  }

  /**
   * 从 consume 数据和 userOwnsMaterials 构建材料背包行
   */
  private buildMaterialRows(
    accountId: string,
    roleUid: string,
    avatarConsume: ZZZMaterialItem[],
    skillConsume: ZZZMaterialItem[],
    weaponConsume: ZZZMaterialItem[],
    userOwnsMaterials: Map<string, number>
  ): MaterialBagRow[] {
    const rows: MaterialBagRow[] = [];
    const materialInfoMap = new Map<string, ZZZMaterialItem>();

    // 收集所有材料信息（去重）
    for (let i = 0; i < avatarConsume.length; i++) {
      const item = avatarConsume[i];
      if (!materialInfoMap.has(item.id)) {
        materialInfoMap.set(item.id, item);
      }
    }
    for (let i = 0; i < skillConsume.length; i++) {
      const item = skillConsume[i];
      if (!materialInfoMap.has(item.id)) {
        materialInfoMap.set(item.id, item);
      }
    }
    for (let i = 0; i < weaponConsume.length; i++) {
      const item = weaponConsume[i];
      if (!materialInfoMap.has(item.id)) {
        materialInfoMap.set(item.id, item);
      }
    }

    // 从 userOwnsMaterials 构建背包数据
    const materialIds = Array.from(userOwnsMaterials.keys());
    for (let i = 0; i < materialIds.length; i++) {
      const materialId = materialIds[i];
      const count = userOwnsMaterials.get(materialId) ?? 0;
      const info = materialInfoMap.get(materialId);

      const row = new MaterialBagRow();
      row.accountId = accountId;
      row.roleUid = roleUid;
      row.materialId = materialId;
      row.count = count;
      row.source = 'api';
      row.updateTime = Math.floor(Date.now() / 1000);

      // 如果有材料详情，填充名称/图标/稀有度
      if (info) {
        row.materialName = info.name;
        row.materialIcon = info.iconUrl;
        row.rarity = info.rarity;
      } else {
        // 没有详情时，用 ID 作为名称兜底
        row.materialName = materialId;
        row.materialIcon = '';
        row.rarity = '';
      }

      rows.push(row);
    }

    return rows;
  }

  /**
   * 解析单角色计算 API 响应为 ZZZAvatarComputeRow
   */
  static parseComputeResult(accountId: string, roleUid: string, avatarId: string, resp: object): ZZZAvatarComputeRow {
    const row = new ZZZAvatarComputeRow();
    row.accountId = accountId;
    row.roleUid = roleUid;
    row.avatarId = avatarId;
    row.rawJson = JSON.stringify(resp);
    row.updateTime = Math.floor(Date.now() / 1000);

    try {
      const respRecord = resp as Record<string, object>;
      const dataObj = respRecord['data'] !== undefined ? respRecord['data'] : resp;
      const data = dataObj as Record<string, object>;

      // 提取各部分的 consume JSON
      const avatarConsume = data['avatar_consume'] as Record<string, object>[] | null;
      row.avatarConsumeJson = avatarConsume ? JSON.stringify(avatarConsume) : '';

      const weaponConsume = data['weapon_consume'] as Record<string, object>[] | null;
      row.weaponConsumeJson = weaponConsume ? JSON.stringify(weaponConsume) : '';

      const skillConsume = data['skill_consume'] as Record<string, object>[] | null;
      row.skillConsumeJson = skillConsume ? JSON.stringify(skillConsume) : '';
    } catch (_) {}

    return row;
  }

  // ── 批量读取计算数据 ────────────────────────────────────────

  /**
   * 读取所有角色的养成计算数据
   */
  async getAllComputeData(accountId: string, roleUid: string): Promise<ZZZAvatarComputeRow[]> {
    return this.avatarComputeDao.findAll(accountId, roleUid);
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