import { RequestParams, RequestOptions } from './APIs';
import { MihoyoApiService } from './MihoyoApiService';
import { MihoyoDomain } from './MihoyoDomain';
import { GenshinApiPath } from './GenshinApiPath';
import { MihoyoHeaderBuilder, HeaderProfile } from './MihoyoHeaderBuilder';
import { ApiConfig } from './ApiConfig';
import { HKey } from './MihoyoHeaderKey';
import { HttpClient } from './HttpClient';
import { Logger } from '../utils/Logger';

/** 养成计算链路统一日志 tag，过滤：hilog | grep */
const CALC_TAG: string = 'GenshinCalc';
/** 分段长度（字符数，中文按 3 字节算也低于 hilog 4KB 上限） */
const CALC_LOG_CHUNK: number = 1000;

export class GenshinApiService extends MihoyoApiService {

  async get(path: string, params?: RequestParams, options?: RequestOptions): Promise<object> {
    return HttpClient.get(path, params, options);
  }

  async post(path: string, data?: string | RequestParams, options?: RequestOptions): Promise<object> {
    return HttpClient.post(path, data, options);
  }

  /** 实时便笺 — GET，Domain=TAKUMI_RECORD，Profile=GAME_RECORD */
  async getDailyNote(roleId: string, server: string, cookie: string, geetestChallenge?: string): Promise<object> {
    const params = new RequestParams();
    params.set('role_id', roleId);
    params.set('server', server);
    const headers = MihoyoHeaderBuilder.build(HeaderProfile.GAME_RECORD, cookie, params);
    headers.set(HKey.TOOL_VERSION, ApiConfig.TOOL_VERSION_GENSHIN);
    headers.set(HKey.PAGE, ApiConfig.PAGE_GENSHIN_NOTE);
    // Geetest 验证通过后，注入 challenge + challenge_path + challenge_game
    // 参考 PizzaHelperUnited URLRequestConfig.writeXRPCChallengeHeaders4DailyNote
    if (geetestChallenge) {
      headers.set(HKey.CHALLENGE, geetestChallenge);
      headers.set(HKey.CHALLENGE_PATH, 'https://api-takumi-record.mihoyo.com' + GenshinApiPath.DAILY_NOTE);
      headers.set(HKey.CHALLENGE_GAME, '2');
    }
    // ── [MIYOYO-NET] dailyNote 请求 header log ───────────────────────
    Logger.info('GenshinApiService', `[MIYOYO-NET][HOS][DailyNote] URL: ${MihoyoDomain.TAKUMI_RECORD + GenshinApiPath.DAILY_NOTE}?role_id=${roleId}&server=${server}`);
    headers.forEach((v: string, k: string) => {
      const display = k.toLowerCase() === 'cookie' ? v.substring(0, 60) + '...' : v;
      Logger.info('GenshinApiService', `[MIYOYO-NET][HOS][DailyNote] Header ${k}: ${display}`);
    });
    // ─────────────────────────────────────────────────────────────────
    const opts = new RequestOptions();
    opts.extraHeaders = headers;
    const result = await HttpClient.get(
      MihoyoDomain.TAKUMI_RECORD + GenshinApiPath.DAILY_NOTE,
      params,
      opts,
    );
    // ── [MIYOYO-NET] dailyNote response log ──────────────────────────
    Logger.info('GenshinApiService', `[MIYOYO-NET][HOS][DailyNote] Response: ${JSON.stringify(result).substring(0, 300)}`);
    // ─────────────────────────────────────────────────────────────────
    return result;
  }

  /**
   * Widget 实时便笺 — GET，Domain=TAKUMI_RECORD
   * 参考 PizzaHelperUnited 抓包：Widget 接口用普通 GAME_RECORD profile（miHoYoBBS UA、client_type=5、Referer=webstatic）
   * Cookie 传完整 cookie（含 ltuid/ltoken），不是精简的 stuid+stoken+mid
   */
  async getDailyNoteWidget(cookie: string): Promise<object> {
    const headers = MihoyoHeaderBuilder.build(HeaderProfile.GAME_RECORD, cookie);
    // ── [MIYOYO-NET] Widget 请求 header log ──────────────────────────
    Logger.info('GenshinApiService', `[MIYOYO-NET][HOS][Widget] URL: ${MihoyoDomain.TAKUMI_RECORD + GenshinApiPath.DAILY_NOTE_WIDGET}`);
    headers.forEach((v: string, k: string) => {
      const display = k.toLowerCase() === 'cookie' ? v.substring(0, 60) + '...' : v;
      Logger.info('GenshinApiService', `[MIYOYO-NET][HOS][Widget] Header ${k}: ${display}`);
    });
    // ─────────────────────────────────────────────────────────────────
    const opts = new RequestOptions();
    opts.extraHeaders = headers;
    const result = await HttpClient.get(
      MihoyoDomain.TAKUMI_RECORD + GenshinApiPath.DAILY_NOTE_WIDGET,
      undefined,
      opts,
    );
    // ── [MIYOYO-NET] Widget response log ─────────────────────────────
    Logger.info('GenshinApiService', `[MIYOYO-NET][HOS][Widget] Response: ${JSON.stringify(result).substring(0, 300)}`);
    // ─────────────────────────────────────────────────────────────────
    return result;
  }

  /** 角色列表 — POST，Domain=TAKUMI_RECORD，Profile=GAME_RECORD */
  async getCharacterList(roleId: string, server: string, cookie: string): Promise<object> {
    Logger.info('💥 GenshinApiService', `getCharacterList: roleId=${roleId}, server=${server}`);
    const bodyStr = JSON.stringify({ role_id: roleId, server: server });
    const headers = MihoyoHeaderBuilder.build(HeaderProfile.GAME_RECORD, cookie, undefined, bodyStr);
    headers.set(HKey.TOOL_VERSION, ApiConfig.TOOL_VERSION_GENSHIN);
    headers.set(HKey.PAGE, ApiConfig.PAGE_GENSHIN_ROLES);
    const opts = new RequestOptions();
    opts.extraHeaders = headers;
    Logger.info('💥 GenshinApiService', `getCharacterList: calling API`);
    const result = await HttpClient.post(
      MihoyoDomain.TAKUMI_RECORD + GenshinApiPath.CHARACTER_LIST,
      bodyStr,
      opts,
    );
    Logger.info('💥 GenshinApiService', `getCharacterList: response=${JSON.stringify(result).substring(0, 500)}`);
    return result;
  }

  /**
   * 角色详情 — POST，Domain=TAKUMI_RECORD，Profile=GAME_RECORD
   * characterIds 为字符串数组（如 ["10000125"]），传空数组时服务器返回 5003
   */
  async getCharacterDetail(
    roleId: string,
    server: string,
    characterIds: string[],
    cookie: string,
  ): Promise<object> {
    const bodyStr = JSON.stringify({
      role_id: roleId,
      server: server,
      character_ids: characterIds,
    });
    const headers = MihoyoHeaderBuilder.build(HeaderProfile.GAME_RECORD, cookie, undefined, bodyStr);
    headers.set(HKey.TOOL_VERSION, ApiConfig.TOOL_VERSION_GENSHIN);
    // x-rpc-page 需要拼接第一个 avatarId，无 avatarId 时用通用页面
    const pageId = characterIds.length > 0 ? characterIds[0] : '';
    headers.set(HKey.PAGE, pageId.length > 0
      ? ApiConfig.PAGE_GENSHIN_ROLE_DETAIL_PREFIX + pageId
      : ApiConfig.PAGE_GENSHIN_ROLES);
    const opts = new RequestOptions();
    opts.extraHeaders = headers;
    return HttpClient.post(
      MihoyoDomain.TAKUMI_RECORD + GenshinApiPath.CHARACTER_DETAIL,
      bodyStr,
      opts,
    );
  }

  /** 养成材料批量计算 — POST，Domain=TAKUMI，Profile=CALCULATE */
  async batchCompute(
    items: object[],
    uid: string,
    region: string,
    cookie: string,
  ): Promise<object> {
    Logger.info(CALC_TAG, `[BatchCompute] START uid=${uid}, region=${region}, items=${items.length}`);
    // 补充缺失的设备字段（v2 API 必需）
    const enrichedCookie = this.ensureDeviceFields(cookie);

    // 将 items 转换为 JSON 格式（调用 toJSON() 方法如果存在）
    const jsonItems: object[] = [];
    for (let i = 0; i < items.length; i++) {
      const item = items[i];
      // 检查是否有 toJSON 方法
      if (item && typeof (item as Record<string, object>)['toJSON'] === 'function') {
        jsonItems[jsonItems.length] = (item as Record<string, () => object>)['toJSON']() as object;
      } else {
        jsonItems[jsonItems.length] = item;
      }
    }
    const bodyStr = JSON.stringify({
      items: jsonItems,
      lang: 'zh-cn',
      region: region,
      uid: uid,
    });
    const headers = MihoyoHeaderBuilder.build(HeaderProfile.CALCULATE, enrichedCookie, undefined, bodyStr);
    headers.set(HKey.CAL_TYPE, '0');  // TeyvatGuide 使用 "0"
    const url = MihoyoDomain.TAKUMI + GenshinApiPath.BATCH_COMPUTE;
    GenshinApiService.logRequest('BatchCompute', url, headers, bodyStr);

    const opts = new RequestOptions();
    opts.extraHeaders = headers;
    const startTime = Date.now();
    let result: object;
    try {
      result = await HttpClient.post(url, bodyStr, opts);
    } catch (e) {
      Logger.error(CALC_TAG, `[BatchCompute] HTTP FAILED after ${Date.now() - startTime}ms: ${e instanceof Error ? e.message : `${e}`}`);
      throw e as Error;
    }
    // 4 个角色约 70 段；上限 100 段，便于抓取完整返回样本
    GenshinApiService.logResponse('BatchCompute', result, Date.now() - startTime, 100);
    return result;
  }

  /**
   * 养成计算器：同步用户已有角色列表 — POST，Domain=TAKUMI，Profile=CALCULATE
   * 返回的 element_attr_id / skill_list[].group_id / weapon / promote_level
   * 是 batch_compute 唯一可信的参数来源（参考 TeyvatGuide takumiReq.ts syncAvatarList）
   */
  async syncCalcAvatarList(uid: string, region: string, cookie: string, page: number, size: number): Promise<object> {
    Logger.info(CALC_TAG, `[SyncAvatarList] START uid=${uid}, region=${region}, page=${page}, size=${size}`);
    const enrichedCookie = this.ensureDeviceFields(cookie);
    const body = new SyncAvatarListBody();
    body.page = page;
    body.size = size;
    body.region = region;
    body.uid = uid;
    const bodyStr = JSON.stringify(body);
    const headers = MihoyoHeaderBuilder.build(HeaderProfile.CALCULATE, enrichedCookie, undefined, bodyStr);
    // TeyvatGuide 的 sync 请求不带 cal_type
    headers.delete(HKey.CAL_TYPE);
    const url = MihoyoDomain.TAKUMI + GenshinApiPath.SYNC_AVATAR_LIST;
    GenshinApiService.logRequest('SyncAvatarList', url, headers, bodyStr);

    const opts = new RequestOptions();
    opts.extraHeaders = headers;
    const startTime = Date.now();
    let result: object;
    try {
      result = await HttpClient.post(url, bodyStr, opts);
    } catch (e) {
      Logger.error(CALC_TAG, `[SyncAvatarList] HTTP FAILED after ${Date.now() - startTime}ms: ${e instanceof Error ? e.message : `${e}`}`);
      throw e as Error;
    }
    // 全量角色数据很大（200KB+），只打前 2 段，避免触发 hilog 流控丢日志；逐角色摘要见 [Avatar]
    GenshinApiService.logResponse('SyncAvatarList', result, Date.now() - startTime, 2);
    return result;
  }

  /** 🚀 打印请求 URL / 全部 header（含完整 Cookie）/ 完整 body */
  private static logRequest(api: string, url: string, headers: Map<string, string>, bodyStr: string): void {
    Logger.info(CALC_TAG, `[${api}] URL: ${url}`);
    headers.forEach((v: string, k: string) => {
      Logger.info(CALC_TAG, `[${api}] Header ${k}: ${v}`);
    });
    GenshinApiService.logLong(`[${api}] REQUEST body`, bodyStr);
  }

  /** 🚀 打印 retcode / message / 耗时 / 响应（最多 maxChunks 段） */
  private static logResponse(api: string, result: object, costMs: number, maxChunks: number): void {
    const r = result as Record<string, Object>;
    Logger.info(CALC_TAG, `[${api}] RESPONSE retcode=${r['retcode']}, message=${r['message']}, cost=${costMs}ms`);
    GenshinApiService.logLong(`[${api}] RESPONSE body`, JSON.stringify(result), maxChunks);
  }

  /** hilog 单条约 4KB 会被截断，长文本分段打印 */
  private static logLong(label: string, text: string, maxChunks: number = Number.MAX_SAFE_INTEGER): void {
    const total = Math.max(Math.ceil(text.length / CALC_LOG_CHUNK), 1);
    const printCount = Math.min(total, maxChunks);
    for (let i = 0; i < printCount; i++) {
      const part = text.substring(i * CALC_LOG_CHUNK, (i + 1) * CALC_LOG_CHUNK);
      Logger.info(CALC_TAG, `${label} [${i + 1}/${total}] (len=${text.length}): ${part}`);
    }
    if (printCount < total) {
      Logger.info(CALC_TAG, `${label} ... omitted ${total - printCount} chunks`);
    }
  }

  /**
   * 确保 Cookie 包含 v2 API 必需的设备字段
   * 如果缺失，使用真实的设备指纹（从 DeviceFpService 获取）
   * 禁止生成假指纹
   */
  private ensureDeviceFields(cookie: string): string {
    // 检查是否已有 DEVICEFP
    const hasDeviceFp = cookie.includes('DEVICEFP=');
    // 检查是否已有 _MHYUUID
    const hasMhyUuid = cookie.includes('_MHYUUID=');

    if (hasDeviceFp && hasMhyUuid) {
      // 都有，直接返回
      return cookie;
    }

    // 使用真实设备指纹补充缺失字段
    let enriched = cookie;
    if (!hasDeviceFp) {
      const realFp = ApiConfig.getDeviceFp();
      if (realFp.length === 0) {
        Logger.error(CALC_TAG, 'ensureDeviceFields: DEVICEFP missing and no real fingerprint available');
        throw new Error('DEVICEFP is required but no real fingerprint is available. Please ensure DeviceFpService is initialized.');
      }
      enriched += `; DEVICEFP=${realFp}`;
      Logger.info(CALC_TAG, `ensureDeviceFields: added real DEVICEFP=${realFp}`);
    }
    if (!hasMhyUuid) {
      // 使用真实的 device_id 作为 _MHYUUID
      const realUuid = ApiConfig.getDeviceIdSync();
      if (realUuid.length === 0) {
        Logger.error(CALC_TAG, 'ensureDeviceFields: _MHYUUID missing and no device_id available');
        throw new Error('_MHYUUID is required but no device_id is available. Please ensure ApiConfig.preloadDeviceId is called.');
      }
      enriched += `; _MHYUUID=${realUuid}`;
      Logger.info(CALC_TAG, `ensureDeviceFields: added real _MHYUUID=${realUuid}`);
    }

    return enriched;
  }
}

/** sync/avatar/list 请求体（字段顺序与 TeyvatGuide 一致） */
class SyncAvatarListBody {
  element_attr_ids: number[] = [];
  lang: string = 'zh-cn';
  page: number = 1;
  region: string = '';
  size: number = 100;
  uid: string = '';
  weapon_cat_ids: number[] = [];
}
