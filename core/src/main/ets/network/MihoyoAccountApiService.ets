import { RequestParams, RequestOptions } from './APIs';
import { MihoyoApiService } from './MihoyoApiService';
import { MihoyoDomain } from './MihoyoDomain';
import { MihoyoAccountApiPath } from './MihoyoAccountApiPath';
import { PassportApiPath } from './PassportApiPath';
import { QRCodeApiPath } from './QRCodeApiPath';
import { MihoyoHeaderBuilder, HeaderProfile } from './MihoyoHeaderBuilder';
import { HKey, HVal } from './MihoyoHeaderKey';
import { HttpClient } from './HttpClient';
import { ApiConfig } from './ApiConfig';
import { DSUtil } from './DSUtil';

export class MihoyoAccountApiService extends MihoyoApiService {

  async get(path: string, params?: RequestParams, options?: RequestOptions): Promise<object> {
    return HttpClient.get(path, params, options);
  }

  async post(path: string, data?: string | RequestParams, options?: RequestOptions): Promise<object> {
    return HttpClient.post(path, data, options);
  }

  // ── 手机号登录 ────────────────────────────────────────────────

  /**
   * 发送短信验证码
   * POST https://passport-api.mihoyo.com/account/ma-cn-verifier/verifier/createLoginCaptcha
   * mobile 和 area_code 需要 RSA 加密后传入（由调用方处理）
   */
  async createLoginCaptcha(encryptedMobile: string, encryptedAreaCode: string): Promise<object> {
    const bodyStr = JSON.stringify({
      area_code: encryptedAreaCode,
      mobile: encryptedMobile,
    });
    const opts = new RequestOptions();
    const h = opts.extraHeaders;
    h.set(HKey.CONTENT_TYPE, HVal.JSON);
    h.set(HKey.APP_ID, ApiConfig.BBS_APP_ID);
    h.set(HKey.APP_VERSION, ApiConfig.APP_VERSION);
    h.set(HKey.CLIENT_TYPE, HVal.CLIENT_ANDROID);
    h.set(HKey.DEVICE_FP, ApiConfig.getDeviceFp());
    h.set(HKey.DEVICE_ID, ApiConfig.getDeviceIdSync());
    h.set(HKey.DEVICE_MODEL, ApiConfig.DEVICE_MODEL);
    h.set(HKey.DEVICE_NAME, ApiConfig.DEVICE_NAME);
    h.set(HKey.GAME_BIZ, HVal.GAME_BIZ_GENSHIN);
    h.set(HKey.AIGIS, '');
    h.set(HKey.USER_AGENT, `Mozilla/5.0 (Linux; Android 12) Mobile miHoYoBBS/${ApiConfig.APP_VERSION}`);
    h.set(HKey.REFERER, HVal.REFERER_USER);
    return HttpClient.post(
      MihoyoDomain.PASSPORT + PassportApiPath.CREATE_LOGIN_CAPTCHA,
      bodyStr,
      opts,
    );
  }

  /**
   * 提交验证码登录
   * POST https://passport-api.mihoyo.com/account/ma-cn-passport/app/loginByMobileCaptcha
   * mobile 和 area_code 需要 RSA 加密后传入（由调用方处理）
   */
  async loginByMobileCaptcha(
    encryptedMobile: string,
    encryptedAreaCode: string,
    captcha: string,
  ): Promise<object> {
    const bodyStr = JSON.stringify({
      area_code: encryptedAreaCode,
      mobile: encryptedMobile,
      action_type: 'login_by_mobile_captcha',
      captcha: captcha,
    });
    const opts = new RequestOptions();
    const h = opts.extraHeaders;
    h.set(HKey.CONTENT_TYPE, HVal.JSON);
    h.set(HKey.APP_ID, ApiConfig.BBS_APP_ID);
    h.set(HKey.APP_VERSION, ApiConfig.APP_VERSION);
    h.set(HKey.CLIENT_TYPE, HVal.CLIENT_ANDROID);
    h.set(HKey.DEVICE_FP, ApiConfig.getDeviceFp());
    h.set(HKey.DEVICE_ID, ApiConfig.getDeviceIdSync());
    h.set(HKey.DEVICE_MODEL, ApiConfig.DEVICE_MODEL);
    h.set(HKey.DEVICE_NAME, ApiConfig.DEVICE_NAME);
    h.set(HKey.AIGIS, '');
    h.set(HKey.USER_AGENT, `Mozilla/5.0 (Linux; Android 12) Mobile miHoYoBBS/${ApiConfig.APP_VERSION}`);
    return HttpClient.post(
      MihoyoDomain.PASSPORT + PassportApiPath.LOGIN_BY_MOBILE_CAPTCHA,
      bodyStr,
      opts,
    );
  }

  // ── Token 换取 ────────────────────────────────────────────────

  /**
   * 用 stoken 换取 ltoken
   * GET https://passport-api.mihoyo.com/account/auth/api/getLTokenBySToken
   * Cookie 格式：mid=xxx;stoken=xxx（字典序）
   * 请求头包含 X4 DS 签名（参考 TeyvatGuide passportReq.ts）
   */
  async getLTokenBySToken(stoken: string, mid: string): Promise<object> {
    const params = new RequestParams();
    params.set('stoken', stoken);
    const opts = new RequestOptions();
    const h = opts.extraHeaders;
    h.set(HKey.COOKIE, `mid=${mid};stoken=${stoken}`);
    h.set(HKey.APP_VERSION, ApiConfig.APP_VERSION);
    h.set(HKey.CLIENT_TYPE, HVal.CLIENT_WEB);
    h.set(HKey.DEVICE_FP, ApiConfig.getDeviceFp());
    h.set(HKey.DEVICE_ID, ApiConfig.getDeviceIdSync());
    h.set(HKey.REQUESTED_WITH, HVal.REQUESTED_HYPERION);
    h.set(HKey.USER_AGENT, ApiConfig.USER_AGENT);
    h.set(HKey.REFERER, HVal.WEBSTATIC);
    h.set(HKey.DS, DSUtil.generateX4(params));
    return HttpClient.get(
      MihoyoDomain.PASSPORT + PassportApiPath.GET_LTOKEN_BY_STOKEN,
      params,
      opts,
    );
  }

  /**
   * 用 stoken 换取 cookie_token
   * GET https://passport-api.mihoyo.com/account/auth/api/getCookieAccountInfoBySToken
   * Cookie 格式：mid=xxx;stoken=xxx（字典序）
   * 请求头包含 X4 DS 签名（参考 TeyvatGuide passportReq.ts）
   */
  async getCookieTokenBySToken(stoken: string, mid: string): Promise<object> {
    const params = new RequestParams();
    params.set('stoken', stoken);
    const opts = new RequestOptions();
    const h = opts.extraHeaders;
    h.set(HKey.COOKIE, `mid=${mid};stoken=${stoken}`);
    h.set(HKey.APP_VERSION, ApiConfig.APP_VERSION);
    h.set(HKey.CLIENT_TYPE, HVal.CLIENT_WEB);
    h.set(HKey.DEVICE_FP, ApiConfig.getDeviceFp());
    h.set(HKey.DEVICE_ID, ApiConfig.getDeviceIdSync());
    h.set(HKey.REQUESTED_WITH, HVal.REQUESTED_HYPERION);
    h.set(HKey.USER_AGENT, ApiConfig.USER_AGENT);
    h.set(HKey.REFERER, HVal.WEBSTATIC);
    h.set(HKey.DS, DSUtil.generateX4(params));
    return HttpClient.get(
      MihoyoDomain.PASSPORT + PassportApiPath.GET_COOKIE_TOKEN_BY_STOKEN,
      params,
      opts,
    );
  }

  // ── 账号相关 ──────────────────────────────────────────────────

  /** 游戏角色绑定列表 — GET，Domain=TAKUMI，Profile=BBS（含 DS 签名） */
  async getGameRoles(cookie: string): Promise<object> {
    const params = new RequestParams();
    const headers = MihoyoHeaderBuilder.build(HeaderProfile.BBS, cookie, params);
    const opts = new RequestOptions();
    opts.extraHeaders = headers;
    return HttpClient.get(
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
    return HttpClient.get(
      MihoyoDomain.TAKUMI_RECORD + MihoyoAccountApiPath.GET_GAME_RECORD_CARD,
      params,
      opts,
    );
  }

  /**
   * BBS 账号详情 — GET，Domain=BBS，Profile=BBS
   * 需要 gids=2 参数（新版接口要求）
   */
  async getUserFullInfo(uid: string, cookie: string): Promise<object> {
    const params = new RequestParams();
    params.set('uid', uid);
    params.set('gids', '2');
    const headers = MihoyoHeaderBuilder.build(HeaderProfile.BBS, cookie, params);
    const opts = new RequestOptions();
    opts.extraHeaders = headers;
    return HttpClient.get(
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
    return HttpClient.get(
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
    return HttpClient.post(
      MihoyoDomain.BBS + MihoyoAccountApiPath.VERIFY_VERIFICATION,
      bodyStr,
      opts,
    );
  }

  // ── 二维码登录（子类可覆盖） ──────────────────────────────────

  /** 获取二维码 URL，mock 子类覆盖此方法返回假数据 */
  async fetchQRCode(deviceId: string): Promise<object> {
    const bodyStr = JSON.stringify({ app_id: 7, device: deviceId });
    const opts = new RequestOptions();
    opts.extraHeaders.set(HKey.CONTENT_TYPE, HVal.TEXT_PLAIN);
    return HttpClient.post(MihoyoDomain.HK4E_SDK + QRCodeApiPath.FETCH, bodyStr, opts);
  }

  /** 查询二维码状态，mock 子类覆盖此方法 */
  async queryQRCode(deviceId: string, ticket: string): Promise<object> {
    const bodyStr = JSON.stringify({ app_id: 7, device: deviceId, ticket: ticket });
    const opts = new RequestOptions();
    opts.extraHeaders.set(HKey.CONTENT_TYPE, HVal.TEXT_PLAIN);
    return HttpClient.post(MihoyoDomain.HK4E_SDK + QRCodeApiPath.QUERY, bodyStr, opts);
  }

  /** 通过 GameToken 获取 SToken，mock 子类覆盖此方法 */
  async getTokenByGameToken(accountId: string, gameToken: string): Promise<object> {
    const bodyStr = JSON.stringify({ account_id: parseInt(accountId, 10), game_token: gameToken });
    const opts = new RequestOptions();
    opts.extraHeaders.set(HKey.APP_ID, ApiConfig.BBS_APP_ID);
    opts.extraHeaders.set(HKey.CONTENT_TYPE, HVal.JSON);
    return HttpClient.post(MihoyoDomain.TAKUMI + PassportApiPath.GET_TOKEN_BY_GAME_TOKEN, bodyStr, opts);
  }

  // ── Cookie 刷新 ───────────────────────────────────────────────

  /** 用 stoken 换取 cookie_token（旧版，保留兼容） — GET，Domain=PASSPORT */
  async refreshCookieToken(stoken: string, stuid: string): Promise<object> {
    const params = new RequestParams();
    params.set('stoken', stoken);
    params.set('uid', stuid);
    const opts = new RequestOptions();
    return HttpClient.get(
      MihoyoDomain.PASSPORT + PassportApiPath.GET_COOKIE_TOKEN_BY_STOKEN,
      params,
      opts,
    );
  }

  /** 用 stoken 换取 ltoken（旧版，保留兼容） — GET，Domain=PASSPORT */
  async refreshLToken(stoken: string, stuid: string): Promise<object> {
    const params = new RequestParams();
    params.set('stoken', stoken);
    params.set('uid', stuid);
    const opts = new RequestOptions();
    return HttpClient.get(
      MihoyoDomain.PASSPORT + PassportApiPath.GET_LTOKEN_BY_STOKEN,
      params,
      opts,
    );
  }

  /** 验证 ltoken 有效性 — POST，Domain=PASSPORT_V4 */
  async verifyLToken(ltoken: string, ltuid: string): Promise<object> {
    const bodyStr = JSON.stringify({ ltoken: ltoken, uid: ltuid });
    const opts = new RequestOptions();
    return HttpClient.post(
      MihoyoDomain.PASSPORT_V4 + PassportApiPath.VERIFY_LTOKEN,
      bodyStr,
      opts,
    );
  }
}
