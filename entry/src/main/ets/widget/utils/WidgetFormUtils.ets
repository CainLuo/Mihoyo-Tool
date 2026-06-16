/**
 * WidgetFormUtils — Widget 表单管理工具函数
 *
 * 提供 Form Name、Form Dimension 等与 Form Manager 相关的工具函数。
 */

import { GameId } from 'core';

// ── Form Name 映射 ─────────────────────────────────────────────────────

/** 游戏 ID 转 Widget Form Name */
export function gameIdToFormName(gameId: string): string {
  if (gameId === 'genshin' || gameId === GameId.GENSHIN) {
    return 'widget_1x2_genshin';
  }
  if (gameId === 'starrail' || gameId === GameId.STARRAIL) {
    return 'widget_1x2_starrail';
  }
  if (gameId === 'zzz' || gameId === GameId.ZZZ) {
    return 'widget_1x2_zzz';
  }
  return 'widget_2x2';
}

/**
 * 根据 formName 返回对应的 FormDimension 数值
 * 参考 FormDimension 枚举：Dimension_1_2=1, Dimension_2_2=2, Dimension_2_4=3, Dimension_4_4=4
 */
export function formNameToDimension(formName: string): number {
  if (formName === 'widget_1x2_genshin' ||
      formName === 'widget_1x2_starrail' ||
      formName === 'widget_1x2_zzz') {
    return 1; // 1×2
  }
  if (formName === 'widget_2x4') {
    return 3; // 2×4
  }
  if (formName === 'widget_4x4') {
    return 4; // 4×4
  }
  return 2; // 2×2（默认）
}

// ── 游戏标签 ─────────────────────────────────────────────────────

/** 游戏 ID 转显示名称资源 */
export function gameIdToLabel(gameId: string): ResourceStr {
  if (gameId === 'genshin' || gameId === GameId.GENSHIN) {
    return $r('app.string.game_name_genshin');
  }
  if (gameId === 'starrail' || gameId === GameId.STARRAIL) {
    return $r('app.string.game_name_starrail');
  }
  if (gameId === 'zzz' || gameId === GameId.ZZZ) {
    return $r('app.string.game_name_zzz');
  }
  return gameId;
}
