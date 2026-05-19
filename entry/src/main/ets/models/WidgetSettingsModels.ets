/**
 * WidgetSettingsModels — Widget 配置页的 UI State 模型
 *
 * 用于封装 WidgetSettingsMainContent 组件所需的所有数据，
 * 避免传递过多独立参数。
 */
import { WidgetSize } from '../widget/models/WidgetConfig';
import { WidgetSlotRef } from '../widget/models/WidgetDataStore';
import { WidgetConfigStep } from '../viewmodel/WidgetConfigViewModel';

/** 配置步骤枚举（重新导出，方便使用） */
export { WidgetConfigStep };

/**
 * WidgetSettingsUIState — Widget 配置页主内容区域的 UI State
 *
 * 包含渲染所需的所有数据，由 WidgetSettings 页面从 ViewModel 转换而来。
 */
@ObservedV2
export class WidgetSettingsUIState {
  /** 当前步骤 */
  @Trace currentStep: WidgetConfigStep = WidgetConfigStep.SIZE;

  /** 选中的卡片尺寸 */
  @Trace selectedSize: WidgetSize = WidgetSize.SIZE_2x2;

  /** 选中的游戏类型（仅 1x2 卡片使用） */
  @Trace selectedGameType: string = '';

  /** 所有可选的 slots */
  @Trace allSlots: WidgetSlotRef[] = [];

  /** 已选中的 slots */
  @Trace selectedSlots: WidgetSlotRef[] = [];

  /** 最大可选 slots 数量 */
  @Trace maxSlots: number = 4;

  /** 已选摘要（用于 Done 步骤展示） */
  @Trace selectedSummary: string = '';

  /** 是否可以后退 */
  @Trace canGoPrev: boolean = false;

  /** 是否可以前进 */
  @Trace canGoNext: boolean = true;
}

/**
 * WidgetSettingsCallbacks — Widget 配置页的回调函数集合
 *
 * 将所有回调函数封装为一个对象，避免逐个传递。
 */
export class WidgetSettingsCallbacks {
  /** 选择尺寸 */
  onSizeSelect: (size: WidgetSize) => void = (_size: WidgetSize) => {};

  /** 选择游戏类型 */
  onGameSelect: (gameId: string) => void = (_gameId: string) => {};

  /** 切换 slot 选中状态 */
  onSlotToggle: (slot: WidgetSlotRef) => void = (_slot: WidgetSlotRef) => {};

  /** 后退 */
  onPrev: () => void = () => {};

  /** 前进 */
  onNext: () => void = () => {};

  /** 完成配置 */
  onComplete: () => void = () => {};
}

/**
 * WidgetSettingsSlotHelper — Slot 相关的辅助方法集合
 *
 * 封装 ViewModel 提供的辅助方法，避免传递多个函数引用。
 */
export class WidgetSettingsSlotHelper {
  /** 获取指定游戏的 slots */
  getSlotsForGame: (gameId: string) => WidgetSlotRef[] = (_gameId: string) => [];

  /** 判断游戏是否有数据 */
  hasDataForGame: (gameId: string) => boolean = (_gameId: string) => false;

  /** 判断 slot 是否已选中 */
  isSlotSelected: (accountId: string, gameId: string, roleId: string) => boolean =
    (_a: string, _g: string, _r: string) => false;
}
