/**
 * WidgetAccount.ets — Widget 账号数据模型
 *
 * 字段命名与 core 模块保持一致
 */

import { WidgetGame, WidgetGameJson } from './WidgetGame';
import { WidgetRole } from './WidgetRole';

/** WidgetAccount JSON 结构 */
interface WidgetAccountJson {
  accountId?: string;
  accountName?: string;
  games?: WidgetGameJson[];
}

/**
 * Widget 账号数据（单个账号下的所有游戏）
 */
export class WidgetAccount {
  /** 米游社账号 UID */
  accountId: string = '';
  /** 账号昵称（用于显示） */
  accountName: string = '';
  /** 该账号下的游戏列表 */
  games: WidgetGame[] = [];

  toJson(): WidgetAccountJson {
    const obj: WidgetAccountJson = {
      accountId: this.accountId,
      accountName: this.accountName,
      games: this.games.map((g) => g.toJson()),
    };
    return obj;
  }

  static fromJson(obj: WidgetAccountJson): WidgetAccount {
    const d = new WidgetAccount();
    d.accountId = obj.accountId ?? '';
    d.accountName = obj.accountName ?? '';
    if (obj.games !== undefined && obj.games !== null) {
      for (let i = 0; i < obj.games.length; i++) {
        d.games.push(WidgetGame.fromJson(obj.games[i]));
      }
    }
    return d;
  }

  /**
   * 根据 gameId 获取游戏数据
   */
  getGame(gameId: string): WidgetGame | null {
    for (let i = 0; i < this.games.length; i++) {
      if (this.games[i].gameId === gameId) {
        return this.games[i];
      }
    }
    return null;
  }

  /**
   * 获取第一个游戏的第一个角色（用于默认显示）
   */
  get firstRole(): WidgetRole | null {
    if (this.games.length > 0 && this.games[0].roles.length > 0) {
      return this.games[0].roles[0];
    }
    return null;
  }
}
