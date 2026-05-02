/**
 * WidgetUtils.ets — Widget 通用工具函数、映射函数和常量
 *
 * 所有 Widget 页面共用的纯函数，集中在此处避免重复。
 * 不依赖任何 UI 组件，可在 @Component 和 @Entry 中直接调用。
 *
 * 注意：卡片渲染进程不支持引入 HAR 共享包（core），
 * 因此这里直接定义游戏 ID 常量，不从 core 导入 GameId。
 */

/** 卡片渲染进程内使用的游戏 ID 常量（与 core/GameId 枚举值保持一致） */
export class WIDGET_GAME_ID {
  static readonly GENSHIN: string = 'genshin';
  static readonly STARRAIL: string = 'starrail';
  static readonly ZZZ: string = 'zzz';
}

/**
 * 将字符串解析为体力当前值，解析失败返回 0
 */
export function parseCurrent(s: string): number {
  return parseInt(s) || 0;
}

/**
 * 将字符串解析为体力上限，解析失败返回 200
 */
export function parseMax(s: string): number {
  return parseInt(s) || 200;
}

/**
 * 将字符串解析为恢复剩余秒数，解析失败返回 0
 */
export function parseSeconds(s: string): number {
  return parseInt(s) || 0;
}

/**
 * 判断体力是否已满（剩余秒数 <= 0 且当前值 >= 上限）
 */
export function calcIsFull(currentStr: string, maxStr: string, secondsStr: string): boolean {
  return parseSeconds(secondsStr) <= 0 && parseCurrent(currentStr) >= parseMax(maxStr);
}

/**
 * 计算体力进度比例 0~1，防止除以 0
 */
export function calcRatio(currentStr: string, maxStr: string): number {
  const m = parseMax(maxStr);
  return m > 0 ? Math.min(parseCurrent(currentStr) / m, 1) : 0;
}

/**
 * 根据游戏 ID 和是否满体力返回对应颜色资源
 * 满体力时统一返回危险色（红色）
 */
export function gameColorRes(gameId: string, isFull: boolean): Resource {
  if (isFull) { return $r('app.color.color_danger'); }
  if (gameId === WIDGET_GAME_ID.GENSHIN) { return $r('app.color.game_color_genshin'); }
  if (gameId === WIDGET_GAME_ID.STARRAIL) { return $r('app.color.game_color_starrail'); }
  return $r('app.color.game_color_zzz');
}

/**
 * 根据游戏 ID 返回游戏名称字符串资源
 */
export function gameNameRes(gameId: string): Resource {
  if (gameId === WIDGET_GAME_ID.GENSHIN) { return $r('app.string.widget_game_genshin'); }
  if (gameId === WIDGET_GAME_ID.STARRAIL) { return $r('app.string.widget_game_starrail'); }
  return $r('app.string.widget_game_zzz');
}

/**
 * 根据游戏 ID 返回体力标签字符串资源
 * 原神：原粹树脂，星铁：开拓力，绝区零：电量
 */
export function staminaLabelRes(gameId: string): Resource {
  if (gameId === WIDGET_GAME_ID.STARRAIL) { return $r('app.string.widget_stamina_label'); }
  if (gameId === WIDGET_GAME_ID.ZZZ) { return $r('app.string.widget_energy_label'); }
  return $r('app.string.widget_resin_label');
}

/**
 * 根据游戏 ID 返回对应便笺详情页的路由 page 参数
 * 用于 postCardAction 单游戏跳转
 */
export function dailyDetailPage(gameId: string): string {
  if (gameId === WIDGET_GAME_ID.GENSHIN) { return 'GenshinDailyDetail'; }
  if (gameId === WIDGET_GAME_ID.STARRAIL) { return 'StarRailDailyDetail'; }
  return 'ZZZDailyDetail';
}

/**
 * 将剩余秒数格式化为恢复描述字符串资源
 * 在卡片渲染进程中调用，可以使用 $r()
 * 返回 ResourceStr 类型，直接传给 Text 组件
 */
export function formatRecoveryDesc(secondsStr: string): ResourceStr {
  const seconds = parseInt(secondsStr) || 0;
  if (seconds <= 0) {
    return $r('app.string.widget_stamina_full');
  }
  const hours = Math.floor(seconds / 3600);
  const minutes = Math.floor((seconds % 3600) / 60);
  if (hours > 0 && minutes > 0) {
    return $r('app.string.widget_recovery_hours_minutes', hours, minutes);
  }
  if (hours > 0) {
    return $r('app.string.widget_recovery_hours', hours);
  }
  return $r('app.string.widget_recovery_minutes', minutes);
}
