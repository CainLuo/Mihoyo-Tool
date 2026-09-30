/**
 * AuthRepository.ets（internal 版，含手机号登录完整功能）
 */

import { NetworkFactory } from '../network/NetworkFactory';
import { RequestParams, RequestOptions } from '../network/APIs';
import { RsaUtil } from '../utils/RsaUtil';
import { HttpClient } from '../network/HttpClient';
import { MihoyoAccountApiService } from '../network/MihoyoAccountApiService';
import { ApiConfig } from '../network/ApiConfig';
import { AppEnvManager } from '../constants/AppEnvManager';
import { Logger } from '../utils/Logger';
import { MihoyoDomain } from '../network/MihoyoDomain';
import { HKey, HVal } from '../network/MihoyoHeaderKey';
import { PassportApiPath } from '../network/PassportApiPath';
import { QRCodeApiPath } from '../network/QRCodeApiPath';
import {
  LOGIN_ACTION_TYPE_MOBILE,
  RETCODE_QR_EXPIRED,
  QR_STAT_EXPIRED,
  QR_STAT_CONFIRMED,
  QR_PROTO_ACCOUNT,
  RESP_FIELD_TOKEN,
  RESP_FIELD_USER_INFO,
  RESP_FIELD_AID,
  RESP_FIELD_MID,
  COOKIE_FIELD_ACCOUNT_ID,
  COOKIE_FIELD_COOKIE_TOKEN,
  COOKIE_FIELD_LTOKEN,
  COOKIE_FIELD_LTUID,
} from '../constants/ApiConstants';
import { LoginMobileResult } from '../models/PhoneLoginModels';
import {
  QRCodeFetchResult,
  QRCodeFetchResponse,
  QRCodeQueryResult,
  QRCodeQueryResponse,
  QRCodeConfirmedData,
} from '../models/QRCodeLoginModels';
import {
  GetLTokenBySTokenResponse,
  GetCookieBySTokenResponse,
  LoginCookieFields,
} from '../models/TokenModels';

export {
  LoginMobileResult,
  MmtData,
  MmtResponse,
  GeetestV4Data,
  PhoneLoginAccountInfo,
  PhoneLoginResponse,
} from '../models/PhoneLoginModels';
export {
  QRCodeFetchResult,
  QRCodeQueryResult,
  QRCodeConfirmedData,
} from '../models/QRCodeLoginModels';
export {
  LoginCookieFields,
  UserInfo,
  GetLTokenBySTokenResponse,
  GetCookieBySTokenResponse,
} from '../models/TokenModels';

export class AuthRepository {

  static accountService: MihoyoAccountApiService | null = null;

  // ── 手机号登录 ────────────────────────────────────────────────

  static async createLoginCaptcha(mobile: string, areaCode: string = '+86'): Promise<void> {
    const svc = AuthRepository.accountService;
    if (svc !== null) {
      let encryptedMobile = mobile;
      let encryptedAreaCode = areaCode;
      if (!AppEnvManager.isMock()) {
        encryptedMobile = await RsaUtil.encrypt(mobile);
        encryptedAreaCode = await RsaUtil.encrypt(areaCode);
      }
      const resp = await svc.createLoginCaptcha(encryptedMobile, encryptedAreaCode) as Record<string, Object>;
      const retcode = resp['retcode'] as number;
      if (retcode !== 0) {
        throw new Error(`[${retcode}] ${resp['message']}`);
      }
      return;
    }
    try {
      const encryptedMobile = await RsaUtil.encrypt(mobile);
      const encryptedAreaCode = await RsaUtil.encrypt(areaCode);
      const bodyStr = JSON.stringify({ area_code: encryptedAreaCode, mobile: encryptedMobile });
      const opts = new RequestOptions();
      opts.extraHeaders.set(HKey.CONTENT_TYPE, HVal.JSON);
      opts.extraHeaders.set(HKey.APP_ID, ApiConfig.BBS_APP_ID);
      opts.extraHeaders.set(HKey.CLIENT_TYPE, HVal.CLIENT_ANDROID);
      opts.extraHeaders.set(HKey.AIGIS, '');
      opts.extraHeaders.set(HKey.REFERER, HVal.REFERER_USER);
      const resp = await HttpClient.post(
        MihoyoDomain.PASSPORT + PassportApiPath.CREATE_LOGIN_CAPTCHA,
        bodyStr,
        opts
      ) as Record<string, Object>;
      const retcode = resp['retcode'] as number;
      if (retcode !== 0) {
        throw new Error(`[${retcode}] ${resp['message']}`);
      }
    } catch (error) {
      const msg = error instanceof Error ? error.message : `${error}`;
      throw new Error(`AuthRepository.createLoginCaptcha failed: ${msg}`);
    }
  }

  static async loginByMobileCaptcha(
    mobile: string,
    captcha: string,
    areaCode: string = '+86'
  ): Promise<LoginMobileResult> {
    const svc = AuthRepository.accountService;
    if (svc !== null) {
      let encryptedMobile = mobile;
      let encryptedAreaCode = areaCode;
      if (!AppEnvManager.isMock()) {
        encryptedMobile = await RsaUtil.encrypt(mobile);
        encryptedAreaCode = await RsaUtil.encrypt(areaCode);
      }
      const resp = await svc.loginByMobileCaptcha(encryptedMobile, encryptedAreaCode, captcha) as Record<string, Object>;
      const retcode = resp['retcode'] as number;
      if (retcode !== 0) {
        throw new Error(`[${retcode}] ${resp['message']}`);
      }
      return AuthRepository.parseLoginMobileResult(resp['data'] as Record<string, Object>);
    }
    try {
      const encryptedMobile = await RsaUtil.encrypt(mobile);
      const encryptedAreaCode = await RsaUtil.encrypt(areaCode);
      const bodyStr = JSON.stringify({
        area_code: encryptedAreaCode,
        mobile: encryptedMobile,
        action_type: LOGIN_ACTION_TYPE_MOBILE,
        captcha: captcha,
      });
      const opts = new RequestOptions();
      opts.extraHeaders.set(HKey.CONTENT_TYPE, HVal.TEXT_PLAIN);
      opts.extraHeaders.set(HKey.APP_ID, ApiConfig.BBS_APP_ID);
      opts.extraHeaders.set(HKey.CLIENT_TYPE, HVal.CLIENT_ANDROID);
      opts.extraHeaders.set(HKey.AIGIS, '');
      const resp = await HttpClient.post(
        MihoyoDomain.PASSPORT + PassportApiPath.LOGIN_BY_MOBILE_CAPTCHA,
        bodyStr,
        opts
      ) as Record<string, Object>;
      const retcode = resp['retcode'] as number;
      if (retcode !== 0) {
        throw new Error(`[${retcode}] ${resp['message']}`);
      }
      return AuthRepository.parseLoginMobileResult(resp['data'] as Record<string, Object>);
    } catch (error) {
      const msg = error instanceof Error ? error.message : `${error}`;
      throw new Error(`AuthRepository.loginByMobileCaptcha failed: ${msg}`);
    }
  }

  // ── Token 换取 ────────────────────────────────────────────────

  static async getLTokenBySToken(stoken: string, mid: string): Promise<string> {
    const svc = AuthRepository.accountService;
    if (svc !== null) {
      const resp = await svc.getLTokenBySToken(stoken, mid) as GetLTokenBySTokenResponse;
      if (resp.retcode !== 0) {
        throw new Error(`getLTokenBySToken failed: [${resp.retcode}] ${resp.message}`);
      }
      return resp.data.ltoken;
    }
    try {
      const params = new RequestParams();
      params.set('stoken', stoken);
      const opts = new RequestOptions();
      opts.extraHeaders.set(HKey.COOKIE, `mid=${mid};stoken=${stoken}`);
      opts.extraHeaders.set(HKey.CLIENT_TYPE, HVal.CLIENT_WEB);
      opts.extraHeaders.set(HKey.REFERER, HVal.WEBSTATIC);
      const resp = await NetworkFactory.getInstance().get(
        MihoyoDomain.PASSPORT + PassportApiPath.GET_LTOKEN_BY_STOKEN,
        params,
        opts
      ) as GetLTokenBySTokenResponse;
      if (resp.retcode !== 0) {
        throw new Error(`getLTokenBySToken failed: [${resp.retcode}] ${resp.message}`);
      }
      return resp.data.ltoken;
    } catch (error) {
      const msg = error instanceof Error ? error.message : `${error}`;
      throw new Error(`AuthRepository.getLTokenBySToken failed: ${msg}`);
    }
  }

  static async getCookieBySToken(stoken: string, mid: string): Promise<string> {
    const svc = AuthRepository.accountService;
    if (svc !== null) {
      const resp = await svc.getCookieTokenBySToken(stoken, mid) as GetCookieBySTokenResponse;
      if (resp.retcode !== 0) {
        throw new Error(`getCookieBySToken failed: [${resp.retcode}] ${resp.message}`);
      }
      return resp.data.cookie_token;
    }
    try {
      const params = new RequestParams();
      params.set('stoken', stoken);
      const opts = new RequestOptions();
      opts.extraHeaders.set(HKey.COOKIE, `mid=${mid};stoken=${stoken}`);
      opts.extraHeaders.set(HKey.CLIENT_TYPE, HVal.CLIENT_WEB);
      opts.extraHeaders.set(HKey.REFERER, HVal.WEBSTATIC);
      const resp = await NetworkFactory.getInstance().get(
        MihoyoDomain.PASSPORT + PassportApiPath.GET_COOKIE_TOKEN_BY_STOKEN,
        params,
        opts
      ) as GetCookieBySTokenResponse;
      if (resp.retcode !== 0) {
        throw new Error(`getCookieBySToken failed: [${resp.retcode}] ${resp.message}`);
      }
      return resp.data.cookie_token;
    } catch (error) {
      const msg = error instanceof Error ? error.message : `${error}`;
      throw new Error(`AuthRepository.getCookieBySToken failed: ${msg}`);
    }
  }

  // ── 二维码登录 ────────────────────────────────────────────────

  static async fetchQRCode(deviceId: string): Promise<QRCodeFetchResult> {
    try {
      let resp: QRCodeFetchResponse;
      const svc = AuthRepository.accountService;
      if (svc !== null) {
        resp = await svc.fetchQRCode(deviceId) as QRCodeFetchResponse;
      } else {
        const opts = new RequestOptions();
        opts.extraHeaders.set(HKey.CONTENT_TYPE, HVal.JSON);
        opts.extraHeaders.set('x-rpc-app_id', 'ddxf5dufpuyo');
        opts.extraHeaders.set('x-rpc-client_type', '3');
        opts.extraHeaders.set('x-rpc-device_id', deviceId);
        opts.extraHeaders.set(HKey.USER_AGENT, 'HYPContainer/1.3.3.182');
        resp = await HttpClient.post(MihoyoDomain.PASSPORT + QRCodeApiPath.FETCH, '{}', opts) as QRCodeFetchResponse;
      }
      if (resp.retcode !== 0) {
        throw new Error(`fetchQRCode failed: [${resp.retcode}] ${resp.message}`);
      }
      const result = new QRCodeFetchResult();
      result.url = resp.data.url;
      result.ticket = resp.data.ticket;
      return result;
    } catch (error) {
      const msg = error instanceof Error ? error.message : `${error}`;
      throw new Error(`AuthRepository.fetchQRCode failed: ${msg}`);
    }
  }

  static async queryQRCode(deviceId: string, ticket: string): Promise<QRCodeQueryResult> {
    try {
      let resp: QRCodeQueryResponse;
      const svc = AuthRepository.accountService;
      if (svc !== null) {
        resp = await svc.queryQRCode(deviceId, ticket) as QRCodeQueryResponse;
      } else {
        const bodyStr = JSON.stringify({ ticket: ticket });
        const opts = new RequestOptions();
        opts.extraHeaders.set(HKey.CONTENT_TYPE, HVal.JSON);
        opts.extraHeaders.set('x-rpc-app_id', 'ddxf5dufpuyo');
        opts.extraHeaders.set('x-rpc-client_type', '3');
        opts.extraHeaders.set('x-rpc-device_id', deviceId);
        opts.extraHeaders.set(HKey.USER_AGENT, 'HYPContainer/1.3.3.182');
        resp = await HttpClient.post(MihoyoDomain.PASSPORT + QRCodeApiPath.QUERY, bodyStr, opts) as QRCodeQueryResponse;
      }
      const queryResult = new QRCodeQueryResult();
      if (resp.retcode === RETCODE_QR_EXPIRED) {
        queryResult.stat = QR_STAT_EXPIRED;
        return queryResult;
      }
      if (resp.retcode !== 0 || resp.data === null) {
        throw new Error(`queryQRCode failed: [${resp.retcode}] ${resp.message}`);
      }
      // 新版 API 使用 status 字段，转换为小写
      const status = resp.data.status as string;
      queryResult.stat = status.toLowerCase();
      // Confirmed 状态时解析 tokens 和 user_info
      if (queryResult.stat === QR_STAT_CONFIRMED && resp.data.tokens !== undefined && resp.data.user_info !== undefined) {
        const tokens = resp.data.tokens;
        const userInfo = resp.data.user_info;
        // token_type: 1=stoken, 2=ltoken, 4=cookie_token
        let stoken = '';
        let ltoken = '';
        for (const t of tokens) {
          if (t.token_type === 1) {
            stoken = t.token;
          } else if (t.token_type === 2) {
            ltoken = t.token;
          }
        }
        const confirmed = new QRCodeConfirmedData();
        confirmed.uid = userInfo.aid;
        confirmed.stoken = stoken;
        confirmed.ltoken = ltoken;
        confirmed.mid = userInfo.mid;
        queryResult.confirmed = confirmed;
      }
      return queryResult;
    } catch (error) {
      const msg = error instanceof Error ? error.message : `${error}`;
      throw new Error(`AuthRepository.queryQRCode failed: ${msg}`);
    }
  }

  static async getLTokenBySTokenLegacy(stoken: string, accountId: string): Promise<string> {
    try {
      const options = new RequestOptions();
      options.extraHeaders.set(HKey.COOKIE, `stoken=${stoken};stuid=${accountId}`);
      const resp = await NetworkFactory.getInstance().get(
        MihoyoDomain.PASSPORT + PassportApiPath.GET_LTOKEN_BY_STOKEN,
        new RequestParams(),
        options
      ) as GetLTokenBySTokenResponse;
      if (resp.retcode !== 0) {
        throw new Error(`getLTokenBySToken failed: [${resp.retcode}] ${resp.message}`);
      }
      return resp.data.ltoken;
    } catch (error) {
      const msg = error instanceof Error ? error.message : `${error}`;
      throw new Error(`AuthRepository.getLTokenBySToken failed: ${msg}`);
    }
  }

  // ── 工具方法 ─────────────────────────────────────────────────

  static buildCookieString(fields: LoginCookieFields): string {
    // 调试日志：打印所有输入字段
    Logger.info('AuthRepository', `buildCookieString input fields:`);
    Logger.info('AuthRepository', `  accountId=${fields.accountId}`);
    Logger.info('AuthRepository', `  cookieToken=${fields.cookieToken}`);
    Logger.info('AuthRepository', `  ltoken=${fields.ltoken}`);
    Logger.info('AuthRepository', `  ltuid=${fields.ltuid}`);
    Logger.info('AuthRepository', `  stoken=${fields.stoken}`);
    Logger.info('AuthRepository', `  mid=${fields.mid}`);
    Logger.info('AuthRepository', `  deviceFp=${fields.deviceFp}`);
    Logger.info('AuthRepository', `  mhyUuid=${fields.mhyUuid}`);
    Logger.info('AuthRepository', `  deviceFpSeedId=${fields.deviceFpSeedId}`);
    Logger.info('AuthRepository', `  deviceFpSeedTime=${fields.deviceFpSeedTime}`);

    // 基础 Cookie 字段
    let cookie = `${COOKIE_FIELD_ACCOUNT_ID}=${fields.accountId}; ${COOKIE_FIELD_COOKIE_TOKEN}=${fields.cookieToken}; ${COOKIE_FIELD_LTOKEN}=${fields.ltoken}; ${COOKIE_FIELD_LTUID}=${fields.ltuid}`;

    // SToken 相关字段（二维码/手机号登录时有值）
    if (fields.stoken.length > 0) {
      cookie += `; stoken=${fields.stoken}; stuid=${fields.accountId}`;
    }
    if (fields.mid.length > 0) {
      cookie += `; mid=${fields.mid}`;
    }

    // v2 版本字段
    // 判断 stoken 是否为 v2 格式（以 "v2_" 开头）
    const isStokenV2 = fields.stoken.length > 0 && fields.stoken.startsWith('v2_');

    // ltuid_v2 和 account_id_v2 始终等于 accountId（这两个字段不依赖 token 格式）
    cookie += `; ltuid_v2=${fields.accountId}; account_id_v2=${fields.accountId}`;

    // 只有当 stoken 是 v2 格式时，才添加完整的 v2 token 字段
    // 否则会导致 API 返回 -100 错误（InvalidCookie）
    if (isStokenV2) {
      // v2 格式的 stoken，可以添加 ltmid_v2 和 account_mid_v2
      if (fields.mid.length > 0) {
        cookie += `; ltmid_v2=${fields.mid}; account_mid_v2=${fields.mid}`;
      }
      // 注意：v2 格式的 ltoken 和 cookie_token 需要通过专门的 v2 API 获取
      // 当前旧版 API（getLTokenBySToken）返回的是 V1 格式 token，不能直接用于 _v2 字段
      // 因此这里不添加 ltoken_v2 和 cookie_token_v2
      // 参考：genshin.py issue #151 - ltoken_v2 + ltuid_v2 单独可以工作，但 ltmid_v2 会导致 InvalidCookie
    }

    // 设备指纹相关字段（新版 batch_compute API 必需）
    if (fields.deviceFp.length > 0) {
      cookie += `; DEVICEFP=${fields.deviceFp}`;
    }
    if (fields.mhyUuid.length > 0) {
      cookie += `; _MHYUUID=${fields.mhyUuid}`;
    }
    if (fields.deviceFpSeedId.length > 0) {
      cookie += `; DEVICEFP_SEED_ID=${fields.deviceFpSeedId}`;
    }
    if (fields.deviceFpSeedTime.length > 0) {
      cookie += `; DEVICEFP_SEED_TIME=${fields.deviceFpSeedTime}`;
    }

    Logger.info('AuthRepository', `buildCookieString result: ${cookie}`);
    return cookie;
  }

  private static parseLoginMobileResult(data: Record<string, Object>): LoginMobileResult {
    const token = data[RESP_FIELD_TOKEN] as Record<string, Object>;
    const userInfo = data[RESP_FIELD_USER_INFO] as Record<string, Object>;
    const result = new LoginMobileResult();
    result.stoken = `${token[RESP_FIELD_TOKEN]}`;
    result.aid = `${userInfo[RESP_FIELD_AID]}`;
    result.mid = `${userInfo[RESP_FIELD_MID]}`;
    return result;
  }
}
