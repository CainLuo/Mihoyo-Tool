/**
 * WidgetConfigPreview.ets — Widget 配置页卡片预览组件
 *
 * 根据选中的尺寸和 slots 渲染卡片预览。
 * 使用占位数据，仅用于配置页预览，不依赖真实 Widget 数据。
 *
 * 布局与真实 Widget 保持一致：
 * - 1x2：左侧游戏色竖线 + 游戏名/UID/体力/恢复时间
 * - 2x2 单游戏：头部 + 体力区块 + 额外数据行
 * - 2x2 多游戏：两个 1x2 内容纵向排列
 * - 2x4：与 2x2 相同（宽度翻倍）
 * - 4x4：与 2x2 相同（宽高翻倍）
 *
 * 使用 @ComponentV2（配置页场景），复用 WidgetColors 颜色常量。
 */

import { themeManager, ThemeManager } from '../../theme/ThemeManager';
import { WidgetSize } from '../../widget/models/WidgetConfig';
import { WidgetSlotRef } from '../../widget/models/WidgetDataStore';
import { GameId } from 'core';
import { PreviewEmptyContent } from './preview/PreviewEmptyContent';
import { Preview1x2Card } from './preview/Preview1x2Card';
import { Preview2x2SingleGame } from './preview/Preview2x2SingleGame';
import { Preview2x2MultiSlot } from './preview/Preview2x2MultiSlot';
import { Preview2x4SingleGame } from './preview/Preview2x4SingleGame';
import { Preview2x4MultiSlot } from './preview/Preview2x4MultiSlot';
import { Preview4x4MultiSlot } from './preview/Preview4x4MultiSlot';
import { Preview4x4SingleGame } from './preview/Preview4x4SingleGame';
import { toGameId, isSingleGame, gameIdToBgColors } from './preview/WidgetPreviewUtils';

/** 尺寸宽高配置 */
class SizeDimension {
  width: number = 168;
  height: number = 168;

  constructor(width: number, height: number) {
    this.width = width;
    this.height = height;
  }
}

/** 尺寸配置 */
const SIZE_DIMENSIONS: Record<string, SizeDimension> = {
  [WidgetSize.SIZE_1x2]: new SizeDimension(168, 80),
  [WidgetSize.SIZE_2x2]: new SizeDimension(168, 168),
  [WidgetSize.SIZE_2x4]: new SizeDimension(336, 168),
  [WidgetSize.SIZE_4x4]: new SizeDimension(336, 336),
};

/** 根据多个游戏 ID 生成混合渐变色 */
function multiGameGradientColors(slots: WidgetSlotRef[]): Array<[ResourceColor, number]> {
  const gameIds: GameId[] = [];

  for (let i = 0; i < slots.length; i++) {
    const gameId = toGameId(slots[i].gameId);
    let found = false;
    for (let j = 0; j < gameIds.length; j++) {
      if (gameIds[j] === gameId) {
        found = true;
        break;
      }
    }
    if (!found) {
      gameIds.push(gameId);
    }
  }

  if (gameIds.length === 0) {
    return [[$r('app.color.widget_bg_default_1'), 0], [$r('app.color.widget_bg_default_2'), 1]];
  }

  if (gameIds.length === 1) {
    const colors = gameIdToBgColors(gameIds[0]);
    return [[colors[0], 0], [colors[1], 0.5], [colors[2], 1]];
  }

  // 双游戏
  if (gameIds.length === 2) {
    const c0 = gameIdToBgColors(gameIds[0]);
    const c1 = gameIdToBgColors(gameIds[1]);
    return [[c0[0], 0], [c0[1], 0.4], [c1[1], 0.6], [c1[0], 1]];
  }

  // 三游戏及以上
  const count = gameIds.length;
  const colors: Resource[][] = [];
  for (let i = 0; i < count; i++) {
    colors.push(gameIdToBgColors(gameIds[i]));
  }

  const result: Array<[ResourceColor, number]> = [];
  result.push([colors[0][0], 0]);

  for (let i = 0; i < count; i++) {
    const position = (i + 0.5) / count;
    result.push([colors[i][1], position]);
  }

  result.push([colors[count - 1][0], 1]);

  return result;
}

@ComponentV2
export struct WidgetConfigPreview {
  @Param selectedSize: WidgetSize = WidgetSize.SIZE_2x2;
  @Param selectedSlots: WidgetSlotRef[] = [];
  @Local private tm: ThemeManager = themeManager;

  private get dimensions(): SizeDimension {
    const dim = SIZE_DIMENSIONS[this.selectedSize];
    return dim !== undefined ? dim : SIZE_DIMENSIONS[WidgetSize.SIZE_2x2];
  }

  private get firstGameId(): GameId {
    if (this.selectedSlots.length === 0) {
      return GameId.GENSHIN;
    }
    return toGameId(this.selectedSlots[0].gameId);
  }

  private get isSingleGameMode(): boolean {
    const gameIds: string[] = [];
    for (let i = 0; i < this.selectedSlots.length; i++) {
      gameIds.push(this.selectedSlots[i].gameId);
    }
    return isSingleGame(gameIds);
  }

  private get cardGradient(): LinearGradient {
    // 多游戏时使用混合渐变色
    if (!this.isSingleGameMode) {
      return {
        angle: this.tm.current.a135,
        colors: multiGameGradientColors(this.selectedSlots)
      };
    }
    // 单游戏时使用该游戏的渐变色
    const colors = gameIdToBgColors(this.firstGameId);
    return {
      angle: this.tm.current.a135,
      colors: [[colors[0], 0], [colors[1], 0.5], [colors[2], 1]]
    };
  }

  build() {
    Column() {
      if (this.selectedSlots.length === 0) {
        // 空态
        PreviewEmptyContent()
      } else if (this.selectedSize === WidgetSize.SIZE_1x2) {
        // 1x2 预览
        Preview1x2Card({
          gameId: this.firstGameId,
          roleId: this.selectedSlots[0].roleId
        })
      } else if (this.selectedSize === WidgetSize.SIZE_2x2) {
        // 2x2 预览
        if (this.isSingleGameMode) {
          Preview2x2SingleGame({
            gameId: this.firstGameId,
            roleId: this.selectedSlots[0].roleId
          })
        } else {
          Preview2x2MultiSlot({ slots: this.selectedSlots })
        }
      } else if (this.selectedSize === WidgetSize.SIZE_2x4) {
        // 2x4 预览
        if (this.isSingleGameMode) {
          Preview2x4SingleGame({
            gameId: this.firstGameId,
            roleId: this.selectedSlots[0].roleId
          })
        } else {
          Preview2x4MultiSlot({ slots: this.selectedSlots })
        }
      } else {
        // 4x4 预览
        if (this.isSingleGameMode) {
          Preview4x4SingleGame({
            gameId: this.firstGameId,
            roleId: this.selectedSlots[0].roleId
          })
        } else {
          Preview4x4MultiSlot({ slots: this.selectedSlots })
        }
      }
    }
    .width(this.dimensions.width)
    .height(this.dimensions.height)
    .padding(this.tm.current.value12)
    .linearGradient(this.cardGradient)
    .borderRadius(this.tm.current.radius12)
    .shadow({
      radius: 8,
      offsetY: 2,
      color: 'rgba(0,0,0,0.5)'
    })
  }
}
