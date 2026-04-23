import { RequestParams, RequestOptions } from './APIs';
import { MihoyoApiService } from './MihoyoApiService';
import { MihoyoDomain } from './MihoyoDomain';
import { GenshinApiPath } from './GenshinApiPath';
import { MihoyoHeaderBuilder, HeaderProfile } from './MihoyoHeaderBuilder';
import { ApiConfig } from './ApiConfig';
import { HKey } from './MihoyoHeaderKey';
import { HttpClient } from './HttpClient';

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
    const opts = new RequestOptions();
    opts.extraHeaders = headers;
    return HttpClient.get(
      MihoyoDomain.TAKUMI_RECORD + GenshinApiPath.DAILY_NOTE,
      params,
      opts,
    );
  }

  /**
   * Widget 实时便笺 — GET，Domain=TAKUMI_RECORD，Profile=WIDGET
   * 无 1034 Geetest 验证，需要 stoken Cookie 格式：stuid=xxx;stoken=v2_xxx;mid=xxx
   * 参考 GenshinPizzaHelper widgetDailyNote 和 HSRPizzaHelper widgetNote 实现
   */
  async getDailyNoteWidget(widgetCookie: string): Promise<object> {
    const headers = MihoyoHeaderBuilder.build(HeaderProfile.WIDGET, widgetCookie);
    const opts = new RequestOptions();
    opts.extraHeaders = headers;
    return HttpClient.get(
      MihoyoDomain.TAKUMI_RECORD + GenshinApiPath.DAILY_NOTE_WIDGET,
      undefined,
      opts,
    );
  }

  /** 角色列表 — POST，Domain=TAKUMI_RECORD，Profile=GAME_RECORD */
  async getCharacterList(roleId: string, server: string, cookie: string): Promise<object> {
    const bodyStr = JSON.stringify({ role_id: roleId, server: server });
    const headers = MihoyoHeaderBuilder.build(HeaderProfile.GAME_RECORD, cookie, undefined, bodyStr);
    headers.set(HKey.TOOL_VERSION, ApiConfig.TOOL_VERSION_GENSHIN);
    headers.set(HKey.PAGE, ApiConfig.PAGE_GENSHIN_ROLES);
    const opts = new RequestOptions();
    opts.extraHeaders = headers;
    return HttpClient.post(
      MihoyoDomain.TAKUMI_RECORD + GenshinApiPath.CHARACTER_LIST,
      bodyStr,
      opts,
    );
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
    const bodyStr = JSON.stringify({
      items: items,
      lang: 'zh-cn',
      region: region,
      uid: uid,
    });
    const headers = MihoyoHeaderBuilder.build(HeaderProfile.CALCULATE, cookie, undefined, bodyStr);
    headers.set(HKey.CAL_TYPE, '1');
    const opts = new RequestOptions();
    opts.extraHeaders = headers;
    return HttpClient.post(
      MihoyoDomain.TAKUMI + GenshinApiPath.BATCH_COMPUTE,
      bodyStr,
      opts,
    );
  }
}
