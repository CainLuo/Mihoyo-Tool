/**
 * WidgetUIStates.ets — Widget UI State 模型
 *
 * 职责：
 * - 定义 Widget 组件使用的 UI 展示数据结构
 * - 所有字段都是 View 层直接可用的形式（string、number）
 *
 * 设计原则：
 * - ViewModel 负责填充这些数据
 * - Component 只负责渲染，不做任何数据解析
 * - Widget Form 环境不支持在 class 字段默认值中使用 $r()
 *
 * 数据流：
 *   EntryFormAbility → parsePayload() → ParsedPayload → ViewModel.buildUIState() → UIState → Component
 */

import { WIDGET_GAME_ID } from '../utils/WidgetUtils';
import { WidgetGameData } from './WidgetModels';

/**
 * 体力颜色类型枚举
 * 组件根据此枚举值决定显示什么颜色
 */
export enum StaminaColorType {
  /** 低体力（≤30%）— 红色 */
  LOW = 'low',
  /** 中等体力（30%~70%）— 黄色 */
  MEDIUM = 'medium',
  /** 高体力（>70%）— 游戏主色 */
  HIGH = 'high'
}

/**
 * 恢复时间数据
 * 存储解析后的小时和分钟，由组件决定如何显示
 */
export class RecoveryTimeData {
  /** 是否已满 */
  isFull: boolean = false;
  /** 小时数 */
  hours: number = 0;
  /** 分钟数 */
  minutes: number = 0;
}

/**
 * Widget 颜色常量
 *
 * 使用 $r() 引用 color.json 中定义的颜色资源。
 * 所有颜色在资源文件中集中定义，便于维护和主题切换。
 * 
 * 重要：Widget 不支持 8 位十六进制颜色（带 Alpha 通道），
 * 必须使用 6 位纯色 + .opacity() 控制透明度。
 */
export class WidgetColors {
  // ── 状态颜色 ──
  /** 低体力颜色（≤30%）— 红色 */
  static readonly STAMINA_LOW: Resource = $r('app.color.color_danger');
  /** 中等体力颜色（30%~70%）— 黄色 */
  static readonly STAMINA_MEDIUM: Resource = $r('app.color.color_warning');

  // ── 游戏主题色 ──
  /** 原神主题色 */
  static readonly GENSHIN_PRIMARY: Resource = $r('app.color.game_color_genshin');
  /** 星铁主题色 */
  static readonly STARRAIL_PRIMARY: Resource = $r('app.color.game_color_starrail');
  /** 绝区零主题色 */
  static readonly ZZZ_PRIMARY: Resource = $r('app.color.game_color_zzz');
  /** 默认/未知游戏颜色 */
  static readonly GAME_DEFAULT: Resource = $r('app.color.color_text_secondary');

  // ── 文字颜色（白色 + 透明度）─
  /** 白色 */
  static readonly WHITE: Resource = $r('app.color.white');

  // ── 功能颜色 ──
  /** 成功/完成状态 */
  static readonly SUCCESS: Resource = $r('app.color.color_success');
  /** 未完成状态 */
  static readonly INCOMPLETE: Resource = $r('app.color.color_text_secondary');

  // ── Widget 文字透明度常量 ──
  /** 文字透明度：高（95%）*/
  static readonly OPACITY_TEXT_HIGH: number = 0.95;
  /** 文字透明度：中（70%）*/
  static readonly OPACITY_TEXT_MEDIUM: number = 0.7;
  /** 文字透明度：次（55%）*/
  static readonly OPACITY_TEXT_SECONDARY: number = 0.55;
  /** 文字透明度：弱（50%）*/
  static readonly OPACITY_TEXT_MUTED: number = 0.5;
  /** 文字透明度：淡（40%）*/
  static readonly OPACITY_TEXT_FAINT: number = 0.4;
  /** 文字透明度：极淡（35%）*/
  static readonly OPACITY_TEXT_GHOST: number = 0.35;

  // ── Widget 边框透明度常量 ──
  /** 边框透明度：默认（20%）*/
  static readonly OPACITY_BORDER: number = 0.2;
}

/**
 * 额外数据行
 */
export class WidgetExtraRow {
  label: string = '';
  value: string = '';
  valueColor: Resource = $r('app.color.gray_600');
}

/**
 * 单个角色的 UIState（用于 1x2 单游戏模板）
 *
 * 包含 1x2 迷你卡片所需的所有字段：
 * - 基本信息：gameId、accountUid
 * - 体力数据：currentStamina、maxStamina、recoverySeconds
 * - 计算后的展示字段：isFull、ratio、staminaColorType、recoveryTime
 */
export class Widget1x2RoleUIState {
  /** 游戏 ID（genshin/starrail/zzz） */
  gameId: string = WIDGET_GAME_ID.GENSHIN;
  /** 游戏角色 UID */
  accountUid: string = '';
  /** 当前体力 */
  currentStamina: number = 0;
  /** 最大体力 */
  maxStamina: number = 160;
  /** 恢复剩余秒数 */
  recoverySeconds: number = 0;
  /** 体力是否已满 */
  isFull: boolean = false;
  /** 体力进度比例 0~1 */
  ratio: number = 0;
  /** 体力颜色类型（组件根据此值决定显示颜色） */
  staminaColorType: StaminaColorType = StaminaColorType.HIGH;
  /** 恢复时间数据（组件根据此数据显示翻译后的文字） */
  recoveryTime: RecoveryTimeData = new RecoveryTimeData();
}

/**
 * 1x2 Widget UIState
 */
export class Widget1x2UIState {
  isEmpty: boolean = true;
  role: Widget1x2RoleUIState = new Widget1x2RoleUIState();
}

/**
 * 单个角色的详细 UIState（用于 2x2/2x4/4x4 单游戏模式）
 */
export class WidgetRoleUIState {
  gameId: string = WIDGET_GAME_ID.GENSHIN;
  gameName: string = '';
  gameColor: ResourceColor = '';
  roleId: string = '';
  currentStamina: number = 0;
  maxStamina: number = 160;
  recoverySeconds: number = 0;
  isFull: boolean = false;
  /** 恢复时间数据（组件根据此数据显示翻译后的文字） */
  recoveryTime: RecoveryTimeData = new RecoveryTimeData();
  /** 体力颜色类型（组件根据此值决定显示颜色） */
  staminaColorType: StaminaColorType = StaminaColorType.HIGH;
  reserveStamina: string = '0';
  extraRows: WidgetExtraRow[] = [];
}

/**
 * 多游戏 UIState
 *
 * 包含多游戏组件需要的所有字段：
 * - accountName: 账号名
 * - accountUid: 账号 UID
 * - gameCount: 游戏数量
 * - games: WidgetGameData 数组（兼容 WidgetMultiGameCompact 组件）
 */
export class WidgetMultiGameUIState {
  accountName: string = '';
  accountUid: string = '';
  gameCount: number = 0;
  games: WidgetGameData[] = [];
}

/**
 * 2x2 Widget UIState
 *
 * 单游戏：使用 singleGameState（详细布局）
 * 多游戏：使用 multiGameStates（两个 1x2 内容纵向排列）
 */
export class Widget2x2UIState {
  isEmpty: boolean = true;
  isSingleGame: boolean = true;
  singleGameState: WidgetRoleUIState = new WidgetRoleUIState();
  /** 多游戏模式：最多 2 个 Widget1x2RoleUIState */
  multiGameStates: Widget1x2RoleUIState[] = [];
}

/**
 * 2x4 Widget UIState
 *
 * 单游戏：使用 singleGameState（详细布局）
 * 多游戏（2个）：使用 multiGameStates（两个 WidgetRoleUIState 横向排列 + Divider）
 */
export class Widget2x4UIState {
  isEmpty: boolean = true;
  isSingleGame: boolean = true;
  singleGameState: WidgetRoleUIState = new WidgetRoleUIState();
  /** 多游戏模式：最多 2 个 WidgetRoleUIState（横向排列） */
  multiGameStates: WidgetRoleUIState[] = [];
}

/**
 * 4x4 Widget UIState
 *
 * 单游戏：使用 singleGameState（完整详细布局）
 * 多游戏（2个）：使用 multiGameStates（两个 WidgetRoleUIState，2x2 网格排列）
 */
export class Widget4x4UIState {
  isEmpty: boolean = true;
  isSingleGame: boolean = true;
  singleGameState: WidgetRoleUIState = new WidgetRoleUIState();
  /** 多游戏模式：最多 2 个 WidgetRoleUIState */
  multiGameStates: WidgetRoleUIState[] = [];
}
