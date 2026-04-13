/**
 * TokenModels.ets
 *
 * Token 换取流程相关的数据模型。
 * 对应接口：
 *   POST /account/ma-cn-session/app/getTokenByGameToken  — GameToken → SToken
 *   GET  /account/auth/api/getLTokenBySToken             — SToken → LToken
 *   GET  /account/auth/api/getCookieAccountInfoBySToken  — SToken → CookieToken
 */

// ─── GameToken → SToken ───────────────────────────────────────────

/** getTokenByGameToken 接口响应 */
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
  /** Token 类型（通常为 1） */
  token_type: number;
  /** SToken 字符串 */
  token: string;
}

/** getTokenByGameToken 业务结果 */
export class GameTokenResult {
  /** SToken（长期有效） */
  stoken: string = '';
  /** 用户基础信息 */
  userInfo: UserInfo = new UserInfo();
}

/** 用户基础信息（来自 getTokenByGameToken 响应） */
export class UserInfo {
  /** 账号 ID */
  aid: string = '';
  /** 设备 mid */
  mid: string = '';
  /** 绑定手机号（脱敏） */
  mobile: string = '';
}

// ─── SToken → LToken ─────────────────────────────────────────────

/** getLTokenBySToken 接口响应 */
export interface GetLTokenBySTokenResponse {
  retcode: number;
  message: string;
  data: GetLTokenBySTokenData;
}

interface GetLTokenBySTokenData {
  /** LToken 字符串 */
  ltoken: string;
}

// ─── LoginTicket → LToken（旧版，保留兼容） ───────────────────────

/** getMultiToken 接口响应（通过 LoginTicket 换取多个 Token） */
export interface GetMultiTokenResponse {
  retcode: number;
  message: string;
  data: GetMultiTokenData;
}

interface GetMultiTokenData {
  list: TokenItem[];
}

interface TokenItem {
  /** Token 名称（如 'ltoken'、'stoken'） */
  name: string;
  /** Token 值 */
  token: string;
}

// ─── SToken → CookieToken ────────────────────────────────────────

/** getCookieAccountInfoBySToken 接口响应 */
export interface GetCookieBySTokenResponse {
  retcode: number;
  message: string;
  data: GetCookieBySTokenData;
}

interface GetCookieBySTokenData {
  /** 账号 UID */
  uid: string;
  /** CookieToken（用于组装完整 Cookie） */
  cookie_token: string;
}

// ─── Cookie 组装 ──────────────────────────────────────────────────

/** 登录成功后组装完整 Cookie 字符串所需的字段 */
export class LoginCookieFields {
  /** 米游社账号 ID */
  accountId: string = '';
  /** CookieToken */
  cookieToken: string = '';
  /** LToken */
  ltoken: string = '';
  /** LToken 对应的 UID（ltuid） */
  ltuid: string = '';
}
