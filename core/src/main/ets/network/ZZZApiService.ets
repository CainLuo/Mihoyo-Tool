import { RequestParams, RequestOptions } from './APIs';
import { MihoyoApiService } from './MihoyoApiService';
import { MihoyoDomain } from './MihoyoDomain';
import { ZZZApiPath } from './ZZZApiPath';
import { MihoyoHeaderBuilder, HeaderProfile } from './MihoyoHeaderBuilder';
import { ApiConfig } from './ApiConfig';
import { HKey } from './MihoyoHeaderKey';
import { HttpClient } from './HttpClient';
import { Logger } from '../utils/Logger';

/** 养成计算链路统一日志 tag，过滤：hilog | grep */
const ZZZ_CALC_TAG: string = 'ZZZCalc';
/** 绝区零代理人列表接口日志，过滤：hilog | grep 🚀🚀🚀 */
const ZZZ_LIST_TAG: string = '🚀🚀🚀 ZZZAvatarBasic';

export class ZZZApiService extends MihoyoApiService {

  async get(path: string, params?: RequestParams, options?: RequestOptions): Promise<object> {
    return HttpClient.get(path, params, options);
  }

  async post(path: string, data?: string | RequestParams, options?: RequestOptions): Promise<object> {
    return HttpClient.post(path, data, options);
  }

  /** 实时便笺 — GET，Domain=TAKUMI_RECORD，Profile=ZZZ_GAME_RECORD */
  async getDailyNote(roleId: string, server: string, cookie: string, geetestChallenge?: string): Promise<object> {
    const params = new RequestParams();
    params.set('role_id', roleId);
    params.set('server', server);
    const headers = MihoyoHeaderBuilder.build(HeaderProfile.ZZZ_GAME_RECORD, cookie, params);
    headers.set(HKey.PAGE, ApiConfig.PAGE_ZZZ_NOTE);
    if (geetestChallenge) {
      headers.set(HKey.CHALLENGE, geetestChallenge);
      headers.set(HKey.CHALLENGE_PATH, 'https://api-takumi-record.mihoyo.com' + ZZZApiPath.DAILY_NOTE);
      headers.set(HKey.CHALLENGE_GAME, '8');
    }
    const opts = new RequestOptions();
    opts.extraHeaders = headers;
    return HttpClient.get(
      MihoyoDomain.TAKUMI_RECORD + ZZZApiPath.DAILY_NOTE,
      params,
      opts,
    );
  }

  /**
   * Widget 实时便笺 — GET，Domain=TAKUMI_RECORD
   * 参考 PizzaHelperUnited widgetNote4ZZZ：覆盖 User-Agent 为 WidgetExtension/434，其余用 ZZZ_GAME_RECORD 默认 header
   */
  async getDailyNoteWidget(widgetCookie: string): Promise<object> {
    const headers = MihoyoHeaderBuilder.build(HeaderProfile.ZZZ_GAME_RECORD, widgetCookie);
    // 覆盖 User-Agent 为 WidgetExtension（参考 PizzaHelperUnited widgetNote4ZZZ）
    headers.set(HKey.USER_AGENT, 'WidgetExtension/434 CFNetwork/1492.0.1 Darwin/23.3.0');
    const opts = new RequestOptions();
    opts.extraHeaders = headers;
    return HttpClient.get(
      MihoyoDomain.TAKUMI_RECORD + ZZZApiPath.DAILY_NOTE_WIDGET,
      undefined,
      opts,
    );
  }

  /** 代理人列表 — GET，Domain=TAKUMI_RECORD，Profile=ZZZ_GAME_RECORD */
  async getAvatarBasic(roleId: string, server: string, cookie: string): Promise<object> {
    const params = new RequestParams();
    params.set('role_id', roleId);
    params.set('server', server);
    const headers = MihoyoHeaderBuilder.build(HeaderProfile.ZZZ_GAME_RECORD, cookie, params);
    headers.set(HKey.PAGE, ApiConfig.PAGE_ZZZ_ROLES);
    const opts = new RequestOptions();
    opts.extraHeaders = headers;
    const url = MihoyoDomain.TAKUMI_RECORD + ZZZApiPath.AVATAR_BASIC;
    Logger.info(ZZZ_LIST_TAG, `[AvatarBasic] REQUEST ${url}?role_id=${roleId}&server=${server}`);
    const startTime = Date.now();
    const resp = await HttpClient.get(url, params, opts);
    const r = resp as Record<string, Object>;
    const data = r['data'] as Record<string, Object> | undefined;
    const list = data !== undefined ? data['avatar_list'] as Object[] | undefined : undefined;
    Logger.info(ZZZ_LIST_TAG, `[AvatarBasic] RESPONSE retcode=${r['retcode']}, message=${r['message']}, ` +
      `cost=${Date.now() - startTime}ms, data keys=${data !== undefined ? Object.keys(data).join(',') : '-'}, ` +
      `avatar_list=${Array.isArray(list) ? list.length : '-'}`);
    ZZZApiService.logLongWithTag(ZZZ_LIST_TAG, '[AvatarBasic] RESPONSE body', JSON.stringify(resp), 100);
    return resp;
  }

  /**
   * 代理人详情 — GET，Domain=TAKUMI_RECORD，Profile=ZZZ_GAME_RECORD
   * idList 使用 PHP 风格数组格式：id_list[]=1171&id_list[]=1141
   */
  async getAvatarInfo(roleId: string, server: string, idList: string[], cookie: string): Promise<object> {
    // 构建 PHP 风格数组 query 参数
    let url = MihoyoDomain.TAKUMI_RECORD + ZZZApiPath.AVATAR_INFO;
    url += `?role_id=${roleId}&server=${server}`;
    for (let i = 0; i < idList.length; i++) {
      url += `&id_list[]=${idList[i]}`;
    }
    const headers = MihoyoHeaderBuilder.build(HeaderProfile.ZZZ_GAME_RECORD, cookie);
    const pageId = idList.length > 0 ? idList[0] : '';
    headers.set(HKey.PAGE, pageId.length > 0
      ? ApiConfig.PAGE_ZZZ_ROLE_DETAIL_PREFIX + pageId + '/detail'
      : ApiConfig.PAGE_ZZZ_ROLES);
    const opts = new RequestOptions();
    opts.extraHeaders = headers;
    return HttpClient.get(url, undefined, opts);
  }

  /** 邦布列表 — GET，Domain=TAKUMI_RECORD，Profile=ZZZ_GAME_RECORD */
  async getBuddyList(roleId: string, server: string, cookie: string): Promise<object> {
    const params = new RequestParams();
    params.set('role_id', roleId);
    params.set('server', server);
    const headers = MihoyoHeaderBuilder.build(HeaderProfile.ZZZ_GAME_RECORD, cookie, params);
    headers.set(HKey.PAGE, ApiConfig.PAGE_ZZZ_BANGBOO);
    const opts = new RequestOptions();
    opts.extraHeaders = headers;
    return HttpClient.get(
      MihoyoDomain.TAKUMI_RECORD + ZZZApiPath.BUDDY_LIST,
      params,
      opts,
    );
  }

  /**
   * 养成材料计算 — POST，Domain=ACT_TAKUMI，Profile=ZZZ_GAME_RECORD
   * uid 和 region 作为 URL query 参数
   */
  async compute(
    avatarId: string,
    avatarLevel: number,
    avatarCurrentLevel: number,
    avatarCurrentPromotes: number,
    skills: object[],
    uid: string,
    region: string,
    cookie: string,
  ): Promise<object> {
    const bodyStr = JSON.stringify({
      avatar_id: parseInt(avatarId),
      avatar_level: avatarLevel,
      avatar_current_level: avatarCurrentLevel,
      avatar_current_promotes: avatarCurrentPromotes,
      skills: skills,
    });
    const headers = MihoyoHeaderBuilder.build(HeaderProfile.ZZZ_GAME_RECORD, cookie, undefined, bodyStr);
    headers.set(HKey.CULTIVATE_SOURCE, 'bbs');
    const opts = new RequestOptions();
    opts.extraHeaders = headers;
    const url = `${MihoyoDomain.ACT_TAKUMI}${ZZZApiPath.COMPUTE}?uid=${uid}&region=${region}`;
    Logger.info(ZZZ_CALC_TAG, `[Compute] avatarId=${avatarId} URL: ${url}`);
    ZZZApiService.logLong(`[Compute] avatarId=${avatarId} REQUEST body`, bodyStr);
    const startTime = Date.now();
    const resp = await HttpClient.post(url, bodyStr, opts);
    const r = resp as Record<string, Object>;
    Logger.info(ZZZ_CALC_TAG, `[Compute] avatarId=${avatarId} RESPONSE retcode=${r['retcode']}, message=${r['message']}, cost=${Date.now() - startTime}ms`);
    // 各材料列表的条数，便于对照页面展示
    const data = r['data'] as Record<string, Object> | undefined;
    if (data) {
      const keys = ['avatar_consume', 'weapon_consume', 'skill_consume', 'need_get'];
      const counts: string[] = [];
      for (let i = 0; i < keys.length; i++) {
        const v = data[keys[i]];
        counts[counts.length] = `${keys[i]}=${Array.isArray(v) ? (v as Object[]).length : '-'}`;
      }
      Logger.info(ZZZ_CALC_TAG, `[Compute] avatarId=${avatarId} RESPONSE counts: ${counts.join(', ')}`);
    }
    ZZZApiService.logLong(`[Compute] avatarId=${avatarId} RESPONSE body`, JSON.stringify(resp));
    return resp;
  }

  /** hilog 单条约 4KB 会被截断，长文本分段打印（最多 maxChunks 段） */
  private static logLongWithTag(tag: string, label: string, text: string, maxChunks: number): void {
    const chunk = 1000;
    const total = Math.max(Math.ceil(text.length / chunk), 1);
    const printCount = Math.min(total, maxChunks);
    for (let i = 0; i < printCount; i++) {
      Logger.info(tag, `${label} [${i + 1}/${total}] (len=${text.length}): ${text.substring(i * chunk, (i + 1) * chunk)}`);
    }
    if (printCount < total) {
      Logger.info(tag, `${label} ... omitted ${total - printCount} chunks`);
    }
  }

  /** hilog 单条约 4KB 会被截断，长文本分段打印（最多 40 段） */
  private static logLong(label: string, text: string): void {
    const chunk = 1000;
    const total = Math.max(Math.ceil(text.length / chunk), 1);
    const printCount = Math.min(total, 40);
    for (let i = 0; i < printCount; i++) {
      Logger.info(ZZZ_CALC_TAG, `${label} [${i + 1}/${total}] (len=${text.length}): ${text.substring(i * chunk, (i + 1) * chunk)}`);
    }
  }
}
