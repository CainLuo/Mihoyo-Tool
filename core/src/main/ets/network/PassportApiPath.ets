export enum PassportApiPath {
  /** 用 stoken 换取 cookie_token — Domain: PASSPORT */
  GET_COOKIE_TOKEN_BY_STOKEN = '/account/auth/api/getCookieAccountInfoBySToken',
  /** 用 stoken 换取 ltoken — Domain: PASSPORT */
  GET_LTOKEN_BY_STOKEN = '/account/auth/api/getLTokenBySToken',
  /** 验证 ltoken 有效性 — Domain: PASSPORT_V4 */
  VERIFY_LTOKEN = '/account/ma-cn-session/app/verify',
  /** 手机号登录 - 发送验证码 — Domain: PASSPORT */
  CREATE_LOGIN_CAPTCHA = '/account/ma-cn-verifier/verifier/createLoginCaptcha',
  /** 手机号登录 - 提交验证码 — Domain: PASSPORT */
  LOGIN_BY_MOBILE_CAPTCHA = '/account/ma-cn-passport/app/loginByMobileCaptcha',
  /** 二维码登录 - GameToken 换取 SToken — Domain: TAKUMI */
  GET_TOKEN_BY_GAME_TOKEN = '/account/ma-cn-session/app/getTokenByGameToken',

  // ── V2 Token Exchange（v2_ 格式 stoken 专用）────────────────────

  /**
   * 用 v2 stoken 换取 cookie_token_v2 — Domain: PASSPORT
   * 参考：genshin.py COOKIE_V2_REFRESH_URL
   */
  GET_COOKIE_BY_STOKEN_V2 = '/account/auth/api/getCookieBySToken',
  /**
   * 用 v2 stoken 换取账号信息（含 cookie_token_v2）— Domain: PASSPORT
   * 参考：genshin.py CN_GET_COOKIE_TOKEN_BY_STOKEN_URL
   * 注意：此 API 与 V1 路径不同，V2 版本路径不含 "AccountInfo"
   */
  GET_COOKIE_ACCOUNT_INFO_BY_STOKEN_V2 = '/account/auth/api/getCookieAccountInfoBySToken',
}
