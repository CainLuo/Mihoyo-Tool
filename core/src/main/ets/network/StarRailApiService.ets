import { RequestParams, RequestOptions } from './APIs';
import { MihoyoApiService } from './MihoyoApiService';
import { MihoyoDomain } from './MihoyoDomain';
import { StarRailApiPath } from './StarRailApiPath';
import { MihoyoHeaderBuilder, HeaderProfile } from './MihoyoHeaderBuilder';
import { ApiConfig } from './ApiConfig';
import { HKey } from './MihoyoHeaderKey';
import { HttpClient } from './HttpClient';

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
    const headers = MihoyoHeaderBuilder.build(HeaderProfile.GAME_RECORD, cookie, params);
    headers.set('x-rpc-tool_verison', ApiConfig.TOOL_VERSION_STARRAIL);
    headers.set('x-rpc-platform', '5');
    headers.set(HKey.PAGE, ApiConfig.PAGE_STARRAIL_NOTE);
    if (geetestChallenge) {
      headers.set('x-rpc-challenge', geetestChallenge);
    }
    const opts = new RequestOptions();
    opts.extraHeaders = headers;
    return HttpClient.get(
      MihoyoDomain.TAKUMI_RECORD + StarRailApiPath.DAILY_NOTE,
      params,
      opts,
    );
  }

  /**
   * Widget 实时便笺 — GET，Domain=TAKUMI_RECORD，Profile=WIDGET
   * 无 1034 Geetest 验证，需要 stoken Cookie 格式：stuid=xxx;stoken=v2_xxx;mid=xxx
   * 参考 HSRPizzaHelper widgetNote 实现（WidgetExtension User-Agent）
   */
  async getDailyNoteWidget(widgetCookie: string): Promise<object> {
    const headers = MihoyoHeaderBuilder.build(HeaderProfile.WIDGET, widgetCookie);
    const opts = new RequestOptions();
    opts.extraHeaders = headers;
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
    headers.set('x-rpc-tool_verison', ApiConfig.TOOL_VERSION_STARRAIL);
    headers.set('x-rpc-platform', '5');
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
    headers.set('x-rpc-tool_verison', ApiConfig.TOOL_VERSION_STARRAIL);
    headers.set('x-rpc-platform', '5');
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
   */
  async compute(
    avatar: object,
    skillList: object[],
    uid: string,
    region: string,
    cookie: string,
  ): Promise<object> {
    const bodyStr = JSON.stringify({
      game: 'hkrpg',
      avatar: avatar,
      skill_list: skillList,
      lang: 'zh-cn',
      uid: uid,
      region: region,
    });
    const headers = MihoyoHeaderBuilder.build(HeaderProfile.CALCULATE, cookie, undefined, bodyStr);
    // 星铁养成计算 Referer 是 webstatic.mihoyo.com，与原神不同
    headers.set('Referer', 'https://webstatic.mihoyo.com/');
    headers.set('Origin', 'https://webstatic.mihoyo.com');
    const opts = new RequestOptions();
    opts.extraHeaders = headers;
    return HttpClient.post(
      MihoyoDomain.TAKUMI + StarRailApiPath.COMPUTE + '?game=hkrpg',
      bodyStr,
      opts,
    );
  }
}
