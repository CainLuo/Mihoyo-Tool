/**
 * WidgetGame.ets — Widget 游戏数据模型
 *
 * 字段命名与 core 模块保持一致
 */

import { WidgetRole, WidgetRoleJson } from './WidgetRole';

/** WidgetGame JSON 结构 */
export interface WidgetGameJson {
  gameId?: string;
  roles?: WidgetRoleJson[];
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

  static fromJson(obj: WidgetGameJson): WidgetGame {
    const d = new WidgetGame();
    d.gameId = obj.gameId ?? '';
    if (obj.roles !== undefined && obj.roles !== null) {
      for (let i = 0; i < obj.roles.length; i++) {
        d.roles.push(WidgetRole.fromJson(obj.roles[i]));
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
