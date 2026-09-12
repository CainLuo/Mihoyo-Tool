import { GameRepository } from './GameRepository';
import { SyncDataType } from '../constants/SyncDataType';
import { StarRailDBManager } from '../database/StarRailDBManager';
import {
  StarRailAvatarBasicRow,
  StarRailDailyNoteRow,
  StarRailAvatarInfoRow,
  StarRailAvatarComputeRow,
  StarRailEquipItem,
  StarRailAvatarItem,
  StarRailAvatarListData,
  StarRailComputeAvatar,
  StarRailComputeEquipment,
  StarRailComputeSkill,
  StarRailAvatarInfoItem,
  StarRailAvatarSkill,
} from '../models/StarRailRows';
import { StarRailApiService } from '../network/StarRailApiService';
import { AuthExpiredError } from '../errors/ApiErrors';
import { CookieRefreshCoordinator } from '../cookie/CookieRefreshCoordinator';
import { CoreInitializer } from '../CoreInitializer';
import { BBSRepository } from './BBSRepository';
import { MaterialBagRow } from '../models/MaterialBagRow';
import { StarRailComputeParser, StarRailMaterialItem } from '../parsers/starrail/StarRailComputeParser';
import { GameId } from '../constants/GameId';
import { Logger } from '../utils/Logger';
import { ApiErrorHandler } from '../utils/ApiErrorHandler';

export class StarRailRepository extends GameRepository {
  private dbManager: StarRailDBManager = new StarRailDBManager();

  // ── 角色基础列表 ──────────────────────────────────────────────

  async getAvatarList(accountId: string, roleUid: string): Promise<StarRailAvatarBasicRow[]> {
    return this.dbManager.getAvatarList(accountId, roleUid);
  }

  async needsAvatarListSync(accountId: string, roleUid: string): Promise<boolean> {
    return this.dbManager.needsSync(accountId, roleUid, SyncDataType.STARRAIL_AVATAR_BASIC);
  }

  /** 拉取角色列表 → 解析 → 写 DB */
  async syncAvatarList(accountId: string, roleUid: string, server: string, cookie: string): Promise<void> {
    await this.dbManager.markSyncing(accountId, roleUid, SyncDataType.STARRAIL_AVATAR_BASIC);
    try {
      const resp = await (this.getService() as StarRailApiService).getAvatarBasic(roleUid, server, cookie);
      ApiErrorHandler.checkResponse(resp);
      const rows = StarRailRepository.parseAvatarBasic(accountId, roleUid, resp);
      await this.dbManager.upsertAvatarListWithSync(accountId, roleUid, rows);
    } catch (error) {
      const msg = this.toErrorMessage(error);
      await this.dbManager.markFailed(accountId, roleUid, SyncDataType.STARRAIL_AVATAR_BASIC, msg);
      throw new Error(msg);
    }
  }

  // ── 实时便笺 ──────────────────────────────────────────────────

  async getDailyNote(accountId: string, roleUid: string): Promise<StarRailDailyNoteRow | null> {
    return this.dbManager.getDailyNote(accountId, roleUid);
  }

  async needsDailyNoteSync(accountId: string, roleUid: string): Promise<boolean> {
    return this.dbManager.needsSync(accountId, roleUid, SyncDataType.STARRAIL_DAILY_NOTE);
  }

  async getDailyNoteLastSyncTime(accountId: string, roleUid: string): Promise<number> {
    return this.dbManager.getLastSyncTime(accountId, roleUid, SyncDataType.STARRAIL_DAILY_NOTE);
  }

  /** 拉取便笺 → 写 DB */
  async syncDailyNote(accountId: string, roleUid: string, server: string, cookie: string, geetestChallenge?: string): Promise<void> {
    await this.dbManager.markSyncing(accountId, roleUid, SyncDataType.STARRAIL_DAILY_NOTE);
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
          await this.dbManager.markFailed(accountId, roleUid, SyncDataType.STARRAIL_DAILY_NOTE, msg);
          if (refreshError instanceof AuthExpiredError) {
            throw refreshError;
          }
          throw new AuthExpiredError(msg);
        }
      }
      const msg = this.toErrorMessage(error);
      await this.dbManager.markFailed(accountId, roleUid, SyncDataType.STARRAIL_DAILY_NOTE, msg);
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
        await this.dbManager.markSuccess(accountId, roleUid, SyncDataType.STARRAIL_DAILY_NOTE);
        return;
      }
      throw new Error(`retcode=${retcodeStr}: Geetest verification required and no widget cookie available`);
    }
    if (respData['data'] === null || respData['data'] === undefined) {
      throw new Error(`retcode=${retcodeStr}: ${respData['message'] ?? 'no data'}`);
    }
    const dataObj = respData['data'] !== undefined ? respData['data'] : resp;
    const row = this.parseStarRailDailyNoteData(accountId, roleUid, dataObj);
    await this.dbManager.upsertDailyNoteWithSync(accountId, roleUid, row);
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
    await this.dbManager.upsertDailyNoteWithSync(accountId, roleUid, row);
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
    return this.dbManager.getAvatarDetail(accountId, roleUid, avatarId);
  }

  async needsAvatarDetailSync(accountId: string, roleUid: string): Promise<boolean> {
    return this.dbManager.needsSync(accountId, roleUid, SyncDataType.STARRAIL_AVATAR_INFO);
  }

  /** 拉取角色详情列表 → 解析 → 写 DB（批量，使用 id=0 拉取全部） */
  async syncAvatarInfo(accountId: string, roleUid: string, server: string, cookie: string): Promise<void> {
    await this.dbManager.markSyncing(accountId, roleUid, SyncDataType.STARRAIL_AVATAR_INFO);
    try {
      const resp = await (this.getService() as StarRailApiService).getAvatarInfo(roleUid, server, '0', cookie);
      ApiErrorHandler.checkResponse(resp);
      const rows = StarRailRepository.parseAvatarInfo(accountId, roleUid, resp);
      await this.dbManager.upsertAvatarDetailsWithSync(accountId, roleUid, rows);
    } catch (error) {
      const msg = this.toErrorMessage(error);
      await this.dbManager.markFailed(accountId, roleUid, SyncDataType.STARRAIL_AVATAR_INFO, msg);
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
        // 解析 skills 数组，提取 point_id 和 level
        const infoItem = item as StarRailAvatarInfoItem;
        if (infoItem.skills !== undefined && infoItem.skills.length > 0) {
          const skillTree: StarRailAvatarSkill[] = infoItem.skills;
          row.skillTreeJson = JSON.stringify(skillTree);
        }
        row.rawJson = JSON.stringify(item);
        row.updateTime = Math.floor(Date.now() / 1000);
        result[result.length] = row;
      }
    } catch (_) {}
    return result;
  }

  // ── 养成材料计算 ──────────────────────────────────────────────

  async getAvatarCompute(accountId: string, roleUid: string, avatarId: string): Promise<StarRailAvatarComputeRow | null> {
    return this.dbManager.getAvatarCompute(accountId, roleUid, avatarId);
  }

  async needsAvatarComputeSync(accountId: string, roleUid: string): Promise<boolean> {
    return this.dbManager.needsSync(accountId, roleUid, SyncDataType.STARRAIL_AVATAR_COMPUTE);
  }

  /**
   * 拉取单角色养成计算 → 解析 → 写 DB
   * 同时写入材料背包数据（从 user_owns_materials）
   * @param avatarId 角色 ID（字符串，如 '1001'）—— 用于 Mock 文件路由
   * @param avatar 角色计算参数（item_id, cur_level, target_level）
   * @param equipment 光锥计算参数（item_id, cur_level, target_level）
   * @param skillList 技能计算参数数组
   * @param uid 游戏 UID
   * @param region 服务器（如 'prod_gf_cn'）
   * @param cookie 登录 Cookie
   */
  async syncAvatarCompute(
    accountId: string,
    roleUid: string,
    avatarId: string,
    avatar: StarRailComputeAvatar,
    equipment: StarRailComputeEquipment,
    skillList: StarRailComputeSkill[],
    uid: string,
    region: string,
    cookie: string
  ): Promise<StarRailAvatarComputeRow> {
    Logger.info('StarRailRepository', `💥💥💥 syncAvatarCompute START: accountId=${accountId}, roleUid=${roleUid}, avatarId=${avatarId}`);
    
    await this.dbManager.markSyncing(accountId, roleUid, SyncDataType.STARRAIL_AVATAR_COMPUTE);
    try {
      Logger.info('StarRailRepository', `💥💥💥 syncAvatarCompute: calling API...`);
      const resp = await (this.getService() as StarRailApiService).compute(avatarId, avatar, equipment, skillList, uid, region, cookie);
      ApiErrorHandler.checkResponse(resp);
      Logger.info('StarRailRepository', `💥💥💥 syncAvatarCompute: API response received, parsing...`);
      
      const row = StarRailRepository.parseComputeResult(accountId, roleUid, avatarId, resp);

      // 解析材料背包数据
      const dataObj = (resp as Record<string, object>)['data'] ?? resp;
      const rawJson = JSON.stringify(dataObj);
      Logger.info('StarRailRepository', `💥💥💥 syncAvatarCompute: rawJson length=${rawJson.length}`);
      
      const computeData = StarRailComputeParser.parse(rawJson);

      // 合并 consume 数据中的材料信息
      const materialRows = this.buildMaterialRows(
        accountId,
        roleUid,
        computeData.avatarConsume,
        computeData.skillConsume,
        computeData.equipmentConsume,
        computeData.userOwnsMaterials
      );

      Logger.info('StarRailRepository', `💥💥💥 syncAvatarCompute: writing to DB, materialRows=${materialRows.length}`);
      
      await this.dbManager.upsertAvatarComputeWithSync(accountId, roleUid, row, materialRows);
      Logger.info('StarRailRepository', `💥💥💥 syncAvatarCompute: DB write DONE`);
      
      Logger.info('StarRailRepository', `💥💥💥 syncAvatarCompute SUCCESS: avatarId=${avatarId}`);
      return row;
    } catch (error) {
      const msg = this.toErrorMessage(error);
      Logger.error('StarRailRepository', `💥💥💥 syncAvatarCompute FAILED: ${msg}`);
      await this.dbManager.markFailed(accountId, roleUid, SyncDataType.STARRAIL_AVATAR_COMPUTE, msg);
      throw new Error(msg);
    }
  }

  /**
   * 从 consume 数据和 userOwnsMaterials 构建材料背包行
   */
  private buildMaterialRows(
    accountId: string,
    roleUid: string,
    avatarConsume: StarRailMaterialItem[],
    skillConsume: StarRailMaterialItem[],
    equipmentConsume: StarRailMaterialItem[],
    userOwnsMaterials: Map<string, number>
  ): MaterialBagRow[] {
    const rows: MaterialBagRow[] = [];
    const materialInfoMap = new Map<string, StarRailMaterialItem>();

    // 收集所有材料信息（去重）
    for (let i = 0; i < avatarConsume.length; i++) {
      const item = avatarConsume[i];
      if (!materialInfoMap.has(item.itemId)) {
        materialInfoMap.set(item.itemId, item);
      }
    }
    for (let i = 0; i < skillConsume.length; i++) {
      const item = skillConsume[i];
      if (!materialInfoMap.has(item.itemId)) {
        materialInfoMap.set(item.itemId, item);
      }
    }
    for (let i = 0; i < equipmentConsume.length; i++) {
      const item = equipmentConsume[i];
      if (!materialInfoMap.has(item.itemId)) {
        materialInfoMap.set(item.itemId, item);
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
        row.materialName = info.itemName;
        row.materialIcon = info.itemUrl;
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
   * 解析单角色计算 API 响应为 StarRailAvatarComputeRow
   * @param avatarId 角色 ID（从调用方传入，因为 API 响应中不包含 avatar.id）
   */
  static parseComputeResult(accountId: string, roleUid: string, avatarId: string, resp: object): StarRailAvatarComputeRow {
    const row = new StarRailAvatarComputeRow();
    row.accountId = accountId;
    row.roleUid = roleUid;
    row.avatarId = avatarId;
    row.updateTime = Math.floor(Date.now() / 1000);

    try {
      const respRecord = resp as Record<string, object>;
      const dataObj = respRecord['data'] !== undefined ? respRecord['data'] : resp;
      const data = dataObj as Record<string, object>;

      // rawJson 只存储 data 部分，与 Parser 期望一致
      row.rawJson = JSON.stringify(dataObj);

      // 提取各部分的 consume JSON
      const avatarConsume = data['avatar_consume'] as Record<string, object>[] | null;
      row.avatarConsumeJson = avatarConsume ? JSON.stringify(avatarConsume) : '';

      const skillConsume = data['skill_consume'] as Record<string, object>[] | null;
      row.skillConsumeJson = skillConsume ? JSON.stringify(skillConsume) : '';

      const equipmentConsume = data['equipment_consume'] as Record<string, object>[] | null;
      row.equipmentConsumeJson = equipmentConsume ? JSON.stringify(equipmentConsume) : '';
    } catch (_) {}

    return row;
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
