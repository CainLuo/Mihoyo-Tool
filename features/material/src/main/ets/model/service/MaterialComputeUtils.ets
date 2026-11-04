/**
 * MaterialComputeUtils.ets — 材料计算服务的共用工具
 *
 * 三个游戏的独立计算模块与 `MaterialComputeService` facade 共用。
 */

import { MaterialComputeResult } from './MaterialComputeResult';

export const GENSHIN_TAG: string = 'GenshinCalc';
export const STARRAIL_TAG: string = 'StarRailCalc';
export const ZZZ_TAG: string = 'ZZZCalc';

export class MaterialComputeUtils {
  /** 等级截断到 1 ~ max */
  static clampLevel(level: number, max: number): number {
    return Math.min(Math.max(level, 1), max);
  }

  /** 有成功 → SUCCESS；全部已达成目标 → NO_NEEDS；其余 → FAILED */
  static toResult(successCount: number, reachedCount: number, selectedCount: number): MaterialComputeResult {
    if (successCount > 0) {
      return MaterialComputeResult.SUCCESS;
    }
    if (reachedCount > 0 && reachedCount === selectedCount) {
      return MaterialComputeResult.NO_NEEDS;
    }
    return MaterialComputeResult.FAILED;
  }

  static parseObject(json: string): Record<string, Object> | null {
    if (json.length === 0) {
      return null;
    }
    try {
      return JSON.parse(json) as Record<string, Object>;
    } catch (_) {
      return null;
    }
  }

  static getErrorMessage(error: Object): string {
    return error instanceof Error ? error.message : `${error}`;
  }
}
