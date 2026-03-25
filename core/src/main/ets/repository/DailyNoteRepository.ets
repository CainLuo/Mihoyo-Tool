/**
 * DailyNoteRepository.ets
 *
 * 实时便笺数据 Repository。
 * 负责从网络拉取各游戏的 daily_note 数据，解析后写入 game_data 表。
 *
 * 数据流：
 *   NetworkFactory.getInstance().get(url) → 解析 JSON → GameDataDao.upsert()
 *
 * 调用方（entry ViewModel）只需调用：
 *   await DailyNoteRepository.syncDailyNote(gameId, roleUid, cookie)
 *   const row = await DailyNoteRepository.findDailyNote(gameId, roleUid)
 *
 * 注意：
 *   - 不得在此处判断 isMock，网络实现由 NetworkFactory 透明切换
 *   - extra_int1 = 当前值（树脂/开拓力），extra_int2 = 最大值
 */

import { NetworkFactory } from '../network/NetworkFactory';
import { RequestOptions, RequestParams } from '../network/APIs';
import { GameDataDao } from '../database/GameDataDao';
import { SyncMetaDao } from '../database/SyncMetaDao';
import { GameDataRow, DataType } from '../models/GameDataRow';

// ─── API 路径常量 ────────────────────────────────────────────────

/** 各游戏 daily_note API 路径（相对于 baseUrl） */
const API_GENSHIN_DAILY_NOTE = '/game_record/app/genshin/api/dailyNote';
const API_STARRAIL_DAILY_NOTE = '/game_record/app/hkrpg/api/note';
const API_ZZZ_DAILY_NOTE = '/game_record/app/zzz/api/note';

// ─── 响应接口（仅声明需要的字段，ArkTS 严格模式要求） ────────────

/** 原神 daily_note 响应 data 字段 */
interface GenshinNoteData {
  current_resin: number;
  max_resin: number;
  resin_recovery_time: string;
  finished_task_num: number;
  total_task_num: number;
}

/** 星穹铁道 daily_note 响应 data 字段 */
interface StarRailNoteData {
  current_stamina: number;
  max_stamina: number;
  stamina_recover_time: number;
  current_reserve_stamina: number;
  is_reserve_stamina_full: boolean;
  current_train_score: number;
  max_train_score: number;
  current_rogue_score: number;
  max_rogue_score: number;
  weekly_cocoon_cnt: number;
  weekly_cocoon_limit: number;
  rogue_tourn_weekly_cur: number;
  rogue_tourn_weekly_max: number;
}

/** 绝区零 daily_note 响应 data 字段 */
interface ZZZNoteData {
  energy: ZZZEnergy;
}

interface ZZZEnergy {
  progress: ZZZEnergyProgress;
}

interface ZZZEnergyProgress {
  current: number;
  max: number;
}

/** 通用 API 响应包装 */
interface ApiResponse {
  retcode: number;
  message: string;
  data: object;
}

// ─── Repository ──────────────────────────────────────────────────

export class DailyNoteRepository {

  /**
   * 从网络拉取指定游戏角色的 daily_note，解析后写入 game_data 表。
   *
   * @param gameId   游戏标识（"genshin" / "starrail" / "zzz"）
   * @param roleUid  游戏内 UID
   * @param server   服务器标识（用于构造请求参数）
   * @param cookie   账号 Cookie（通过 RequestOptions.extraHeaders 注入）
   * @throws 网络失败或 retcode != 0 时抛出 Error
   */
  static async syncDailyNote(
    gameId: string,
    roleUid: string,
    server: string,
    cookie: string
  ): Promise<void> {
    const apiUrl = DailyNoteRepository.getApiUrl(gameId);
    if (apiUrl === '') {
      throw new Error(`DailyNoteRepository: unsupported gameId "${gameId}"`);
    }

    // 标记同步中（持久化，App 重启后可感知）
    try {
      await SyncMetaDao.markSyncing(gameId, roleUid, DataType.DAILY_NOTE);
    } catch (_) {}

    const options = new RequestOptions();
    options.extraHeaders.set('Cookie', cookie);

    const params = DailyNoteRepository.buildParams(gameId, roleUid, server);
    let raw: object;
    try {
      raw = await NetworkFactory.getInstance().get(apiUrl, params, options);
    } catch (error) {
      const msg = error instanceof Error ? error.message : `${error}`;
      try {
        await SyncMetaDao.markFailed(gameId, roleUid, DataType.DAILY_NOTE, msg);
      } catch (_) {}
      throw new Error(msg);
    }

    const resp = raw as ApiResponse;
    if (resp.retcode !== 0) {
      const errMsg = `DailyNoteRepository: API error retcode=${resp.retcode} msg=${resp.message}`;
      try {
        await SyncMetaDao.markFailed(gameId, roleUid, DataType.DAILY_NOTE, errMsg);
      } catch (_) {}
      throw new Error(errMsg);
    }

    // 用整个响应的 JSON 字符串提取 data 部分，避免 object 类型导致字段丢失
    const rawJsonStr = JSON.stringify(raw);
    const rawParsed = JSON.parse(rawJsonStr) as Record<string, object>;
    const dataJson = JSON.stringify(rawParsed['data'] ?? {});
    const row = DailyNoteRepository.parseToRow(gameId, roleUid, resp.data, dataJson);
    await GameDataDao.upsert(row);

    // 标记同步成功，更新 last_sync_time
    try {
      await SyncMetaDao.markSuccess(gameId, roleUid, DataType.DAILY_NOTE);
    } catch (_) {}
  }

  /**
   * 携带 Geetest 验证结果重试 syncDailyNote。
   * 在 Geetest 校验成功后，用新 challenge + validate + seccode 注入请求头重试。
   *
   * @param gameId      游戏标识
   * @param roleUid     游戏内 UID
   * @param server      服务器标识
   * @param cookie      账号 Cookie
   * @param challenge   verifyVerification 返回的新 challenge
   * @param validate    geetest_validate
   * @param seccode     geetest_seccode
   */
  static async syncDailyNoteWithChallenge(
    gameId: string,
    roleUid: string,
    server: string,
    cookie: string,
    challenge: string,
    validate: string,
    seccode: string
  ): Promise<void> {
    const apiUrl = DailyNoteRepository.getApiUrl(gameId);
    if (apiUrl === '') {
      throw new Error(`DailyNoteRepository: unsupported gameId "${gameId}"`);
    }

    try {
      await SyncMetaDao.markSyncing(gameId, roleUid, DataType.DAILY_NOTE);
    } catch (_) {}

    const options = new RequestOptions();
    options.extraHeaders.set('Cookie', cookie);
    options.extraHeaders.set('x-rpc-challenge', challenge);
    options.extraHeaders.set('x-rpc-validate', validate);
    options.extraHeaders.set('x-rpc-seccode', seccode);

    const params = DailyNoteRepository.buildParams(gameId, roleUid, server);
    let raw: object;
    try {
      raw = await NetworkFactory.getInstance().get(apiUrl, params, options);
    } catch (error) {
      const msg = error instanceof Error ? error.message : `${error}`;
      try {
        await SyncMetaDao.markFailed(gameId, roleUid, DataType.DAILY_NOTE, msg);
      } catch (_) {}
      throw new Error(msg);
    }

    const resp = raw as ApiResponse;
    if (resp.retcode !== 0) {
      const errMsg = `DailyNoteRepository: API error retcode=${resp.retcode} msg=${resp.message}`;
      try {
        await SyncMetaDao.markFailed(gameId, roleUid, DataType.DAILY_NOTE, errMsg);
      } catch (_) {}
      throw new Error(errMsg);
    }

    const rawJsonStr2 = JSON.stringify(raw);
    const rawParsed2 = JSON.parse(rawJsonStr2) as Record<string, object>;
    const dataJson2 = JSON.stringify(rawParsed2['data'] ?? {});
    const row = DailyNoteRepository.parseToRow(gameId, roleUid, resp.data, dataJson2);
    await GameDataDao.upsert(row);

    try {
      await SyncMetaDao.markSuccess(gameId, roleUid, DataType.DAILY_NOTE);
    } catch (_) {}
  }

  /**
   * 从本地 DB 读取 daily_note 行（不触发网络请求）。
   * 返回 null 表示尚未同步过。
   */
  static async findDailyNote(
    gameId: string,
    roleUid: string
  ): Promise<GameDataRow | null> {
    return GameDataDao.findOne(gameId, roleUid, DataType.DAILY_NOTE, 'daily_note');
  }

  // ─── 私有方法 ────────────────────────────────────────────────

  private static getApiUrl(gameId: string): string {
    if (gameId === 'genshin') {
      return API_GENSHIN_DAILY_NOTE;
    }
    if (gameId === 'starrail') {
      return API_STARRAIL_DAILY_NOTE;
    }
    if (gameId === 'zzz') {
      return API_ZZZ_DAILY_NOTE;
    }
    return '';
  }

  private static buildParams(
    gameId: string,
    roleUid: string,
    server: string
  ): RequestParams {
    const p = new RequestParams();
    p.set('role_id', roleUid);
    p.set('server', server);
    if (gameId === 'genshin') {
      p.set('schedule_type', 1);
    }
    return p;
  }

  /**
   * 将 API 响应 data 解析为 GameDataRow。
   * extra_int1 = 当前值，extra_int2 = 最大值（与 database-architecture.md 约定一致）
   */
  private static parseToRow(
    gameId: string,
    roleUid: string,
    data: object,
    rawJson: string
  ): GameDataRow {
    const row = new GameDataRow();
    row.gameId = gameId;
    row.roleUid = roleUid;
    row.dataType = DataType.DAILY_NOTE;
    row.entityId = 'daily_note';
    row.rawJson = rawJson;
    row.updateTime = Math.floor(Date.now() / 1000);

    if (gameId === 'genshin') {
      const d = data as GenshinNoteData;
      row.extraInt1 = d.current_resin;
      row.extraInt2 = d.max_resin;
    } else if (gameId === 'starrail') {
      const d = data as StarRailNoteData;
      row.extraInt1 = d.current_stamina;
      row.extraInt2 = d.max_stamina;
    } else if (gameId === 'zzz') {
      const d = data as ZZZNoteData;
      row.extraInt1 = d.energy.progress.current;
      row.extraInt2 = d.energy.progress.max;
    }

    return row;
  }
}
