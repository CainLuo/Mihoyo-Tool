/**
 * StarRailPropertyUtil — 星穹铁道属性类型工具函数
 *
 * 提供 StarRailPropertyType → Resource（多语言字符串）的映射。
 *
 * 使用场景：
 *   - 遗器/饰品主词条/副词条名称
 *   - 角色属性面板名称
 */

import { StarRailPropertyType } from 'core';

/**
 * StarRailPropertyType → 属性名称 Resource
 * 未知 property_type 返回 null。
 */
export function starRailPropertyTypeToResource(pt: number): Resource | null {
  if (pt === StarRailPropertyType.HP || pt === StarRailPropertyType.HP_FLAT) {
    return $r('app.string.sr_prop_hp');
  }
  if (pt === StarRailPropertyType.DEF || pt === StarRailPropertyType.DEF_FLAT) {
    return $r('app.string.sr_prop_def');
  }
  if (pt === StarRailPropertyType.ATK || pt === StarRailPropertyType.ATK_FLAT) {
    return $r('app.string.sr_prop_atk');
  }
  if (pt === StarRailPropertyType.SPD) { return $r('app.string.sr_prop_spd'); }
  if (pt === StarRailPropertyType.CRIT_RATE) { return $r('app.string.sr_prop_crit_rate'); }
  if (pt === StarRailPropertyType.CRIT_DMG) { return $r('app.string.sr_prop_crit_dmg'); }
  if (pt === StarRailPropertyType.EFFECT_HIT) { return $r('app.string.sr_prop_effect_hit'); }
  if (pt === StarRailPropertyType.ENERGY_REGEN || pt === StarRailPropertyType.ENERGY_REGEN_ORNAMENT) {
    return $r('app.string.sr_prop_energy_regen');
  }
  if (pt === StarRailPropertyType.EFFECT_RES) { return $r('app.string.sr_prop_effect_res'); }
  if (pt === StarRailPropertyType.BREAK_DMG) { return $r('app.string.sr_prop_break_dmg'); }
  if (pt === StarRailPropertyType.HEALING_BONUS) { return $r('app.string.sr_prop_healing_bonus'); }
  if (pt === StarRailPropertyType.HP_PCT) { return $r('app.string.sr_prop_hp_pct'); }
  if (pt === StarRailPropertyType.ATK_PCT || pt === StarRailPropertyType.ATK_PCT_ORNAMENT) {
    return $r('app.string.sr_prop_atk_pct');
  }
  if (pt === StarRailPropertyType.DEF_PCT) { return $r('app.string.sr_prop_def_pct'); }
  if (pt === StarRailPropertyType.SPD_PCT) { return $r('app.string.sr_prop_spd_pct'); }
  if (pt === StarRailPropertyType.PHYSICAL_DMG_BONUS) { return $r('app.string.sr_prop_physical_dmg'); }
  if (pt === StarRailPropertyType.FIRE_DMG_BONUS || pt === StarRailPropertyType.UNKNOWN_FIRE_DMG) {
    return $r('app.string.sr_prop_fire_dmg');
  }
  if (pt === StarRailPropertyType.ICE_DMG_BONUS || pt === StarRailPropertyType.UNKNOWN_ICE_DMG) {
    return $r('app.string.sr_prop_ice_dmg');
  }
  if (pt === StarRailPropertyType.LIGHTNING_DMG_BONUS) { return $r('app.string.sr_prop_lightning_dmg'); }
  if (pt === StarRailPropertyType.WIND_DMG_BONUS) { return $r('app.string.sr_prop_wind_dmg'); }
  if (pt === StarRailPropertyType.QUANTUM_DMG_BONUS || pt === StarRailPropertyType.UNKNOWN_QUANTUM_DMG) {
    return $r('app.string.sr_prop_quantum_dmg');
  }
  if (pt === StarRailPropertyType.IMAGINARY_DMG_BONUS || pt === StarRailPropertyType.UNKNOWN_IMAGINARY_DMG) {
    return $r('app.string.sr_prop_imaginary_dmg');
  }
  if (pt === StarRailPropertyType.UNKNOWN_71) { return $r('app.string.sr_prop_unknown_71'); }
  return null;
}
