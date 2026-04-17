/**
 * AuthRepository.ets
 *
 * 米游社国服登录 API 封装（Repository 层）。
 * 国际服（HoYoLAB）逻辑已预留占位，完成度：0%（接口路径待确认）。
 *
 * 国服登录流程（手机号）：
 *   1. createLoginCaptcha()    — 发送短信验证码
 *   2. loginByMobileCaptcha()  — 提交验证码，换取 SToken
 *   3. getLTokenBySToken()     — SToken → LToken
 *   4. getCookieBySToken()     — SToken → CookieToken
 *
 * 国服登录流程（二维码）：
 *   1. fetchQRCode()           — 获取二维码 URL（含 ticket）
 *   2. queryQRCode()           — 轮询扫码状态，Confirmed 后拿到 uid + game_token
 *   3. getTokenByGameToken()   — game_token → SToken
 *   4. getLTokenBySToken()     — SToken → LToken
 *   5. getCookieBySToken()     — SToken → CookieToken
 *
 * 国服登录流程（Cookie 手动输入）：
 *   直接调用 getUserGameRoles() 验证 Cookie 有效性，成功则写入 AccountRepository。
 *
 * API 来源：UIGF-org/mihoyo-api-collect
 */

import { NetworkFactory } from '../network/NetworkFactory';
import { RequestParams, RequestOptions } from '../network/APIs';
import { RsaUtil } from '../utils/RsaUtil';
import { HttpClient } from '../network/HttpClient';
import { MihoyoAccountApiService } from '../network/MihoyoAccountApiService';
import { ApiConfig } from '../network/ApiConfig';
import { AppEnvManager } from '../constants/AppEnvManager';
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
import {
  LoginMobileResult,
} from '../models/PhoneLoginModels';
import {
  QRCodeFetchResult,
  QRCodeFetchResponse,
  QRCodeQueryResult,
  QRCodeQueryResponse,
  QRCodeConfirmedData,
} from '../models/QRCodeLoginModels';
import {
  GameTokenResult,
  GetTokenByGameTokenResponse,
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
  GameTokenResult,
  UserInfo,
  GetLTokenBySTokenResponse,
  GetCookieBySTokenResponse,
  GetTokenByGameTokenResponse,
} from '../models/TokenModels';

export class AuthRepository {

  /**
   * 注入的 account service（由 BBSRepository.setService() 同步设置）。
   * mock 环境下为 MihoyoAccountMockService，release 环境下为 MihoyoAccountApiService。
   */
  static accountService: MihoyoAccountApiService | null = null;

  // ── 手机号登录 ────────────────────────────────────────────────

  /**
   * 发送短信验证码。
   * mock 环境：通过 MihoyoAccountMockService 校验手机号是否存在。
   * release/debug 环境：RSA 加密后调用真实接口。
   */
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
    // 兜底：直接调 HttpClient（不应该走到这里）
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

  /**
   * 提交验证码登录，换取 SToken。
   * mock 环境：校验手机号 + 验证码（固定 111111）。
   * release/debug 环境：RSA 加密后调用真实接口。
   */
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
    // 兜底
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

  /**
   * 通过 SToken 获取 LToken。
   */
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

  /**
   * 通过 SToken 获取 CookieToken。
   */
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

  /**
   * 获取二维码 URL（二维码登录第一步）。
   */
  static async fetchQRCode(deviceId: string): Promise<QRCodeFetchResult> {
    try {
      let resp: QRCodeFetchResponse;
      const svc = AuthRepository.accountService;
      if (svc !== null) {
        resp = await svc.fetchQRCode(deviceId) as QRCodeFetchResponse;
      } else {
        const bodyStr = JSON.stringify({ app_id: 7, device: deviceId });
        const opts = new RequestOptions();
        opts.extraHeaders.set(HKey.CONTENT_TYPE, HVal.TEXT_PLAIN);
        resp = await HttpClient.post(
          MihoyoDomain.HK4E_SDK + QRCodeApiPath.FETCH,
          bodyStr,
          opts
        ) as QRCodeFetchResponse;
      }
      if (resp.retcode !== 0) {
        throw new Error(`fetchQRCode failed: [${resp.retcode}] ${resp.message}`);
      }
      const url = resp.data.url;
      const ticketMatch = url.split('ticket=');
      const ticket = ticketMatch.length > 1 ? ticketMatch[1].split('&')[0] : '';
      const result = new QRCodeFetchResult();
      result.url = url;
      result.ticket = ticket;
      return result;
    } catch (error) {
      const msg = error instanceof Error ? error.message : `${error}`;
      throw new Error(`AuthRepository.fetchQRCode failed: ${msg}`);
    }
  }

  /**
   * 轮询二维码扫码状态。
   */
  static async queryQRCode(deviceId: string, ticket: string): Promise<QRCodeQueryResult> {
    try {
      let resp: QRCodeQueryResponse;
      const svc = AuthRepository.accountService;
      if (svc !== null) {
        resp = await svc.queryQRCode(deviceId, ticket) as QRCodeQueryResponse;
      } else {
        const bodyStr = JSON.stringify({ app_id: 7, device: deviceId, ticket: ticket });
        const opts = new RequestOptions();
        opts.extraHeaders.set(HKey.CONTENT_TYPE, HVal.TEXT_PLAIN);
        resp = await HttpClient.post(
          MihoyoDomain.HK4E_SDK + QRCodeApiPath.QUERY,
          bodyStr,
          opts
        ) as QRCodeQueryResponse;
      }
      const queryResult = new QRCodeQueryResult();
      if (resp.retcode === RETCODE_QR_EXPIRED) {
        queryResult.stat = QR_STAT_EXPIRED;
        return queryResult;
      }
      if (resp.retcode !== 0 || resp.data === null) {
        throw new Error(`queryQRCode failed: [${resp.retcode}] ${resp.message}`);
      }
      queryResult.stat = resp.data.stat.toLowerCase();
      if (queryResult.stat === QR_STAT_CONFIRMED && resp.data.payload.proto === QR_PROTO_ACCOUNT) {
        queryResult.confirmed = JSON.parse(resp.data.payload.raw) as QRCodeConfirmedData;
      }
      return queryResult;
    } catch (error) {
      const msg = error instanceof Error ? error.message : `${error}`;
      throw new Error(`AuthRepository.queryQRCode failed: ${msg}`);
    }
  }

  /**
   * 通过 GameToken 换取 SToken。
   */
  static async getTokenByGameToken(accountId: string, gameToken: string): Promise<GameTokenResult> {
    try {
      let resp: GetTokenByGameTokenResponse;
      const svc = AuthRepository.accountService;
      if (svc !== null) {
        resp = await svc.getTokenByGameToken(accountId, gameToken) as GetTokenByGameTokenResponse;
      } else {
        const bodyStr = JSON.stringify({ account_id: parseInt(accountId, 10), game_token: gameToken });
        const opts = new RequestOptions();
        opts.extraHeaders.set(HKey.APP_ID, ApiConfig.BBS_APP_ID);
        opts.extraHeaders.set(HKey.CONTENT_TYPE, HVal.JSON);
        resp = await HttpClient.post(
          MihoyoDomain.TAKUMI + PassportApiPath.GET_TOKEN_BY_GAME_TOKEN,
          bodyStr,
          opts
        ) as GetTokenByGameTokenResponse;
      }
      if (resp.retcode !== 0) {
        throw new Error(`getTokenByGameToken failed: [${resp.retcode}] ${resp.message}`);
      }
      const tokenResult = new GameTokenResult();
      tokenResult.stoken = resp.data.token.token;
      tokenResult.userInfo = resp.data.user_info;
      return tokenResult;
    } catch (error) {
      const msg = error instanceof Error ? error.message : `${error}`;
      throw new Error(`AuthRepository.getTokenByGameToken failed: ${msg}`);
    }
  }

  /**
   * 通过 SToken 获取 LToken（旧版，供二维码登录使用）。
   */
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

  /**
   * 组装完整 Cookie 字符串。
   * 格式：account_id=xxx; cookie_token=xxx; ltoken=xxx; ltuid=xxx[; stoken=xxx; stuid=xxx; mid=xxx]
   * stoken/mid 仅手机号和二维码登录时有值，Cookie 登录时为空，有值才追加。
   */
  static buildCookieString(fields: LoginCookieFields): string {
    let cookie = `${COOKIE_FIELD_ACCOUNT_ID}=${fields.accountId}; ${COOKIE_FIELD_COOKIE_TOKEN}=${fields.cookieToken}; ${COOKIE_FIELD_LTOKEN}=${fields.ltoken}; ${COOKIE_FIELD_LTUID}=${fields.ltuid}`;
    if (fields.stoken.length > 0) {
      cookie += `; stoken=${fields.stoken}; stuid=${fields.accountId}`;
    }
    if (fields.mid.length > 0) {
      cookie += `; mid=${fields.mid}`;
    }
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

  // ── 国际服占位（完成度：0%）────────────────────────────────────  // TODO: 国际服（HoYoLAB）登录 API 路径待确认
  // 预计接口：
  //   手机号：https://webapi.hoyolab.com/Api/create_mmt（路径待确认）
  //   二维码：https://sg-public-api.hoyolab.com/...（路径待确认）
  //   游戏角色：https://bbs-api-os.hoyolab.com/game_record/card/wapi/getGameRecordCard
  // 完成度：0% — UI 不展示，逻辑待实现
}
