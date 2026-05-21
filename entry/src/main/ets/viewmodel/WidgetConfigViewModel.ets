/**
 * WidgetConfigViewModel — Widget 卡片配置页的 ViewModel
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
import { formProvider } from '@kit.FormKit';
import { Want, common } from '@kit.AbilityKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { preferences } from '@kit.ArkData';
import { Logger, GameId } from 'core';
import { WidgetSize, WidgetConfig, getMaxSlots } from '../widget/models/WidgetConfig';
import { WidgetSlotRef, WidgetDataStore } from '../widget/models/WidgetDataStore';
import { WidgetDataStoreManager } from '../widget/utils/WidgetDataStoreManager';
import { WidgetDataStoreBuilder } from '../widget/utils/WidgetDataStoreBuilder';
import { WidgetSettingsUIState, WidgetSettingsCallbacks, WidgetSettingsSlotHelper, MihoyoAccountVM } from '../models/WidgetSettingsModels';
import { GameRoleCardVM } from '../models/HomeModels';
import { gameIdStrToLogo } from '../utils/GameIdUtil';
import BuildProfile from 'BuildProfile';

const TAG = 'WIDGET';

/** 配置步骤枚举 */
export enum WidgetConfigStep {
  SIZE = 'size',
  GAME = 'game',    // 仅 1x2 卡片：选择游戏类型
  SLOT = 'slot',    // 选择账号/角色
  DONE = 'done',
}

/** 配置完成回调类型 */
export type WidgetConfigCallback = () => void;

@ObservedV2
export class WidgetConfigViewModel {
  /** 当前步骤 */
  @Trace currentStep: WidgetConfigStep = WidgetConfigStep.SIZE;

  /** 选中的卡片尺寸 */
  @Trace selectedSize: WidgetSize = WidgetSize.SIZE_2x2;

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
      case WidgetConfigStep.SIZE:
        return true;
      case WidgetConfigStep.GAME:
        // 1x2 卡片必须选择游戏类型
        return true;
      case WidgetConfigStep.SLOT:
        return this.selectedSlots.length > 0;
      case WidgetConfigStep.DONE:
        return false;
    }
    return false;
  }

  /** 是否可以后退 */
  canGoPrev(): boolean {
    return this.currentStep !== WidgetConfigStep.SIZE;
  }

  /** 前进到下一步 */
  goNext(): void {
    // 根据尺寸决定步骤流程
    if (this.selectedSize === WidgetSize.SIZE_1x2) {
      // 1x2 卡片：SIZE → GAME → SLOT → DONE
      const steps1x2 = [WidgetConfigStep.SIZE, WidgetConfigStep.GAME, WidgetConfigStep.SLOT, WidgetConfigStep.DONE];
      const curIdx = steps1x2.indexOf(this.currentStep);
      if (curIdx < steps1x2.length - 1 && this.canGoNext()) {
        this.currentStep = steps1x2[curIdx + 1];
      }
    } else {
      // 其他尺寸：SIZE → SLOT → DONE
      const stepsOther = [WidgetConfigStep.SIZE, WidgetConfigStep.SLOT, WidgetConfigStep.DONE];
      const curIdx = stepsOther.indexOf(this.currentStep);
      if (curIdx < stepsOther.length - 1 && this.canGoNext()) {
        this.currentStep = stepsOther[curIdx + 1];
      }
    }
  }

  /** 返回上一步 */
  goPrev(): void {
    if (this.selectedSize === WidgetSize.SIZE_1x2) {
      const steps1x2 = [WidgetConfigStep.SIZE, WidgetConfigStep.GAME, WidgetConfigStep.SLOT, WidgetConfigStep.DONE];
      const curIdx = steps1x2.indexOf(this.currentStep);
      if (curIdx > 0) {
        this.currentStep = steps1x2[curIdx - 1];
      }
    } else {
      const stepsOther = [WidgetConfigStep.SIZE, WidgetConfigStep.SLOT, WidgetConfigStep.DONE];
      const curIdx = stepsOther.indexOf(this.currentStep);
      if (curIdx > 0) {
        this.currentStep = stepsOther[curIdx - 1];
      }
    }
  }

  /** 重置到第一步 */
  reset(): void {
    this.currentStep = WidgetConfigStep.SIZE;
    this.selectedSize = WidgetSize.SIZE_2x2;
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
    if (size !== WidgetSize.SIZE_1x2) {
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
    if (this.selectedSize === WidgetSize.SIZE_1x2) {
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
    if (this.selectedSize === WidgetSize.SIZE_1x2) {
      return [];
    }

    const groups: MihoyoAccountVM[] = [];
    const accountIds = Object.keys(this.dataStore.data);

    // 游戏排序顺序
    const gameOrder: Record<string, number> = {
      'genshin': 0,
      'starrail': 1,
      'zzz': 2,
      'honkai3': 3,
    };

    for (let i = 0; i < accountIds.length; i++) {
      const accountId = accountIds[i];
      const account = this.dataStore.data[accountId];
      const roleIds = Object.keys(account.slots);

      // 收集该账号下所有 slot
      const roles: GameRoleCardVM[] = [];
      for (let j = 0; j < roleIds.length; j++) {
        const roleId = roleIds[j];
        const slot = account.slots[roleId];
        
        // 构建 GameRoleCardVM（只填充 Widget 配置需要的字段）
        const role = new GameRoleCardVM(
          slot.gameId as GameId,
          '',
          $r('app.color.color_primary'),
          roleId,
          slot.nickname,
          slot.serverName,
          null,  // snapshot 不需要
          '',    // lastSyncDesc 不需要
          gameIdStrToLogo(slot.gameId)
        );
        roles.push(role);
      }

      // 按 gameId 排序
      for (let a = 0; a < roles.length; a++) {
        for (let b = a + 1; b < roles.length; b++) {
          const orderA = gameOrder[roles[a].gameId] ?? 99;
          const orderB = gameOrder[roles[b].gameId] ?? 99;
          if (orderA > orderB) {
            const temp = roles[a];
            roles[a] = roles[b];
            roles[b] = temp;
          }
        }
      }

      // 构建 MihoyoAccountVM
      const vm = new MihoyoAccountVM(
        accountId,
        accountId,
        roles,
        account.accountName,
        account.avatarUrl
      );
      groups.push(vm);
    }

    return groups;
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
    if (this.selectedSize === WidgetSize.SIZE_1x2) {
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
   * 注意：formProvider.openFormManager() 的 want.parameters 中只能传递标准参数，
   * 自定义参数（如 widgetConfig）无法传递到 onAddForm()。
   * 因此需要在调用 openFormManager 之前将配置保存到 Preferences，
   * 在 onAddForm() 时读取并应用。
   */
  /**
   * 完成配置，调用 formProvider.openFormManager()
   * 
   * 重要发现（来自官方文档验证）：
   * - openFormManager 的 want.parameters 只支持三个标准参数：
   *   - ohos.extra.param.key.form_dimension
   *   - ohos.extra.param.key.form_name
   *   - ohos.extra.param.key.module_name
   * - 自定义参数无法传递到 onAddForm()
   * 
   * 解决方案：
   * - 使用 formName 作为配置存储的 key（不使用 pending_config_ 前缀）
   * - 在 onAddForm() 中直接根据 formName 读取配置
   * - 必须在调用 openFormManager 之前保存配置
   */
  async complete(): Promise<void> {
    if (this.selectedSlots.length === 0) {
      Logger.error(TAG, 'complete: no slots selected');
      return;
    }

    const formName = this.sizeToFormName();
    const dimension = this.sizeToDimension();

    // 构建配置
    const config = new WidgetConfig();
    config.size = this.selectedSize;
    config.slots = this.selectedSlots;

    // 关键：直接使用 formName 作为配置 key（不带前缀）
    // 这样 onAddForm() 可以根据 want.parameters 中的 formName 直接读取
    const configKey = formName;
    const configJson = config.toJson();

    const want: Want = {
      bundleName: BuildProfile.BUNDLE_NAME,
      abilityName: 'EntryFormAbility',
      parameters: {
        'ohos.extra.param.key.form_dimension': dimension,
        'ohos.extra.param.key.form_name': formName,
        'ohos.extra.param.key.module_name': 'entry',
        // 注意：自定义参数无法传递，已验证
      },
    };

    Logger.info(TAG, `complete: formName=${formName} configKey=${configKey} slots=${this.selectedSlots.length} selectedGames=${this.getSelectedGameIds().join(',')}`);

    try {
      // 关键：必须等待配置保存完成后再调用 openFormManager
      await this.savePendingConfig(configKey, configJson);
      Logger.info(TAG, `complete: config saved, key=${configKey} jsonLen=${configJson.length}`);
      
      formProvider.openFormManager(want);
      if (this.onConfigComplete !== null) {
        this.onConfigComplete();
      }
    } catch (e) {
      const err = e as BusinessError;
      Logger.error(TAG, `openFormManager failed: code=${err.code} msg=${err.message}`);
    }
  }

  /**
   * 获取选中 slots 对应的游戏 ID 列表（去重）
   */
  private getSelectedGameIds(): string[] {
    const gameIds: string[] = [];
    for (let i = 0; i < this.selectedSlots.length; i++) {
      const slot = this.selectedSlots[i];
      let found = false;
      for (let j = 0; j < gameIds.length; j++) {
        if (gameIds[j] === slot.gameId) {
          found = true;
          break;
        }
      }
      if (!found) {
        gameIds.push(slot.gameId);
      }
    }
    return gameIds;
  }

  /**
   * 保存 pending config 到 Preferences
   * 
   * 注意：此方法在主应用进程执行，onAddForm() 在 FormExtension 进程执行。
   * 两个进程通过 Preferences 文件共享数据，必须确保 flush() 完成后再调用 openFormManager()。
   */
  private async savePendingConfig(key: string, configJson: string): Promise<void> {
    if (this.context === null) {
      Logger.error(TAG, 'savePendingConfig: context is null');
      return;
    }
    try {
      Logger.info(TAG, `savePendingConfig: start saving key=${key} jsonLen=${configJson.length}`);
      
      // 关键：先清除缓存，确保获取最新的 Preferences 实例
      // 这样可以避免多进程间的缓存不一致问题
      preferences.removePreferencesFromCacheSync(this.context, { name: 'widget_configs' });
      Logger.info(TAG, `savePendingConfig: cache cleared`);
      
      // 获取 Preferences 实例
      const prefs = await preferences.getPreferences(this.context, 'widget_configs');
      Logger.info(TAG, `savePendingConfig: prefs instance obtained`);
      
      // 写入配置
      await prefs.put(key, configJson);
      Logger.info(TAG, `savePendingConfig: put done`);
      
      // 刷新到磁盘（使用同步 API 确保数据立即写入）
      prefs.flushSync();
      Logger.info(TAG, `savePendingConfig: flushSync done`);
      
      // 验证写入：立即读取确认（使用同步 API）
      const verifyJson = prefs.getSync(key, '') as string;
      Logger.info(TAG, `savePendingConfig: verify read jsonLen=${verifyJson.length}`);
      
      if (verifyJson.length === 0) {
        Logger.error(TAG, `savePendingConfig: VERIFY FAILED - json is empty after flush!`);
      } else {
        Logger.info(TAG, `savePendingConfig: ✅ VERIFY SUCCESS`);
      }
    } catch (e) {
      const err = e as BusinessError;
      Logger.error(TAG, `savePendingConfig failed: code=${err.code} msg=${err.message}`);
    }
  }

  // ── 辅助方法 ─────────────────────────────────────────────────────

  /** 根据选中的尺寸返回对应的 formName */
  private sizeToFormName(): string {
    // 1×2 有三个独立模板，根据选中的游戏类型决定
    if (this.selectedSize === WidgetSize.SIZE_1x2) {
      if (this.selectedGameType === GameId.STARRAIL) {
        return 'widget_1x2_starrail';
      } else if (this.selectedGameType === GameId.ZZZ) {
        return 'widget_1x2_zzz';
      }
      return 'widget_1x2_genshin';
    }
    // 其他尺寸使用通用模板名
    if (this.selectedSize === WidgetSize.SIZE_2x4) {
      return 'widget_2x4';
    }
    if (this.selectedSize === WidgetSize.SIZE_4x4) {
      return 'widget_4x4';
    }
    return 'widget_2x2';
  }

  /** 根据尺寸返回对应的 FormDimension 数值 */
  private sizeToDimension(): number {
    if (this.selectedSize === WidgetSize.SIZE_1x2) {
      return 1; // Dimension_1_2
    }
    if (this.selectedSize === WidgetSize.SIZE_2x4) {
      return 3; // Dimension_2_4
    }
    if (this.selectedSize === WidgetSize.SIZE_4x4) {
      return 4; // Dimension_4_4
    }
    return 2; // Dimension_2_2
  }

  /** 获取选中 slots 的摘要信息 */
  getSelectedSummary(): string {
    if (this.selectedSlots.length === 0) {
      return '';
    }
    const names: string[] = [];
    for (let i = 0; i < this.selectedSlots.length; i++) {
      const slot = this.selectedSlots[i];
      names.push(`${slot.nickname} (${this.gameIdToName(slot.gameId)})`);
    }
    return names.join('、');
  }

  /** gameId 转游戏名称 */
  private gameIdToName(gameId: string): string {
    if (gameId === GameId.GENSHIN || gameId === 'genshin') return '原神';
    if (gameId === GameId.STARRAIL || gameId === 'starrail') return '星穹铁道';
    if (gameId === GameId.ZZZ || gameId === 'zzz') return '绝区零';
    return '未知';
  }
}
