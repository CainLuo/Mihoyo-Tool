/**
 * WidgetConfigViewModel — Widget 卡片配置页的 ViewModel
 *
 * 支持多账号混合显示：
 * 1. 选择卡片尺寸（1×2 / 2×2 / 2×4 / 4×4）
 * 2. 选择要显示的角色 slots（跨账号多选）
 * 3. 完成 → 调用 formProvider.openFormManager()
 */
import { formProvider } from '@kit.FormKit';
import { Want } from '@kit.AbilityKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { Logger, GameId } from 'core';
import { WidgetSize, WidgetConfig, getMaxSlots } from '../widget/models/WidgetConfig';
import { WidgetSlotRef, WidgetDataStore } from '../widget/models/WidgetDataStore';
import { WidgetDataStoreManager } from '../widget/utils/WidgetDataStoreManager';
import { WidgetDataStoreBuilder } from '../widget/utils/WidgetDataStoreBuilder';
import BuildProfile from 'BuildProfile';

const TAG = 'WidgetConfigViewModel';

/** 配置步骤枚举 */
export enum WidgetConfigStep {
  SIZE = 'size',
  SLOT = 'slot',
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

  /** 选中的 slots（三元组列表） */
  @Trace selectedSlots: WidgetSlotRef[] = [];

  /** 全局数据存储 */
  @Trace dataStore: WidgetDataStore = new WidgetDataStore();

  /** 配置完成回调 */
  onConfigComplete: WidgetConfigCallback | null = null;

  // ── 初始化 ───────────────────────────────────────────────────────

  /**
   * 初始化数据
   * 从 Preferences 加载数据，如果为空则从 DB 构建
   */
  async init(): Promise<void> {
    try {
      // 尝试从 Preferences 加载
      let store = await WidgetDataStoreManager.load();
      if (store.accounts.length === 0) {
        // 无数据则从 DB 构建
        store = await WidgetDataStoreBuilder.buildFromDB();
        await WidgetDataStoreManager.save(store);
      }
      this.dataStore = store;
      Logger.info(TAG, `init: ${store.accounts.length} accounts`);
    } catch (e) {
      Logger.error(TAG, `init failed: ${JSON.stringify(e)}`);
      this.dataStore = new WidgetDataStore();
    }
  }

  // ── 步骤导航 ─────────────────────────────────────────────────────

  /** 是否可以前进 */
  canGoNext(): boolean {
    switch (this.currentStep) {
      case WidgetConfigStep.SIZE:
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
    const steps = [WidgetConfigStep.SIZE, WidgetConfigStep.SLOT, WidgetConfigStep.DONE];
    const curIdx = steps.indexOf(this.currentStep);
    if (curIdx < steps.length - 1 && this.canGoNext()) {
      this.currentStep = steps[curIdx + 1];
    }
  }

  /** 返回上一步 */
  goPrev(): void {
    const steps = [WidgetConfigStep.SIZE, WidgetConfigStep.SLOT, WidgetConfigStep.DONE];
    const curIdx = steps.indexOf(this.currentStep);
    if (curIdx > 0) {
      this.currentStep = steps[curIdx - 1];
    }
  }

  /** 重置到第一步 */
  reset(): void {
    this.currentStep = WidgetConfigStep.SIZE;
    this.selectedSize = WidgetSize.SIZE_2x2;
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
  }

  /** 获取最大 slots 数量 */
  getMaxSlots(): number {
    return getMaxSlots(this.selectedSize);
  }

  // ── Slot 选择 ─────────────────────────────────────────────────────

  /** 获取所有可用的 slots */
  getAllSlots(): WidgetSlotRef[] {
    return this.dataStore.getAllSlots();
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
   * @returns 切换后的选中状态（true 表示选中，false 表示取消）
   */
  toggleSlot(slot: WidgetSlotRef): boolean {
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
   */
  complete(): void {
    if (this.selectedSlots.length === 0) {
      Logger.error(TAG, 'complete: no slots selected');
      return;
    }

    const formName = this.sizeToFormName();
    const dimension = this.sizeToDimension();

    // 构建配置保存到 Preferences（后续 FormExtension 会读取）
    const config = new WidgetConfig();
    config.size = this.selectedSize;
    config.slots = this.selectedSlots;

    const want: Want = {
      bundleName: BuildProfile.BUNDLE_NAME,
      abilityName: 'EntryFormAbility',
      parameters: {
        'ohos.extra.param.key.form_dimension': dimension,
        'ohos.extra.param.key.form_name': formName,
        'ohos.extra.param.key.module_name': 'entry',
        'widgetConfig': config.toJson(),
      },
    };

    Logger.info(TAG, `complete: bundleName=${BuildProfile.BUNDLE_NAME} formName=${formName} slots=${this.selectedSlots.length}`);

    try {
      formProvider.openFormManager(want);
      if (this.onConfigComplete !== null) {
        this.onConfigComplete();
      }
    } catch (e) {
      const err = e as BusinessError;
      Logger.error(TAG, `openFormManager failed: code=${err.code} msg=${err.message}`);
    }
  }

  // ── 辅助方法 ─────────────────────────────────────────────────────

  /** 根据选中的尺寸返回对应的 formName */
  private sizeToFormName(): string {
    // 1×2 有三个独立模板，根据选中的第一个 slot 决定
    if (this.selectedSize === WidgetSize.SIZE_1x2) {
      const firstGame = this.selectedSlots[0]?.gameId ?? 'genshin';
      if (firstGame === 'starrail') {
        return 'widget_1x2_starrail';
      } else if (firstGame === 'zzz') {
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
      names.push(`${slot.nickname} (${slot.gameId})`);
    }
    return names.join('、');
  }
}
