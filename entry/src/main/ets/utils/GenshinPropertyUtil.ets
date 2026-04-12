/**
 * GenshinPropertyUtil — 原神属性类型工具函数
 *
 * 提供 GenshinPropertyType → Resource（多语言字符串）的映射，
 * 以及属性面板的展示顺序和高亮规则。
 *
 * 使用场景：
 *   - 圣遗物主词条/副词条标签
 *   - 武器副词条标签
 *   - 角色属性面板
 */

import { GenshinPropertyType } from 'core';

/**
 * 属性面板展示顺序（HP → ATK → DEF → EM → 暴击率 → 暴击伤害 → 充能 → 治疗）
 */
export const GENSHIN_STAT_ORDER: number[] = [
  GenshinPropertyType.HP_FINAL,
  GenshinPropertyType.ATK_FINAL,
  GenshinPropertyType.DEF_FINAL,
  GenshinPropertyType.ELEMENTAL_MASTERY,
  GenshinPropertyType.CRIT_RATE,
  GenshinPropertyType.CRIT_DMG,
  GenshinPropertyType.ENERGY_RECHARGE,
  GenshinPropertyType.HEALING_BONUS,
];

/**
 * 属性面板标签（与 GENSHIN_STAT_ORDER 一一对应）
 */
export const GENSHIN_STAT_LABELS: Resource[] = [
  $r('app.string.char_detail_hp'),
  $r('app.string.char_detail_atk'),
  $r('app.string.char_detail_def'),
  $r('app.string.char_detail_em'),
  $r('app.string.char_detail_cr'),
  $r('app.string.char_detail_cd'),
  $r('app.string.char_detail_er'),
  $r('app.string.char_detail_heal'),
];

/**
 * 需要高亮显示的属性类型（暴击率/暴击伤害）
 */
export const GENSHIN_HIGHLIGHT_PROPS: number[] = [
  GenshinPropertyType.CRIT_RATE,
  GenshinPropertyType.CRIT_DMG,
];

/**
 * GenshinPropertyType → Resource（多语言字符串）
 * 用于圣遗物词条、武器副词条、属性面板等所有需要展示属性名称的场景。
 * 未知 property_type 返回 null。
 */
export function genshinPropertyTypeToResource(pt: number): Resource | null {
  if (pt === GenshinPropertyType.HP_FLAT) { return $r('app.string.prop_hp_flat'); }
  if (pt === GenshinPropertyType.HP_PCT) { return $r('app.string.prop_hp_pct'); }
  if (pt === GenshinPropertyType.BASE_ATK) { return $r('app.string.prop_base_atk'); }
  if (pt === GenshinPropertyType.ATK_FLAT) { return $r('app.string.prop_atk_flat'); }
  if (pt === GenshinPropertyType.ATK_PCT) { return $r('app.string.prop_atk_pct'); }
  if (pt === GenshinPropertyType.DEF_FLAT) { return $r('app.string.prop_def_flat'); }
  if (pt === GenshinPropertyType.DEF_PCT) { return $r('app.string.prop_def_pct'); }
  if (pt === GenshinPropertyType.BASE_HP) { return $r('app.string.prop_base_hp'); }
  if (pt === GenshinPropertyType.BASE_DEF) { return $r('app.string.prop_base_def'); }
  if (pt === GenshinPropertyType.CRIT_RATE) { return $r('app.string.prop_crit_rate'); }
  if (pt === GenshinPropertyType.CRIT_DMG) { return $r('app.string.prop_crit_dmg'); }
  if (pt === GenshinPropertyType.ENERGY_RECHARGE) { return $r('app.string.prop_energy_recharge'); }
  if (pt === GenshinPropertyType.HEALING_BONUS) { return $r('app.string.prop_healing_bonus'); }
  if (pt === GenshinPropertyType.INCOMING_HEALING_BONUS) { return $r('app.string.prop_incoming_healing'); }
  if (pt === GenshinPropertyType.ELEMENTAL_MASTERY) { return $r('app.string.prop_elemental_mastery'); }
  if (pt === GenshinPropertyType.HP_FINAL) { return $r('app.string.prop_hp_flat'); }
  if (pt === GenshinPropertyType.ATK_FINAL) { return $r('app.string.prop_atk_flat'); }
  if (pt === GenshinPropertyType.DEF_FINAL) { return $r('app.string.prop_def_flat'); }
  if (pt === GenshinPropertyType.PYRO_DMG_BONUS) { return $r('app.string.prop_pyro_dmg'); }
  if (pt === GenshinPropertyType.ELECTRO_DMG_BONUS) { return $r('app.string.prop_electro_dmg'); }
  if (pt === GenshinPropertyType.HYDRO_DMG_BONUS) { return $r('app.string.prop_hydro_dmg'); }
  if (pt === GenshinPropertyType.DENDRO_DMG_BONUS) { return $r('app.string.prop_dendro_dmg'); }
  if (pt === GenshinPropertyType.ANEMO_DMG_BONUS) { return $r('app.string.prop_anemo_dmg'); }
  if (pt === GenshinPropertyType.GEO_DMG_BONUS) { return $r('app.string.prop_geo_dmg'); }
  if (pt === GenshinPropertyType.CRYO_DMG_BONUS) { return $r('app.string.prop_cryo_dmg'); }
  if (pt === GenshinPropertyType.PHYSICAL_DMG_BONUS) { return $r('app.string.prop_physical_dmg'); }
  if (pt === GenshinPropertyType.COOLDOWN_REDUCTION) { return $r('app.string.prop_cooldown_reduction'); }
  if (pt === GenshinPropertyType.SHIELD_STRENGTH) { return $r('app.string.prop_shield_strength'); }
  return null;
}
