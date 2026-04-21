/**
 * GameId.ets
 *
 * 游戏 ID 枚举，提供米游社 game_id 数字到本项目 GameId 的映射。
 * 所有 gameId 字段必须使用此枚举，禁止直接写字符串字面量。
 */
export enum GameId {
  GENSHIN = 'genshin',
  STARRAIL = 'starrail',
  ZZZ = 'zzz',
  HONKAI3 = 'honkai3',
}

/**
 * 当前支持展示的游戏列表。
 * 不在此列表中的游戏角色会在登录时被过滤，不写入 DB。
 */
export const SUPPORTED_GAMES: GameId[] = [
  GameId.GENSHIN,
  GameId.STARRAIL,
  GameId.ZZZ,
];

/** 判断某个 gameId 是否受支持 */
export function isGameSupported(gameId: GameId | string): boolean {
  for (let i = 0; i < SUPPORTED_GAMES.length; i++) {
    if (SUPPORTED_GAMES[i] === gameId) {
      return true;
    }
  }
  return false;
}

/**
 * 将米游社 game_id 数字转换为 GameId 枚举。
 * 米游社 game_id 对应关系：
 *   2 = 原神（hk4e_cn）
 *   6 = 崩坏：星穹铁道（hkrpg_cn）
 *   8 = 绝区零（nap_cn）
 *   1 = 崩坏3（bh3_cn）
 */
export function gameIdFromMihoyo(gameId: number): GameId {
  if (gameId === 2) { return GameId.GENSHIN; }
  if (gameId === 6) { return GameId.STARRAIL; }
  if (gameId === 8) { return GameId.ZZZ; }
  if (gameId === 1) { return GameId.HONKAI3; }
  return GameId.GENSHIN; // fallback
}
