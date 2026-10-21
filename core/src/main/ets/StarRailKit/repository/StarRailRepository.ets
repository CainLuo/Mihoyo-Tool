import { GameRepository } from '../../repository/GameRepository';
import { SyncDataType } from '../../common/constants/SyncDataType';
import { StarRailDBManager } from '../db/StarRailDBManager';
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
} from '../model/StarRailRows';
import { StarRailApiService } from '../api/StarRailApiService';
import { GeetestService } from '../../base/network/GeetestService';
import { MihoyoDomain } from '../../base/network/MihoyoDomain';
import { StarRailApiPath } from '../api/StarRailApiPath';
import { AuthExpiredError } from '../../base/errors/ApiErrors';
import { CookieRefreshCoordinator } from '../../base/cookie/CookieRefreshCoordinator';
import { CoreInitializer } from '../../CoreInitializer';
import { BBSRepository } from '../../repository/BBSRepository';
import { MaterialBagRow } from '../../models/MaterialBagRow';
import { StarRailComputeParser, StarRailMaterialItem } from '../parser/StarRailComputeParser';
import { GameId } from '../../common/constants/GameId';
import { Logger } from '../../base/utils/Logger';
import { CookieDebug } from '../../base/utils/CookieDebug';
import { ApiErrorCodes } from '../../common/constants/ApiErrorCodes';
import { ApiErrorHandler } from '../../base/utils/ApiErrorHandler';


/** tryWidgetFallback 结果 */
const WIDGET_FALLBACK_SUCCESS: string = 'success';
const WIDGET_FALLBACK_REJECTED: string = 'rejected';
const WIDGET_FALLBACK_UNAVAILABLE: string = 'unavailable';

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

  /**
   * 拉取实时便笺。便笺接口返回 retcode ≠ 0 时一律降级到 Widget 接口；
   * Widget 成功则视为同步成功；Widget 失败或没有 v2 stoken 时，按便笺接口原本的错误抛出
   * （登录过期仍会触发上层的 Cookie 自动刷新，人机验证仍会触发验证弹框）。
   */
  private async doSyncDailyNote(accountId: string, roleUid: string, server: string, cookie: string, geetestChallenge?: string): Promise<void> {
    const resp = await (this.getService() as StarRailApiService).getDailyNote(roleUid, server, cookie, geetestChallenge);
    const respData = resp as Record<string, object>;
    const retcode = Number(respData['retcode'] ?? 0);
    const message: string = `${respData['message'] ?? 'no data'}`;

    if (retcode !== ApiErrorCodes.SUCCESS) {
      const fallback = await this.tryWidgetFallback(accountId, roleUid, cookie, `retcode=${retcode}: ${message}`);
      if (fallback === WIDGET_FALLBACK_SUCCESS) {
        return;
      }
      // 便笺与 Widget 都没拿到数据且便笺需要人机验证：统一上报弹框（便笺请求本身不自动上报）
      if (GeetestService.isGeetestRetcode(retcode)) {
        GeetestService.reportRequired(MihoyoDomain.TAKUMI_RECORD + StarRailApiPath.DAILY_NOTE, cookie, roleUid, retcode);
      }
      if (fallback === WIDGET_FALLBACK_REJECTED) {
        // Widget 也返回登录过期（-100 / 10001）：视为登录已过期。
        // 上层 syncDailyNote 会先用 stoken 自动刷新 Cookie 重试一次，仍失败则由首页弹"登录已过期"
        const reason4Expire = `retcode=${retcode}: ${message}; widget auth expired`;
        throw new AuthExpiredError(`note ${reason4Expire}`);
      }
      // Widget 不可用 / 返回其他错误：按便笺接口原本的错误处理（1034 仍会触发人机验证）
      if (ApiErrorHandler.isAuthExpired(retcode)) {
        throw new AuthExpiredError(`retcode=${retcode}: ${message}`);
      }
      throw new Error(`retcode=${retcode}: ${message}`);
    }
    if (respData['data'] === null || respData['data'] === undefined) {
      throw new Error(`retcode=${retcode}: ${message}`);
    }
    const dataObj = respData['data'] !== undefined ? respData['data'] : resp;
    const row = this.parseStarRailDailyNoteData(accountId, roleUid, dataObj);
    await this.dbManager.upsertDailyNoteWithSync(accountId, roleUid, row);
  }

  /**
   * 降级到 Widget 接口同步便笺。
   * @returns WIDGET_FALLBACK_SUCCESS：Widget 同步成功；
   *          WIDGET_FALLBACK_REJECTED：Widget 返回 -100 / 10001（调用方视为登录已过期）；
   *          WIDGET_FALLBACK_UNAVAILABLE：没有 v2 stoken、网络异常或 Widget 返回其他错误（调用方按便笺原错误处理）
   */
  private async tryWidgetFallback(accountId: string, roleUid: string, cookie: string, reason: string): Promise<string> {
    // 与 PizzaHelperUnited 一致：Cookie 含 v2 stoken 才能降级，Widget 请求使用账号完整 Cookie
    const widgetCookie = cookie.indexOf('stoken=v2_') !== -1 ? cookie : '';
    if (widgetCookie.length === 0) {
      return WIDGET_FALLBACK_UNAVAILABLE;
    }
    try {
      await this.doSyncDailyNoteWidget(accountId, roleUid, widgetCookie);
      await this.dbManager.markSuccess(accountId, roleUid, SyncDataType.STARRAIL_DAILY_NOTE);
      return WIDGET_FALLBACK_SUCCESS;
    } catch (widgetError) {
      const msg = widgetError instanceof Error ? widgetError.message : String(widgetError);
      // doSyncDailyNoteWidget 在接口返回 retcode ≠ 0 时抛出 "Widget API failed: retcode=..."
      // 只有 Widget 自己返回登录过期（-100 / 10001）才视为过期；其他错误（如 -10001）按便笺接口原错误处理
      const m = msg.match(/retcode=(-?\d+)/);
      const rejected = m !== null && CookieDebug.isAuthExpiredCode(Number(m[1]));
      Logger.error('StarRailRepository', `[Fallback] starrail widget FAILED (${rejected ? 'rejected' : 'unavailable'}): ${msg}`);
      return rejected ? WIDGET_FALLBACK_REJECTED : WIDGET_FALLBACK_UNAVAILABLE;
    }
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

  /** 读取该游戏 UID 下全部养成计算结果（角色选择页的"历史记录"使用） */
  async getAllComputeData(accountId: string, roleUid: string): Promise<StarRailAvatarComputeRow[]> {
    return this.dbManager.getAllComputeData(accountId, roleUid);
  }

  /**
   * 标记指定角色"已达成目标"：写入（覆盖）一行 target_reached = 1、各 consume / raw_json 为空的记录。
   * 同一角色 ID 覆盖旧的计算结果，不存在则新增；该角色保留在历史记录中（排在最后）。
   */
  async markTargetReached(accountId: string, roleUid: string, avatarIds: string[]): Promise<void> {
    const now = Math.floor(Date.now() / 1000);
    // dbManager.upsertAvatarCompute 自带事务，这里逐条写入，不再外包事务（避免嵌套）
    for (let i = 0; i < avatarIds.length; i++) {
      const row = new StarRailAvatarComputeRow();
      row.accountId = accountId;
      row.roleUid = roleUid;
      row.avatarId = avatarIds[i];
      row.updateTime = now;
      row.targetReached = 1;
      await this.dbManager.upsertAvatarCompute(row);
    }
  }

  /**
   * 拉取单角色养成计算 → 解析 → 写 DB
   * 同时写入材料背包数据（从 user_owns_materials）
   * @param avatarId 角色 ID（字符串，如 '1001'）
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
    
    await this.dbManager.markSyncing(accountId, roleUid, SyncDataType.STARRAIL_AVATAR_COMPUTE);
    try {
      const resp = await (this.getService() as StarRailApiService).compute(avatarId, avatar, equipment, skillList, uid, region, cookie);
      ApiErrorHandler.checkResponse(resp);
      
      const row = StarRailRepository.parseComputeResult(accountId, roleUid, avatarId, resp);

      // 解析材料背包数据
      const dataObj = (resp as Record<string, object>)['data'] ?? resp;
      const rawJson = JSON.stringify(dataObj);
      
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

      
      await this.dbManager.upsertAvatarComputeWithSync(accountId, roleUid, row, materialRows);
      
      return row;
    } catch (error) {
      const msg = this.toErrorMessage(error);
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
