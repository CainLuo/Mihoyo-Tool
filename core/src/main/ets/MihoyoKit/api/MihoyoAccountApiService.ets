/**
 * MihoyoAccountApiService（internal 版，含手机号 API 方法）
 */
import { RequestParams, RequestOptions } from '../../base/network/APIs';
import { MihoyoApiService } from '../../base/network/MihoyoApiService';
import { MihoyoDomain } from '../../base/network/MihoyoDomain';
import { MihoyoAccountApiPath } from './MihoyoAccountApiPath';
import { PassportApiPath } from './PassportApiPath';
import { QRCodeApiPath, QRCodeConfig } from './QRCodeApiPath';
import { HeaderContext, HeaderProfile } from '../../base/network/MihoyoHeaderBuilder';
import { HKey, HVal } from '../../base/network/MihoyoHeaderKey';
import { ApiConfig } from '../../base/network/ApiConfig';
import { DSUtil } from '../../base/network/DSUtil';
import { RsaUtil } from '../../base/utils/RsaUtil';

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
    const context = new HeaderContext(HeaderProfile.BBS, cookie);
    const url = MihoyoDomain.TAKUMI + MihoyoAccountApiPath.GET_GAME_ROLES;
    const response = await this.getWithProfile(url, context, params);
    this.reportBusinessError(url, response.data, undefined, params, undefined, cookie, '');
    return response.data;
  }

  async getGameRecordCard(uid: string, cookie: string): Promise<object> {
    const params = new RequestParams();
    params.set('uid', uid);
    const context = new HeaderContext(HeaderProfile.BBS, cookie);
    const url = MihoyoDomain.TAKUMI_RECORD + MihoyoAccountApiPath.GET_GAME_RECORD_CARD;
    const response = await this.getWithProfile(url, context, params);
    this.reportBusinessError(url, response.data, undefined, params, undefined, cookie, '');
    return response.data;
  }

  async getUserFullInfo(uid: string, cookie: string): Promise<object> {
    const params = new RequestParams();
    params.set('uid', uid);
    params.set('gids', '2');
    const context = new HeaderContext(HeaderProfile.BBS, cookie);
    const url = MihoyoDomain.BBS + MihoyoAccountApiPath.GET_USER_FULL_INFO;
    const response = await this.getWithProfile(url, context, params);
    this.reportBusinessError(url, response.data, undefined, params, undefined, cookie, '');
    return response.data;
  }

  async createVerification(cookie: string): Promise<object> {
    const params = new RequestParams();
    params.set('is_high', 'true');
    const context = new HeaderContext(HeaderProfile.BBS, cookie);
    const response = await this.getWithProfile(
      MihoyoDomain.BBS + MihoyoAccountApiPath.CREATE_VERIFICATION,
      context,
      params,
    );
    return response.data;
  }

  async verifyVerification(input: object, cookie: string): Promise<object> {
    const bodyStr = JSON.stringify(input);
    const context = new HeaderContext(HeaderProfile.BBS, cookie);
    const response = await this.postWithProfile(
      MihoyoDomain.BBS + MihoyoAccountApiPath.VERIFY_VERIFICATION,
      context,
      bodyStr,
    );
    return response.data;
  }

  // ── 二维码登录 ────────────────────────────────────────────────

  async fetchQRCode(deviceId: string): Promise<object> {
    const bodyStr = '{}';
    const opts = QRCodeConfig.buildOptions(deviceId, bodyStr);
    const response = await this.post(MihoyoDomain.PASSPORT + QRCodeApiPath.FETCH, bodyStr, opts);
    return response.data;
  }

  async queryQRCode(deviceId: string, ticket: string): Promise<object> {
    const bodyStr = JSON.stringify({ ticket: ticket });
    const opts = QRCodeConfig.buildOptions(deviceId, bodyStr);
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
