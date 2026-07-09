/**
 * MihoyoAccountApiService（internal 版，含手机号 API 方法）
 */
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
    h.set(HKey.USER_AGENT, ApiConfig.ANDROID_USER_AGENT);
    h.set(HKey.REFERER, HVal.REFERER_USER);
    return HttpClient.post(
      MihoyoDomain.PASSPORT + PassportApiPath.CREATE_LOGIN_CAPTCHA,
      bodyStr,
      opts,
    );
  }

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
    h.set(HKey.USER_AGENT, ApiConfig.ANDROID_USER_AGENT);
    return HttpClient.post(
      MihoyoDomain.PASSPORT + PassportApiPath.LOGIN_BY_MOBILE_CAPTCHA,
      bodyStr,
      opts,
    );
  }

  // ── Token 换取 ────────────────────────────────────────────────

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

  async getGameRoles(cookie: string): Promise<object> {
    const params = new RequestParams();
    const headers = MihoyoHeaderBuilder.build(HeaderProfile.BBS, cookie, params);
    const opts = new RequestOptions();
    opts.extraHeaders = headers;
    return HttpClient.get(MihoyoDomain.TAKUMI + MihoyoAccountApiPath.GET_GAME_ROLES, params, opts);
  }

  async getGameRecordCard(uid: string, cookie: string): Promise<object> {
    const params = new RequestParams();
    params.set('uid', uid);
    const headers = MihoyoHeaderBuilder.build(HeaderProfile.BBS, cookie, params);
    const opts = new RequestOptions();
    opts.extraHeaders = headers;
    return HttpClient.get(MihoyoDomain.TAKUMI_RECORD + MihoyoAccountApiPath.GET_GAME_RECORD_CARD, params, opts);
  }

  async getUserFullInfo(uid: string, cookie: string): Promise<object> {
    const params = new RequestParams();
    params.set('uid', uid);
    params.set('gids', '2');
    const headers = MihoyoHeaderBuilder.build(HeaderProfile.BBS, cookie, params);
    const opts = new RequestOptions();
    opts.extraHeaders = headers;
    return HttpClient.get(MihoyoDomain.BBS + MihoyoAccountApiPath.GET_USER_FULL_INFO, params, opts);
  }

  async createVerification(cookie: string): Promise<object> {
    const params = new RequestParams();
    params.set('is_high', 'true');
    const headers = MihoyoHeaderBuilder.build(HeaderProfile.BBS, cookie, params);
    const opts = new RequestOptions();
    opts.extraHeaders = headers;
    return HttpClient.get(MihoyoDomain.BBS + MihoyoAccountApiPath.CREATE_VERIFICATION, params, opts);
  }

  async verifyVerification(input: object, cookie: string): Promise<object> {
    const bodyStr = JSON.stringify(input);
    const headers = MihoyoHeaderBuilder.build(HeaderProfile.BBS, cookie, undefined, bodyStr);
    const opts = new RequestOptions();
    opts.extraHeaders = headers;
    return HttpClient.post(MihoyoDomain.BBS + MihoyoAccountApiPath.VERIFY_VERIFICATION, bodyStr, opts);
  }

  // ── 二维码登录（新版 passport API）────────────────────────────────

  async fetchQRCode(deviceId: string): Promise<object> {
    const opts = new RequestOptions();
    const h = opts.extraHeaders;
    h.set(HKey.CONTENT_TYPE, HVal.JSON);
    h.set('x-rpc-app_id', 'ddxf5dufpuyo');
    h.set('x-rpc-client_type', '3');
    h.set('x-rpc-device_id', deviceId);
    h.set(HKey.USER_AGENT, 'HYPContainer/1.3.3.182');
    // 新版 passport API 空请求体，设备 ID 通过 header 传递
    return HttpClient.post(MihoyoDomain.PASSPORT + QRCodeApiPath.FETCH, '{}', opts);
  }

  async queryQRCode(deviceId: string, ticket: string): Promise<object> {
    const bodyStr = JSON.stringify({ ticket: ticket });
    const opts = new RequestOptions();
    const h = opts.extraHeaders;
    h.set(HKey.CONTENT_TYPE, HVal.JSON);
    h.set('x-rpc-app_id', 'ddxf5dufpuyo');
    h.set('x-rpc-client_type', '3');
    h.set('x-rpc-device_id', deviceId);
    h.set(HKey.USER_AGENT, 'HYPContainer/1.3.3.182');
    return HttpClient.post(MihoyoDomain.PASSPORT + QRCodeApiPath.QUERY, bodyStr, opts);
  }

  // ── Cookie 刷新 ───────────────────────────────────────────────

  async refreshCookieToken(stoken: string, stuid: string): Promise<object> {
    const params = new RequestParams();
    params.set('stoken', stoken);
    params.set('uid', stuid);
    const opts = new RequestOptions();
    return HttpClient.get(MihoyoDomain.PASSPORT + PassportApiPath.GET_COOKIE_TOKEN_BY_STOKEN, params, opts);
  }

  async refreshLToken(stoken: string, stuid: string): Promise<object> {
    const params = new RequestParams();
    params.set('stoken', stoken);
    params.set('uid', stuid);
    const opts = new RequestOptions();
    return HttpClient.get(MihoyoDomain.PASSPORT + PassportApiPath.GET_LTOKEN_BY_STOKEN, params, opts);
  }

  async verifyLToken(ltoken: string, ltuid: string): Promise<object> {
    const bodyStr = JSON.stringify({ ltoken: ltoken, uid: ltuid });
    const opts = new RequestOptions();
    return HttpClient.post(MihoyoDomain.PASSPORT_V4 + PassportApiPath.VERIFY_LTOKEN, bodyStr, opts);
  }
}
