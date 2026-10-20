import { RequestParams, RequestOptions } from './APIs';
import { MihoyoApiService } from './MihoyoApiService';
import { MihoyoDomain } from './MihoyoDomain';
import { StarRailApiPath } from './StarRailApiPath';
import { MihoyoHeaderBuilder, HeaderProfile } from './MihoyoHeaderBuilder';
import { ApiConfig } from './ApiConfig';
import { HKey, HVal } from './MihoyoHeaderKey';
import { GameFpBiz } from './DeviceFpService';
import { HttpClient } from './HttpClient';
import { Logger } from '../utils/Logger';
import { StarRailComputeAvatar, StarRailComputeEquipment, StarRailComputeSkill } from '../models/StarRailRows';

const WIDGET_EXTENSION_UA: string = 'WidgetExtension/434 CFNetwork/1492.0.1 Darwin/23.3.0';

/** 养成计算链路统一日志 tag，过滤：hilog | grep */
const SR_CALC_TAG: string = 'StarRailCalc';

export class StarRailApiService extends MihoyoApiService {

  async get(path: string, params?: RequestParams, options?: RequestOptions): Promise<object> {
    return HttpClient.get(path, params, options);
  }

  async post(path: string, data?: string | RequestParams, options?: RequestOptions): Promise<object> {
    return HttpClient.post(path, data, options);
  }

  /**
   * 实时便笺 — GET，Domain=TAKUMI_RECORD，Profile=GAME_RECORD
   * 需要有效的 x-rpc-device_fp（通过 DeviceFpService 获取真实指纹）
   */
  async getDailyNote(roleId: string, server: string, cookie: string, geetestChallenge?: string): Promise<object> {
    const params = new RequestParams();
    params.set('role_id', roleId);
    params.set('server', server);
    // 请求头整套对齐 PizzaHelperUnited fullNote4HSR（星铁指纹 hkrpg_cn）
    const headers = MihoyoHeaderBuilder.buildPizza(cookie, GameFpBiz.STARRAIL, params);
    if (geetestChallenge) {
      headers.set(HKey.CHALLENGE, geetestChallenge);
      headers.set(HKey.CHALLENGE_PATH, 'https://api-takumi-record.mihoyo.com' + StarRailApiPath.DAILY_NOTE);
      headers.set(HKey.CHALLENGE_GAME, '6');
    }
    const opts = new RequestOptions();
    opts.extraHeaders = headers;
    // 便笺 / Widget 不自动上报人机验证：降级 Widget 成功则不弹，由 Repository 在两者都失败后上报
    opts.suppressGeetestReport = true;
    return HttpClient.get(
      MihoyoDomain.TAKUMI_RECORD + StarRailApiPath.DAILY_NOTE,
      params,
      opts,
    );
  }

  /**
   * Widget 实时便笺 — GET，Domain=TAKUMI_RECORD
   * 参考 PizzaHelperUnited widgetNote4HSR：覆盖 User-Agent 为 WidgetExtension/434，其余用 GAME_RECORD 默认 header
   */
  async getDailyNoteWidget(widgetCookie: string): Promise<object> {
    // 请求头整套对齐 PizzaHelperUnited widgetNote4HSR（User-Agent 为 WidgetExtension）
    const headers = MihoyoHeaderBuilder.buildPizza(widgetCookie, GameFpBiz.STARRAIL, undefined, WIDGET_EXTENSION_UA);
    const opts = new RequestOptions();
    opts.extraHeaders = headers;
    // 便笺 / Widget 不自动上报人机验证：降级 Widget 成功则不弹，由 Repository 在两者都失败后上报
    opts.suppressGeetestReport = true;
    return HttpClient.get(
      MihoyoDomain.TAKUMI_RECORD + StarRailApiPath.DAILY_NOTE_WIDGET,
      undefined,
      opts,
    );
  }

  /** 角色列表 — GET，Domain=TAKUMI_RECORD，Profile=GAME_RECORD */
  async getAvatarBasic(roleId: string, server: string, cookie: string): Promise<object> {
    const params = new RequestParams();
    params.set('role_id', roleId);
    params.set('server', server);
    const headers = MihoyoHeaderBuilder.build(HeaderProfile.GAME_RECORD, cookie, params);
    headers.set(HKey.TOOL_VERSION, ApiConfig.TOOL_VERSION_STARRAIL);
    headers.set(HKey.PLATFORM, HVal.PLATFORM_WEB);
    headers.set(HKey.PAGE, ApiConfig.PAGE_STARRAIL_ROLES);
    const opts = new RequestOptions();
    opts.extraHeaders = headers;
    return HttpClient.get(
      MihoyoDomain.TAKUMI_RECORD + StarRailApiPath.AVATAR_BASIC,
      params,
      opts,
    );
  }

  /** 角色详情 — GET，Domain=TAKUMI_RECORD，Profile=GAME_RECORD */
  async getAvatarInfo(roleId: string, server: string, id: string, cookie: string): Promise<object> {
    const params = new RequestParams();
    params.set('role_id', roleId);
    params.set('server', server);
    params.set('id', id);
    params.set('need_wiki', 'true');
    const headers = MihoyoHeaderBuilder.build(HeaderProfile.GAME_RECORD, cookie, params);
    headers.set(HKey.TOOL_VERSION, ApiConfig.TOOL_VERSION_STARRAIL);
    headers.set(HKey.PLATFORM, HVal.PLATFORM_WEB);
    headers.set(HKey.PAGE, ApiConfig.PAGE_STARRAIL_ROLE);
    const opts = new RequestOptions();
    opts.extraHeaders = headers;
    return HttpClient.get(
      MihoyoDomain.TAKUMI_RECORD + StarRailApiPath.AVATAR_INFO,
      params,
      opts,
    );
  }

  /**
   * 养成材料计算 — POST，Domain=TAKUMI，Profile=CALCULATE
   * URL 追加 ?game=hkrpg，Referer/Origin 覆盖为 webstatic.mihoyo.com
   * 星铁 API 只支持逐角色请求
   */
  async compute(
    avatarId: string,
    avatar: StarRailComputeAvatar,
    equipment: StarRailComputeEquipment,
    skillList: StarRailComputeSkill[],
    uid: string,
    region: string,
    cookie: string,
  ): Promise<object> {
    const bodyStr = JSON.stringify({
      game: 'hkrpg',
      avatar: avatar,
      equipment: equipment,
      skill_list: skillList,
      lang: 'zh-cn',
      uid: uid,
      region: region,
    });
    const url = MihoyoDomain.TAKUMI + StarRailApiPath.COMPUTE + '?game=hkrpg';
    const headers = MihoyoHeaderBuilder.build(HeaderProfile.CALCULATE, cookie, undefined, bodyStr);
    // 星铁养成计算 Referer 是 webstatic.mihoyo.com，与原神不同
    headers.set('Referer', 'https://webstatic.mihoyo.com/');
    headers.set('Origin', 'https://webstatic.mihoyo.com');
    const opts = new RequestOptions();
    opts.extraHeaders = headers;
    Logger.info(SR_CALC_TAG, `[Compute] avatarId=${avatarId} URL: ${url}`);
    StarRailApiService.logLong(`[Compute] avatarId=${avatarId} REQUEST body`, bodyStr);
    const startTime = Date.now();
    const resp = await HttpClient.post(url, bodyStr, opts);
    const r = resp as Record<string, Object>;
    Logger.info(SR_CALC_TAG, `[Compute] avatarId=${avatarId} RESPONSE retcode=${r['retcode']}, message=${r['message']}, cost=${Date.now() - startTime}ms`);
    // 各材料列表的条数，便于确认"已满级仍返回材料"时具体是哪一类
    const data = r['data'] as Record<string, Object> | undefined;
    if (data) {
      const keys = ['avatar_consume', 'skill_consume', 'equipment_consume', 'need_get_materials', 'can_pay_materials', 'can_merge_materials'];
      const counts: string[] = [];
      for (let i = 0; i < keys.length; i++) {
        const v = data[keys[i]];
        counts[counts.length] = `${keys[i]}=${Array.isArray(v) ? (v as Object[]).length : '-'}`;
      }
      Logger.info(SR_CALC_TAG, `[Compute] avatarId=${avatarId} RESPONSE counts: ${counts.join(', ')}`);
    }
    StarRailApiService.logLong(`[Compute] avatarId=${avatarId} RESPONSE body`, JSON.stringify(resp));
    return resp;
  }

  /** hilog 单条约 4KB 会被截断，长文本分段打印（最多 40 段） */
  private static logLong(label: string, text: string): void {
    const chunk = 1000;
    const total = Math.max(Math.ceil(text.length / chunk), 1);
    const printCount = Math.min(total, 40);
    for (let i = 0; i < printCount; i++) {
      Logger.info(SR_CALC_TAG, `${label} [${i + 1}/${total}] (len=${text.length}): ${text.substring(i * chunk, (i + 1) * chunk)}`);
    }
  }
}
