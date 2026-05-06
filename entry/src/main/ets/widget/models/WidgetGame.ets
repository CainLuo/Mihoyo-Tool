/**
 * WidgetGame.ets — Widget 游戏数据模型
 *
 * 字段命名与 core 模块保持一致
 */

import { WidgetRole } from './WidgetRole';

/** WidgetGame JSON 结构 */
interface WidgetGameJson {
  gameId: string;
  roles: Object[];
}

/**
 * Widget 游戏数据（单个游戏下的所有角色）
 */
export class WidgetGame {
  /** 游戏 ID（GameId 枚举值：genshin/starrail/zzz） */
  gameId: string = '';
  /** 该游戏下的角色列表 */
  roles: WidgetRole[] = [];

  toJson(): WidgetGameJson {
    const obj: WidgetGameJson = {
      gameId: this.gameId,
      roles: this.roles.map((r) => r.toJson()),
    };
    return obj;
  }

  static fromJson(obj: Record<string, Object>): WidgetGame {
    const d = new WidgetGame();
    if (obj['gameId'] !== undefined) { d.gameId = obj['gameId'] as string; }
    if (obj['roles'] !== undefined) {
      const rolesArr = obj['roles'] as Object[];
      for (let i = 0; i < rolesArr.length; i++) {
        d.roles.push(WidgetRole.fromJson(rolesArr[i] as Record<string, Object>));
      }
    }
    return d;
  }

  /**
   * 获取第一个角色（用于默认显示）
   */
  get firstRole(): WidgetRole | null {
    if (this.roles.length > 0) {
      return this.roles[0];
    }
    return null;
  }
}
