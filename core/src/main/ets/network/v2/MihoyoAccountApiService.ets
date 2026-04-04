import { RequestParams, RequestOptions } from '../APIs';
import { MihoyoApiService } from './MihoyoApiService';
import { MihoyoDomain } from './MihoyoDomain';
import { MihoyoAccountApiPath } from './MihoyoAccountApiPath';
import { PassportApiPath } from './PassportApiPath';
import { MihoyoHeaderBuilder, HeaderProfile } from './MihoyoHeaderBuilder';
import { HttpClientV2 } from './HttpClientV2';

export class MihoyoAccountApiService extends MihoyoApiService {

  async get(path: string, params?: RequestParams, options?: RequestOptions): Promise<object> {
    return HttpClientV2.get(path, params, options);
  }

  async post(path: string, data?: string | RequestParams, options?: RequestOptions): Promise<object> {
    return HttpClientV2.post(path, data, options);
  }

  // ── 账号相关 ──────────────────────────────────────────────────

  /** 游戏角色绑定列表 — GET，Domain=TAKUMI，Profile=BBS */
  async getGameRoles(cookie: string): Promise<object> {
    const params = new RequestParams();
    const headers = MihoyoHeaderBuilder.build(HeaderProfile.BBS, cookie, params);
    const opts = new RequestOptions();
    opts.extraHeaders = headers;
    return HttpClientV2.get(
      MihoyoDomain.TAKUMI + MihoyoAccountApiPath.GET_GAME_ROLES,
      params,
      opts,
    );
  }

  /** 游戏战绩卡片 — GET，Domain=TAKUMI_RECORD，Profile=BBS */
  async getGameRecordCard(uid: string, cookie: string): Promise<object> {
    const params = new RequestParams();
    params.set('uid', uid);
    const headers = MihoyoHeaderBuilder.build(HeaderProfile.BBS, cookie, params);
    const opts = new RequestOptions();
    opts.extraHeaders = headers;
    return HttpClientV2.get(
      MihoyoDomain.TAKUMI_RECORD + MihoyoAccountApiPath.GET_GAME_RECORD_CARD,
      params,
      opts,
    );
  }

  /** BBS 账号详情 — GET，Domain=BBS，Profile=BBS */
  async getUserFullInfo(uid: string, cookie: string): Promise<object> {
    const params = new RequestParams();
    params.set('uid', uid);
    const headers = MihoyoHeaderBuilder.build(HeaderProfile.BBS, cookie, params);
    const opts = new RequestOptions();
    opts.extraHeaders = headers;
    return HttpClientV2.get(
      MihoyoDomain.BBS + MihoyoAccountApiPath.GET_USER_FULL_INFO,
      params,
      opts,
    );
  }

  /** 申请 Geetest 验证 — GET，Domain=BBS，Profile=BBS */
  async createVerification(cookie: string): Promise<object> {
    const params = new RequestParams();
    params.set('is_high', 'true');
    const headers = MihoyoHeaderBuilder.build(HeaderProfile.BBS, cookie, params);
    const opts = new RequestOptions();
    opts.extraHeaders = headers;
    return HttpClientV2.get(
      MihoyoDomain.BBS + MihoyoAccountApiPath.CREATE_VERIFICATION,
      params,
      opts,
    );
  }

  /** 提交 Geetest 验证结果 — POST，Domain=BBS，Profile=BBS */
  async verifyVerification(input: object, cookie: string): Promise<object> {
    const bodyStr = JSON.stringify(input);
    const headers = MihoyoHeaderBuilder.build(HeaderProfile.BBS, cookie, undefined, bodyStr);
    const opts = new RequestOptions();
    opts.extraHeaders = headers;
    return HttpClientV2.post(
      MihoyoDomain.BBS + MihoyoAccountApiPath.VERIFY_VERIFICATION,
      bodyStr,
      opts,
    );
  }

  // ── Cookie 刷新 ───────────────────────────────────────────────

  /** 用 stoken 换取 cookie_token — GET，Domain=PASSPORT */
  async refreshCookieToken(stoken: string, stuid: string): Promise<object> {
    const params = new RequestParams();
    params.set('stoken', stoken);
    params.set('uid', stuid);
    const opts = new RequestOptions();
    return HttpClientV2.get(
      MihoyoDomain.PASSPORT + PassportApiPath.GET_COOKIE_TOKEN_BY_STOKEN,
      params,
      opts,
    );
  }

  /** 用 stoken 换取 ltoken — GET，Domain=PASSPORT */
  async refreshLToken(stoken: string, stuid: string): Promise<object> {
    const params = new RequestParams();
    params.set('stoken', stoken);
    params.set('uid', stuid);
    const opts = new RequestOptions();
    return HttpClientV2.get(
      MihoyoDomain.PASSPORT + PassportApiPath.GET_LTOKEN_BY_STOKEN,
      params,
      opts,
    );
  }

  /** 验证 ltoken 有效性 — POST，Domain=PASSPORT_V4 */
  async verifyLToken(ltoken: string, ltuid: string): Promise<object> {
    const bodyStr = JSON.stringify({ ltoken: ltoken, uid: ltuid });
    const opts = new RequestOptions();
    return HttpClientV2.post(
      MihoyoDomain.PASSPORT_V4 + PassportApiPath.VERIFY_LTOKEN,
      bodyStr,
      opts,
    );
  }
}
