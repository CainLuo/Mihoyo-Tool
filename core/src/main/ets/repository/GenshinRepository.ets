import { GameRepository } from './GameRepository';
import { SyncDataType } from '../constants/SyncDataType';
import {
  GenshinCharacterListDao,
  GenshinDailyNoteDao,
  GenshinCharacterDetailDao,
  GenshinCharacterComputeDao,
  GenshinCalcAvatarDao,
  GenshinComputeSummaryDao
} from '../database/GenshinDao';
import {
  GenshinCharacterListRow,
  GenshinDailyNoteRow,
  GenshinCharacterDetailRow,
  GenshinCharacterComputeRow,
  GenshinCalcAvatarRow,
  GenshinComputeSummaryRow,
  GenshinWeaponItem,
  GenshinCharacterItem,
  GenshinCharacterListData,
} from '../models/GenshinRows';
import { GenshinApiService } from '../network/GenshinApiService';
import { SyncError, SyncErrorKind, SyncErrorFactory } from '../errors/ApiErrors';
import { CookieRefreshCoordinator } from '../cookie/CookieRefreshCoordinator';
import { Logger } from '../utils/Logger';
import { ApiErrorHandler } from '../utils/ApiErrorHandler';
import { ApiErrorCodes } from '../constants/ApiErrorCodes';
import { CoreInitializer } from '../CoreInitializer';
import { BBSRepository } from './BBSRepository';
import { MaterialBagRepository } from './MaterialBagRepository';
import { MaterialBagRow } from '../models/MaterialBagRow';
import { GameId } from '../constants/GameId';
import { AUTH_EXPIRE_TAG } from '../utils/CookieDebug';
import {
  GENSHIN_TALENT_SLOT_COUNT,
  GenshinCalcTargets,
  GenshinCalcAvatarParam,
  GenshinCalcSkillParam,
  GenshinCalcWeaponParam,
} from '../models/GenshinCalcModels';

/** 计算器不支持的角色（奇偶·男/女），与 TeyvatGuide EXCLUDED_CHARACTER_IDS 一致 */
const CALC_EXCLUDED_AVATAR_IDS: number[] = [10000117, 10000118];
const SYNC_AVATAR_PAGE_SIZE: number = 100;
const SYNC_AVATAR_MAX_PAGES: number = 10;
/** 养成计算链路统一日志 tag，过滤：hilog | grep */
const CALC_TAG: string = 'GenshinCalc';

export class GenshinRepository extends GameRepository {
  private characterListDao: GenshinCharacterListDao = new GenshinCharacterListDao();
  private dailyNoteDao: GenshinDailyNoteDao = new GenshinDailyNoteDao();
  private characterDetailDao: GenshinCharacterDetailDao = new GenshinCharacterDetailDao();
  private characterComputeDao: GenshinCharacterComputeDao = new GenshinCharacterComputeDao();
  private calcAvatarDao: GenshinCalcAvatarDao = new GenshinCalcAvatarDao();
  private computeSummaryDao: GenshinComputeSummaryDao = new GenshinComputeSummaryDao();
  private materialBagRepo: MaterialBagRepository = new MaterialBagRepository();

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
    Logger.info('💥 GenshinRepository', `syncAvatarList: accountId=${accountId}, roleUid=${roleUid}, server=${server}`);
    await this.markSyncing(accountId, roleUid, SyncDataType.GENSHIN_CHARACTER_LIST);
    try {
      Logger.info('💥 GenshinRepository', `syncAvatarList: calling getCharacterList API`);
      const resp = await (this.getService() as GenshinApiService).getCharacterList(roleUid, server, cookie);
      ApiErrorHandler.checkResponse(resp);
      Logger.info('💥 GenshinRepository', `syncAvatarList: API response received, parsing`);
      const rows = GenshinRepository.parseCharacterList(accountId, roleUid, resp);
      Logger.info('💥 GenshinRepository', `syncAvatarList: parsed ${rows.length} rows, writing to DB`);
      await this.upsertAvatarList(accountId, roleUid, rows);
      Logger.info('💥 GenshinRepository', `syncAvatarList: completed successfully`);
    } catch (error) {
      const msg = this.toErrorMessage(error);
      Logger.error('💥 GenshinRepository', `syncAvatarList: failed - ${msg}`);
      await this.markFailed(accountId, roleUid, SyncDataType.GENSHIN_CHARACTER_LIST, msg);
      // 直接抛出 SyncError（ApiErrorHandler.checkResponse 已经转换）
      throw error as Error;
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

  async getDailyNoteLastSyncTime(accountId: string, roleUid: string): Promise<number> {
    return this.getLastSyncTime(accountId, roleUid, SyncDataType.GENSHIN_DAILY_NOTE);
  }

  async markDailyNoteSyncing(accountId: string, roleUid: string): Promise<void> {
    await this.markSyncing(accountId, roleUid, SyncDataType.GENSHIN_DAILY_NOTE);
  }

  async markDailyNoteFailed(accountId: string, roleUid: string, errorMsg: string): Promise<void> {
    await this.markFailed(accountId, roleUid, SyncDataType.GENSHIN_DAILY_NOTE, errorMsg);
  }

  /**
   * 拉取便笺 → 写 DB（entry 层只需调用此方法）
   * @param geetestChallenge Geetest 验证通过后的新 challenge（可选）
   * @param geetestValidate  Geetest 验证结果 validate（可选）
   * @param geetestSeccode   Geetest 验证结果 seccode（可选）
   */
  async syncDailyNote(accountId: string, roleUid: string, server: string, cookie: string, geetestChallenge?: string): Promise<void> {
    await this.markSyncing(accountId, roleUid, SyncDataType.GENSHIN_DAILY_NOTE);
    try {
      await this.doSyncDailyNote(accountId, roleUid, server, cookie, geetestChallenge);
    } catch (error) {
      const syncError = error as SyncError;
      if (syncError.kind === SyncErrorKind.AUTH_EXPIRED) {
        // 尝试用 stoken 刷新 cookie 后重试一次
        try {
          const newCookie = await CookieRefreshCoordinator.instance.refreshWithLock(
            accountId,
            cookie,
            CoreInitializer.bbsRepository,
          );
          await this.doSyncDailyNote(accountId, roleUid, server, newCookie);
          return;
        } catch (refreshError) {
          // 刷新失败或重试仍失败，向上抛出 SyncError
          const msg = this.toErrorMessage(refreshError);
          await this.markFailed(accountId, roleUid, SyncDataType.GENSHIN_DAILY_NOTE, msg);
          throw refreshError as Error;
        }
      }
      const msg = this.toErrorMessage(error);
      await this.markFailed(accountId, roleUid, SyncDataType.GENSHIN_DAILY_NOTE, msg);
      throw error as Error;
    }
  }

  /**
   * 拉取实时便笺。便笺接口返回 retcode ≠ 0 时一律降级到 Widget 接口；
   * Widget 成功则视为同步成功；Widget 失败或没有 v2 stoken 时，按便笺接口原本的错误抛出
   * （登录过期仍会触发上层的 Cookie 自动刷新，人机验证仍会触发验证弹框）。
   */
  private async doSyncDailyNote(accountId: string, roleUid: string, server: string, cookie: string, geetestChallenge?: string): Promise<void> {
    const resp = await (this.getService() as GenshinApiService).getDailyNote(roleUid, server, cookie, geetestChallenge);
    const respData = resp as Record<string, object>;
    const retcode = Number(respData['retcode'] ?? 0);
    const message: string = `${respData['message'] ?? 'no data'}`;

    if (retcode !== ApiErrorCodes.SUCCESS) {
      if (await this.tryWidgetFallback(accountId, roleUid, cookie, `retcode=${retcode}: ${message}`)) {
        return;
      }
      // Widget 也失败：按便笺接口原本的错误处理
      if (ApiErrorHandler.isAuthExpired(retcode)) {
        throw SyncErrorFactory.authExpired(`retcode=${retcode}: ${message}`);
      }
      throw SyncErrorFactory.normal(retcode, message);
    }
    if (respData['data'] === null || respData['data'] === undefined) {
      throw SyncErrorFactory.normal(retcode, message);
    }
    const dataObj = respData['data'] !== undefined ? respData['data'] : resp;
    const row = this.parseDailyNoteData(accountId, roleUid, dataObj);
    await this.upsertDailyNote(accountId, roleUid, row);
  }

  /**
   * 降级到 Widget 接口同步便笺。
   * @returns true 表示 Widget 同步成功；false 表示没有 v2 stoken 或 Widget 也失败（由调用方抛出原错误）
   */
  private async tryWidgetFallback(accountId: string, roleUid: string, cookie: string, reason: string): Promise<boolean> {
    const widgetCookie = BBSRepository.buildWidgetCookie(cookie);
    Logger.warn(AUTH_EXPIRE_TAG, `[Fallback] genshin note failed (${reason}), fallback to widget, widgetCookie=${widgetCookie.length > 0 ? 'OK' : 'NONE (no v2 stoken)'}`);
    if (widgetCookie.length === 0) {
      return false;
    }
    try {
      await this.doSyncDailyNoteWidget(accountId, roleUid, widgetCookie);
      await this.markSuccess(accountId, roleUid, SyncDataType.GENSHIN_DAILY_NOTE);
      Logger.warn(AUTH_EXPIRE_TAG, `[Fallback] genshin widget OK`);
      return true;
    } catch (widgetError) {
      Logger.error(AUTH_EXPIRE_TAG, `[Fallback] genshin widget FAILED: ${widgetError instanceof Error ? widgetError.message : String(widgetError)}`);
      return false;
    }
  }


  /**
   * Widget API 降级同步便笺（原神 /aapi/widget/v2）
   * Widget 返回字段是普通便笺的子集，只更新有对应字段的数据
   */
  private async doSyncDailyNoteWidget(accountId: string, roleUid: string, widgetCookie: string): Promise<void> {
    const resp = await (this.getService() as GenshinApiService).getDailyNoteWidget(widgetCookie);
    const respData = resp as Record<string, object>;
    const retcode = Number(respData['retcode'] ?? 0);
    const message: string = `${respData['message'] ?? 'no data'}`;

    if (retcode !== ApiErrorCodes.SUCCESS) {
      throw new Error(`Widget API failed: retcode=${retcode}: ${message}`);
    }
    if (respData['data'] === null || respData['data'] === undefined) {
      throw new Error(`Widget API: no data`);
    }
    const dataObj = respData['data'] !== undefined ? respData['data'] : resp;
    const row = this.parseDailyNoteData(accountId, roleUid, dataObj);
    await this.upsertDailyNote(accountId, roleUid, row);
  }

  private parseDailyNoteData(accountId: string, roleUid: string, dataObj: object): GenshinDailyNoteRow {
    const d = dataObj as Record<string, object>;
    const row = new GenshinDailyNoteRow();
    row.accountId = accountId;
    row.roleUid = roleUid;
    row.rawJson = JSON.stringify(dataObj);
    row.updateTime = Math.floor(Date.now() / 1000);
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
    return row;
  }

  // ── 角色详情 ──────────────────────────────────────────────────

  async getAvatarDetail(accountId: string, roleUid: string, avatarId: string): Promise<GenshinCharacterDetailRow | null> {
    return this.characterDetailDao.findByAvatarId(accountId, roleUid, avatarId);
  }

  async getAllAvatarDetails(accountId: string, roleUid: string): Promise<GenshinCharacterDetailRow[]> {
    return this.characterDetailDao.findAll(accountId, roleUid);
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

  /** 拉取角色详情（先从 DB 读取角色列表，再批量请求详情）→ 解析 → 写 DB */
  async syncAvatarDetail(accountId: string, roleUid: string, server: string, cookie: string): Promise<void> {
    await this.markSyncing(accountId, roleUid, SyncDataType.GENSHIN_CHARACTER_DETAIL);
    try {
      // 先从 DB 读取已有的角色列表，获取 avatarId 列表
      const existingRows = await this.characterListDao.findAll(accountId, roleUid);
      const characterIds: string[] = [];
      for (let i = 0; i < existingRows.length; i++) {
        if (existingRows[i].avatarId.length > 0) {
          characterIds[characterIds.length] = existingRows[i].avatarId;
        }
      }
      if (characterIds.length === 0) {
        // 没有角色数据，跳过详情同步
        await this.markSuccess(accountId, roleUid, SyncDataType.GENSHIN_CHARACTER_DETAIL);
        return;
      }
      const resp = await (this.getService() as GenshinApiService).getCharacterDetail(roleUid, server, characterIds, cookie);
      ApiErrorHandler.checkResponse(resp);
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

        // 提取技能等级列表（逗号分隔，只取 skill_type=1 的可升级技能）
        const skills = item['skills'] as Record<string, object>[];
        if (skills && skills.length > 0) {
          const levels: string[] = [];
          for (let j = 0; j < skills.length; j++) {
            const skillTypeRaw = skills[j]['skill_type'];
            const skillType = typeof skillTypeRaw === 'number' ? skillTypeRaw : parseInt(`${skillTypeRaw ?? 0}`, 10);
            // skill_type=1 是可升级技能（普攻、E、Q），skill_type=2 是固有天赋/被动
            // 如果没有 skill_type 字段（旧数据），默认为可升级技能
            if (skillType === 1 || skillType === 0) {
              levels[levels.length] = `${skills[j]['level_current'] ?? skills[j]['level'] ?? 0}`;
            }
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

  /**
   * 批量计算角色养成材料 → 原样写 DB
   * 原神 API 一次最多处理 8 个角色，需要分批请求。
   *
   * 写入（字段与 API 一致，不做 UI 相关转换，见 06-core-data-layer.md 四、数据流规范）：
   * - genshin_character_compute：每个角色一行，来自 data.items[i] 与 data.single_role_result[i]
   * - genshin_compute_summary：data 顶层的整批合计（overall_consume 等），只有一个批次时才代表全部角色，
   *   多批次时删除旧汇总（页面回退到按角色估算）
   * - genshin_material_bag：data.available_material（接口只返回部分材料，主要是可用于合成的低级材料，不是完整背包）
   *
   * @param items 计算项数组（由 buildCalcItems 生成，每项包含 avatar_id）
   * @param uid 游戏 UID
   * @param region 服务器（如 'cn_gf01'）
   * @param cookie 登录 Cookie
   * 只 upsert 本批角色（唯一键 account_id + role_uid + avatar_id），其他角色以前的计算结果保留，作为历史记录。
   */
  async syncAvatarCompute(
    accountId: string,
    roleUid: string,
    items: object[],
    uid: string,
    region: string,
    cookie: string
  ): Promise<void> {
    await this.markSyncing(accountId, roleUid, SyncDataType.GENSHIN_CHARACTER_COMPUTE);

    // 原神批量计算 API 限制：每次最多 8 个角色，分批请求直到处理完所有角色
    const BATCH_SIZE = 8;
    const allRows: GenshinCharacterComputeRow[] = [];
    const bagRows = new Map<string, MaterialBagRow>();
    let summaryRow: GenshinComputeSummaryRow | null = null;

    try {
      const totalItems = items.length;
      const batchCount = Math.ceil(totalItems / BATCH_SIZE);
      Logger.info(CALC_TAG, `[Compute] total ${totalItems} items, will request in ${batchCount} batches (max ${BATCH_SIZE} per batch)`);

      for (let batchIndex = 0; batchIndex < batchCount; batchIndex++) {
        const startIdx = batchIndex * BATCH_SIZE;
        const endIdx = Math.min(startIdx + BATCH_SIZE, totalItems);
        const batchItems: object[] = [];
        for (let i = startIdx; i < endIdx; i++) {
          batchItems[batchItems.length] = items[i];
        }

        Logger.info(CALC_TAG, `[Compute] batch ${batchIndex + 1}/${batchCount}, items ${startIdx + 1}-${endIdx}, avatarIds=${batchItems.map((it: object) => GenshinRepository.extractAvatarId(it as Record<string, Object>)).join(',')}`);

        const resp = await (this.getService() as GenshinApiService).batchCompute(batchItems, uid, region, cookie);
        const respRec = resp as Record<string, Object>;
        if (GenshinRepository.toNum(respRec['retcode']) !== 0) {
          Logger.error(CALC_TAG, `[Compute] batch ${batchIndex + 1} FAILED retcode=${respRec['retcode']}, message=${respRec['message']}`);
        }
        ApiErrorHandler.checkResponse(resp);

        const data = (respRec['data'] ?? resp) as Record<string, Object>;
        const rows = GenshinRepository.parseComputeRows(accountId, roleUid, data, batchItems);
        for (let i = 0; i < rows.length; i++) {
          allRows[allRows.length] = rows[i];
        }
        GenshinRepository.collectAvailableMaterials(data, bagRows);
        if (batchCount === 1) {
          summaryRow = GenshinRepository.parseComputeSummary(accountId, roleUid, data, batchItems);
        }

        Logger.info(CALC_TAG, `[Compute] batch ${batchIndex + 1} completed, got ${rows.length} rows, available_material total=${bagRows.size}`);
      }

      Logger.info(CALC_TAG, `[Compute] all batches completed, total rows=${allRows.length}, writing DB...`);

      await this.runInTransaction(async () => {
        for (let i = 0; i < allRows.length; i++) {
          await this.characterComputeDao.upsert(allRows[i]);
        }
        if (summaryRow !== null) {
          await this.computeSummaryDao.upsert(summaryRow);
        } else {
          // 多批次：顶层合计只覆盖单个批次，删除旧汇总避免展示过期数据
          await this.computeSummaryDao.deleteOne(accountId, roleUid);
          Logger.warn(CALC_TAG, `[Compute] ${batchCount} batches, compute summary not stored`);
        }
        await this.markSuccess(accountId, roleUid, SyncDataType.GENSHIN_CHARACTER_COMPUTE);
      });
      Logger.info(CALC_TAG, `[Compute] DB write done, upserted rows=${allRows.length}`);
    } catch (error) {
      const msg = this.toErrorMessage(error);
      Logger.error(CALC_TAG, `[Compute] FAILED: ${msg}`);
      await this.markFailed(accountId, roleUid, SyncDataType.GENSHIN_CHARACTER_COMPUTE, msg);
      throw new Error(msg);
    }

    // 材料背包单独写入（MaterialBagDao.upsertAll 自带事务，不嵌套在上面的事务里）；失败不影响计算结果
    try {
      const bag: MaterialBagRow[] = [];
      bagRows.forEach((row: MaterialBagRow) => {
        bag[bag.length] = row;
      });
      await this.materialBagRepo.upsertMaterials(accountId, roleUid, bag, GameId.GENSHIN);
      Logger.info(CALC_TAG, `[Compute] material bag written, count=${bag.length}`);
    } catch (error) {
      Logger.warn(CALC_TAG, `[Compute] material bag write failed: ${this.toErrorMessage(error)}`);
    }
  }

  /**
   * 标记指定角色"已达成目标"：写入（覆盖）一行 target_reached = 1、各 consume / raw_json 为空的记录。
   * 同一角色 ID 覆盖旧的计算结果，不存在则新增；该角色保留在历史记录中（排在最后）。
   */
  async markTargetReached(accountId: string, roleUid: string, avatarIds: string[]): Promise<void> {
    const now = Math.floor(Date.now() / 1000);
    await this.runInTransaction(async () => {
      for (let i = 0; i < avatarIds.length; i++) {
        const row = new GenshinCharacterComputeRow();
        row.accountId = accountId;
        row.roleUid = roleUid;
        row.avatarId = avatarIds[i];
        row.updateTime = now;
        row.targetReached = 1;
        await this.characterComputeDao.upsert(row);
      }
    });
  }

  /** 读取最近一次计算的整批合计（genshin_compute_summary），没有时返回 null */
  async getComputeSummary(accountId: string, roleUid: string): Promise<GenshinComputeSummaryRow | null> {
    return this.computeSummaryDao.findOne(accountId, roleUid);
  }

  /** 读取材料背包（来自 batch_compute 的 available_material，只含部分材料，不是完整背包） */
  async getMaterialBag(accountId: string, roleUid: string): Promise<MaterialBagRow[]> {
    return this.materialBagRepo.getMaterials(accountId, roleUid, GameId.GENSHIN);
  }

  // ── 养成计算器角色（sync/avatar/list，genshin_calc_avatar）────────

  /**
   * 拉取计算器 sync/avatar/list 全部角色 → 原样写 DB（genshin_calc_avatar，整体替换该游戏 UID 的数据）
   * @param accountId 米游社账号 UID
   * @param roleUid 游戏 UID（同时作为请求的 uid）
   * @param region 服务器（如 'cn_gf01'）
   * @param cookie 登录 Cookie
   */
  async syncCalcAvatarList(accountId: string, roleUid: string, region: string, cookie: string): Promise<GenshinCalcAvatarRow[]> {
    await this.markSyncing(accountId, roleUid, SyncDataType.GENSHIN_CALC_AVATAR);
    try {
      const list = await this.fetchCalcSyncAvatars(roleUid, region, cookie);
      const now = Math.floor(Date.now() / 1000);
      const rows: GenshinCalcAvatarRow[] = [];
      for (let i = 0; i < list.length; i++) {
        rows[rows.length] = GenshinRepository.parseCalcAvatar(accountId, roleUid, list[i], now);
      }
      await this.runInTransaction(async () => {
        await this.calcAvatarDao.deleteAll(accountId, roleUid);
        for (let i = 0; i < rows.length; i++) {
          await this.calcAvatarDao.upsert(rows[i]);
        }
        await this.markSuccess(accountId, roleUid, SyncDataType.GENSHIN_CALC_AVATAR);
      });
      Logger.info(CALC_TAG, `[CalcAvatar] synced ${rows.length} avatars to DB`);
      return rows;
    } catch (error) {
      const msg = this.toErrorMessage(error);
      Logger.error(CALC_TAG, `[CalcAvatar] sync FAILED: ${msg}`);
      await this.markFailed(accountId, roleUid, SyncDataType.GENSHIN_CALC_AVATAR, msg);
      throw new Error(msg);
    }
  }

  /** 读取 DB 中的计算器角色 */
  async getCalcAvatars(accountId: string, roleUid: string): Promise<GenshinCalcAvatarRow[]> {
    return this.calcAvatarDao.findAll(accountId, roleUid);
  }

  /**
   * 构建 batch_compute 的 items 参数。
   *
   * 先同步计算器 sync/avatar/list 并写入 genshin_calc_avatar，再从 DB 读取并按目标等级组装；
   * 同步失败时使用 DB 中已有的数据（若为空则抛出原错误）。
   * 不使用战绩接口数据：战绩的 skill_id、元素名、weapon_type 与计算器的
   * group_id、element_attr_id、weapon_cat_id 不通用，会导致 -500001。
   * 参考 TeyvatGuide Cultivation.vue createApiRefreshParams。
   *
   * @param accountId 米游社账号 UID
   * @param uid 游戏 UID
   * @param region 服务器（如 'cn_gf01'）
   * @param cookie 登录 Cookie
   * @param avatarLevel / weaponLevel 目标等级（会按各自 max_level 截断，且不低于当前等级）
   * @param skillLevels 各天赋目标等级 [普通攻击, 元素战技, 元素爆发]（同样按 max_level 截断）
   * @param onlyAvatarIds 只计算这些角色（角色选择页传入）；不传则计算全部
   * @returns 有升级需求的角色计算项
   */
  async buildCalcItems(
    accountId: string,
    uid: string,
    region: string,
    cookie: string,
    avatarLevel: number,
    skillLevels: number[],
    weaponLevel: number,
    onlyAvatarIds?: string[],
  ): Promise<object[]> {
    const targets = new GenshinCalcTargets();
    targets.avatarLevel = avatarLevel;
    targets.skillLevels = skillLevels;
    targets.weaponLevel = weaponLevel;
    Logger.info(CALC_TAG, `[Build] START uid=${uid}, region=${region}, target avatar=${avatarLevel}, skills=[${skillLevels.join(',')}], weapon=${weaponLevel}, only=${onlyAvatarIds ? onlyAvatarIds.join(',') : 'ALL'}`);

    let avatars: GenshinCalcAvatarRow[];
    try {
      avatars = await this.syncCalcAvatarList(accountId, uid, region, cookie);
    } catch (error) {
      avatars = await this.getCalcAvatars(accountId, uid);
      if (avatars.length === 0) {
        throw new Error(this.toErrorMessage(error));
      }
      Logger.warn(CALC_TAG, `[Build] sync failed, use ${avatars.length} cached avatars from DB`);
    }

    const items: object[] = [];
    for (let i = 0; i < avatars.length; i++) {
      if (onlyAvatarIds && !onlyAvatarIds.includes(avatars[i].avatarId)) {
        continue;
      }
      const item = GenshinRepository.buildCalcAvatarParam(avatars[i], targets);
      if (item !== null) {
        items[items.length] = item;
      }
    }
    Logger.info(CALC_TAG, `[Build] DONE calcAvatars=${avatars.length}, items=${items.length}`);
    if (onlyAvatarIds) {
      const syncedIds: string[] = avatars.map((a: GenshinCalcAvatarRow) => a.avatarId);
      for (let i = 0; i < onlyAvatarIds.length; i++) {
        if (!syncedIds.includes(onlyAvatarIds[i])) {
          Logger.warn(CALC_TAG, `[Build] selected avatarId=${onlyAvatarIds[i]} NOT FOUND in sync/avatar/list`);
        }
      }
    }
    for (let i = 0; i < items.length; i++) {
      Logger.info(CALC_TAG, `[Build] item[${i}] = ${JSON.stringify(items[i])}`);
    }
    return items;
  }

  /** 分页拉取 sync/avatar/list 的全部角色（原样返回 data.list[]） */
  private async fetchCalcSyncAvatars(uid: string, region: string, cookie: string): Promise<Record<string, Object>[]> {
    const result: Record<string, Object>[] = [];
    for (let page = 1; page <= SYNC_AVATAR_MAX_PAGES; page++) {
      const resp = await (this.getService() as GenshinApiService)
        .syncCalcAvatarList(uid, region, cookie, page, SYNC_AVATAR_PAGE_SIZE);
      const respRecord = resp as Record<string, Object>;
      const retcode = GenshinRepository.toNum(respRecord['retcode']);
      if (retcode !== 0) {
        Logger.error(CALC_TAG, `[Fetch] page=${page} FAILED retcode=${retcode}, message=${respRecord['message'] ?? ''}`);
      }
      ApiErrorHandler.checkResponse(resp);
      if (retcode !== 0) {
        throw new Error(`sync/avatar/list retcode=${retcode}: ${respRecord['message'] ?? ''}`);
      }
      const data = respRecord['data'] as Record<string, Object> | null;
      const list = data ? data['list'] as Record<string, Object>[] | null : null;
      Logger.info(CALC_TAG, `[Fetch] page=${page} got ${list ? list.length : 0} avatars, total so far=${result.length + (list ? list.length : 0)}`);
      if (!list || list.length === 0) {
        break;
      }
      for (let i = 0; i < list.length; i++) {
        result[result.length] = list[i];
      }
      if (list.length < SYNC_AVATAR_PAGE_SIZE) {
        break;
      }
    }
    return result;
  }

  /** sync/avatar/list 的 data.list[i] → GenshinCalcAvatarRow（字段原样，嵌套结构存 JSON） */
  private static parseCalcAvatar(accountId: string, roleUid: string, item: Record<string, Object>, now: number): GenshinCalcAvatarRow {
    const row = new GenshinCalcAvatarRow();
    row.accountId = accountId;
    row.roleUid = roleUid;
    row.avatarId = `${item['id'] ?? ''}`;
    row.name = `${item['name'] ?? ''}`;
    row.icon = `${item['icon'] ?? ''}`;
    row.weaponCatId = GenshinRepository.toNum(item['weapon_cat_id']);
    row.avatarLevel = GenshinRepository.toNum(item['avatar_level']);
    row.elementAttrId = GenshinRepository.toNum(item['element_attr_id']);
    row.maxLevel = GenshinRepository.toNum(item['max_level']);
    row.levelCurrent = GenshinRepository.toNum(item['level_current']);
    row.promoteLevel = GenshinRepository.toNum(item['promote_level']);
    row.constellationNum = GenshinRepository.toNum(item['constellation_num']);
    row.fetterLevel = GenshinRepository.toNum(item['fetter_level']);
    row.skillListJson = item['skill_list'] !== undefined ? JSON.stringify(item['skill_list']) : '';
    row.weaponJson = item['weapon'] !== undefined && item['weapon'] !== null ? JSON.stringify(item['weapon']) : '';
    row.reliquaryListJson = item['reliquary_list'] !== undefined ? JSON.stringify(item['reliquary_list']) : '';
    row.rawJson = JSON.stringify(item);
    row.updateTime = now;
    return row;
  }

  /** 将单个计算器角色转换为计算项；无任何升级需求或不支持的角色返回 null */
  private static buildCalcAvatarParam(
    avatar: GenshinCalcAvatarRow,
    targets: GenshinCalcTargets,
  ): GenshinCalcAvatarParam | null {
    const avatarId = GenshinRepository.toNum(avatar.avatarId);
    if (avatarId <= 0 || CALC_EXCLUDED_AVATAR_IDS.includes(avatarId)) {
      Logger.info(CALC_TAG, `[Avatar] SKIP id=${avatarId} ${avatar.name}: excluded or invalid id`);
      return null;
    }

    const item = new GenshinCalcAvatarParam();
    item.avatar_id = avatarId;
    item.element_attr_id = avatar.elementAttrId;
    item.avatar_promote_level = avatar.promoteLevel;
    item.avatar_level_current = Math.max(avatar.levelCurrent, 1);
    item.avatar_level_target = GenshinRepository.clampTarget(targets.avatarLevel, item.avatar_level_current, avatar.maxLevel);
    let hasNeeds = item.avatar_level_target > item.avatar_level_current;

    // 技能：id 用 group_id；固有天赋（max_level=1）保持当前等级原样回传。
    // 可升级天赋（max_level>1）按出现顺序依次对应 普通攻击、元素战技、元素爆发，分别使用各自的目标等级
    const skills = GenshinRepository.parseJsonArray(avatar.skillListJson);
    let talentSlot = 0;
    for (let i = 0; i < skills.length; i++) {
      const s = skills[i];
      const skill = new GenshinCalcSkillParam();
      skill.id = GenshinRepository.toNum(s['group_id']);
      skill.level_current = Math.max(GenshinRepository.toNum(s['level_current']), 1);
      const maxLevel = GenshinRepository.toNum(s['max_level']);
      if (maxLevel > 1) {
        const slot = Math.min(talentSlot, GENSHIN_TALENT_SLOT_COUNT - 1);
        const slotTarget = targets.skillLevels[slot] ?? targets.skillLevels[targets.skillLevels.length - 1] ?? 10;
        skill.level_target = GenshinRepository.clampTarget(slotTarget, skill.level_current, maxLevel);
        talentSlot++;
      } else {
        skill.level_target = skill.level_current;
      }
      if (skill.level_target > skill.level_current) {
        hasNeeds = true;
      }
      item.skill_list[item.skill_list.length] = skill;
    }

    // 武器：原样回传 sync 返回的 weapon，只改 level_target；已满级则不传
    const w = GenshinRepository.parseJsonObject(avatar.weaponJson);
    if (w !== null && GenshinRepository.toNum(w['id']) > 0) {
      const weapon = new GenshinCalcWeaponParam();
      weapon.id = GenshinRepository.toNum(w['id']);
      weapon.name = `${w['name'] ?? ''}`;
      weapon.icon = `${w['icon'] ?? ''}`;
      weapon.weapon_cat_id = GenshinRepository.toNum(w['weapon_cat_id']);
      weapon.weapon_level = GenshinRepository.toNum(w['weapon_level']);
      weapon.max_level = GenshinRepository.toNum(w['max_level']);
      weapon.level_current = Math.max(GenshinRepository.toNum(w['level_current']), 1);
      weapon.level_target = GenshinRepository.clampTarget(targets.weaponLevel, weapon.level_current, weapon.max_level);
      if (weapon.level_target > weapon.level_current) {
        item.weapon = weapon;
        hasNeeds = true;
      }
    }

    const skillDesc = item.skill_list.map((sk: GenshinCalcSkillParam) => `${sk.id}:${sk.level_current}->${sk.level_target}`).join(',');
    const weaponDesc = item.weapon !== null
      ? `${item.weapon.id}(${item.weapon.name},cat=${item.weapon.weapon_cat_id},star=${item.weapon.weapon_level}):${item.weapon.level_current}->${item.weapon.level_target}`
      : (w !== null ? `maxed/none(raw level=${w['level_current'] ?? '?'}/${w['max_level'] ?? '?'})` : 'none');
    Logger.info(CALC_TAG, `[Avatar] ${hasNeeds ? 'ADD ' : 'SKIP'} id=${avatarId} ${avatar.name}, ` +
      `element=${item.element_attr_id}, promote=${item.avatar_promote_level}, ` +
      `level=${item.avatar_level_current}->${item.avatar_level_target}(max=${avatar.maxLevel}), ` +
      `skills=[${skillDesc}], weapon=${weaponDesc}${hasNeeds ? '' : ' (no upgrade needs)'}`);
    return hasNeeds ? item : null;
  }

  /** 目标等级：不超过 maxLevel（maxLevel<=0 时不限制），且不低于当前等级 */
  private static clampTarget(target: number, current: number, maxLevel: number): number {
    const capped = maxLevel > 0 ? Math.min(target, maxLevel) : target;
    return Math.max(capped, current);
  }

  private static toNum(v: Object | null | undefined): number {
    if (typeof v === 'number') {
      return v;
    }
    const n = parseInt(`${v ?? 0}`, 10);
    return isNaN(n) ? 0 : n;
  }

  private static parseJsonArray(json: string): Record<string, Object>[] {
    if (json.length === 0) {
      return [];
    }
    try {
      const v = JSON.parse(json) as Record<string, Object>[];
      return Array.isArray(v) ? v : [];
    } catch (_) {
      return [];
    }
  }

  private static parseJsonObject(json: string): Record<string, Object> | null {
    if (json.length === 0) {
      return null;
    }
    try {
      return JSON.parse(json) as Record<string, Object>;
    } catch (_) {
      return null;
    }
  }

  /**
   * 读取所有角色的养成计算数据
   */
  async getAllComputeData(accountId: string, roleUid: string): Promise<GenshinCharacterComputeRow[]> {
    return this.characterComputeDao.findAll(accountId, roleUid);
  }

  /**
   * batch_compute 的 data → GenshinCharacterComputeRow[]（字段原样，不做任何计算）。
   *
   * 响应结构（参考 TeyvatGuide Calculate.d.ts）：
   * - data.items[i]：第 i 个请求项的材料，不带 avatar_id，按请求顺序与 requestItems 对应
   * - data.single_role_result[i]：第 i 个角色单独计算的完整结果（含 overall_consume，lack_num 为该角色的真实缺口）
   * avatarId 取自请求参数 requestItems[i].avatar_id。
   */
  private static parseComputeRows(
    accountId: string,
    roleUid: string,
    data: Record<string, Object>,
    requestItems: object[],
  ): GenshinCharacterComputeRow[] {
    const result: GenshinCharacterComputeRow[] = [];
    const now = Math.floor(Date.now() / 1000);
    const respItems = (data['items'] ?? []) as Record<string, Object>[];
    const singles = (data['single_role_result'] ?? []) as Record<string, Object>[];
    const useSingles = singles.length === requestItems.length;

    if (respItems.length !== requestItems.length) {
      Logger.warn(CALC_TAG, `[Rows] response items=${respItems.length} != request items=${requestItems.length}, map by index anyway`);
    }
    if (!useSingles) {
      Logger.warn(CALC_TAG, `[Rows] single_role_result=${singles.length} != request items=${requestItems.length}, overall_consume_json will be empty`);
    }

    const count = Math.min(respItems.length, requestItems.length);
    for (let i = 0; i < count; i++) {
      const avatarId = GenshinRepository.extractAvatarId(requestItems[i] as Record<string, Object>);
      if (avatarId.length === 0 || avatarId === '0') {
        continue;
      }
      const item = respItems[i];
      const single = useSingles ? singles[i] : null;

      const row = new GenshinCharacterComputeRow();
      row.accountId = accountId;
      row.roleUid = roleUid;
      row.avatarId = avatarId;
      row.updateTime = now;
      row.avatarConsumeJson = JSON.stringify(item['avatar_consume'] ?? []);
      // TeyvatGuide 类型为 avatar_skill_consume；旧解析器注释称实际返回 skill_consume，两者都接受（[Rows] 日志会打印实际字段名）
      row.avatarSkillConsumeJson = JSON.stringify(item['avatar_skill_consume'] ?? item['skill_consume'] ?? []);
      row.weaponConsumeJson = JSON.stringify(item['weapon_consume'] ?? []);
      row.skillsConsumeJson = JSON.stringify(item['skills_consume'] ?? []);
      row.overallConsumeJson = single !== null ? JSON.stringify(single['overall_consume'] ?? []) : '';
      row.rawJson = JSON.stringify(single ?? item);
      result[result.length] = row;

      Logger.info(CALC_TAG, `[Rows] item[${i}] avatarId=${avatarId}: keys=${Object.keys(item).join(',')}, ` +
        `single=${single !== null ? Object.keys(single).join(',') : 'none'}`);
    }
    return result;
  }

  /** batch_compute 的 data → GenshinComputeSummaryRow（顶层字段原样存储） */
  private static parseComputeSummary(
    accountId: string,
    roleUid: string,
    data: Record<string, Object>,
    requestItems: object[],
  ): GenshinComputeSummaryRow {
    const row = new GenshinComputeSummaryRow();
    row.accountId = accountId;
    row.roleUid = roleUid;
    row.avatarIds = requestItems.map((it: object) => GenshinRepository.extractAvatarId(it as Record<string, Object>)).join(',');
    row.overallConsumeJson = JSON.stringify(data['overall_consume'] ?? []);
    row.overallMaterialConsumeJson = data['overall_material_consume'] !== undefined ? JSON.stringify(data['overall_material_consume']) : '';
    row.availableMaterialJson = JSON.stringify(data['available_material'] ?? []);
    row.hasUserInfo = data['has_user_info'] === true ? 1 : 0;
    row.rawJson = JSON.stringify(data);
    row.updateTime = Math.floor(Date.now() / 1000);
    return row;
  }

  /** data.available_material → 材料背包行（同一材料以最后一批为准） */
  private static collectAvailableMaterials(data: Record<string, Object>, out: Map<string, MaterialBagRow>): void {
    const list = (data['available_material'] ?? []) as Record<string, Object>[];
    for (let i = 0; i < list.length; i++) {
      const m = list[i];
      const row = new MaterialBagRow();
      row.materialId = `${m['id'] ?? ''}`;
      row.materialName = `${m['name'] ?? ''}`;
      row.materialIcon = `${m['icon'] ?? m['icon_url'] ?? ''}`;
      row.rarity = `${m['level'] ?? ''}`;
      row.count = GenshinRepository.toNum(m['num']);
      row.source = 'api';
      if (row.materialId.length > 0) {
        out.set(row.materialId, row);
      }
    }
  }

  /**
   * 从请求参数中提取 avatarId
   */
  private static extractAvatarId(reqItem: Record<string, Object>): string {
    const avatarId = reqItem['avatar_id'];
    if (typeof avatarId === 'number') {
      return `${avatarId}`;
    } else if (typeof avatarId === 'string') {
      return avatarId;
    }
    return '';
  }

  // ── 解析方法 ─────────────────────────────────────────────────

  static parseCharacterList(accountId: string, roleUid: string, resp: object): GenshinCharacterListRow[] {
    const result: GenshinCharacterListRow[] = [];
    try {
      Logger.info('💥 GenshinRepository', `parseCharacterList: accountId=${accountId}, roleUid=${roleUid}`);
      const respRecord = resp as Record<string, object>;
      Logger.info('💥 GenshinRepository', `parseCharacterList: respRecord keys=${Object.keys(respRecord).join(',')}`);
      // 🔍 诊断：记录 retcode 和 message
      const retcode = respRecord['retcode'];
      const message = respRecord['message'];
      Logger.info('💥 GenshinRepository', `parseCharacterList: retcode=${retcode}, message=${message}`);
      const dataObj = respRecord['data'] !== undefined ? respRecord['data'] : resp;
      Logger.info('💥 GenshinRepository', `parseCharacterList: dataObj type=${typeof dataObj}, is null=${dataObj === null}`);
      if (dataObj && typeof dataObj === 'object') {
        Logger.info('💥 GenshinRepository', `parseCharacterList: dataObj keys=${Object.keys(dataObj as Record<string, object>).join(',')}`);
      }
      const data = dataObj as GenshinCharacterListData;
      const list = data.list;
      Logger.info('💥 GenshinRepository', `parseCharacterList: list=${list ? list.length : 'null'}`);
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
