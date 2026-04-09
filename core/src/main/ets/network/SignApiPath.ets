export enum SignApiPath {
  /**
   * 大别野签到 — Domain: BBS_APIHUB
   * 完整 URL = BBS_APIHUB + SIGN_BBS = https://bbs-api.miyoushe.com/apihub/app/api/signIn
   */
  SIGN_BBS = '/app/api/signIn',
  /**
   * 游戏签到基础路径 — Domain: TAKUMI
   * 完整路径需拼接游戏 host，如：
   *   原神签到：SIGN_GAME_BASE + '/hk4e/sign'
   *   星铁签到：SIGN_GAME_BASE + '/hkrpg/sign'
   *   绝区零签到：SIGN_GAME_BASE + '/zzz/sign'
   */
  SIGN_GAME_BASE = '/event/luna',
}
