/**
 * AuthRepository.ets
 *
 * 米游社国服登录 API 封装（Repository 层）。
 * 国际服（HoYoLAB）逻辑已预留占位，完成度：0%（接口路径待确认）。
 *
 * 国服登录流程（手机号）：
 *   1. createMmt()          — 申请人机验证任务（可能需要 Geetest）
 *   2. sendSmsCode()        — 发送短信验证码（携带 Geetest 结果）
 *   3. loginByPhone()       — 用短信验证码换取 LoginTicket
 *   4. getLTokenByTicket()  — LoginTicket → LToken
 *   5. getCookieByLToken()  — LToken → CookieToken（完整 Cookie 组装）
 *   6. getUserGameRoles()   — 获取绑定的游戏角色列表
 *
 * 国服登录流程（二维码）：
 *   1. fetchQRCode()        — 获取二维码 URL（含 ticket）
 *   2. queryQRCode()        — 轮询扫码状态，Confirmed 后拿到 uid + game_token
 *   3. getTokenByGameToken()— game_token → SToken
 *   4. getLTokenBySToken()  — SToken → LToken
 *   5. getCookieBySToken()  — SToken → CookieToken
 *   6. getUserGameRoles()   — 获取绑定的游戏角色列表
 *
 * 国服登录流程（Cookie 手动输入）：
 *   直接调用 getUserGameRoles() 验证 Cookie 有效性，成功则写入 AccountRepository。
 *
 * API 来源：UIGF-org/mihoyo-api-collect
 */

import { NetworkFactory } from '../network/NetworkFactory';
import { RequestParams, RequestOptions } from '../network/APIs';
import { GameId } from '../constants/GameId';
import { RsaUtil } from '../utils/RsaUtil';
import { HttpClient } from '../network/HttpClient';
import { MihoyoAccountApiService } from '../network/MihoyoAccountApiService';
import { ApiConfig } from '../network/ApiConfig';

// ─── 旧版游戏角色数据模型（供 AuthRepository 返回值和 entry 层使用）────────────

/** 游戏角色信息（来自 API 响应，供 AuthRepository 网络层使用） */
export class GameRoleRecord {
  id: number = 0;
  accountId: number = 0;
  gameId: string = '';
  roleId: string = '';
  nickname: string = '';
  level: number = 0;
  server: string = '';
  /** 游戏背景图 URL */
  bgImageUrl: string = '';
  /** 游戏内统计数据 JSON 字符串 */
  statsJson: string = '';
}

/** 游戏内统计数据项（从 statsJson 解析而来） */
export class RoleStatItem {
  name: string = '';
  value: string = '';

  constructor(name: string, value: string) {
    this.name = name;
    this.value = value;
  }

  /** 将 statsJson 字符串解析为 RoleStatItem 数组，解析失败返回空数组 */
  static parseAll(statsJson: string): RoleStatItem[] {
    if (!statsJson || statsJson === '') { return []; }
    try {
      interface RawStat { name: string; value: string }
      const parsed = JSON.parse(statsJson) as RawStat[];
      const result: RoleStatItem[] = [];
      for (let i = 0; i < parsed.length; i++) {
        result[result.length] = new RoleStatItem(parsed[i].name, parsed[i].value);
      }
      return result;
    } catch (_) {
      return [];
    }
  }
}

// ─── 国服 API 基础路径 ────────────────────────────────────────────

/** 米游社通行证 webapi（手机号登录） */
const WEBAPI_ACCOUNT = 'https://webapi.account.mihoyo.com/Api';
/** 米游社 takumi API（Token 换取） */
const TAKUMI_API = 'https://api-takumi.mihoyo.com';
/** 米游社 passport API（SToken 换取） */
const PASSPORT_API = 'https://passport-api.mihoyo.com';
/** 原神 SDK（二维码登录） */
const HK4E_SDK = 'https://hk4e-sdk.mihoyo.com';
/** 米游社绑定 API（游戏角色查询） */
const BINDING_API = 'https://api-takumi.mihoyo.com/binding/api';

// ─── 类型定义 ────────────────────────────────────────────────────

/** create_mmt 接口返回的人机验证任务数据 */
export interface MmtData {
  /** 验证任务 key，无论是否需要 Geetest 都会返回 */
  mmt_key: string;
  /** Geetest 应用 ID（需要验证时才有） */
  gt?: string;
  /** v3 challenge（需要 v3 验证时才有） */
  challenge?: string;
  /** v4 风险类型（需要 v4 验证时才有） */
  risk_type?: string;
  /** 是否新验证码 */
  new_captcha?: number;
  /** 是否成功 */
  success?: number;
  /** 是否使用 v4 */
  use_v4?: boolean;
}

/** create_mmt 接口响应 */
export interface MmtResponse {
  code: number;
  data: MmtResponseData;
}

interface MmtResponseData {
  mmt_data: MmtData;
  /** 0=无需验证，1=需要验证 */
  mmt_type: number;
  msg: string;
  scene_type: number;
  status: number;
}

/** Geetest v4 验证结果（用于发送短信） */
export interface GeetestV4Data {
  lot_number: string;
  captcha_output: string;
  pass_token: string;
  gen_time: string;
  captcha_id: string;
  sign_token: string;
}

/** 手机号登录成功后的账号信息 */
export interface PhoneLoginAccountInfo {
  account_id: number;
  area_code: string;
  mobile: string;
  /** Login Ticket（即 weblogin_token） */
  weblogin_token: string;
}

/** 手机号登录响应 */
export interface PhoneLoginResponse {
  code: number;
  data: PhoneLoginResponseData;
}

interface PhoneLoginResponseData {
  account_info: PhoneLoginAccountInfo;
  msg: string;
  status: number;
}

/** 二维码 fetch 响应 */
export interface QRCodeFetchResponse {
  retcode: number;
  message: string;
  data: QRCodeFetchData;
}

interface QRCodeFetchData {
  /** 二维码指向的 URL，传给 ArkUI QRCode 组件展示 */
  url: string;
}

/** 二维码 query 响应 */
export interface QRCodeQueryResponse {
  retcode: number;
  message: string;
  data: QRCodeQueryData | null;
}

interface QRCodeQueryData {
  /** Init / Scanned / Confirmed */
  stat: string;
  payload: QRCodePayload;
}

interface QRCodePayload {
  /** Raw / Account */
  proto: string;
  /** Confirmed 后为 JSON 字符串：{"uid":"xxx","token":"xxx"} */
  raw: string;
  ext: string;
}

/** 二维码扫描确认后解析出的 uid + game_token */
export interface QRCodeConfirmedData {
  uid: string;
  token: string;
}

/** 通过 GameToken 获取 SToken 的响应 */
export interface GetTokenByGameTokenResponse {
  retcode: number;
  message: string;
  data: GetTokenByGameTokenData;
}

interface GetTokenByGameTokenData {
  token: TokenObj;
  user_info: UserInfo;
}

interface TokenObj {
  token_type: number;
  token: string;
}

/** 通过 SToken 获取 LToken 的响应 */
export interface GetLTokenBySTokenResponse {
  retcode: number;
  message: string;
  data: GetLTokenBySTokenData;
}

interface GetLTokenBySTokenData {
  ltoken: string;
}

/** 通过 LoginTicket 获取 LToken 的响应 */
export interface GetMultiTokenResponse {
  retcode: number;
  message: string;
  data: GetMultiTokenData;
}

interface GetMultiTokenData {
  list: TokenItem[];
}

interface TokenItem {
  name: string;
  token: string;
}

/** 通过 SToken 获取 CookieToken 的响应 */
export interface GetCookieBySTokenResponse {
  retcode: number;
  message: string;
  data: GetCookieBySTokenData;
}

interface GetCookieBySTokenData {
  uid: string;
  cookie_token: string;
}

/** 游戏角色信息（来自 getUserGameRolesByCookie） */
export interface GameRoleApiInfo {
  game_biz: string;
  region: string;
  game_uid: string;
  nickname: string;
  level: number;
  is_chosen: boolean;
  region_name: string;
  is_official: boolean;
}

/** getUserGameRolesByCookie 响应 */
export interface GameRolesResponse {
  retcode: number;
  message: string;
  data: GameRolesData;
}

interface GameRolesData {
  list: GameRoleApiInfo[];
}

/** 账号详情接口返回的游戏数据项 */
interface GameRecordDataItem {
  name: string;
  type: number;
  value: string;
}

/** 账号详情接口返回的游戏角色信息 */
interface GameRecordCardItem {
  game_id: number;
  game_role_id: string;
  nickname: string;
  region: string;
  level: number;
  background_image_v2: string;
  data: GameRecordDataItem[];
  game_name: string;
}

/** getGameRecordCard 响应 */
interface GameRecordCardResponse {
  retcode: number;
  message: string;
  data: GameRecordCardData;
}

interface GameRecordCardData {
  list: GameRecordCardItem[];
}

/** BBS 账号详情响应 */
interface BbsUserInfo {
  uid: string;
  nickname: string;
  avatar_url: string;
}

interface BbsAccountDetailData {
  user_info: BbsUserInfo;
}

interface BbsAccountDetailResponse {
  retcode: number;
  message: string;
  data: BbsAccountDetailData;
}

/** BBS 账号详情结果 class（供外部使用） */
export class BbsAccountDetailResult {
  uid: string = '';
  nickname: string = '';
  avatarUrl: string = '';
  rawJson: string = '';
}

/** 登录成功后组装的完整 Cookie 字符串所需的字段 */
export class LoginCookieFields {
  accountId: string = '';
  cookieToken: string = '';
  ltoken: string = '';
  ltuid: string = '';
}

/** fetchQRCode 返回值 */
export class QRCodeFetchResult {
  url: string = '';
  ticket: string = '';
}

/** queryQRCode 返回值 */
export class QRCodeQueryResult {
  stat: string = '';
  confirmed: QRCodeConfirmedData | null = null;
}

/** getTokenByGameToken 返回值 */
export class GameTokenResult {
  stoken: string = '';
  userInfo: UserInfo = new UserInfo();
}

/** UserInfo 独立 class（供 GameTokenResult 使用） */
export class UserInfo {
  aid: string = '';
  mid: string = '';
  mobile: string = '';
}

// ─── game_biz → gameId 映射 ──────────────────────────────────────

/** 将米游社 game_biz 转换为本项目 gameId */
function gameBizToGameId(gameBiz: string): string {
  if (gameBiz === 'hk4e_cn') {
    return 'genshin';
  }
  if (gameBiz === 'hkrpg_cn') {
    return 'starrail';
  }
  if (gameBiz === 'nap_cn') {
    return 'zzz';
  }
  if (gameBiz === 'bh3_cn') {
    return 'honkai3';
  }
  return gameBiz;
}

/** 手机号登录成功后的 Token 信息 */
export class LoginMobileResult {
  stoken: string = '';
  aid: string = '';
  mid: string = '';
}

// ─── AuthRepository ──────────────────────────────────────────────

export class AuthRepository {

  /**
   * 注入的 account service（由 BBSRepository.setService() 同步设置）。
   * mock 环境下为 MihoyoAccountMockService，release 环境下为 MihoyoAccountApiService。
   */
  static accountService: MihoyoAccountApiService | null = null;

  /** 由 CoreInitializer.initCore() 设置，仅用于无 service 时的兜底判断 */
  static isMock: boolean = false;

  // ── 手机号登录 ────────────────────────────────────────────────

  /**
   * 发送短信验证码
   * mock 环境：通过 MihoyoAccountMockService 校验手机号是否存在
   * release 环境：RSA 加密后调用真实接口
   */
  static async createLoginCaptcha(mobile: string, areaCode: string = '+86'): Promise<void> {
    const svc = AuthRepository.accountService;
    if (svc !== null) {
      // 通过注入的 service 调用（mock/release 统一入口）
      // mock 环境下 service 直接用明文 mobile，release 环境下 service 内部加密
      let encryptedMobile = mobile;
      let encryptedAreaCode = areaCode;
      if (!AuthRepository.isMock) {
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
      opts.extraHeaders.set('content-type', 'application/json');
      opts.extraHeaders.set('x-rpc-app_id', ApiConfig.BBS_APP_ID);
      opts.extraHeaders.set('x-rpc-client_type', '2');
      opts.extraHeaders.set('x-rpc-aigis', '');
      opts.extraHeaders.set('Referer', 'https://user.miyoushe.com/');
      const resp = await HttpClient.post(
        'https://passport-api.mihoyo.com/account/ma-cn-verifier/verifier/createLoginCaptcha',
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
   * 提交验证码登录
   * mock 环境：校验手机号 + 验证码（固定 111111）
   * release 环境：RSA 加密后调用真实接口
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
      if (!AuthRepository.isMock) {
        encryptedMobile = await RsaUtil.encrypt(mobile);
        encryptedAreaCode = await RsaUtil.encrypt(areaCode);
      }
      const resp = await svc.loginByMobileCaptcha(encryptedMobile, encryptedAreaCode, captcha) as Record<string, Object>;
      const retcode = resp['retcode'] as number;
      if (retcode !== 0) {
        throw new Error(`[${retcode}] ${resp['message']}`);
      }
      const data = resp['data'] as Record<string, Object>;
      const token = data['token'] as Record<string, Object>;
      const userInfo = data['user_info'] as Record<string, Object>;
      const result = new LoginMobileResult();
      result.stoken = `${token['token']}`;
      result.aid = `${userInfo['aid']}`;
      result.mid = `${userInfo['mid']}`;
      return result;
    }
    // 兜底
    try {
      const encryptedMobile = await RsaUtil.encrypt(mobile);
      const encryptedAreaCode = await RsaUtil.encrypt(areaCode);
      const bodyStr = JSON.stringify({
        area_code: encryptedAreaCode,
        mobile: encryptedMobile,
        action_type: 'login_by_mobile_captcha',
        captcha: captcha,
      });
      const opts = new RequestOptions();
      opts.extraHeaders.set('content-type', 'text/plain;charset=UTF-8');
      opts.extraHeaders.set('x-rpc-app_id', ApiConfig.BBS_APP_ID);
      opts.extraHeaders.set('x-rpc-client_type', '2');
      opts.extraHeaders.set('x-rpc-aigis', '');
      const resp = await HttpClient.post(
        'https://passport-api.mihoyo.com/account/ma-cn-passport/app/loginByMobileCaptcha',
        bodyStr,
        opts
      ) as Record<string, Object>;
      const retcode = resp['retcode'] as number;
      if (retcode !== 0) {
        throw new Error(`[${retcode}] ${resp['message']}`);
      }
      const data = resp['data'] as Record<string, Object>;
      const token = data['token'] as Record<string, Object>;
      const userInfo = data['user_info'] as Record<string, Object>;
      const result = new LoginMobileResult();
      result.stoken = `${token['token']}`;
      result.aid = `${userInfo['aid']}`;
      result.mid = `${userInfo['mid']}`;
      return result;
    } catch (error) {
      const msg = error instanceof Error ? error.message : `${error}`;
      throw new Error(`AuthRepository.loginByMobileCaptcha failed: ${msg}`);
    }
  }

  /**
   * 通过 SToken 获取 LToken
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
      opts.extraHeaders.set('Cookie', `mid=${mid};stoken=${stoken}`);
      opts.extraHeaders.set('x-rpc-client_type', '5');
      opts.extraHeaders.set('Referer', 'https://webstatic.mihoyo.com');
      const resp = await NetworkFactory.getInstance().get(
        `${PASSPORT_API}/account/auth/api/getLTokenBySToken`,
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
   * 通过 SToken 获取 CookieToken
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
      opts.extraHeaders.set('Cookie', `mid=${mid};stoken=${stoken}`);
      opts.extraHeaders.set('x-rpc-client_type', '5');
      opts.extraHeaders.set('Referer', 'https://webstatic.mihoyo.com');
      const resp = await NetworkFactory.getInstance().get(
        `${PASSPORT_API}/account/auth/api/getCookieAccountInfoBySToken`,
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
   * 获取二维码 URL（二维码登录第一步）
   * 接口：POST https://hk4e-sdk.mihoyo.com/hk4e_cn/combo/panda/qrcode/fetch
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
        opts.extraHeaders.set('content-type', 'text/plain;charset=UTF-8');
        resp = await HttpClient.post(`${HK4E_SDK}/hk4e_cn/combo/panda/qrcode/fetch`, bodyStr, opts) as QRCodeFetchResponse;
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

  static async queryQRCode(deviceId: string, ticket: string): Promise<QRCodeQueryResult> {
    try {
      let resp: QRCodeQueryResponse;
      const svc = AuthRepository.accountService;
      if (svc !== null) {
        resp = await svc.queryQRCode(deviceId, ticket) as QRCodeQueryResponse;
      } else {
        const bodyStr = JSON.stringify({ app_id: 7, device: deviceId, ticket: ticket });
        const opts = new RequestOptions();
        opts.extraHeaders.set('content-type', 'text/plain;charset=UTF-8');
        resp = await HttpClient.post(`${HK4E_SDK}/hk4e_cn/combo/panda/qrcode/query`, bodyStr, opts) as QRCodeQueryResponse;
      }
      const queryResult = new QRCodeQueryResult();
      if (resp.retcode === -106) {
        queryResult.stat = 'expired';
        return queryResult;
      }
      if (resp.retcode !== 0 || resp.data === null) {
        throw new Error(`queryQRCode failed: [${resp.retcode}] ${resp.message}`);
      }
      queryResult.stat = resp.data.stat.toLowerCase();
      if (queryResult.stat === 'confirmed' && resp.data.payload.proto === 'Account') {
        queryResult.confirmed = JSON.parse(resp.data.payload.raw) as QRCodeConfirmedData;
      }
      return queryResult;
    } catch (error) {
      const msg = error instanceof Error ? error.message : `${error}`;
      throw new Error(`AuthRepository.queryQRCode failed: ${msg}`);
    }
  }

  static async getTokenByGameToken(accountId: string, gameToken: string): Promise<GameTokenResult> {
    try {
      let resp: GetTokenByGameTokenResponse;
      const svc = AuthRepository.accountService;
      if (svc !== null) {
        resp = await svc.getTokenByGameToken(accountId, gameToken) as GetTokenByGameTokenResponse;
      } else {
        const bodyStr = JSON.stringify({ account_id: parseInt(accountId, 10), game_token: gameToken });
        const opts = new RequestOptions();
        opts.extraHeaders.set('x-rpc-app_id', ApiConfig.BBS_APP_ID);
        opts.extraHeaders.set('content-type', 'application/json');
        resp = await HttpClient.post(`${TAKUMI_API}/account/ma-cn-session/app/getTokenByGameToken`, bodyStr, opts) as GetTokenByGameTokenResponse;
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
   * 通过 SToken 获取 LToken（旧版，保留供二维码登录使用）
   * 接口：GET https://passport-api.mihoyo.com/account/auth/api/getLTokenBySToken
   * @deprecated 新版手机号登录请使用 getLTokenBySToken(stoken, mid)
   */
  static async getLTokenBySTokenLegacy(stoken: string, accountId: string): Promise<string> {
    try {
      const options = new RequestOptions();
      options.extraHeaders.set('Cookie', `stoken=${stoken};stuid=${accountId}`);
      const resp = await NetworkFactory.getInstance().get(
        `${PASSPORT_API}/account/auth/api/getLTokenBySToken`,
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

  // ── 游戏角色查询 ──────────────────────────────────────────────

  /**
   * 获取米游社 BBS 账号详情（nickname、avatar_url）
   * 接口：GET https://bbs-api.miyoushe.com/user/wapi/getUserFullInfo
   */
  static async getBbsAccountDetail(cookie: string): Promise<BbsAccountDetailResult> {
    try {
      const options = new RequestOptions();
      options.extraHeaders.set('Cookie', cookie);
      const resp = await NetworkFactory.getInstance().get(
        '/user/wapi/getUserFullInfo',
        new RequestParams(),
        options
      ) as BbsAccountDetailResponse;
      if (resp.retcode !== 0) {
        throw new Error(`getBbsAccountDetail failed: [${resp.retcode}] ${resp.message}`);
      }
      const result = new BbsAccountDetailResult();
      result.uid = resp.data.user_info.uid ?? '';
      result.nickname = resp.data.user_info.nickname ?? '';
      result.avatarUrl = resp.data.user_info.avatar_url ?? '';
      result.rawJson = JSON.stringify(resp.data);
      return result;
    } catch (error) {
      const msg = error instanceof Error ? error.message : `${error}`;
      throw new Error(`AuthRepository.getBbsAccountDetail failed: ${msg}`);
    }
  }

  /**
   * 获取账号绑定的所有游戏角色
   * 接口：GET https://api-takumi.mihoyo.com/binding/api/getUserGameRolesByCookie
   */
  static async getUserGameRoles(cookie: string): Promise<GameRoleRecord[]> {
    try {
      const options = new RequestOptions();
      options.extraHeaders.set('Cookie', cookie);
      const resp = await NetworkFactory.getInstance().get(
        `${BINDING_API}/getUserGameRolesByCookie`,
        new RequestParams(),
        options
      ) as GameRolesResponse;
      if (resp.retcode !== 0) {
        throw new Error(`getUserGameRoles failed: [${resp.retcode}] ${resp.message}`);
      }
      const rows: GameRoleRecord[] = [];
      for (const info of resp.data.list) {
        const row = new GameRoleRecord();
        row.gameId = gameBizToGameId(info.game_biz);
        row.roleId = info.game_uid;
        row.nickname = info.nickname;
        row.level = info.level;
        row.server = info.region;
        rows[rows.length] = row;
      }
      return rows;
    } catch (error) {
      const msg = error instanceof Error ? error.message : `${error}`;
      throw new Error(`AuthRepository.getUserGameRoles failed: ${msg}`);
    }
  }

  /**
   * 获取账号详情（含 background_image_v2 和游戏内统计数据）
   * 接口：GET https://api-takumi-record.mihoyo.com/game_record/app/card/wapi/getGameRecordCard
   */
  static async getGameRecordCard(cookie: string, uid: string): Promise<GameRoleRecord[]> {
    try {
      const options = new RequestOptions();
      options.extraHeaders.set('Cookie', cookie);
      const params = new RequestParams();
      params.set('uid', uid);
      const resp = await NetworkFactory.getInstance().get(
        '/game_record/app/card/wapi/getGameRecordCard',
        params,
        options
      ) as GameRecordCardResponse;
      if (resp.retcode !== 0) {
        throw new Error(`getGameRecordCard failed: [${resp.retcode}] ${resp.message}`);
      }
      const rows: GameRoleRecord[] = [];
      for (const item of resp.data.list) {
        const row = new GameRoleRecord();
        row.gameId = GameId.fromMihoyoGameId(item.game_id);
        row.roleId = item.game_role_id;
        row.nickname = item.nickname;
        row.level = item.level;
        row.server = item.region;
        row.bgImageUrl = item.background_image_v2 ?? '';
        row.statsJson = JSON.stringify(item.data ?? []);
        rows[rows.length] = row;
      }
      return rows;
    } catch (error) {
      const msg = error instanceof Error ? error.message : `${error}`;
      throw new Error(`AuthRepository.getGameRecordCard failed: ${msg}`);
    }
  }

  /**
   * 组装完整 Cookie 字符串
   * 格式：account_id=xxx; cookie_token=xxx; ltoken=xxx; ltuid=xxx
   */
  static buildCookieString(fields: LoginCookieFields): string {
    return `account_id=${fields.accountId}; cookie_token=${fields.cookieToken}; ltoken=${fields.ltoken}; ltuid=${fields.ltuid}`;
  }

  // ── 国际服占位（完成度：0%）────────────────────────────────────
  // TODO: 国际服（HoYoLAB）登录 API 路径待确认
  // 预计接口：
  //   手机号：https://webapi.hoyolab.com/Api/create_mmt（路径待确认）
  //   二维码：https://sg-public-api.hoyolab.com/...（路径待确认）
  //   游戏角色：https://bbs-api-os.hoyolab.com/game_record/card/wapi/getGameRecordCard
  // 完成度：0% — UI 不展示，逻辑待实现
}
