/**
 * ZZZElement — 绝区零属性/职业枚举
 *
 * element_type 为数字，avatar_profession 为数字。
 */

export enum ZZZElementType {
  PHYSICAL  = 200,
  FIRE      = 201,
  ICE       = 202,
  ELECTRIC  = 203,
  ETHER     = 205,
  UNKNOWN   = 0,
}

export enum ZZZProfession {
  ATTACK    = 1,  // 强攻
  STUN      = 2,  // 击破
  SUPPORT   = 3,  // 支援
  ANOMALY   = 4,  // 异常
  DEFENSE   = 5,  // 防御
  ASSIST    = 6,  // 辅助
  UNKNOWN   = 0,
}

/** element_type 数字 → 中文标签 */
export function zzzElementLabel(elementType: number): string {
  if (elementType === ZZZElementType.PHYSICAL) { return '物理'; }
  if (elementType === ZZZElementType.FIRE)     { return '火'; }
  if (elementType === ZZZElementType.ICE)      { return '冰'; }
  if (elementType === ZZZElementType.ELECTRIC) { return '电'; }
  if (elementType === ZZZElementType.ETHER)    { return '以太'; }
  return '';
}

/** avatar_profession 数字 → 中文标签 */
export function zzzProfessionLabel(profession: number): string {
  if (profession === ZZZProfession.ATTACK)  { return '强攻'; }
  if (profession === ZZZProfession.STUN)    { return '击破'; }
  if (profession === ZZZProfession.SUPPORT) { return '支援'; }
  if (profession === ZZZProfession.ANOMALY) { return '异常'; }
  if (profession === ZZZProfession.DEFENSE) { return '防御'; }
  if (profession === ZZZProfession.ASSIST)  { return '辅助'; }
  return '';
}

/** element_type 数字 → 颜色资源 */
export function zzzElementColor(elementType: number): Resource {
  if (elementType === ZZZElementType.PHYSICAL) { return $r('app.color.zzz_element_physical'); }
  if (elementType === ZZZElementType.FIRE)     { return $r('app.color.zzz_element_fire'); }
  if (elementType === ZZZElementType.ICE)      { return $r('app.color.zzz_element_ice'); }
  if (elementType === ZZZElementType.ELECTRIC) { return $r('app.color.zzz_element_electric'); }
  if (elementType === ZZZElementType.ETHER)    { return $r('app.color.zzz_element_ether'); }
  return $r('app.color.color_text_secondary');
}
