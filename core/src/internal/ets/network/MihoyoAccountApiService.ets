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
import { ApiConfig } from './ApiConfig';
import { DSUtil } from './DSUtil';
import { RsaUtil } from '../utils/RsaUtil';

export class MihoyoAccountApiService extends MihoyoApiService {

  // ── 手机号登录 ────────────────────────────────────────────────

  async createLoginCaptcha(mobile: string, areaCode: string): Promise<object> {
    const encryptedMobile = await RsaUtil.encrypt(mobile);
    const encryptedAreaCode = await RsaUtil.encrypt(areaCode);
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
    const response = await this.post(
      MihoyoDomain.PASSPORT + PassportApiPath.CREATE_LOGIN_CAPTCHA,
      bodyStr,
      opts,
    );
    return response.data;
  }

  async loginByMobileCaptcha(
    mobile: string,
    areaCode: string,
    captcha: string,
  ): Promise<object> {
    const encryptedMobile = await RsaUtil.encrypt(mobile);
    const encryptedAreaCode = await RsaUtil.encrypt(areaCode);
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
    const response = await this.post(
      MihoyoDomain.PASSPORT + PassportApiPath.LOGIN_BY_MOBILE_CAPTCHA,
      bodyStr,
      opts,
    );
    return response.data;
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
    const response = await this.get(
      MihoyoDomain.PASSPORT + PassportApiPath.GET_LTOKEN_BY_STOKEN,
      params,
      opts,
    );
    return response.data;
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
    const response = await this.get(
      MihoyoDomain.PASSPORT + PassportApiPath.GET_COOKIE_TOKEN_BY_STOKEN,
      params,
      opts,
    );
    return response.data;
  }

  // ── 账号相关 ──────────────────────────────────────────────────

  async getGameRoles(cookie: string): Promise<object> {
    const params = new RequestParams();
    const headers = MihoyoHeaderBuilder.build(HeaderProfile.BBS, cookie, params);
    const opts = new RequestOptions();
    opts.extraHeaders = headers;
    const url = MihoyoDomain.TAKUMI + MihoyoAccountApiPath.GET_GAME_ROLES;
    const response = await this.get(url, params, opts);
    this.reportBusinessError(url, response.data, opts, params, undefined, cookie, '');
    return response.data;
  }

  async getGameRecordCard(uid: string, cookie: string): Promise<object> {
    const params = new RequestParams();
    params.set('uid', uid);
    const headers = MihoyoHeaderBuilder.build(HeaderProfile.BBS, cookie, params);
    const opts = new RequestOptions();
    opts.extraHeaders = headers;
    const url = MihoyoDomain.TAKUMI_RECORD + MihoyoAccountApiPath.GET_GAME_RECORD_CARD;
    const response = await this.get(url, params, opts);
    this.reportBusinessError(url, response.data, opts, params, undefined, cookie, '');
    return response.data;
  }

  async getUserFullInfo(uid: string, cookie: string): Promise<object> {
    const params = new RequestParams();
    params.set('uid', uid);
    params.set('gids', '2');
    const headers = MihoyoHeaderBuilder.build(HeaderProfile.BBS, cookie, params);
    const opts = new RequestOptions();
    opts.extraHeaders = headers;
    const url = MihoyoDomain.BBS + MihoyoAccountApiPath.GET_USER_FULL_INFO;
    const response = await this.get(url, params, opts);
    this.reportBusinessError(url, response.data, opts, params, undefined, cookie, '');
    return response.data;
  }

  async createVerification(cookie: string): Promise<object> {
    const params = new RequestParams();
    params.set('is_high', 'true');
    const headers = MihoyoHeaderBuilder.build(HeaderProfile.BBS, cookie, params);
    const opts = new RequestOptions();
    opts.extraHeaders = headers;
    const response = await this.get(MihoyoDomain.BBS + MihoyoAccountApiPath.CREATE_VERIFICATION, params, opts);
    return response.data;
  }

  async verifyVerification(input: object, cookie: string): Promise<object> {
    const bodyStr = JSON.stringify(input);
    const headers = MihoyoHeaderBuilder.build(HeaderProfile.BBS, cookie, undefined, bodyStr);
    const opts = new RequestOptions();
    opts.extraHeaders = headers;
    const response = await this.post(MihoyoDomain.BBS + MihoyoAccountApiPath.VERIFY_VERIFICATION, bodyStr, opts);
    return response.data;
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
    const response = await this.post(MihoyoDomain.PASSPORT + QRCodeApiPath.FETCH, '{}', opts);
    return response.data;
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
    const response = await this.post(MihoyoDomain.PASSPORT + QRCodeApiPath.QUERY, bodyStr, opts);
    return response.data;
  }

  // ── Cookie 刷新 ───────────────────────────────────────────────

  async refreshCookieToken(stoken: string, stuid: string): Promise<object> {
    const params = new RequestParams();
    params.set('stoken', stoken);
    params.set('uid', stuid);
    const opts = new RequestOptions();
    const response = await this.get(MihoyoDomain.PASSPORT + PassportApiPath.GET_COOKIE_TOKEN_BY_STOKEN, params, opts);
    return response.data;
  }

  async refreshLToken(stoken: string, stuid: string): Promise<object> {
    const params = new RequestParams();
    params.set('stoken', stoken);
    params.set('uid', stuid);
    const opts = new RequestOptions();
    const response = await this.get(MihoyoDomain.PASSPORT + PassportApiPath.GET_LTOKEN_BY_STOKEN, params, opts);
    return response.data;
  }

  async verifyLToken(ltoken: string, ltuid: string): Promise<object> {
    const bodyStr = JSON.stringify({ ltoken: ltoken, uid: ltuid });
    const opts = new RequestOptions();
    const response = await this.post(MihoyoDomain.PASSPORT_V4 + PassportApiPath.VERIFY_LTOKEN, bodyStr, opts);
    return response.data;
  }
}
