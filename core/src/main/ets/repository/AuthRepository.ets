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

// ─── AuthRepository ──────────────────────────────────────────────

export class AuthRepository {

  // ── 手机号登录 ────────────────────────────────────────────────

  /**
   * 申请人机验证任务（手机号登录第一步）
   * 接口：GET https://webapi.account.mihoyo.com/Api/create_mmt
   *
   * @returns MmtData，mmt_type=0 表示无需 Geetest，直接用 mmt_key 发短信
   */
  static async createMmt(): Promise<MmtData> {
    try {
      const now = Math.floor(Date.now() / 1000);
      const params = new RequestParams();
      params.set('scene_type', '1');
      params.set('now', `${now}`);
      params.set('reason', 'user.mihoyo.com%2523%252Flogin%252Fcaptcha');
      params.set('action_type', 'login_by_mobile_captcha');
      const resp = await NetworkFactory.getInstance().get(
        `${WEBAPI_ACCOUNT}/create_mmt`,
        params,
        new RequestOptions()
      ) as MmtResponse;
      if (resp.code !== 200 || resp.data.status !== 1) {
        throw new Error(`createMmt failed: code=${resp.code}`);
      }
      return resp.data.mmt_data;
    } catch (error) {
      const msg = error instanceof Error ? error.message : `${error}`;
      throw new Error(`AuthRepository.createMmt failed: ${msg}`);
    }
  }

  /**
   * 发送短信验证码（手机号登录第二步）
   * 接口：POST https://webapi.account.mihoyo.com/Api/create_mobile_captcha
   */
  static async sendSmsCode(
    mobile: string,
    mmtKey: string,
    v4Data?: GeetestV4Data,
    v3Challenge?: string,
    v3Validate?: string,
    v3Seccode?: string
  ): Promise<void> {
    try {
      const now = Math.floor(Date.now() / 1000);
      const params = new RequestParams();
      params.set('action_type', 'login');
      params.set('mmt_key', mmtKey);
      params.set('mobile', mobile);
      params.set('t', `${now}`);
      if (v4Data !== undefined) {
        params.set('geetest_v4_data', JSON.stringify(v4Data));
      }
      if (v3Challenge !== undefined) {
        params.set('geetest_challenge', v3Challenge);
      }
      if (v3Validate !== undefined) {
        params.set('geetest_validate', v3Validate);
      }
      if (v3Seccode !== undefined) {
        params.set('geetest_seccode', v3Seccode);
      }
      const resp = await NetworkFactory.getInstance().post(
        `${WEBAPI_ACCOUNT}/create_mobile_captcha`,
        params,
        new RequestOptions()
      ) as MmtResponse;
      if (resp.code !== 200 || resp.data.status !== 1) {
        throw new Error(`sendSmsCode failed: code=${resp.code} status=${resp.data.status}`);
      }
    } catch (error) {
      const msg = error instanceof Error ? error.message : `${error}`;
      throw new Error(`AuthRepository.sendSmsCode failed: ${msg}`);
    }
  }

  /**
   * 用短信验证码换取 LoginTicket（手机号登录第三步）
   * 接口：POST https://webapi.account.mihoyo.com/Api/login_by_mobilecaptcha
   */
  static async loginByPhone(mobile: string, captcha: string): Promise<PhoneLoginAccountInfo> {
    try {
      const now = Math.floor(Date.now() / 1000);
      const params = new RequestParams();
      params.set('mobile', mobile);
      params.set('mobile_captcha', captcha);
      params.set('source', 'user.mihoyo.com');
      params.set('t', `${now}`);
      const resp = await NetworkFactory.getInstance().post(
        `${WEBAPI_ACCOUNT}/login_by_mobilecaptcha`,
        params,
        new RequestOptions()
      ) as PhoneLoginResponse;
      if (resp.code !== 200 || resp.data.status !== 1) {
        throw new Error(`loginByPhone failed: code=${resp.code} status=${resp.data.status}`);
      }
      return resp.data.account_info;
    } catch (error) {
      const msg = error instanceof Error ? error.message : `${error}`;
      throw new Error(`AuthRepository.loginByPhone failed: ${msg}`);
    }
  }

  /**
   * 通过 LoginTicket 获取 LToken
   * 接口：GET https://api-takumi.mihoyo.com/auth/api/getMultiTokenByLoginTicket
   */
  static async getLTokenByTicket(loginTicket: string, accountId: number): Promise<string> {
    try {
      const params = new RequestParams();
      params.set('token_types', '2');
      params.set('login_ticket', loginTicket);
      params.set('uid', `${accountId}`);
      const resp = await NetworkFactory.getInstance().get(
        `${TAKUMI_API}/auth/api/getMultiTokenByLoginTicket`,
        params,
        new RequestOptions()
      ) as GetMultiTokenResponse;
      if (resp.retcode !== 0) {
        throw new Error(`getLTokenByTicket failed: [${resp.retcode}] ${resp.message}`);
      }
      for (const item of resp.data.list) {
        if (item.name === 'ltoken') {
          return item.token;
        }
      }
      throw new Error('getLTokenByTicket: ltoken not found in response');
    } catch (error) {
      const msg = error instanceof Error ? error.message : `${error}`;
      throw new Error(`AuthRepository.getLTokenByTicket failed: ${msg}`);
    }
  }

  /**
   * 通过 SToken 获取 CookieToken
   * 接口：GET https://api-takumi.mihoyo.com/auth/api/getCookieAccountInfoBySToken
   */
  static async getCookieBySToken(stoken: string, accountId: string): Promise<string> {
    try {
      const params = new RequestParams();
      params.set('stoken', stoken);
      params.set('uid', accountId);
      const resp = await NetworkFactory.getInstance().get(
        `${TAKUMI_API}/auth/api/getCookieAccountInfoBySToken`,
        params,
        new RequestOptions()
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
      const params = new RequestParams();
      params.set('app_id', '4');
      params.set('device', deviceId);
      const resp = await NetworkFactory.getInstance().post(
        `${HK4E_SDK}/hk4e_cn/combo/panda/qrcode/fetch`,
        params,
        new RequestOptions()
      ) as QRCodeFetchResponse;
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
   * 查询二维码扫描状态（二维码登录第二步，需轮询）
   * 接口：POST https://hk4e-sdk.mihoyo.com/hk4e_cn/combo/panda/qrcode/query
   */
  static async queryQRCode(
    deviceId: string,
    ticket: string
  ): Promise<QRCodeQueryResult> {
    try {
      const params = new RequestParams();
      params.set('app_id', '4');
      params.set('device', deviceId);
      params.set('ticket', ticket);
      const resp = await NetworkFactory.getInstance().post(
        `${HK4E_SDK}/hk4e_cn/combo/panda/qrcode/query`,
        params,
        new RequestOptions()
      ) as QRCodeQueryResponse;
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
        const raw = resp.data.payload.raw;
        queryResult.confirmed = JSON.parse(raw) as QRCodeConfirmedData;
      }
      return queryResult;
    } catch (error) {
      const msg = error instanceof Error ? error.message : `${error}`;
      throw new Error(`AuthRepository.queryQRCode failed: ${msg}`);
    }
  }

  /**
   * 通过 GameToken 获取 SToken（二维码登录第三步）
   * 接口：POST https://api-takumi.mihoyo.com/account/ma-cn-session/app/getTokenByGameToken
   */
  static async getTokenByGameToken(
    accountId: string,
    gameToken: string
  ): Promise<GameTokenResult> {
    try {
      const params = new RequestParams();
      params.set('account_id', accountId);
      params.set('game_token', gameToken);
      const options = new RequestOptions();
      options.extraHeaders.set('x-rpc-app_id', 'bll8iq97cem8');
      const resp = await NetworkFactory.getInstance().post(
        `${TAKUMI_API}/account/ma-cn-session/app/getTokenByGameToken`,
        params,
        options
      ) as GetTokenByGameTokenResponse;
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
   * 通过 SToken 获取 LToken
   * 接口：GET https://passport-api.mihoyo.com/account/auth/api/getLTokenBySToken
   */
  static async getLTokenBySToken(stoken: string, accountId: string): Promise<string> {
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
