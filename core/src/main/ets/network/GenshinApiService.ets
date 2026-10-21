import { RequestParams, RequestOptions } from '../base/network/APIs';
import { MihoyoApiService } from '../base/network/MihoyoApiService';
import { MihoyoDomain } from '../base/network/MihoyoDomain';
import { GenshinApiPath } from './GenshinApiPath';
import { MihoyoHeaderBuilder, HeaderProfile } from '../base/network/MihoyoHeaderBuilder';
import { ApiConfig } from '../base/network/ApiConfig';
import { HKey } from '../base/network/MihoyoHeaderKey';
import { GameFpBiz } from '../base/network/DeviceFpService';
import { Logger } from '../base/utils/Logger';

/** 养成计算链路统一日志 tag，过滤：hilog | grep */
const CALC_TAG: string = 'GenshinCalc';
/** 分段长度（字符数，中文按 3 字节算也低于 hilog 4KB 上限） */
const CALC_LOG_CHUNK: number = 1000;

export class GenshinApiService extends MihoyoApiService {

  /** 实时便笺 — GET，Domain=TAKUMI_RECORD，Profile=GAME_RECORD */
  async getDailyNote(roleId: string, server: string, cookie: string, geetestChallenge?: string): Promise<object> {
    const params = new RequestParams();
    params.set('role_id', roleId);
    params.set('server', server);
    // 请求头整套对齐 PizzaHelperUnited fullNote4GI（原神指纹 hk4e_cn）
    const headers = MihoyoHeaderBuilder.buildPizza(cookie, GameFpBiz.GENSHIN, params);
    // Geetest 验证通过后，注入 challenge + challenge_path + challenge_game
    // 参考 PizzaHelperUnited URLRequestConfig.writeXRPCChallengeHeaders4DailyNote
    if (geetestChallenge) {
      headers.set(HKey.CHALLENGE, geetestChallenge);
      headers.set(HKey.CHALLENGE_PATH, 'https://api-takumi-record.mihoyo.com' + GenshinApiPath.DAILY_NOTE);
      headers.set(HKey.CHALLENGE_GAME, '2');
    }
    const opts = new RequestOptions();
    opts.extraHeaders = headers;
    // 便笺 / Widget 不自动上报人机验证：降级 Widget 成功则不弹，由 Repository 在两者都失败后上报
    opts.suppressGeetestReport = true;
    const url = MihoyoDomain.TAKUMI_RECORD + GenshinApiPath.DAILY_NOTE;
    const response = await this.get(url, params, opts);
    this.reportBusinessError(url, response.data, opts, params, undefined, cookie, roleId);
    return response.data;
  }

  /**
   * Widget 实时便笺 — GET，Domain=TAKUMI_RECORD
   * 参考 PizzaHelperUnited 抓包：Widget 接口用普通 GAME_RECORD profile（miHoYoBBS UA、client_type=5、Referer=webstatic）
   * Cookie 传完整 cookie（含 ltuid/ltoken），不是精简的 stuid+stoken+mid
   */
  async getDailyNoteWidget(cookie: string): Promise<object> {
    // 请求头整套对齐 PizzaHelperUnited widgetNote4GI
    const headers = MihoyoHeaderBuilder.buildPizza(cookie, GameFpBiz.GENSHIN);
    const opts = new RequestOptions();
    opts.extraHeaders = headers;
    // 便笺 / Widget 不自动上报人机验证：降级 Widget 成功则不弹，由 Repository 在两者都失败后上报
    opts.suppressGeetestReport = true;
    const url = MihoyoDomain.TAKUMI_RECORD + GenshinApiPath.DAILY_NOTE_WIDGET;
    const response = await this.get(url, undefined, opts);
    this.reportBusinessError(url, response.data, opts, undefined, undefined, cookie, '');
    return response.data;
  }

  /** 角色列表 — POST，Domain=TAKUMI_RECORD，Profile=GAME_RECORD */
  async getCharacterList(roleId: string, server: string, cookie: string): Promise<object> {
    const bodyStr = JSON.stringify({ role_id: roleId, server: server });
    const headers = MihoyoHeaderBuilder.build(HeaderProfile.GAME_RECORD, cookie, undefined, bodyStr);
    headers.set(HKey.TOOL_VERSION, ApiConfig.TOOL_VERSION_GENSHIN);
    headers.set(HKey.PAGE, ApiConfig.PAGE_GENSHIN_ROLES);
    const opts = new RequestOptions();
    opts.extraHeaders = headers;
    const url = MihoyoDomain.TAKUMI_RECORD + GenshinApiPath.CHARACTER_LIST;
    const response = await this.post(url, bodyStr, opts);
    this.reportBusinessError(url, response.data, opts, undefined, bodyStr, cookie, roleId);
    return response.data;
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
    const url = MihoyoDomain.TAKUMI_RECORD + GenshinApiPath.CHARACTER_DETAIL;
    const response = await this.post(url, bodyStr, opts);
    this.reportBusinessError(url, response.data, opts, undefined, bodyStr, cookie, roleId);
    return response.data;
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
      const response = await this.post(url, bodyStr, opts);
      this.reportBusinessError(url, response.data, opts, undefined, bodyStr, enrichedCookie, uid);
      result = response.data;
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
      const response = await this.post(url, bodyStr, opts);
      this.reportBusinessError(url, response.data, opts, undefined, bodyStr, enrichedCookie, uid);
      result = response.data;
    } catch (e) {
      Logger.error(CALC_TAG, `[SyncAvatarList] HTTP FAILED after ${Date.now() - startTime}ms: ${e instanceof Error ? e.message : `${e}`}`);
      throw e as Error;
    }
    // 全量角色数据很大（200KB+），只打前 2 段，避免触发 hilog 流控丢日志；逐角色摘要见 [Avatar]
    GenshinApiService.logResponse('SyncAvatarList', result, Date.now() - startTime, 2);
    return result;
  }

  /** 打印请求 URL / 全部 header（Cookie 只打印字段名）/ 完整 body */
  private static logRequest(api: string, url: string, headers: Map<string, string>, bodyStr: string): void {
    Logger.info(CALC_TAG, `[${api}] URL: ${url}`);
    headers.forEach((v: string, k: string) => {
      const display = k.toLowerCase() === 'cookie'
        ? v.split(';').map((p: string) => p.split('=')[0].trim()).filter((n: string) => n.length > 0).join(',')
        : v;
      Logger.info(CALC_TAG, `[${api}] Header ${k}: ${display}`);
    });
    GenshinApiService.logLong(`[${api}] REQUEST body`, bodyStr);
  }

  /** 打印 retcode / message / 耗时 / 响应（最多 maxChunks 段） */
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
