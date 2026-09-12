import { RequestParams, RequestOptions } from './APIs';
import { MihoyoApiService } from './MihoyoApiService';
import { MihoyoDomain } from './MihoyoDomain';
import { GenshinApiPath } from './GenshinApiPath';
import { MihoyoHeaderBuilder, HeaderProfile } from './MihoyoHeaderBuilder';
import { ApiConfig } from './ApiConfig';
import { HKey } from './MihoyoHeaderKey';
import { HttpClient } from './HttpClient';
import { Logger } from '../utils/Logger';

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
    Logger.info('💥💥💥 GenshinApiService', `batchCompute START: uid=${uid}, region=${region}, items count=${items.length}`);
    const bodyStr = JSON.stringify({
      items: items,
      lang: 'zh-cn',
      region: region,
      uid: uid,
    });
    Logger.info('💥💥💥 GenshinApiService', `batchCompute REQUEST body: ${bodyStr.substring(0, 500)}`);
    const headers = MihoyoHeaderBuilder.build(HeaderProfile.CALCULATE, cookie, undefined, bodyStr);
    headers.set(HKey.CAL_TYPE, '1');
    // ── [MIYOYO-NET] batchCompute 请求 header log ───────────────────────
    Logger.info('💥💥💥 GenshinApiService', `[MIYOYO-NET][HOS][BatchCompute] URL: ${MihoyoDomain.TAKUMI + GenshinApiPath.BATCH_COMPUTE}`);
    headers.forEach((v: string, k: string) => {
      const display = k.toLowerCase() === 'cookie' ? v.substring(0, 60) + '...' : v;
      Logger.info('💥💥💥 GenshinApiService', `[MIYOYO-NET][HOS][BatchCompute] Header ${k}: ${display}`);
    });
    // ─────────────────────────────────────────────────────────────────────
    const opts = new RequestOptions();
    opts.extraHeaders = headers;
    const result = await HttpClient.post(
      MihoyoDomain.TAKUMI + GenshinApiPath.BATCH_COMPUTE,
      bodyStr,
      opts,
    );
    // ── [MIYOYO-NET] batchCompute response log ────────────────────────────
    Logger.info('💥💥💥 GenshinApiService', `[MIYOYO-NET][HOS][BatchCompute] Response: ${JSON.stringify(result).substring(0, 1000)}`);
    // ─────────────────────────────────────────────────────────────────────
    return result;
  }
}
