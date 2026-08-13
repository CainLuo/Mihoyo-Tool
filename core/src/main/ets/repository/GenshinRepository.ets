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
  GenshinCharacterComputeRow,
  GenshinWeaponItem,
  GenshinCharacterItem,
  GenshinCharacterListData,
} from '../models/GenshinRows';
import { GenshinApiService } from '../network/GenshinApiService';
import { AuthExpiredError } from '../errors/ApiErrors';
import { CookieRefreshCoordinator } from '../cookie/CookieRefreshCoordinator';
import { Logger } from '../utils/Logger';
import { CoreInitializer } from '../CoreInitializer';
import { BBSRepository } from './BBSRepository';

// ─── 解析用本地 interface ────────────────────────────────────────

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
      if (error instanceof AuthExpiredError) {
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
          // 刷新失败或重试仍失败，向上抛出 AuthExpiredError
          const msg = this.toErrorMessage(refreshError);
          await this.markFailed(accountId, roleUid, SyncDataType.GENSHIN_DAILY_NOTE, msg);
          if (refreshError instanceof AuthExpiredError) {
            throw refreshError;
          }
          throw new AuthExpiredError(msg);
        }
      }
      const msg = this.toErrorMessage(error);
      await this.markFailed(accountId, roleUid, SyncDataType.GENSHIN_DAILY_NOTE, msg);
      throw new Error(msg);
    }
  }

  private async doSyncDailyNote(accountId: string, roleUid: string, server: string, cookie: string, geetestChallenge?: string): Promise<void> {
    const resp = await (this.getService() as GenshinApiService).getDailyNote(roleUid, server, cookie, geetestChallenge);
    const respData = resp as Record<string, object>;
    const retcodeStr = `${respData['retcode'] ?? ''}`;
    if (retcodeStr === '-100' || retcodeStr === '10001' || retcodeStr === '-10001') {
      throw new AuthExpiredError(`retcode=${retcodeStr}`);
    }
    if (retcodeStr === '1034' || retcodeStr === '10035') {
      // 1034/10035：尝试降级到 Widget API
      // 参考 PizzaHelperUnited 抓包：Widget 接口用完整 cookie（含 ltuid/ltoken），不是精简的 widgetCookie
      const widgetCookie = BBSRepository.buildWidgetCookie(cookie);
      if (widgetCookie.length > 0) {
        await this.doSyncDailyNoteWidget(accountId, roleUid, cookie);
        // Widget 降级成功，标记为 success
        await this.markSuccess(accountId, roleUid, SyncDataType.GENSHIN_DAILY_NOTE);
        return;
      }
      throw new Error(`retcode=${retcodeStr}: Geetest verification required and no widget cookie available`);
    }
    if (respData['data'] === null || respData['data'] === undefined) {
      throw new Error(`retcode=${retcodeStr}: ${respData['message'] ?? 'no data'}`);
    }
    const dataObj = respData['data'] !== undefined ? respData['data'] : resp;
    const row = this.parseDailyNoteData(accountId, roleUid, dataObj);
    await this.upsertDailyNote(accountId, roleUid, row);
  }

  /**
   * Widget API 降级同步便笺（原神 /aapi/widget/v2）
   * Widget 返回字段是普通便笺的子集，只更新有对应字段的数据
   */
  private async doSyncDailyNoteWidget(accountId: string, roleUid: string, widgetCookie: string): Promise<void> {
    const resp = await (this.getService() as GenshinApiService).getDailyNoteWidget(widgetCookie);
    const respData = resp as Record<string, object>;
    const retcodeStr = `${respData['retcode'] ?? ''}`;
    if (retcodeStr !== '0' && retcodeStr !== '') {
      throw new Error(`Widget API failed: retcode=${retcodeStr}: ${respData['message'] ?? 'no data'}`);
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
   * 批量计算角色养成材料 → 解析 → 写 DB
   * 原神 API 一次最多处理 8 个角色，需要分批请求。
   * @param items 计算项数组（每项包含 avatar_id、等级、技能等级等）
   * @param uid 游戏 UID
   * @param region 服务器（如 'cn_gf01'）
   * @param cookie 登录 Cookie
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
    
    const BATCH_SIZE = 8; // 原神 API 一次最多处理 8 个角色
    const allRows: GenshinCharacterComputeRow[] = [];
    
    try {
      // 分批处理
      for (let batchStart = 0; batchStart < items.length; batchStart += BATCH_SIZE) {
        const batchEnd = Math.min(batchStart + BATCH_SIZE, items.length);
        const batchItems = items.slice(batchStart, batchEnd);
        
        Logger.info('GenshinRepository', `syncAvatarCompute: batch ${Math.floor(batchStart / BATCH_SIZE) + 1}, items ${batchStart}-${batchEnd - 1}`);
        
        const resp = await (this.getService() as GenshinApiService).batchCompute(batchItems, uid, region, cookie);
        const rows = GenshinRepository.parseComputeResult(accountId, roleUid, resp, batchItems);
        
        for (let i = 0; i < rows.length; i++) {
          allRows[allRows.length] = rows[i];
        }
      }
      
      Logger.info('GenshinRepository', `syncAvatarCompute: total rows=${allRows.length}`);
      
      await this.runInTransaction(async () => {
        for (let i = 0; i < allRows.length; i++) {
          await this.characterComputeDao.upsert(allRows[i]);
        }
        await this.markSuccess(accountId, roleUid, SyncDataType.GENSHIN_CHARACTER_COMPUTE);
      });
    } catch (error) {
      const msg = this.toErrorMessage(error);
      await this.markFailed(accountId, roleUid, SyncDataType.GENSHIN_CHARACTER_COMPUTE, msg);
      throw new Error(msg);
    }
  }

  /**
   * 读取所有角色的养成计算数据
   */
  async getAllComputeData(accountId: string, roleUid: string): Promise<GenshinCharacterComputeRow[]> {
    return this.characterComputeDao.findAll(accountId, roleUid);
  }

  /**
   * 解析批量计算 API 响应为 GenshinCharacterComputeRow 数组
   * 
   * API 响应结构：
   * - data.items[]: 所有角色的材料模板（lack_num 全是 0，无用）
   * - data.overall_consume: 所有角色的汇总缺口（批量请求时）
   * - data.single_role_result[i].items[]: 单个角色的材料模板
   * - data.single_role_result[i].overall_consume: 单个角色的真实缺口（lack_num 有值）
   * 
   * 正确做法：
   * 1. 批量请求时，从 single_role_result[i].overall_consume 提取真实 lack_num
   * 2. 单角色请求时，从 data.overall_consume 提取真实 lack_num
   * 3. 用真实 lack_num 覆盖 items 中的 0 值
   * 
   * @param accountId 米游社账号 UID
   * @param roleUid 游戏角色 UID
   * @param resp API 响应对象
   * @param requestItems 请求参数中的 items 数组（可选，用于提取 avatar_id）
   */
  static parseComputeResult(accountId: string, roleUid: string, resp: object, requestItems?: object[]): GenshinCharacterComputeRow[] {
    const result: GenshinCharacterComputeRow[] = [];
    try {
      const respRecord = resp as Record<string, Object>;
      const dataObj = respRecord['data'] !== undefined ? respRecord['data'] : resp;
      const data = dataObj as Record<string, Object>;
      
      // 日志：响应数据结构
      Logger.info('GenshinRepository', `parseComputeResult: data keys=${Object.keys(data).join(',')}`);
      
      // 检查是否有 single_role_result（批量请求返回此字段）
      const singleRoleResult = data['single_role_result'] as Record<string, Object>[] | null;
      
      // 获取 overall_consume（真实缺口数据）
      const overallConsume = data['overall_consume'] as Record<string, Object>[] | null;
      Logger.info('GenshinRepository', `parseComputeResult: overallConsume length=${overallConsume?.length ?? 0}`);
      
      // 检查 items 数组（模板数据，包含 avatar_consume、skill_consume、weapon_consume 分类）
      const items = data['items'] as Record<string, Object>[] | null;
      Logger.info('GenshinRepository', `parseComputeResult: items length=${items?.length ?? 0}`);
      
      // 如果 items 为空且 requestItems 存在，说明是批量请求但返回的 items 为空
      // 此时需要从 requestItems 构建（批量请求模式）
      if ((items === null || items === undefined || items.length === 0) && 
          requestItems !== undefined && requestItems.length > 0) {
        Logger.info('GenshinRepository', `parseComputeResult: no items, using requestItems (length=${requestItems.length})`);
        
        // 批量请求模式：从 requestItems 获取 avatar_id，从 overall_consume 获取材料数据
        const lackNumMap = GenshinRepository.buildLackNumMap(overallConsume);
        
        for (let i = 0; i < requestItems.length; i++) {
          const reqItem = requestItems[i] as Record<string, Object>;
          const reqAvatarId = reqItem['avatar_id'];
          
          let avatarId = '';
          if (typeof reqAvatarId === 'number') {
            avatarId = `${reqAvatarId}`;
          } else if (typeof reqAvatarId === 'string') {
            avatarId = reqAvatarId;
          }
          
          if (avatarId.length === 0 || avatarId === '0') {
            continue;
          }
          
          const now = Math.floor(Date.now() / 1000);
          const row = new GenshinCharacterComputeRow();
          row.accountId = accountId;
          row.roleUid = roleUid;
          row.avatarId = avatarId;
          row.updateTime = now;
          
          // 从请求参数中提取技能和武器信息
          const skillList = reqItem['skill_list'] as Record<string, Object>[] | null;
          const weapon = reqItem['weapon'] as Record<string, Object> | null;
          
          // 使用 overall_consume 构建 rawJson（因为 items 为空）
          // 但需要按类型分类存储到各个字段
          // 由于 overall_consume 是汇总数据，无法区分角色/技能/武器材料
          // 暂时存储为 avatar_consume（后续可以根据材料 ID 范围分类）
          
          const avatarMaterials: Record<string, Object>[] = [];
          const skillMaterials: Record<string, Object>[] = [];
          const weaponMaterials: Record<string, Object>[] = [];
          
          if (overallConsume !== null && overallConsume !== undefined) {
            for (let j = 0; j < overallConsume.length; j++) {
              const mat = overallConsume[j];
              const matCopy: Record<string, Object> = {};
              const keys = Object.keys(mat);
              for (let k = 0; k < keys.length; k++) {
                matCopy[keys[k]] = mat[keys[k]];
              }
              
              // 简单分类：根据材料 ID 范围判断
              const matId = mat['id'];
              if (typeof matId === 'number') {
                // 104xxx: 经验书、摩拉
                // 112xxx: 怪物掉落材料
                // 113xxx: 周本材料
                // 1043xx: 天赋书
                if (matId >= 104300 && matId < 104400) {
                  skillMaterials[skillMaterials.length] = matCopy;
                } else {
                  avatarMaterials[avatarMaterials.length] = matCopy;
                }
              } else {
                avatarMaterials[avatarMaterials.length] = matCopy;
              }
            }
          }
          
          row.avatarConsumeJson = JSON.stringify(avatarMaterials);
          row.skillConsumeJson = JSON.stringify(skillMaterials);
          row.weaponConsumeJson = JSON.stringify(weaponMaterials);
          
          // rawJson 存储完整数据
          const rawData: Record<string, Object> = {
            'avatar_id': avatarId,
            'avatar_consume': avatarMaterials,
            'skill_consume': skillMaterials,
            'weapon_consume': weaponMaterials,
            'overall_consume': overallConsume ?? []
          };
          row.rawJson = JSON.stringify(rawData);
          
          result[result.length] = row;
          Logger.info('GenshinRepository', `parseComputeResult: created row for avatarId=${avatarId} from requestItems`);
        }
      } else if (items !== null && items !== undefined && items.length > 0) {
        // items 不为空：从 items 提取数据（单角色或批量模式）
        Logger.info('GenshinRepository', `parseComputeResult: processing items (length=${items.length})`);
        
        const lackNumMap = GenshinRepository.buildLackNumMap(overallConsume);
        
        for (let i = 0; i < items.length; i++) {
          const item = items[i];
          const row = GenshinRepository.buildComputeRow(accountId, roleUid, item, requestItems, i, lackNumMap);
          if (row !== null) {
            result[result.length] = row;
          }
        }
      } else {
        Logger.warn('GenshinRepository', `parseComputeResult: no items and no requestItems, cannot parse`);
      }
      
      Logger.info('GenshinRepository', `parseComputeResult: result.length=${result.length}`);
    } catch (e) {
      Logger.error('GenshinRepository', `parseComputeResult error: ${e}`);
    }
    return result;
  }
  
  /**
   * 构建 materialId -> lackNum 的映射表
   */
  private static buildLackNumMap(overallConsume: Record<string, Object>[] | null): Map<number, number> {
    const map: Map<number, number> = new Map();
    if (overallConsume === null || overallConsume === undefined) {
      return map;
    }
    
    for (let i = 0; i < overallConsume.length; i++) {
      const mat = overallConsume[i];
      const id = mat['id'];
      const lackNum = mat['lack_num'];
      if (typeof id === 'number' && typeof lackNum === 'number') {
        map.set(id, lackNum);
      }
    }
    return map;
  }
  
  /**
   * 构建单个 GenshinCharacterComputeRow
   * 使用 lackNumMap 覆盖材料数据中的 lack_num
   */
  private static buildComputeRow(
    accountId: string,
    roleUid: string,
    item: Record<string, Object>,
    requestItems: object[] | undefined,
    index: number,
    lackNumMap: Map<number, number>
  ): GenshinCharacterComputeRow | null {
    // 优先从响应中读取 avatar_id
    let avatarId = `${item['avatar_id'] ?? ''}`;
    
    // 如果响应中没有 avatar_id，尝试从请求参数中按索引获取
    if ((avatarId.length === 0 || avatarId === '0' || avatarId === 'undefined') && requestItems !== undefined && index < requestItems.length) {
      const requestItem = requestItems[index] as Record<string, Object>;
      const reqAvatarId = requestItem['avatar_id'];
      if (typeof reqAvatarId === 'number') {
        avatarId = `${reqAvatarId}`;
      } else if (typeof reqAvatarId === 'string') {
        avatarId = reqAvatarId;
      }
    }
    
    // 如果没有 avatar_id，跳过此条
    if (avatarId.length === 0 || avatarId === '0' || avatarId === 'undefined') {
      return null;
    }
    
    const now = Math.floor(Date.now() / 1000);
    const row = new GenshinCharacterComputeRow();
    row.accountId = accountId;
    row.roleUid = roleUid;
    row.avatarId = avatarId;
    row.updateTime = now;
    
    // 提取各部分的 consume JSON，并用 lackNumMap 覆盖 lack_num
    const avatarConsume = item['avatar_consume'] as Record<string, Object>[] | null;
    row.avatarConsumeJson = avatarConsume !== null ? JSON.stringify(GenshinRepository.mergeLackNum(avatarConsume, lackNumMap)) : '';
    
    const skillConsume = (item['skill_consume'] ?? item['avatar_skill_consume']) as Record<string, Object>[] | null;
    row.skillConsumeJson = skillConsume !== null ? JSON.stringify(GenshinRepository.mergeLackNum(skillConsume, lackNumMap)) : '';
    
    const weaponConsume = item['weapon_consume'] as Record<string, Object>[] | null;
    row.weaponConsumeJson = weaponConsume !== null ? JSON.stringify(GenshinRepository.mergeLackNum(weaponConsume, lackNumMap)) : '';
    
    // rawJson 存储合并后的完整 item
    const mergedItem = GenshinRepository.mergeItemLackNum(item, lackNumMap);
    row.rawJson = JSON.stringify(mergedItem);
    
    return row;
  }
  
  /**
   * 合并 lack_num 到材料数组
   */
  private static mergeLackNum(materials: Record<string, Object>[] | null, lackNumMap: Map<number, number>): Record<string, Object>[] {
    if (materials === null || materials === undefined) {
      return [];
    }
    
    const result: Record<string, Object>[] = [];
    for (let i = 0; i < materials.length; i++) {
      const mat: Record<string, Object> = {};
      const keys = Object.keys(materials[i]);
      for (let j = 0; j < keys.length; j++) {
        mat[keys[j]] = materials[i][keys[j]];
      }
      
      // 用 lackNumMap 覆盖 lack_num
      const id = mat['id'];
      if (typeof id === 'number' && lackNumMap.has(id)) {
        mat['lack_num'] = lackNumMap.get(id) as Object;
      }
      result[result.length] = mat;
    }
    return result;
  }
  
  /**
   * 合并 lack_num 到整个 item（包括 avatar_consume、skill_consume、weapon_consume）
   */
  private static mergeItemLackNum(item: Record<string, Object>, lackNumMap: Map<number, number>): Record<string, Object> {
    const result: Record<string, Object> = {};
    const keys = Object.keys(item);
    for (let i = 0; i < keys.length; i++) {
      const key = keys[i];
      if (key === 'avatar_consume' || key === 'skill_consume' || key === 'avatar_skill_consume' || key === 'weapon_consume') {
        const materials = item[key] as Record<string, Object>[] | null;
        result[key] = GenshinRepository.mergeLackNum(materials, lackNumMap);
      } else {
        result[key] = item[key];
      }
    }
    return result;
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
