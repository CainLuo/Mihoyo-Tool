/**
 * ZZZElement — 绝区零属性/职业枚举（从 core 重新导出）+ 图标/颜色工具函数
 *
 * enum 定义和转换函数在 core，此文件只保留依赖 $r() 的图标/颜色函数。
 */
import { ZZZElementType, ZZZProfession } from 'core';
export { ZZZElementType, ZZZProfession, zzzElementTypeFromNumber, zzzProfessionFromNumber } from 'core';

/** element_type 数字 → 属性图标资源 */
export function zzzElementIcon(elementType: number): Resource | null {
  if (elementType === ZZZElementType.PHYSICS)           { return $r('app.media.zzz_element_physics'); }
  if (elementType === ZZZElementType.FIRE)              { return $r('app.media.zzz_element_fire'); }
  if (elementType === ZZZElementType.ICE)               { return $r('app.media.zzz_element_ice'); }
  if (elementType === ZZZElementType.ELECTRIC)          { return $r('app.media.zzz_element_elec'); }
  if (elementType === ZZZElementType.ETHER)             { return $r('app.media.zzz_element_ether'); }
  if (elementType === ZZZElementType.ZHEN_ZHEN_ASSAULT) { return $r('app.media.zzz_element_zhen_zhen_assault'); }
  if (elementType === ZZZElementType.FIRE_FROST)        { return $r('app.media.zzz_element_fire_frost'); }
  if (elementType === ZZZElementType.AURIC_ETHER)       { return $r('app.media.zzz_element_auric_ether'); }
  return null;
}

/** avatar_profession 数字 → 职业图标资源 */
export function zzzProfessionIcon(profession: number): Resource | null {
  if (profession === ZZZProfession.ATTACK)  { return $r('app.media.zzz_avatar_profession_powerful_attack'); }
  if (profession === ZZZProfession.STUN)    { return $r('app.media.zzz_avatar_profession_break_stun'); }
  if (profession === ZZZProfession.ANOMALY) { return $r('app.media.zzz_avatar_profession_element_abnormal'); }
  if (profession === ZZZProfession.SUPPORT) { return $r('app.media.zzz_avatar_profession_support'); }
  if (profession === ZZZProfession.DEFENSE) { return $r('app.media.zzz_avatar_profession_defense'); }
  if (profession === ZZZProfession.RUPTURE) { return $r('app.media.zzz_avatar_profession_rupture'); }
  return null;
}

/** element_type 数字 → 颜色资源 */
export function zzzElementColor(elementType: number): Resource {
  if (elementType === ZZZElementType.PHYSICS)  { return $r('app.color.zzz_element_physical'); }
  if (elementType === ZZZElementType.FIRE)     { return $r('app.color.zzz_element_fire'); }
  if (elementType === ZZZElementType.ICE)      { return $r('app.color.zzz_element_ice'); }
  if (elementType === ZZZElementType.ELECTRIC) { return $r('app.color.zzz_element_electric'); }
  if (elementType === ZZZElementType.ETHER)    { return $r('app.color.zzz_element_ether'); }
  return $r('app.color.color_text_secondary');
}
