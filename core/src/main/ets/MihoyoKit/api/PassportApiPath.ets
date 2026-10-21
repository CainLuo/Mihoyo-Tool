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
}
