/**
 * WidgetPreviewModels.ets — Widget 预览组件数据模型
 *
 * 提供预览组件所需的占位数据和工具函数。
 */

import { GameId } from 'core';

/**
 * 占位数据：体力值
 */
export class PreviewStamina {
  cur: number = 0;
  max: number = 0;
  recHours: number = 0;
  recMinutes: number = 0;

  constructor(cur: number, max: number, recHours: number, recMinutes: number) {
    this.cur = cur;
    this.max = max;
    this.recHours = recHours;
    this.recMinutes = recMinutes;
  }
}

/**
 * 获取占位体力数据
 */
export function getPreviewStaminaData(gameId: GameId): PreviewStamina {
  if (gameId === GameId.GENSHIN) {
    return new PreviewStamina(140, 160, 2, 30);
  }
  if (gameId === GameId.STARRAIL) {
    return new PreviewStamina(200, 240, 3, 15);
  }
  if (gameId === GameId.ZZZ) {
    return new PreviewStamina(180, 240, 2, 0);
  }
  return new PreviewStamina(0, 160, 0, 0);
}
