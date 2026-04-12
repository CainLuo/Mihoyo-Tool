/**
 * StarRailPropertyUtil — 星穹铁道属性类型工具函数
 *
 * 提供 StarRailPropertyType → 属性名称字符串的映射。
 *
 * 使用场景：
 *   - 遗器/饰品主词条/副词条名称
 *   - 角色属性面板名称
 */

import { StarRailPropertyType } from 'core';

/**
 * StarRailPropertyType → 属性名称字符串
 * 未知 property_type 返回 `属性{pt}`。
 */
export function starRailPropertyTypeToName(pt: number): string {
  if (pt === StarRailPropertyType.HP) { return '生命值'; }
  if (pt === StarRailPropertyType.DEF) { return '防御力'; }
  if (pt === StarRailPropertyType.ATK) { return '攻击力'; }
  if (pt === StarRailPropertyType.SPD) { return '速度'; }
  if (pt === StarRailPropertyType.CRIT_RATE) { return '暴击率'; }
  if (pt === StarRailPropertyType.CRIT_DMG) { return '暴击伤害'; }
  if (pt === StarRailPropertyType.EFFECT_HIT) { return '效果命中'; }
  if (pt === StarRailPropertyType.ENERGY_REGEN) { return '能量恢复效率'; }
  if (pt === StarRailPropertyType.EFFECT_RES) { return '效果抵抗'; }
  if (pt === StarRailPropertyType.BREAK_DMG) { return '击破特攻'; }
  if (pt === StarRailPropertyType.HEALING_BONUS) { return '治疗量加成'; }
  if (pt === StarRailPropertyType.PHYSICAL_DMG_BONUS) { return '物理属性伤害提高'; }
  if (pt === StarRailPropertyType.FIRE_DMG_BONUS) { return '火属性伤害提高'; }
  if (pt === StarRailPropertyType.ICE_DMG_BONUS) { return '冰属性伤害提高'; }
  if (pt === StarRailPropertyType.LIGHTNING_DMG_BONUS) { return '雷属性伤害提高'; }
  if (pt === StarRailPropertyType.WIND_DMG_BONUS) { return '风属性伤害提高'; }
  if (pt === StarRailPropertyType.QUANTUM_DMG_BONUS) { return '量子属性伤害提高'; }
  if (pt === StarRailPropertyType.IMAGINARY_DMG_BONUS) { return '虚数属性伤害提高'; }
  if (pt === StarRailPropertyType.HP_FLAT) { return '生命值'; }
  if (pt === StarRailPropertyType.ATK_FLAT) { return '攻击力'; }
  if (pt === StarRailPropertyType.DEF_FLAT) { return '防御力'; }
  if (pt === StarRailPropertyType.HP_PCT) { return '生命值%'; }
  if (pt === StarRailPropertyType.ATK_PCT) { return '攻击力%'; }
  if (pt === StarRailPropertyType.DEF_PCT) { return '防御力%'; }
  if (pt === StarRailPropertyType.SPD_PCT) { return '速度%'; }
  if (pt === StarRailPropertyType.UNKNOWN_71) { return '欢愉度'; }
  // 补充未在枚举中定义的属性
  if (pt === 12) { return '冰属性伤害提高'; }
  if (pt === 14) { return '火属性伤害提高'; }
  if (pt === 16) { return '量子属性伤害提高'; }
  if (pt === 18) { return '虚数属性伤害提高'; }
  return `属性${pt}`;
}
