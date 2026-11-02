/**
 * HomeCardPresenter.ets
 *
 * 首页卡片展示辅助：游戏主题色 / Logo / 同步描述 / 主体力颜色。
 * 纯静态工具，不持有状态；HomeViewModel 保留同名静态方法作为对外 facade。
 */
import { getGameColor as resolveGameColor, getGameLogo as resolveGameLogo } from 'basic';
import { GameId } from 'core';

export class HomeCardPresenter {
  /** 根据 gameId 返回对应的游戏主题色资源引用 */
  static getGameColor(gameId: GameId): ResourceColor {
    return resolveGameColor(gameId);
  }

  /** 根据 gameId 返回对应的游戏 Logo 图标资源 */
  static getGameLogo(gameId: GameId): Resource {
    return resolveGameLogo(gameId);
  }

  /**
   * 根据上次同步时间戳生成同步描述 key，供 GameToolCardHeader.syncDescResource 使用
   * 格式：
   *   'sync_not_synced'         — 从未同步
   *   'sync_just_now'           — 1 分钟内
   *   'sync_minutes_ago:{n}'    — n 分钟前（1 ≤ n < 60）
   *   'sync_hours_ago:{n}'      — n 小时前（1 ≤ n < 24）
   *   'sync_long_ago'           — 超过 24 小时
   */
  static syncDescKey(lastSyncTime: number): string {
    if (lastSyncTime === 0) {
      return 'sync_not_synced';
    }
    const now = Math.floor(Date.now() / 1000);
    const diffSec = now - lastSyncTime;
    if (diffSec < 60) {
      return 'sync_just_now';
    }
    const diffMin = Math.floor(diffSec / 60);
    if (diffMin < 60) {
      return `sync_minutes_ago:${diffMin}`;
    }
    const diffHour = Math.floor(diffMin / 60);
    if (diffHour < 24) {
      return `sync_hours_ago:${diffHour}`;
    }
    return 'sync_long_ago';
  }

  /**
   * 根据体力比例和游戏类型计算主体力颜色。
   * 原神树脂满了 = danger（需要消耗），其他游戏体力满了 = primary（好事）。
   */
  static getPrimaryColor(gameId: GameId, current: number, max: number, isFull: boolean): ResourceColor {
    if (isFull) {
      return gameId === GameId.GENSHIN
        ? $r('app.color.color_danger')
        : $r('app.color.color_primary');
    }
    const ratio = max > 0 ? current / max : 0;
    if (ratio < 0.3) { return $r('app.color.color_danger'); }
    if (ratio < 0.7) { return $r('app.color.color_warning'); }
    return $r('app.color.color_primary');
  }
}
