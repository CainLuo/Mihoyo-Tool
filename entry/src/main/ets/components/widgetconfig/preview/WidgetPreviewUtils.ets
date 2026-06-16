/**
 * WidgetPreviewUtils — Widget 预览组件工具函数
 *
 * 提供体力颜色计算、恢复时间格式化等工具函数。
 * 所有 Widget 预览组件共享使用。
 */

import { GameId } from 'core';
import { WidgetColors, StaminaColorType } from '../../../widget/models/WidgetUIStates';
import { PreviewStaminaData } from '../../../models/WidgetPreviewModels';

// ── 游戏相关 ─────────────────────────────────────────────────────

/** 游戏 Widget 名称资源（使用 widget_ 前缀的资源） */
export function gameIdToWidgetName(gameId: GameId): ResourceStr {
  if (gameId === GameId.GENSHIN) {
    return $r('app.string.widget_game_genshin');
  }
  if (gameId === GameId.STARRAIL) {
    return $r('app.string.widget_game_starrail');
  }
  if (gameId === GameId.ZZZ) {
    return $r('app.string.widget_game_zzz');
  }
  return '';
}

/** 游戏主题色（WidgetColors） */
export function gameIdToWidgetColor(gameId: GameId): Resource {
  if (gameId === GameId.GENSHIN) {
    return WidgetColors.GENSHIN_PRIMARY;
  }
  if (gameId === GameId.STARRAIL) {
    return WidgetColors.STARRAIL_PRIMARY;
  }
  if (gameId === GameId.ZZZ) {
    return WidgetColors.ZZZ_PRIMARY;
  }
  return WidgetColors.GAME_DEFAULT;
}

/** 游戏背景渐变色（返回 Resource 数组，用于 linearGradient.colors） */
export function gameIdToBgColors(gameId: GameId): Resource[] {
  if (gameId === GameId.GENSHIN) {
    return [$r('app.color.widget_bg_genshin_1'), $r('app.color.widget_bg_genshin_2'), $r('app.color.widget_bg_genshin_3')];
  }
  if (gameId === GameId.STARRAIL) {
    return [$r('app.color.widget_bg_starrail_1'), $r('app.color.widget_bg_starrail_2'), $r('app.color.widget_bg_starrail_3')];
  }
  if (gameId === GameId.ZZZ) {
    return [$r('app.color.widget_bg_zzz_1'), $r('app.color.widget_bg_zzz_2'), $r('app.color.widget_bg_zzz_3')];
  }
  // 默认使用两色渐变，第三色复用第二色
  return [$r('app.color.widget_bg_default_1'), $r('app.color.widget_bg_default_2'), $r('app.color.widget_bg_default_2')];
}

// ── 体力颜色 ─────────────────────────────────────────────────────

/** 体力颜色类型（根据比例判断） */
export function staminaColorType(ratio: number): StaminaColorType {
  if (ratio <= 0.3) return StaminaColorType.LOW;
  if (ratio <= 0.7) return StaminaColorType.MEDIUM;
  return StaminaColorType.HIGH;
}

/** 体力颜色资源（根据类型和游戏） */
export function staminaColor(type: StaminaColorType, gameId: GameId): Resource {
  if (type === StaminaColorType.LOW) return WidgetColors.STAMINA_LOW;
  if (type === StaminaColorType.MEDIUM) return WidgetColors.STAMINA_MEDIUM;
  return gameIdToWidgetColor(gameId);
}

// ── 恢复时间 ─────────────────────────────────────────────────────

/** 恢复时间文字 */
export function recoveryTimeText(staminaData: PreviewStaminaData): ResourceStr {
  if (staminaData.recHours > 0 && staminaData.recMinutes > 0) {
    return $r('app.string.widget_recovery_hours_minutes', staminaData.recHours, staminaData.recMinutes);
  }
  if (staminaData.recHours > 0) {
    return $r('app.string.widget_recovery_hours', staminaData.recHours);
  }
  if (staminaData.recMinutes > 0) {
    return $r('app.string.widget_recovery_minutes', staminaData.recMinutes);
  }
  return $r('app.string.widget_stamina_full');
}

// ── 字符串转枚举 ─────────────────────────────────────────────────────

/** 字符串转 GameId 枚举 */
export function toGameId(gameIdStr: string): GameId {
  if (gameIdStr === GameId.GENSHIN || gameIdStr === 'genshin') {
    return GameId.GENSHIN;
  }
  if (gameIdStr === GameId.STARRAIL || gameIdStr === 'starrail') {
    return GameId.STARRAIL;
  }
  if (gameIdStr === GameId.ZZZ || gameIdStr === 'zzz') {
    return GameId.ZZZ;
  }
  return GameId.GENSHIN;
}

/** 判断是否为单游戏 */
export function isSingleGame(gameIds: string[]): boolean {
  if (gameIds.length <= 1) {
    return true;
  }
  const firstGameId = gameIds[0];
  for (let i = 1; i < gameIds.length; i++) {
    if (gameIds[i] !== firstGameId) {
      return false;
    }
  }
  return true;
}
