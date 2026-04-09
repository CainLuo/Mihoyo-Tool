/**
 * GameId.ets
 *
 * 游戏 ID 工具类，提供米游社 game_id 数字到本项目 gameId 字符串的映射。
 */
export class GameId {
  /** 原神 */
  static readonly GENSHIN: string = 'genshin';
  /** 崩坏：星穹铁道 */
  static readonly STARRAIL: string = 'starrail';
  /** 绝区零 */
  static readonly ZZZ: string = 'zzz';
  /** 崩坏3 */
  static readonly HONKAI3: string = 'honkai3';

  /**
   * 将米游社 game_id 数字转换为本项目 gameId 字符串。
   * 米游社 game_id 对应关系：
   *   2 = 原神（hk4e_cn）
   *   6 = 崩坏：星穹铁道（hkrpg_cn）
   *   8 = 绝区零（nap_cn）
   *   1 = 崩坏3（bh3_cn）
   */
  static fromMihoyoGameId(gameId: number): string {
    if (gameId === 2) {
      return GameId.GENSHIN;
    }
    if (gameId === 6) {
      return GameId.STARRAIL;
    }
    if (gameId === 8) {
      return GameId.ZZZ;
    }
    if (gameId === 1) {
      return GameId.HONKAI3;
    }
    return `unknown_${gameId}`;
  }
}
