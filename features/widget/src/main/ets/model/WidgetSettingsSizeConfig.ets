/**
 * WidgetSettingsSizeConfig — Widget 配置页的尺寸映射
 *
 * 集中维护「尺寸 → formName / FormDimension / preset key」三张映射，
 * 避免 ViewModel 里三份平行的 if-else 分支。
 */
import { GameId } from 'core';
import { WidgetSize } from './WidgetConfigModels';

/** 根据尺寸与游戏类型返回 formName（1x2 有三个独立模板） */
export function getFormName(size: WidgetSize, gameType: string): string {
  if (size === WidgetSize.SIZE_1X2) {
    if (gameType === GameId.STARRAIL) {
      return 'widget_1x2_starrail';
    }
    if (gameType === GameId.ZZZ) {
      return 'widget_1x2_zzz';
    }
    return 'widget_1x2_genshin';
  }
  if (size === WidgetSize.SIZE_2X4) {
    return 'widget_2x4';
  }
  if (size === WidgetSize.SIZE_4X4) {
    return 'widget_4x4';
  }
  return 'widget_2x2';
}

/** 根据尺寸返回对应的 FormDimension 数值 */
export function getDimension(size: WidgetSize): number {
  if (size === WidgetSize.SIZE_1X2) {
    return 1; // Dimension_1_2
  }
  if (size === WidgetSize.SIZE_2X4) {
    return 3; // Dimension_2_4
  }
  if (size === WidgetSize.SIZE_4X4) {
    return 4; // Dimension_4_4
  }
  return 2; // Dimension_2_2
}

/** 根据尺寸返回 preset key（用于 WidgetDataStore.widgets，不带游戏后缀） */
export function getPresetKey(size: WidgetSize): string {
  if (size === WidgetSize.SIZE_1X2) {
    return 'widget12';
  }
  if (size === WidgetSize.SIZE_2X4) {
    return 'widget24';
  }
  if (size === WidgetSize.SIZE_4X4) {
    return 'widget44';
  }
  return 'widget22';
}
