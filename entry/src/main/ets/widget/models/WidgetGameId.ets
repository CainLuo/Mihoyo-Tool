/**
 * WidgetGameId.ets — Widget 专用游戏 ID 枚举
 *
 * 重要约束：
 * - Widget 不能导入 HSP 模块（core 是 HSP）
 * - 此文件是 core 模块 GameId 枚举的副本，专门供 Widget 使用
 *
 * 与 core/GameId 保持同步，但独立维护以避免 HSP 依赖。
 */

/**
 * 游戏 ID 枚举
 */
export enum WidgetGameId {
  GENSHIN = 'genshin',
  STARRAIL = 'starrail',
  ZZZ = 'zzz',
  HONKAI3 = 'honkai3',
}

/**
 * 将 gameId 字符串转换为 WidgetGameId 枚举
 */
export function toWidgetGameId(str: string): WidgetGameId {
  if (str === 'genshin') { return WidgetGameId.GENSHIN; }
  if (str === 'starrail') { return WidgetGameId.STARRAIL; }
  if (str === 'zzz') { return WidgetGameId.ZZZ; }
  if (str === 'honkai3') { return WidgetGameId.HONKAI3; }
  return WidgetGameId.GENSHIN; // fallback
}

/**
 * 将 WidgetGameId 转换为字符串
 */
export function fromWidgetGameId(id: WidgetGameId): string {
  return id as string;
}
