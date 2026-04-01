/**
 * StarRailElement — 崩坏：星穹铁道属性枚举
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
  DESTRUCTION = 1,  // 毁灭
  HUNT        = 2,  // 巡猎
  ERUDITION   = 3,  // 智识
  HARMONY     = 4,  // 同谐
  NIHILITY    = 5,  // 虚无
  PRESERVATION= 6,  // 存护
  ABUNDANCE   = 7,  // 丰饶
  REMEMBRANCE = 8,  // 记忆
  ELATION     = 9,  // 欢愉
  UNKNOWN     = 0,
}

/** API element 字符串 → 中文标签 */
export function starRailElementLabel(element: string): string {
  if (element === StarRailElement.PHYSICAL)  { return '物理'; }
  if (element === StarRailElement.FIRE)      { return '火'; }
  if (element === StarRailElement.ICE)       { return '冰'; }
  if (element === StarRailElement.LIGHTNING) { return '雷'; }
  if (element === StarRailElement.WIND)      { return '风'; }
  if (element === StarRailElement.QUANTUM)   { return '量子'; }
  if (element === StarRailElement.IMAGINARY) { return '虚数'; }
  return element;
}

/** base_type 数字 → 命途中文名 */
export function starRailPathLabel(baseType: number): string {
  if (baseType === StarRailPath.DESTRUCTION)  { return '毁灭'; }
  if (baseType === StarRailPath.HUNT)         { return '巡猎'; }
  if (baseType === StarRailPath.ERUDITION)    { return '智识'; }
  if (baseType === StarRailPath.HARMONY)      { return '同谐'; }
  if (baseType === StarRailPath.NIHILITY)     { return '虚无'; }
  if (baseType === StarRailPath.PRESERVATION) { return '存护'; }
  if (baseType === StarRailPath.ABUNDANCE)    { return '丰饶'; }
  if (baseType === StarRailPath.REMEMBRANCE)  { return '记忆'; }
  if (baseType === StarRailPath.ELATION)      { return '欢愉'; }
  return '';
}

/** API element 字符串 → 颜色资源 */
export function starRailElementColor(element: string): Resource {
  if (element === StarRailElement.PHYSICAL)  { return $r('app.color.sr_element_physical'); }
  if (element === StarRailElement.FIRE)      { return $r('app.color.sr_element_fire'); }
  if (element === StarRailElement.ICE)       { return $r('app.color.sr_element_ice'); }
  if (element === StarRailElement.LIGHTNING) { return $r('app.color.sr_element_lightning'); }
  if (element === StarRailElement.WIND)      { return $r('app.color.sr_element_wind'); }
  if (element === StarRailElement.QUANTUM)   { return $r('app.color.sr_element_quantum'); }
  if (element === StarRailElement.IMAGINARY) { return $r('app.color.sr_element_imaginary'); }
  return $r('app.color.color_text_secondary');
}

/** base_type 数字 → 命途颜色资源 */
export function starRailPathColor(baseType: number): Resource {
  if (baseType === StarRailPath.DESTRUCTION)  { return $r('app.color.sr_path_destruction'); }
  if (baseType === StarRailPath.HUNT)         { return $r('app.color.sr_path_hunt'); }
  if (baseType === StarRailPath.ERUDITION)    { return $r('app.color.sr_path_erudition'); }
  if (baseType === StarRailPath.HARMONY)      { return $r('app.color.sr_path_harmony'); }
  if (baseType === StarRailPath.NIHILITY)     { return $r('app.color.sr_path_nihility'); }
  if (baseType === StarRailPath.PRESERVATION) { return $r('app.color.sr_path_preservation'); }
  if (baseType === StarRailPath.ABUNDANCE)    { return $r('app.color.sr_path_abundance'); }
  if (baseType === StarRailPath.REMEMBRANCE)  { return $r('app.color.sr_path_remembrance'); }
  if (baseType === StarRailPath.ELATION)      { return $r('app.color.sr_path_elation'); }
  return $r('app.color.color_text_secondary');
}
