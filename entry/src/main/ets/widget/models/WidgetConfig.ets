/**
 * WidgetConfig.ets — Widget 配置存储模型
 *
 * 每个 Widget 只存储选择的 slot 索引，不存储 rawJson。
 * 存储位置：Preferences 文件名 widget_configs，Key form_{formId}
 */

import { WidgetSlotRef, WidgetSlotRefJson } from './WidgetDataStore';

/** WidgetConfig JSON 结构 */
interface WidgetConfigJson {
  formId: string;
  formName: string;
  size: string;
  slots: WidgetSlotRefJson[];
}

/**
 * Widget 尺寸枚举
 */
export enum WidgetSize {
  SIZE_1x2 = '1x2',
  SIZE_2x2 = '2x2',
  SIZE_2x4 = '2x4',
  SIZE_4x4 = '4x4',
}

/**
 * 获取尺寸对应的最大 slots 数量
 */
export function getMaxSlots(size: WidgetSize): number {
  switch (size) {
    case WidgetSize.SIZE_1x2:
      return 1;
    case WidgetSize.SIZE_2x2:
    case WidgetSize.SIZE_2x4:
      return 2;
    case WidgetSize.SIZE_4x4:
      return 3;
    default:
      return 1;
  }
}

/**
 * Widget 配置
 */
export class WidgetConfig {
  /** Widget 实例 ID（formId） */
  formId: string = '';
  /** 卡片模板名，如 'widget_1x2_genshin' */
  formName: string = '';
  /** Widget 尺寸 */
  size: WidgetSize = WidgetSize.SIZE_2x2;
  /** 选择的槽位列表（只存三元组，不存 rawJson） */
  slots: WidgetSlotRef[] = [];

  toJson(): string {
    const obj: WidgetConfigJson = {
      formId: this.formId,
      formName: this.formName,
      size: this.size,
      slots: this.slots.map((s) => s.toJson()),
    };
    return JSON.stringify(obj);
  }

  static fromJson(json: string): WidgetConfig {
    const d = new WidgetConfig();
    if (json.length === 0) {
      return d;
    }
    try {
      const obj = JSON.parse(json) as WidgetConfigJson;
      d.formId = obj.formId ?? '';
      d.formName = obj.formName ?? '';
      d.size = obj.size as WidgetSize ?? WidgetSize.SIZE_2x2;
      if (obj.slots !== undefined && obj.slots !== null) {
        for (let i = 0; i < obj.slots.length; i++) {
          d.slots.push(WidgetSlotRef.fromJson(obj.slots[i]));
        }
      }
    } catch (_e) {
      // 解析失败返回默认值，不崩溃
    }
    return d;
  }

  /**
   * 校验 slots 数量是否在尺寸限制内
   */
  validate(): boolean {
    const maxSlots = getMaxSlots(this.size);
    return this.slots.length > 0 && this.slots.length <= maxSlots;
  }

  /**
   * 添加 slot，如果未超过限制且不重复
   * @returns 是否添加成功
   */
  addSlot(slot: WidgetSlotRef): boolean {
    const maxSlots = getMaxSlots(this.size);
    if (this.slots.length >= maxSlots) {
      return false;
    }
    // 检查是否已存在相同的 key
    for (let i = 0; i < this.slots.length; i++) {
      if (this.slots[i].key === slot.key) {
        return false;
      }
    }
    this.slots.push(slot);
    return true;
  }

  /**
   * 移除指定 index 的 slot
   */
  removeSlotAt(index: number): void {
    if (index >= 0 && index < this.slots.length) {
      this.slots.splice(index, 1);
    }
  }

  /**
   * 检查指定的 slot 是否已选中
   */
  isSlotSelected(accountId: string, gameId: string, roleId: string): boolean {
    for (let i = 0; i < this.slots.length; i++) {
      const slot = this.slots[i];
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
    for (let i = 0; i < this.slots.length; i++) {
      if (this.slots[i].key === slot.key) {
        this.slots.splice(i, 1);
        return false;
      }
    }
    // 未找到，尝试添加
    return this.addSlot(slot);
  }
}
