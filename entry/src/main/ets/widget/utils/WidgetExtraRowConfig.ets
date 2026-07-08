/**
 * WidgetExtraRowConfig.ets — 额外信息行优先级配置
 *
 * 为原神和星铁的额外信息定义显示优先级。
 * 数字越小优先级越高，当 maxRows 限制数量时，优先显示高优先级行。
 *
 * 绝区零直接使用 API 返回的 note_list 字段，不需要优先级配置。
 */

import { ExtraRowType } from './WidgetExtraRowType';
import { WIDGET_GAME_ID } from './WidgetUtils';

/**
 * 额外信息行优先级配置
 */
export class WidgetExtraRowConfig {
  /**
   * 原神优先级配置
   * 探索派遣 > 洞天宝钱 > 每日委托 > 参量质变仪 > 周活跃进度
   */
  static readonly GENSHIN_PRIORITY: Record<string, number> = {
    [ExtraRowType.GENSHIN_EXPEDITION]: 1,
    [ExtraRowType.GENSHIN_HOME_COIN]: 2,
    [ExtraRowType.GENSHIN_DAILY_TASK]: 3,
    [ExtraRowType.GENSHIN_TRANSFORMER]: 4,
    [ExtraRowType.GENSHIN_WEEK_ACTIVE]: 5,
  };

  /**
   * 星铁优先级配置
   * 委托派遣 > 每日实训 > 模拟宇宙积分
   */
  static readonly STARRAIL_PRIORITY: Record<string, number> = {
    [ExtraRowType.STARRAIL_EXPEDITION]: 1,
    [ExtraRowType.STARRAIL_TRAIN_SCORE]: 2,
    [ExtraRowType.STARRAIL_ROGUE_TOURN]: 3,
  };

  /**
   * 根据游戏 ID 获取优先级配置
   *
   * @param gameId 游戏 ID
   * @returns 优先级配置对象，key 为 label 字符串，value 为优先级（数字越小越优先）
   */
  static getPriority(gameId: string): Record<string, number> {
    if (gameId === WIDGET_GAME_ID.GENSHIN) {
      return WidgetExtraRowConfig.GENSHIN_PRIORITY;
    }
    if (gameId === WIDGET_GAME_ID.STARRAIL) {
      return WidgetExtraRowConfig.STARRAIL_PRIORITY;
    }
    // 其他游戏返回空对象（不排序）
    return {};
  }
}
