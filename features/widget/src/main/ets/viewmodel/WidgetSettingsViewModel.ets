/**
 * WidgetSettingsViewModel — Widget 卡片配置页的 ViewModel
 *
 * 配置流程根据卡片尺寸不同而不同：
 *
 * **1x2 卡片**（游戏专用模板）：
 * 1. 选择卡片尺寸（1×2）
 * 2. 选择游戏类型（原神/星铁/绝区零）
 * 3. 选择该游戏的账号
 * 4. 完成 → 调用 formProvider.openFormManager()
 *
 * **2x2 / 2x4 / 4x4 卡片**（通用模板）：
 * 1. 选择卡片尺寸
 * 2. 选择要显示的角色 slots（跨账号多选）
 * 3. 完成 → 调用 formProvider.openFormManager()
 */
import { common } from '@kit.AbilityKit';
import { Logger, GameId } from 'core';
import { WidgetSize, WidgetConfig, getMaxSlots } from '../model/WidgetConfigModels';
import { WidgetSlotRef, WidgetDataStore } from '../model/WidgetDataStoreModels';
import { WidgetDataStoreManager } from '../model/service/WidgetDataStoreManager';
import { WidgetDataStoreBuilder } from '../model/service/WidgetDataStoreBuilder';
import { WidgetSettingsUIState, WidgetSettingsCallbacks, WidgetSettingsSlotHelper, MihoyoAccountVM } from '../model/WidgetSettingsModels';
import { buildAccountGroups } from '../model/WidgetSettingsAccountGroups';
import { getFormName, getDimension, getPresetKey } from '../model/WidgetSettingsSizeConfig';
import {
  savePresetSlots,
  savePendingConfig,
  buildFormManagerWant,
  openFormManager
} from '../model/service/WidgetSettingsConfigSaver';

const TAG = 'WIDGET';

/** 配置步骤枚举 */
export enum WidgetSettingsStep {
  SIZE = 'size',
  GAME = 'game',    // 仅 1x2 卡片：选择游戏类型
  SLOT = 'slot',    // 选择账号/角色
  DONE = 'done',
}

/** 配置完成回调类型 */
export type WidgetConfigCallback = () => void;

@ObservedV2
export class WidgetSettingsViewModel {
  /** 当前步骤 */
  @Trace currentStep: WidgetSettingsStep = WidgetSettingsStep.SIZE;

  /** 选中的卡片尺寸 */
  @Trace selectedSize: WidgetSize = WidgetSize.SIZE_2X2;

  /** 选中的游戏类型（仅 1x2 卡片使用，使用 core 的 GameId 枚举） */
  @Trace selectedGameType: string = GameId.GENSHIN;

  /** 选中的 slots（三元组列表） */
  @Trace selectedSlots: WidgetSlotRef[] = [];

  /** 全局数据存储 */
  @Trace dataStore: WidgetDataStore = new WidgetDataStore();

  /** UI State（供 View 层直接使用） */
  @Trace uiState: WidgetSettingsUIState = new WidgetSettingsUIState();

  /** 回调函数集合（供 View 层直接使用） */
  callbacks: WidgetSettingsCallbacks = new WidgetSettingsCallbacks();

  /** Slot 辅助方法（供 View 层直接使用） */
  slotHelper: WidgetSettingsSlotHelper = new WidgetSettingsSlotHelper();

  /** 配置完成回调 */
  onConfigComplete: WidgetConfigCallback | null = null;

  /** Context 用于保存配置 */
  private context: common.UIAbilityContext | null = null;

  // ── 初始化 ───────────────────────────────────────────────────────

  /**
   * 初始化数据
   * 从 Preferences 加载数据，如果为空则从 DB 构建
   * @param context UIAbilityContext，用于初始化 Preferences
   */
  async init(context?: common.UIAbilityContext): Promise<void> {
    try {
      // 保存 context 用于后续保存配置
      if (context !== undefined) {
        this.context = context;
        await WidgetDataStoreManager.init(context);
      }
      // 尝试从 Preferences 加载
      let store = await WidgetDataStoreManager.load();
      if (!store.hasData) {
        // 无数据则从 DB 构建
        store = await WidgetDataStoreBuilder.buildFromDB();
        await WidgetDataStoreManager.save(store);
      }
      this.dataStore = store;
      const accountCount = Object.keys(store.data).length;
      Logger.info(TAG, `init: ${accountCount} accounts`);
      
      // 初始化回调函数
      this.initCallbacks();
      // 初始化辅助方法
      this.initSlotHelper();
      // 同步 UI State
      this.syncUIState();
    } catch (e) {
      Logger.error(TAG, `init failed: ${JSON.stringify(e)}`);
      this.dataStore = new WidgetDataStore();
    }
  }

  /**
   * 初始化回调函数
   * View 层直接使用 vm.callbacks，不需要自己管理回调
   */
  private initCallbacks(): void {
    this.callbacks.onSizeSelect = (size: WidgetSize) => {
      this.selectSize(size);
      this.syncUIState();
    };
    this.callbacks.onGameSelect = (gameId: string) => {
      this.selectGameType(gameId);
      this.syncUIState();
    };
    this.callbacks.onSlotToggle = (slot: WidgetSlotRef) => {
      this.toggleSlot(slot);
      this.syncUIState();
    };
    this.callbacks.onPrev = () => {
      this.goPrev();
      this.syncUIState();
    };
    this.callbacks.onNext = () => {
      this.goNext();
      this.syncUIState();
    };
    this.callbacks.onComplete = async () => {
      await this.complete();
    };
  }

  /**
   * 初始化 Slot 辅助方法
   * View 层直接使用 vm.slotHelper，不需要自己管理
   * 
   * 注意：游戏颜色和名称使用 GameIdUtil 工具函数，不在此处初始化
   */
  private initSlotHelper(): void {
    this.slotHelper.getSlotsForGame = (gameId: string): WidgetSlotRef[] => {
      return this.getSlotsForGame(gameId);
    };
    this.slotHelper.hasDataForGame = (gameId: string): boolean => {
      return this.hasDataForGame(gameId);
    };
    this.slotHelper.isSlotSelected = (accountId: string, gameId: string, roleId: string): boolean => {
      return this.isSlotSelected(accountId, gameId, roleId);
    };
  }

  /**
   * 将 ViewModel 状态同步到 UI State
   * UI State 是 View 层使用的展示数据，ViewModel 负责组装
   */
  private syncUIState(): void {
    this.uiState.currentStep = this.currentStep;
    this.uiState.selectedSize = this.selectedSize;
    this.uiState.selectedGameType = this.selectedGameType;
    this.uiState.allSlots = this.getAllSlots();
    this.uiState.accountGroups = this.getAccountGroups();
    this.uiState.selectedSlots = this.selectedSlots;
    this.uiState.maxSlots = this.getMaxSlots();
    this.uiState.selectedSummary = this.getSelectedSummary();
    this.uiState.canGoPrev = this.canGoPrev();
    this.uiState.canGoNext = this.canGoNext();
  }

  // ── 步骤导航 ─────────────────────────────────────────────────────

  /** 是否可以前进 */
  canGoNext(): boolean {
    switch (this.currentStep) {
      case WidgetSettingsStep.SIZE:
        return true;
      case WidgetSettingsStep.GAME:
        // 1x2 卡片必须选择游戏类型
        return true;
      case WidgetSettingsStep.SLOT:
        return this.selectedSlots.length > 0;
      case WidgetSettingsStep.DONE:
        return false;
    }
    return false;
  }

  /** 是否可以后退 */
  canGoPrev(): boolean {
    return this.currentStep !== WidgetSettingsStep.SIZE;
  }

  /** 当前尺寸对应的步骤流程 */
  private getStepFlow(): WidgetSettingsStep[] {
    if (this.selectedSize === WidgetSize.SIZE_1X2) {
      return [WidgetSettingsStep.SIZE, WidgetSettingsStep.GAME, WidgetSettingsStep.SLOT, WidgetSettingsStep.DONE];
    }
    return [WidgetSettingsStep.SIZE, WidgetSettingsStep.SLOT, WidgetSettingsStep.DONE];
  }

  /** 前进到下一步 */
  goNext(): void {
    const steps = this.getStepFlow();
    const curIdx = steps.indexOf(this.currentStep);
    if (curIdx < steps.length - 1 && this.canGoNext()) {
      this.currentStep = steps[curIdx + 1];
    }
  }

  /** 返回上一步 */
  goPrev(): void {
    const steps = this.getStepFlow();
    const curIdx = steps.indexOf(this.currentStep);
    if (curIdx > 0) {
      this.currentStep = steps[curIdx - 1];
    }
  }

  /** 重置到第一步 */
  reset(): void {
    this.currentStep = WidgetSettingsStep.SIZE;
    this.selectedSize = WidgetSize.SIZE_2X2;
    this.selectedGameType = GameId.GENSHIN;
    this.selectedSlots = [];
  }

  // ── 尺寸选择 ─────────────────────────────────────────────────────

  /** 选择卡片尺寸 */
  selectSize(size: WidgetSize): void {
    this.selectedSize = size;
    // 如果已选 slots 超过新尺寸限制，截断
    const maxSlots = getMaxSlots(size);
    if (this.selectedSlots.length > maxSlots) {
      this.selectedSlots = this.selectedSlots.slice(0, maxSlots);
    }
    // 切换尺寸时重置游戏类型
    if (size !== WidgetSize.SIZE_1X2) {
      this.selectedGameType = GameId.GENSHIN;
    }
  }

  /** 获取最大 slots 数量 */
  getMaxSlots(): number {
    return getMaxSlots(this.selectedSize);
  }

  // ── 游戏类型选择（仅 1x2 卡片）─────────────────────────────────────

  /** 选择游戏类型 */
  selectGameType(gameType: string): void {
    this.selectedGameType = gameType;
    // 切换游戏类型时清空已选 slots
    this.selectedSlots = [];
  }

  /** 获取所有可选的游戏类型（使用 core 的 GameId） */
  getAvailableGameTypes(): string[] {
    return [GameId.GENSHIN, GameId.STARRAIL, GameId.ZZZ];
  }

  /** 判断游戏类型是否有可用数据 */
  hasDataForGame(gameType: string): boolean {
    const slots = this.getSlotsForGame(gameType);
    return slots.length > 0;
  }

  /** 获取指定游戏类型的所有 slots */
  getSlotsForGame(gameType: string): WidgetSlotRef[] {
    const allSlots = this.dataStore.getAllSlotRefs();
    const filtered: WidgetSlotRef[] = [];
    for (let i = 0; i < allSlots.length; i++) {
      if (allSlots[i].gameId === gameType) {
        filtered.push(allSlots[i]);
      }
    }
    return filtered;
  }

  // ── Slot 选择 ─────────────────────────────────────────────────────

  /** 获取所有可用的 slots */
  getAllSlots(): WidgetSlotRef[] {
    // 1x2 卡片只显示当前选中游戏的 slots
    if (this.selectedSize === WidgetSize.SIZE_1X2) {
      return this.getSlotsForGame(this.selectedGameType);
    }
    return this.dataStore.getAllSlotRefs();
  }

  /**
   * 获取按账号分组的 slots（用于 2x2 及以上尺寸）
   * 组内角色按游戏排序：原神 → 星铁 → 绝区零
   * 直接返回 MihoyoAccountVM[]，复用首页的 UserGameSection 组件
   */
  getAccountGroups(): MihoyoAccountVM[] {
    // 1x2 卡片不使用分组，返回空数组
    if (this.selectedSize === WidgetSize.SIZE_1X2) {
      return [];
    }
    return buildAccountGroups(this.dataStore);
  }

  /** 判断 slot 是否已选中 */
  isSlotSelected(accountId: string, gameId: string, roleId: string): boolean {
    for (let i = 0; i < this.selectedSlots.length; i++) {
      const slot = this.selectedSlots[i];
      if (slot.accountId === accountId && slot.gameId === gameId && slot.roleId === roleId) {
        return true;
      }
    }
    return false;
  }

  /**
   * 切换 slot 的选中状态
   * - 1x2 卡片：单选模式，点击新项直接替换
   * - 其他尺寸：多选模式，点击切换选中/取消
   * @returns 切换后的选中状态（true 表示选中，false 表示取消）
   */
  toggleSlot(slot: WidgetSlotRef): boolean {
    // 1x2 卡片：单选模式
    if (this.selectedSize === WidgetSize.SIZE_1X2) {
      // 如果点击的是当前已选中的项，不做任何改变（保持选中）
      if (this.selectedSlots.length > 0 && this.selectedSlots[0].key === slot.key) {
        return true;
      }
      // 否则替换为新选中的项
      this.selectedSlots = [slot];
      return true;
    }

    // 其他尺寸：多选模式
    for (let i = 0; i < this.selectedSlots.length; i++) {
      if (this.selectedSlots[i].key === slot.key) {
        this.selectedSlots.splice(i, 1);
        return false;
      }
    }
    // 未找到，检查是否可以添加
    if (this.selectedSlots.length < this.getMaxSlots()) {
      this.selectedSlots.push(slot);
      return true;
    }
    return false;
  }

  /** 清空所有选中的 slots */
  clearSlots(): void {
    this.selectedSlots = [];
  }

  // ── 完成配置 ─────────────────────────────────────────────────────

  /**
   * 完成配置，调用 formProvider.openFormManager()
   *
   * openFormManager 的 want.parameters 只支持三个标准参数，自定义参数无法传递到 onAddForm()。
   * 因此必须在调用前把配置保存到 Preferences，并在 onAddForm() 时按 formName 读取。
   */
  async complete(): Promise<void> {
    if (this.selectedSlots.length === 0) {
      Logger.error(TAG, 'complete: no slots selected');
      return;
    }

    const formName = getFormName(this.selectedSize, this.selectedGameType);
    const dimension = getDimension(this.selectedSize);

    // 构建配置
    const config = new WidgetConfig();
    config.size = this.selectedSize;
    config.slots = this.selectedSlots;

    // 直接使用 formName 作为配置 key（不带前缀），onAddForm 据此读取
    const configKey = formName;
    const configJson = config.toJson();

    // 同时保存预配置到 WidgetDataStore.widgets，供 EntryFormAbility 兜底读取
    const presetKey = getPresetKey(this.selectedSize);
    const slotKeys: string[] = [];
    for (let i = 0; i < this.selectedSlots.length; i++) {
      slotKeys.push(this.selectedSlots[i].key);
    }
    Logger.info(TAG, `complete: saving preset ${presetKey} with slots=${slotKeys.join(',')}`);
    await savePresetSlots(this.dataStore, presetKey, slotKeys);

    const want = buildFormManagerWant(formName, dimension);

    Logger.info(TAG, `complete: formName=${formName} configKey=${configKey} slots=${this.selectedSlots.length} selectedGames=${this.getSelectedGameIds().join(',')}`);

    // 必须等待配置保存完成后再调用 openFormManager
    await savePendingConfig(this.context, configKey, configJson);
    Logger.info(TAG, `complete: config saved, key=${configKey} jsonLen=${configJson.length}`);

    if (openFormManager(want) && this.onConfigComplete !== null) {
      this.onConfigComplete();
    }
  }

  /**
   * 获取选中 slots 对应的游戏 ID 列表（去重）
   */
  private getSelectedGameIds(): string[] {
    const gameIds: string[] = [];
    for (let i = 0; i < this.selectedSlots.length; i++) {
      const gameId = this.selectedSlots[i].gameId;
      if (gameIds.indexOf(gameId) < 0) {
        gameIds.push(gameId);
      }
    }
    return gameIds;
  }

  /**
   * 获取选中 slots 的摘要信息
   */
  getSelectedSummary(): string {
    if (this.selectedSlots.length === 0) {
      return '';
    }
    const names: string[] = [];
    for (let i = 0; i < this.selectedSlots.length; i++) {
      const slot = this.selectedSlots[i];
      names.push(`${slot.nickname} (${this.getGameName(slot.gameId)})`);
    }
    return names.join('、');
  }

  /** gameId 转游戏名称 */
  private getGameName(gameId: string): string {
    if (gameId === GameId.GENSHIN || gameId === 'genshin') return '原神';
    if (gameId === GameId.STARRAIL || gameId === 'starrail') return '星穹铁道';
    if (gameId === GameId.ZZZ || gameId === 'zzz') return '绝区零';
    return '未知';
  }
}
