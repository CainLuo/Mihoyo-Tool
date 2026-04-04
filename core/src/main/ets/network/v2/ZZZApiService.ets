import { RequestParams, RequestOptions } from '../APIs';
import { MihoyoApiService } from './MihoyoApiService';
import { MihoyoDomain } from './MihoyoDomain';
import { ZZZApiPath } from './ZZZApiPath';
import { MihoyoHeaderBuilder, HeaderProfile } from './MihoyoHeaderBuilder';
import { HttpClientV2 } from './HttpClientV2';

export class ZZZApiService extends MihoyoApiService {

  async get(path: string, params?: RequestParams, options?: RequestOptions): Promise<object> {
    return HttpClientV2.get(path, params, options);
  }

  async post(path: string, data?: string | RequestParams, options?: RequestOptions): Promise<object> {
    return HttpClientV2.post(path, data, options);
  }

  /** 实时便笺 — GET，Domain=TAKUMI_RECORD，Profile=ZZZ_GAME_RECORD */
  async getDailyNote(roleId: string, server: string, cookie: string): Promise<object> {
    const params = new RequestParams();
    params.set('role_id', roleId);
    params.set('server', server);
    const headers = MihoyoHeaderBuilder.build(HeaderProfile.ZZZ_GAME_RECORD, cookie, params);
    const opts = new RequestOptions();
    opts.extraHeaders = headers;
    return HttpClientV2.get(
      MihoyoDomain.TAKUMI_RECORD + ZZZApiPath.DAILY_NOTE,
      params,
      opts,
    );
  }

  /** 代理人列表 — GET，Domain=TAKUMI_RECORD，Profile=ZZZ_GAME_RECORD */
  async getAvatarBasic(roleId: string, server: string, cookie: string): Promise<object> {
    const params = new RequestParams();
    params.set('role_id', roleId);
    params.set('server', server);
    const headers = MihoyoHeaderBuilder.build(HeaderProfile.ZZZ_GAME_RECORD, cookie, params);
    const opts = new RequestOptions();
    opts.extraHeaders = headers;
    return HttpClientV2.get(
      MihoyoDomain.TAKUMI_RECORD + ZZZApiPath.AVATAR_BASIC,
      params,
      opts,
    );
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
    const opts = new RequestOptions();
    opts.extraHeaders = headers;
    return HttpClientV2.get(url, undefined, opts);
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
    headers.set('x-rpc-cultivate_source', 'bbs');
    const opts = new RequestOptions();
    opts.extraHeaders = headers;
    const url = `${MihoyoDomain.ACT_TAKUMI}${ZZZApiPath.COMPUTE}?uid=${uid}&region=${region}`;
    return HttpClientV2.post(url, bodyStr, opts);
  }
}
