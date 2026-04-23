/**
 * StarRailElement — 星铁属性/命途枚举（从 core 重新导出）+ 图标工具函数
 *
 * enum 定义和转换函数在 core，此文件只保留依赖 $r() 的图标函数。
 */
import { StarRailElement, StarRailPath } from 'core';
export { StarRailElement, StarRailPath, starRailElementFromString, starRailPathFromNumber } from 'core';

/** element 字符串 → 属性图标资源 */
export function starRailElementIcon(element: string): Resource | null {
  if (element === StarRailElement.PHYSICAL)  { return $r('app.media.sr_element_physical'); }
  if (element === StarRailElement.FIRE)      { return $r('app.media.sr_element_fire'); }
  if (element === StarRailElement.ICE)       { return $r('app.media.sr_element_ice'); }
  if (element === StarRailElement.LIGHTNING) { return $r('app.media.sr_element_thunder'); }
  if (element === StarRailElement.WIND)      { return $r('app.media.sr_element_wind'); }
  if (element === StarRailElement.QUANTUM)   { return $r('app.media.sr_element_quantum'); }
  if (element === StarRailElement.IMAGINARY) { return $r('app.media.sr_element_imaginary'); }
  return null;
}

/** base_type 数字 → 命途图标资源 */
export function starRailPathIcon(baseType: number): Resource | null {
  if (baseType === StarRailPath.DESTRUCTION)  { return $r('app.media.sr_path_destruction'); }
  if (baseType === StarRailPath.HUNT)         { return $r('app.media.sr_path_hunt'); }
  if (baseType === StarRailPath.ERUDITION)    { return $r('app.media.sr_path_erudition'); }
  if (baseType === StarRailPath.HARMONY)      { return $r('app.media.sr_path_harmony'); }
  if (baseType === StarRailPath.NIHILITY)     { return $r('app.media.sr_path_nihility'); }
  if (baseType === StarRailPath.PRESERVATION) { return $r('app.media.sr_path_preservation'); }
  if (baseType === StarRailPath.ABUNDANCE)    { return $r('app.media.sr_path_abundance'); }
  if (baseType === StarRailPath.REMEMBRANCE)  { return $r('app.media.sr_path_remembrance'); }
  if (baseType === StarRailPath.ELATION)      { return $r('app.media.sr_path_elation'); }
  return null;
}
