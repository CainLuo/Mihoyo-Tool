/**
 * WidgetUtil.ets — Widget 通用工具函数、映射函数和常量
 *
 * 所有 Widget 页面共用的纯函数，集中在此处避免重复。
 * 不依赖任何 UI 组件，可在 @Component 和 @Entry 中直接调用。
 *
 * 注意：卡片渲染进程不支持引入 HAR 共享包（core），
 * 因此这里直接定义游戏 ID 常量，不从 core 导入 GameId。
 */

import { WidgetColors, StaminaColorType, RecoveryTime } from '../model/WidgetUIStateModels';

/** 卡片渲染进程内使用的游戏 ID 常量（与 core/GameId 枚举值保持一致） */
export class WidgetGameId {
  static readonly GENSHIN: string = 'genshin';
  static readonly STARRAIL: string = 'starrail';
  static readonly ZZZ: string = 'zzz';
}

/**
 * 根据游戏 ID 返回游戏名称字符串
 * 注意：卡片渲染进程不支持 $r()，使用硬编码字符串
 */
export function getGameName(gameId: string): string {
  if (gameId === WidgetGameId.GENSHIN) { return '原神'; }
  if (gameId === WidgetGameId.STARRAIL) { return '崩坏：星穹铁道'; }
  if (gameId === WidgetGameId.ZZZ) { return '绝区零'; }
  return '未知游戏';
}

/**
 * 根据游戏 ID 返回游戏主色（Resource 类型）
 * 使用 $r() 引用 color.json 中的颜色资源
 */
export function getGameColor(gameId: string): Resource {
  if (gameId === WidgetGameId.GENSHIN) { return WidgetColors.GENSHIN_PRIMARY; }
  if (gameId === WidgetGameId.STARRAIL) { return WidgetColors.STARRAIL_PRIMARY; }
  if (gameId === WidgetGameId.ZZZ) { return WidgetColors.ZZZ_PRIMARY; }
  return WidgetColors.GAME_DEFAULT;
}

/**
 * 根据体力颜色类型和游戏 ID 获取显示颜色
 * 用于 Widget 体力数值显示
 */
export function getStaminaColorByType(colorType: StaminaColorType, gameId: string): Resource {
  if (colorType === StaminaColorType.LOW) {
    return WidgetColors.STAMINA_LOW;
  }
  if (colorType === StaminaColorType.MEDIUM) {
    return WidgetColors.STAMINA_MEDIUM;
  }
  // HIGH 状态使用游戏主色
  return getGameColor(gameId);
}

/**
 * 格式化恢复时间文字（使用 $r() 获取翻译）
 * 根据 RecoveryTime 返回显示文字
 */
export function formatRecoveryTimeText(recoveryTime: RecoveryTime): ResourceStr {
  if (recoveryTime.isFull) {
    return $r('app.string.widget_stamina_full');
  }

  const hours = recoveryTime.hours;
  const minutes = recoveryTime.minutes;

  if (hours > 0 && minutes > 0) {
    return $r('app.string.widget_recovery_hours_minutes', hours, minutes);
  }
  if (hours > 0) {
    return $r('app.string.widget_recovery_hours', hours);
  }
  return $r('app.string.widget_recovery_minutes', minutes);
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
export function getGameColorRes(gameId: string, isFull: boolean): Resource {
  if (isFull) { return $r('app.color.color_danger'); }
  if (gameId === WidgetGameId.GENSHIN) { return $r('app.color.game_color_genshin'); }
  if (gameId === WidgetGameId.STARRAIL) { return $r('app.color.game_color_starrail'); }
  return $r('app.color.game_color_zzz');
}

/**
 * 根据游戏 ID 返回游戏名称字符串资源
 */
export function getGameNameRes(gameId: string): Resource {
  if (gameId === WidgetGameId.GENSHIN) { return $r('app.string.widget_game_genshin'); }
  if (gameId === WidgetGameId.STARRAIL) { return $r('app.string.widget_game_starrail'); }
  return $r('app.string.widget_game_zzz');
}

/**
 * 根据游戏 ID 返回体力标签字符串资源
 * 原神：原粹树脂，星铁：开拓力，绝区零：电量
 */
export function getStaminaLabelRes(gameId: string): Resource {
  if (gameId === WidgetGameId.STARRAIL) { return $r('app.string.widget_stamina_label'); }
  if (gameId === WidgetGameId.ZZZ) { return $r('app.string.widget_energy_label'); }
  return $r('app.string.widget_resin_label');
}

/**
 * 根据游戏 ID 返回对应便笺详情页的路由 page 参数
 * 用于 postCardAction 单游戏跳转
 */
export function getDailyDetailPage(gameId: string): string {
  if (gameId === WidgetGameId.GENSHIN) { return 'GenshinDailyDetail'; }
  if (gameId === WidgetGameId.STARRAIL) { return 'StarRailDailyDetail'; }
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

// ============================================================
// 数据新鲜度工具函数
// ============================================================

/** 数据超过该时长（秒）视为陈旧，卡片会高亮提示 */
export const WIDGET_FRESHNESS_STALE_SECONDS: number = 3600;

/** 新鲜度单位：刚刚 / 分钟 / 小时 / 天 */
const FRESHNESS_JUST_NOW: number = 0;
const FRESHNESS_MINUTES: number = 1;
const FRESHNESS_HOURS: number = 2;
const FRESHNESS_DAYS: number = 3;

/** 新鲜度换算结果（内部使用） */
class FreshnessBucket {
  unit: number = FRESHNESS_JUST_NOW;
  value: number = 0;
}

/** 把时间差换算成「单位 + 数值」 */
function resolveFreshness(updatedAt: number, nowSeconds: number): FreshnessBucket {
  const bucket = new FreshnessBucket();
  const diff = nowSeconds - updatedAt;
  if (diff < 60) {
    return bucket;
  }
  const minutes = Math.floor(diff / 60);
  if (minutes < 60) {
    bucket.unit = FRESHNESS_MINUTES;
    bucket.value = minutes;
    return bucket;
  }
  const hours = Math.floor(minutes / 60);
  if (hours < 24) {
    bucket.unit = FRESHNESS_HOURS;
    bucket.value = hours;
    return bucket;
  }
  bucket.unit = FRESHNESS_DAYS;
  bucket.value = Math.floor(hours / 24);
  return bucket;
}

/**
 * 判断数据是否陈旧。
 *
 * @param updatedAt 数据拉取时间（秒级时间戳，来自 WidgetDataStore.updatedAt）
 * @param nowSeconds 当前时间（秒级时间戳）
 *
 * updatedAt 为 0 表示从未成功拉取过数据，此时卡片展示空态，不算「陈旧」。
 */
export function isWidgetDataStale(updatedAt: number, nowSeconds: number): boolean {
  if (updatedAt <= 0) {
    return false;
  }
  return nowSeconds - updatedAt > WIDGET_FRESHNESS_STALE_SECONDS;
}

/**
 * 格式化数据新鲜度文字（完整文案，2x4 / 4x4 使用）
 *
 * 例：刚刚更新 / 更新于 12 分钟前 / 更新于 3 小时前 / 更新于 2 天前
 * updatedAt 为 0 时返回空字符串，调用方据此不渲染该行。
 */
export function formatUpdatedAtText(updatedAt: number, nowSeconds: number): ResourceStr {
  if (updatedAt <= 0) {
    return '';
  }
  const bucket = resolveFreshness(updatedAt, nowSeconds);
  if (bucket.unit === FRESHNESS_MINUTES) {
    return $r('app.string.widget_updated_minutes_ago', bucket.value);
  }
  if (bucket.unit === FRESHNESS_HOURS) {
    return $r('app.string.widget_updated_hours_ago', bucket.value);
  }
  if (bucket.unit === FRESHNESS_DAYS) {
    return $r('app.string.widget_updated_days_ago', bucket.value);
  }
  return $r('app.string.widget_updated_just_now');
}

/**
 * 格式化数据新鲜度文字（紧凑文案，2x2 使用，宽度不足以放下完整文案）
 *
 * 例：刚刚 / 12分钟前 / 3小时前 / 2天前
 */
export function formatUpdatedAtCompactText(updatedAt: number, nowSeconds: number): ResourceStr {
  if (updatedAt <= 0) {
    return '';
  }
  const bucket = resolveFreshness(updatedAt, nowSeconds);
  if (bucket.unit === FRESHNESS_MINUTES) {
    return $r('app.string.widget_updated_minutes_ago_short', bucket.value);
  }
  if (bucket.unit === FRESHNESS_HOURS) {
    return $r('app.string.widget_updated_hours_ago_short', bucket.value);
  }
  if (bucket.unit === FRESHNESS_DAYS) {
    return $r('app.string.widget_updated_days_ago_short', bucket.value);
  }
  return $r('app.string.widget_updated_just_now_short');
}

// ============================================================
// 渐变背景工具函数（使用 $r() 资源引用）
// ============================================================

/** Widget 卡片渐变角度常量 */
export const WIDGET_GRADIENT_ANGLE: number = 135;

/** 渐变位置常量 */
export class GradientPosition {
  /** 起点 */
  static readonly START: number = 0;
  /** 单游戏中点 */
  static readonly MID: number = 0.5;
  /** 终点 */
  static readonly END: number = 1;
  /** 双游戏第一段结束 */
  static readonly TWO_GAME_FIRST_END: number = 0.4;
  /** 双游戏第二段开始 */
  static readonly TWO_GAME_SECOND_START: number = 0.6;
  /** 三游戏第一段中点 */
  static readonly THREE_GAME_FIRST_MID: number = 0.25;
  /** 三游戏第二段中点 */
  static readonly THREE_GAME_SECOND_MID: number = 0.5;
  /** 三游戏第三段中点 */
  static readonly THREE_GAME_THIRD_MID: number = 0.75;
}

/**
 * 根据游戏 ID 返回渐变背景深色资源
 */
export function getWidgetBgDarkRes(gameId: string): Resource {
  if (gameId === WidgetGameId.STARRAIL) return $r('app.color.widget_bg_starrail_1');
  if (gameId === WidgetGameId.ZZZ) return $r('app.color.widget_bg_zzz_1');
  return $r('app.color.widget_bg_genshin_1');
}

/**
 * 根据游戏 ID 返回渐变背景中间色资源
 */
export function getWidgetBgMidRes(gameId: string): Resource {
  if (gameId === WidgetGameId.STARRAIL) return $r('app.color.widget_bg_starrail_2');
  if (gameId === WidgetGameId.ZZZ) return $r('app.color.widget_bg_zzz_2');
  return $r('app.color.widget_bg_genshin_2');
}

/**
 * 根据游戏 ID 返回渐变背景浅色资源
 */
export function getWidgetBgLightRes(gameId: string): Resource {
  if (gameId === WidgetGameId.STARRAIL) return $r('app.color.widget_bg_starrail_3');
  if (gameId === WidgetGameId.ZZZ) return $r('app.color.widget_bg_zzz_3');
  return $r('app.color.widget_bg_genshin_3');
}

/**
 * 单游戏渐变背景
 * 
 * @param gameId 游戏 ID
 * @returns LinearGradient 对象
 */
export function createSingleGameGradient(gameId: string): LinearGradient {
  return {
    angle: WIDGET_GRADIENT_ANGLE,
    colors: [
      [getWidgetBgDarkRes(gameId), GradientPosition.START],
      [getWidgetBgMidRes(gameId), GradientPosition.MID],
      [getWidgetBgLightRes(gameId), GradientPosition.END]
    ]
  };
}

/**
 * 双游戏混合渐变背景
 * 左上角第一款游戏色系，右下角第二款游戏色系
 * 
 * @param gameId0 第一个游戏 ID（左上）
 * @param gameId1 第二个游戏 ID（右下）
 * @returns LinearGradient 对象
 */
export function createTwoGameGradient(gameId0: string, gameId1: string): LinearGradient {
  return {
    angle: WIDGET_GRADIENT_ANGLE,
    colors: [
      [getWidgetBgDarkRes(gameId0), GradientPosition.START],
      [getWidgetBgMidRes(gameId0), GradientPosition.TWO_GAME_FIRST_END],
      [getWidgetBgMidRes(gameId1), GradientPosition.TWO_GAME_SECOND_START],
      [getWidgetBgDarkRes(gameId1), GradientPosition.END]
    ]
  };
}

/**
 * 三游戏及以上混合渐变背景
 * 多段渐变，每个游戏占一段
 * 
 * @param gameIds 游戏 ID 数组（取前三个）
 * @returns LinearGradient 对象
 */
export function createMultiGameGradient(gameIds: string[]): LinearGradient {
  if (gameIds.length === 0) {
    // 无游戏数据时使用默认背景色
    return {
      angle: WIDGET_GRADIENT_ANGLE,
      colors: [
        [$r('app.color.widget_bg_default_1'), GradientPosition.START],
        [$r('app.color.widget_bg_default_mid'), GradientPosition.MID],
        [$r('app.color.widget_bg_default_2'), GradientPosition.END]
      ]
    };
  }
  
  if (gameIds.length === 1) {
    return createSingleGameGradient(gameIds[0]);
  }
  
  if (gameIds.length === 2) {
    return createTwoGameGradient(gameIds[0], gameIds[1]);
  }
  
  // 三游戏及以上
  return {
    angle: WIDGET_GRADIENT_ANGLE,
    colors: [
      [getWidgetBgDarkRes(gameIds[0]), GradientPosition.START],
      [getWidgetBgMidRes(gameIds[0]), GradientPosition.THREE_GAME_FIRST_MID],
      [getWidgetBgMidRes(gameIds[1]), GradientPosition.THREE_GAME_SECOND_MID],
      [getWidgetBgMidRes(gameIds[2]), GradientPosition.THREE_GAME_THIRD_MID],
      [getWidgetBgDarkRes(gameIds[2]), GradientPosition.END]
    ]
  };
}

/**
 * 根据游戏数量自动选择渐变背景
 * 
 * @param gameIds 游戏 ID 数组
 * @returns LinearGradient 对象
 */
export function createWidgetGradient(gameIds: string[]): LinearGradient {
  return createMultiGameGradient(gameIds);
}
