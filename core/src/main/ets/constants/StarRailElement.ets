/**
 * StarRailElement — 崩坏：星穹铁道属性和命途枚举
 *
 * element 字段为英文小写字符串（如 'fire'、'ice'），来自 avatar/basic API。
 * base_type 字段为数字，对应角色命途，来自 avatar/basic API。
 * 转换函数在边界处（ViewModel）调用一次，之后全程使用 enum。
 */
export enum StarRailElement {
  PHYSICAL  = 'physical',  // 物理
  FIRE      = 'fire',       // 火
  ICE       = 'ice',        // 冰
  LIGHTNING = 'lightning',  // 雷
  WIND      = 'wind',       // 风
  QUANTUM   = 'quantum',    // 量子
  IMAGINARY = 'imaginary',  // 虚数
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

/**
 * API element 字符串 → StarRailElement enum
 * 未知值返回 StarRailElement.UNKNOWN
 */
export function starRailElementFromString(s: string): StarRailElement {
  if (s === StarRailElement.PHYSICAL)  { return StarRailElement.PHYSICAL; }
  if (s === StarRailElement.FIRE)      { return StarRailElement.FIRE; }
  if (s === StarRailElement.ICE)       { return StarRailElement.ICE; }
  if (s === StarRailElement.LIGHTNING) { return StarRailElement.LIGHTNING; }
  if (s === StarRailElement.WIND)      { return StarRailElement.WIND; }
  if (s === StarRailElement.QUANTUM)   { return StarRailElement.QUANTUM; }
  if (s === StarRailElement.IMAGINARY) { return StarRailElement.IMAGINARY; }
  return StarRailElement.UNKNOWN;
}

/**
 * base_type 数字 → StarRailPath enum
 * 未知值返回 StarRailPath.UNKNOWN
 */
export function starRailPathFromNumber(n: number): StarRailPath {
  if (n === StarRailPath.DESTRUCTION)  { return StarRailPath.DESTRUCTION; }
  if (n === StarRailPath.HUNT)         { return StarRailPath.HUNT; }
  if (n === StarRailPath.ERUDITION)    { return StarRailPath.ERUDITION; }
  if (n === StarRailPath.HARMONY)      { return StarRailPath.HARMONY; }
  if (n === StarRailPath.NIHILITY)     { return StarRailPath.NIHILITY; }
  if (n === StarRailPath.PRESERVATION) { return StarRailPath.PRESERVATION; }
  if (n === StarRailPath.ABUNDANCE)    { return StarRailPath.ABUNDANCE; }
  if (n === StarRailPath.REMEMBRANCE)  { return StarRailPath.REMEMBRANCE; }
  if (n === StarRailPath.ELATION)      { return StarRailPath.ELATION; }
  return StarRailPath.UNKNOWN;
}
