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

/** 游戏每日签到活动 ID（米游社固定值） */
export const SIGN_GAME_ACT_ID: string = 'e202311201442471';

/**
 * 从 gameBiz 提取签到 host（如 hk4e_cn → hk4e）
 * SignApiService 和 SignMockService 共用此函数
 */
export function gameBizToSignHost(gameBiz: string): string {
  if (gameBiz.startsWith('hk4e')) { return 'hk4e'; }
  if (gameBiz.startsWith('hkrpg')) { return 'hkrpg'; }
  if (gameBiz.startsWith('nap') || gameBiz.startsWith('zzz')) { return 'zzz'; }
  const idx = gameBiz.indexOf('_');
  return idx > 0 ? gameBiz.substring(0, idx) : gameBiz;
}
