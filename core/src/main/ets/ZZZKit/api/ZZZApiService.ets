import { RequestOptions } from '../../base/network/APIs';
import { MihoyoApiService } from '../../base/network/MihoyoApiService';
import { MihoyoDomain } from '../../base/network/MihoyoDomain';
import { ZZZApiPath } from './ZZZApiPath';
import { MihoyoHeaderBuilder, HeaderProfile } from '../../base/network/MihoyoHeaderBuilder';
import { ApiConfig } from '../../base/network/ApiConfig';
import { HKey, HVal } from '../../base/network/MihoyoHeaderKey';
import { GameFpBiz } from '../../base/network/GameFpBiz';
import { ZZZRecordRequest } from './ZZZRecordRequest';
import { Logger } from '../../base/utils/Logger';


/** 养成计算链路统一日志 tag，过滤：hilog | grep */
const ZZZ_CALC_TAG: string = 'ZZZCalc';

export class ZZZApiService extends MihoyoApiService {

  /**
   * 实时便笺 — GET。请求照 ZZZ-Plugin（tool.js zzzNote：query=role_id&server），见 ZZZRecordRequest
   */
  async getDailyNote(roleId: string, server: string, cookie: string, geetestChallenge?: string): Promise<object> {
    const req = await ZZZRecordRequest.build(cookie, ZZZApiPath.DAILY_NOTE, `role_id=${roleId}&server=${server}`);
    if (geetestChallenge) {
      req.options.extraHeaders.set(HKey.CHALLENGE, geetestChallenge);
      req.options.extraHeaders.set(HKey.CHALLENGE_PATH, MihoyoDomain.TAKUMI_RECORD + ZZZApiPath.DAILY_NOTE);
      req.options.extraHeaders.set(HKey.CHALLENGE_GAME, '8');
    }
    // 便笺 / Widget 不自动上报人机验证：降级 Widget 成功则不弹，由 Repository 在两者都失败后上报
    req.options.suppressGeetestReport = true;
    const response = await this.get(req.url, undefined, req.options);
    this.reportBusinessError(req.url, response.data, req.options, undefined, undefined, cookie, roleId);
    return response.data;
  }

  /**
   * Widget 实时便笺 — GET，Domain=TAKUMI_RECORD
   * 参考 PizzaHelperUnited widgetNote4ZZZ：覆盖 User-Agent 为 WidgetExtension/434，其余用 ZZZ_GAME_RECORD 默认 header
   */
  async getDailyNoteWidget(widgetCookie: string): Promise<object> {
    // 请求头整套对齐 PizzaHelperUnited widgetNote4ZZZ（绝区零指纹 nap_cn，User-Agent 为 WidgetExtension）
    const headers = MihoyoHeaderBuilder.buildPizza(widgetCookie, GameFpBiz.ZZZ, undefined, 'WidgetExtension/434 CFNetwork/1492.0.1 Darwin/23.3.0');
    const opts = new RequestOptions();
    opts.extraHeaders = headers;
    // 便笺 / Widget 不自动上报人机验证：降级 Widget 成功则不弹，由 Repository 在两者都失败后上报
    opts.suppressGeetestReport = true;
    const url = MihoyoDomain.TAKUMI_RECORD + ZZZApiPath.DAILY_NOTE_WIDGET;
    const response = await this.get(url, undefined, opts);
    this.reportBusinessError(url, response.data, opts, undefined, undefined, widgetCookie, '');
    return response.data;
  }

  /** 代理人列表 — GET。请求照 ZZZ-Plugin（tool.js zzzAvatarList：query=lang&role_id&server），见 ZZZRecordRequest */
  async getAvatarBasic(roleId: string, server: string, cookie: string): Promise<object> {
    const req = await ZZZRecordRequest.build(cookie, ZZZApiPath.AVATAR_BASIC,
      `lang=zh-cn&role_id=${roleId}&server=${server}`);
    const response = await this.get(req.url, undefined, req.options);
    this.reportBusinessError(req.url, response.data, req.options, undefined, undefined, cookie, roleId);
    return response.data;
  }

  /**
   * 代理人详情 — GET。请求照 ZZZ-Plugin（tool.js zzzAvatarInfo：query=lang&role_id&server&need_wiki=false，
   * id_list 以 id_list[]=xxx 追加且不参与 DS 签名），见 ZZZRecordRequest
   */
  async getAvatarInfo(roleId: string, server: string, idList: string[], cookie: string): Promise<object> {
    const ids: string[] = [];
    for (let i = 0; i < idList.length; i++) {
      ids[ids.length] = `id_list[]=${idList[i]}`;
    }
    const req = await ZZZRecordRequest.build(cookie, ZZZApiPath.AVATAR_INFO,
      `lang=zh-cn&role_id=${roleId}&server=${server}&need_wiki=false`, ids.join('&'));
    const response = await this.get(req.url, undefined, req.options);
    this.reportBusinessError(req.url, response.data, req.options, undefined, undefined, cookie, roleId);
    return response.data;
  }

  /** 邦布列表 — GET。请求照 ZZZ-Plugin（tool.js zzzBuddyList：query=lang&role_id&server），见 ZZZRecordRequest */
  async getBuddyList(roleId: string, server: string, cookie: string): Promise<object> {
    const req = await ZZZRecordRequest.build(cookie, ZZZApiPath.BUDDY_LIST,
      `lang=zh-cn&role_id=${roleId}&server=${server}`);
    const response = await this.get(req.url, undefined, req.options);
    this.reportBusinessError(req.url, response.data, req.options, undefined, undefined, cookie, roleId);
    return response.data;
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
    const response = await this.post(url, bodyStr, opts);
    const resp = response.data;
    this.reportBusinessError(url, resp, opts, undefined, bodyStr, cookie, '');
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
