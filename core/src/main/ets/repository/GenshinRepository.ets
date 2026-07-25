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
    try {
      const resp = await (this.getService() as GenshinApiService).batchCompute(items, uid, region, cookie);
      // 传入请求参数 items，用于按索引提取 avatar_id
      const rows = GenshinRepository.parseComputeResult(accountId, roleUid, resp, items);
      await this.runInTransaction(async () => {
        for (let i = 0; i < rows.length; i++) {
          await this.characterComputeDao.upsert(rows[i]);
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
   * 注意：API 响应中的 items 数组顺序与请求参数中的 items 数组顺序是一一对应的，
   * 但响应本身不包含 avatar_id，需要从请求参数中提取。
   * 
   * @param accountId 米游社账号 UID
   * @param roleUid 游戏角色 UID
   * @param resp API 响应对象
   * @param requestItems 请求参数中的 items 数组（可选，用于提取 avatar_id）
   */
  static parseComputeResult(accountId: string, roleUid: string, resp: object, requestItems?: object[]): GenshinCharacterComputeRow[] {
    const result: GenshinCharacterComputeRow[] = [];
    try {
      const respRecord = resp as Record<string, object>;
      const dataObj = respRecord['data'] !== undefined ? respRecord['data'] : resp;
      const data = dataObj as Record<string, object>;
      // API 返回 items 字段（v3 API）或 list 字段（旧版）
      const list = (data['items'] ?? data['list']) as Record<string, object>[];
      
      // 日志：响应数据结构
      Logger.info('GenshinRepository', `parseComputeResult: data keys=${Object.keys(data).join(',')}`);
      Logger.info('GenshinRepository', `parseComputeResult: list=${list !== undefined && list !== null ? 'exists' : 'null'}, length=${list?.length ?? 0}`);
      
      if (!list || list.length === 0) { return result; }

      const now = Math.floor(Date.now() / 1000);
      for (let i = 0; i < list.length; i++) {
        const item = list[i];
        
        // 优先从响应中读取 avatar_id（部分 API 版本会返回）
        let avatarId = `${item['avatar_id'] ?? ''}`;
        
        // 如果响应中没有 avatar_id，尝试从请求参数中按索引获取
        if ((avatarId.length === 0 || avatarId === '0' || avatarId === 'undefined') && requestItems && i < requestItems.length) {
          const requestItem = requestItems[i] as Record<string, object>;
          const reqAvatarId = requestItem['avatar_id'];
          if (typeof reqAvatarId === 'number') {
            avatarId = `${reqAvatarId}`;
          } else if (typeof reqAvatarId === 'string') {
            avatarId = reqAvatarId;
          }
        }
        
        // 日志：每个 item 的 avatar_id
        if (i < 3) {
          Logger.info('GenshinRepository', `parseComputeResult: item[${i}] avatar_id=${avatarId}`);
        }
        
        // 如果没有 avatar_id，跳过此条（无法关联到角色）
        if (avatarId.length === 0 || avatarId === '0' || avatarId === 'undefined') { continue; }

        const row = new GenshinCharacterComputeRow();
        row.accountId = accountId;
        row.roleUid = roleUid;
        row.avatarId = avatarId;
        row.rawJson = JSON.stringify(item);
        row.updateTime = now;

        // 提取各部分的 consume JSON
        const avatarConsume = item['avatar_consume'] as Record<string, object>[] | null;
        row.avatarConsumeJson = avatarConsume ? JSON.stringify(avatarConsume) : '';

        const skillConsume = item['skill_consume'] as Record<string, object>[] | null;
        row.skillConsumeJson = skillConsume ? JSON.stringify(skillConsume) : '';

        const weaponConsume = item['weapon_consume'] as Record<string, object>[] | null;
        row.weaponConsumeJson = weaponConsume ? JSON.stringify(weaponConsume) : '';

        result[result.length] = row;
      }
      
      Logger.info('GenshinRepository', `parseComputeResult: result.length=${result.length}`);
    } catch (e) {
      Logger.error('GenshinRepository', `parseComputeResult error: ${e}`);
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
