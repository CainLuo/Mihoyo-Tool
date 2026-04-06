export enum PassportApiPath {
  /** 用 stoken 换取 cookie_token — Domain: PASSPORT */
  GET_COOKIE_TOKEN_BY_STOKEN = '/account/auth/api/getCookieAccountInfoBySToken',
  /** 用 stoken 换取 ltoken — Domain: PASSPORT */
  GET_LTOKEN_BY_STOKEN = '/account/auth/api/getLTokenBySToken',
  /** 验证 ltoken 有效性 — Domain: PASSPORT_V4 */
  VERIFY_LTOKEN = '/account/ma-cn-session/app/verify',
}
