/**
 * StarRailElement — 崩坏：星穹铁道属性和命途枚举
 *
 * API 返回的 element 字段为英文小写字符串。
 * base_type 字段为数字，对应命途。
 */

export enum StarRailElement {
  PHYSICAL  = 'physical',
  FIRE      = 'fire',
  ICE       = 'ice',
  LIGHTNING = 'lightning',
  WIND      = 'wind',
  QUANTUM   = 'quantum',
  IMAGINARY = 'imaginary',
  UNKNOWN   = '',
}

export enum StarRailPath {
  DESTRUCTION  = 1,  // 毁灭
  HUNT         = 2,  // 巡猎
  ERUDITION    = 3,  // 智识
  HARMONY      = 4,  // 同谐
  NIHILITY     = 5,  // 虚无
  PRESERVATION = 6,  // 存护
  ABUNDANCE    = 7,  // 丰饶
  REMEMBRANCE  = 8,  // 记忆
  ELATION      = 9,  // 欢愉
  UNKNOWN      = 0,
}

/** API element 字符串 → 属性图标资源，未知属性返回 null */
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

/** base_type 数字 → 命途图标资源，未知命途返回 null */
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
