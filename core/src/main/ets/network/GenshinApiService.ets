import { RequestParams, RequestOptions } from './APIs';
import { MihoyoApiService } from './MihoyoApiService';
import { MihoyoDomain } from './MihoyoDomain';
import { GenshinApiPath } from './GenshinApiPath';
import { MihoyoHeaderBuilder, HeaderProfile } from './MihoyoHeaderBuilder';
import { ApiConfig } from './ApiConfig';
import { HttpClient } from './HttpClient';

export class GenshinApiService extends MihoyoApiService {

  async get(path: string, params?: RequestParams, options?: RequestOptions): Promise<object> {
    return HttpClient.get(path, params, options);
  }

  async post(path: string, data?: string | RequestParams, options?: RequestOptions): Promise<object> {
    return HttpClient.post(path, data, options);
  }

  /** 实时便笺 — GET，Domain=TAKUMI_RECORD，Profile=GAME_RECORD */
  async getDailyNote(roleId: string, server: string, cookie: string): Promise<object> {
    const params = new RequestParams();
    params.set('role_id', roleId);
    params.set('server', server);
    const headers = MihoyoHeaderBuilder.build(HeaderProfile.GAME_RECORD, cookie, params);
    // 注意：拼写是 "verison"（米游社服务端拼写错误）
    headers.set('x-rpc-tool_verison', ApiConfig.TOOL_VERSION_GENSHIN);
    // 原神不需要 x-rpc-platform
    const opts = new RequestOptions();
    opts.extraHeaders = headers;
    return HttpClient.get(
      MihoyoDomain.TAKUMI_RECORD + GenshinApiPath.DAILY_NOTE,
      params,
      opts,
    );
  }

  /** 角色列表 — POST，Domain=TAKUMI_RECORD，Profile=GAME_RECORD */
  async getCharacterList(roleId: string, server: string, cookie: string): Promise<object> {
    const bodyStr = JSON.stringify({ role_id: roleId, server: server });
    const headers = MihoyoHeaderBuilder.build(HeaderProfile.GAME_RECORD, cookie, undefined, bodyStr);
    headers.set('x-rpc-tool_verison', ApiConfig.TOOL_VERSION_GENSHIN);
    const opts = new RequestOptions();
    opts.extraHeaders = headers;
    return HttpClient.post(
      MihoyoDomain.TAKUMI_RECORD + GenshinApiPath.CHARACTER_LIST,
      bodyStr,
      opts,
    );
  }

  /** 角色详情 — POST，Domain=TAKUMI_RECORD，Profile=GAME_RECORD */
  async getCharacterDetail(
    roleId: string,
    server: string,
    characterIds: number[],
    cookie: string,
  ): Promise<object> {
    const bodyStr = JSON.stringify({
      role_id: roleId,
      server: server,
      character_ids: characterIds,
    });
    const headers = MihoyoHeaderBuilder.build(HeaderProfile.GAME_RECORD, cookie, undefined, bodyStr);
    headers.set('x-rpc-tool_verison', ApiConfig.TOOL_VERSION_GENSHIN);
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
    headers.set('x-rpc-cal_type', '1');
    const opts = new RequestOptions();
    opts.extraHeaders = headers;
    return HttpClient.post(
      MihoyoDomain.TAKUMI + GenshinApiPath.BATCH_COMPUTE,
      bodyStr,
      opts,
    );
  }
}
