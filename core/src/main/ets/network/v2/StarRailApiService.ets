import { RequestParams, RequestOptions } from '../APIs';
import { MihoyoApiService } from './MihoyoApiService';
import { MihoyoDomain } from './MihoyoDomain';
import { StarRailApiPath } from './StarRailApiPath';
import { MihoyoHeaderBuilder, HeaderProfile } from './MihoyoHeaderBuilder';
import { ApiConfigV2 } from './ApiConfigV2';
import { HttpClientV2 } from './HttpClientV2';

export class StarRailApiService extends MihoyoApiService {

  async get(path: string, params?: RequestParams, options?: RequestOptions): Promise<object> {
    return HttpClientV2.get(path, params, options);
  }

  async post(path: string, data?: string | RequestParams, options?: RequestOptions): Promise<object> {
    return HttpClientV2.post(path, data, options);
  }

  /** 实时便笺 — GET，Domain=TAKUMI_RECORD，Profile=GAME_RECORD，注入星铁版本号和 x-rpc-platform:5 */
  async getDailyNote(roleId: string, server: string, cookie: string): Promise<object> {
    const params = new RequestParams();
    params.set('role_id', roleId);
    params.set('server', server);
    const headers = MihoyoHeaderBuilder.build(HeaderProfile.GAME_RECORD, cookie, params);
    headers.set('x-rpc-tool_verison', ApiConfigV2.TOOL_VERSION_STARRAIL);
    headers.set('x-rpc-platform', '5');
    const opts = new RequestOptions();
    opts.extraHeaders = headers;
    return HttpClientV2.get(
      MihoyoDomain.TAKUMI_RECORD + StarRailApiPath.DAILY_NOTE,
      params,
      opts,
    );
  }

  /** 角色列表 — GET，Domain=TAKUMI_RECORD，Profile=GAME_RECORD */
  async getAvatarBasic(roleId: string, server: string, cookie: string): Promise<object> {
    const params = new RequestParams();
    params.set('role_id', roleId);
    params.set('server', server);
    const headers = MihoyoHeaderBuilder.build(HeaderProfile.GAME_RECORD, cookie, params);
    headers.set('x-rpc-tool_verison', ApiConfigV2.TOOL_VERSION_STARRAIL);
    headers.set('x-rpc-platform', '5');
    const opts = new RequestOptions();
    opts.extraHeaders = headers;
    return HttpClientV2.get(
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
    params.set('need_wiki', 'false');
    const headers = MihoyoHeaderBuilder.build(HeaderProfile.GAME_RECORD, cookie, params);
    headers.set('x-rpc-tool_verison', ApiConfigV2.TOOL_VERSION_STARRAIL);
    headers.set('x-rpc-platform', '5');
    const opts = new RequestOptions();
    opts.extraHeaders = headers;
    return HttpClientV2.get(
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
    return HttpClientV2.post(
      MihoyoDomain.TAKUMI + StarRailApiPath.COMPUTE + '?game=hkrpg',
      bodyStr,
      opts,
    );
  }
}
