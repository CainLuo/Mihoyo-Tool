/**
 * NotificationModels.ets — 通知功能数据模型
 */
import { GameId } from 'core';

/** 通知样式枚举 */
export enum NotificationStyle {
  /** 每个角色独立一条普通文本通知 */
  STYLE_A = 'styleA',
  /** 所有角色合并为一条多行文本通知 */
  STYLE_B = 'styleB',
}

/** 单个账号下某游戏的通知配置（UI 展示用） */
export class GameNotificationConfig {
  /** 游戏 ID：GameId.GENSHIN | GameId.STARRAIL | GameId.ZZZ */
  gameId: GameId = GameId.GENSHIN;
  /** 游戏显示名称（多语言 Resource） */
  gameName: ResourceStr = '';
  /** 体力名称（多语言 Resource，如原粹树脂 / 开拓力 / 电量） */
  staminaName: ResourceStr = '';
  /** 该账号该游戏的通知开关 */
  enabled: boolean = true;
  /** 阈值（1 ≤ threshold ≤ maxStamina） */
  threshold: number = 0;
  /** 来自 DB 的 API 实际上限，0 表示尚无数据 */
  maxStamina: number = 0;
  /** 每点恢复秒数（原神 480，星铁/绝区零 360） */
  secondsPerUnit: number = 0;
}

/** 单个账号的通知配置（UI 展示用） */
export class AccountNotificationConfig {
  accountId: string = '';
  nickname: string = '';
  uid: string = '';
  avatarUrl: string = '';
  /** 只包含该账号实际拥有的游戏 */
  games: GameNotificationConfig[] = [];
  /** 折叠/展开状态 */
  isExpanded: boolean = true;
}

/** 持久化到 preferences 的全局通知设置 */
export class NotificationSettings {
  /** 总开关 */
  enabled: boolean = false;
  /** 通知样式 */
  style: NotificationStyle = NotificationStyle.STYLE_A;
}

/** 持久化到 preferences 的单个游戏通知配置，key = "{accountId}_{gameId}" */
export class GameNotificationSetting {
  enabled: boolean = true;
  threshold: number = 0;
}

/** 持久化到 preferences 的通知状态条目，key = "{accountId}_{roleUid}_{gameId}" */
export class NotificationStateEntry {
  /** 系统分配的 reminderId（用于取消） */
  reminderId: number = -1;
  /** 调度时的 Recovery_Time 快照（秒） */
  recoveryTimeSnapshot: number = -1;
  /** 对应的阈值 */
  threshold: number = 0;
  /** 调度时的 Unix 时间戳（秒） */
  scheduledAt: number = 0;
}

/** 游戏常量（每点恢复秒数） */
export class GameStaminaConstants {
  /**
   * 每点体力恢复所需秒数（游戏机制固定值，与 PizzaHelperUnited 一致）
   * 原神：8 分钟/格，星铁/绝区零：6 分钟/格
   * API 不返回此值，由游戏机制决定，多年未变。
   */
  static readonly GENSHIN_SECONDS_PER_UNIT: number = 480;  // 8 分钟
  static readonly STARRAIL_SECONDS_PER_UNIT: number = 360; // 6 分钟
  static readonly ZZZ_SECONDS_PER_UNIT: number = 360;      // 6 分钟

  /** 各游戏默认阈值（满值的 80%，仅作 fallback，实际以 maxStamina × 0.8 为准） */
  static readonly GENSHIN_DEFAULT_THRESHOLD: number = 160;   // 200 × 80%
  static readonly STARRAIL_DEFAULT_THRESHOLD: number = 240;  // 300 × 80%
  static readonly ZZZ_DEFAULT_THRESHOLD: number = 192;       // 240 × 80%

  /** 各游戏 fallback 上限（DB 无数据时使用，仅影响首次同步前的 UI 显示） */
  static readonly GENSHIN_MAX_FALLBACK: number = 200;
  static readonly STARRAIL_MAX_FALLBACK: number = 300;
  static readonly ZZZ_MAX_FALLBACK: number = 240;

  /** 代理提醒上限（API 10+ 普通应用） */
  static readonly REMINDER_LIMIT: number = 30;

  /** 根据 gameId 返回 fallback 上限 */
  static fallbackMax(gameId: string): number {
    if (gameId === GameId.GENSHIN) {
      return GameStaminaConstants.GENSHIN_MAX_FALLBACK;
    }
    if (gameId === GameId.STARRAIL) {
      return GameStaminaConstants.STARRAIL_MAX_FALLBACK;
    }
    return GameStaminaConstants.ZZZ_MAX_FALLBACK;
  }
}
