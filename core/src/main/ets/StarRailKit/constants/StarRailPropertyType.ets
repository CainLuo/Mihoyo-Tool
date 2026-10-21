/**
 * StarRailPropertyType — 星穹铁道属性类型枚举
 *
 * 对应米游社 API 中 property_type 字段的所有已知值。
 * 用于遗器词条、角色属性面板的统一映射，
 * 禁止在业务代码中直接写 property_type 数字字面量。
 *
 * 数据来源：game_record/app/hkrpg/api/avatar/info 接口
 * 响应体中 properties 数组的 property_type 字段，
 * 以及 relics/ornaments 的 main_property 和 properties 字段。
 *
 * 注意：星铁属性体系与原神完全不同，不可混用 GenshinPropertyType。
 */
export enum StarRailPropertyType {
  // ── 基础属性 ──────────────────────────────────────────────────────

  /** 生命值（base: "1771"，add: "1222"，final: "2994"） */
  HP = 1,

  /** 防御力（base: "788"，add: "632"，final: "1421"） */
  DEF = 2,

  /** 攻击力（base: "916"，add: "190"，final: "1107"） */
  ATK = 3,

  /** 速度（base: "105"，add: "2"，final: "107"） */
  SPD = 4,

  /** 暴击率（base: "46.7%"，add: "0.0%"，final: "46.7%"） */
  CRIT_RATE = 5,

  /** 暴击伤害（base: "68.1%"，add: "0.0%"，final: "68.1%"） */
  CRIT_DMG = 6,

  /** 效果命中（base: "0.0%"，add: "0.0%"，final: "0.0%"） */
  EFFECT_HIT = 7,

  /** 能量恢复效率（base: "100.0%"，add: "0.0%"，final: "100.0%"） */
  ENERGY_REGEN = 9,

  /** 效果抵抗（base: "0.0%"，add: "0.0%"，final: "0.0%"） */
  EFFECT_RES = 10,

  /** 击破特攻（base: "11.3%"，add: "0.0%"，final: "11.3%"） */
  BREAK_DMG = 11,

  // ── 遗器主词条 / 副词条 ───────────────────────────────────────────

  /** 生命值（固定值，遗器副词条，如 "42"） */
  HP_FLAT = 27,

  /** 攻击力（固定值，遗器副词条，如 "16"） */
  ATK_FLAT = 29,

  /** 防御力（固定值，遗器副词条，如 "56"） */
  DEF_FLAT = 31,

  /** 生命值百分比（遗器主/副词条，如 "6.9%"） */
  HP_PCT = 32,

  /** 攻击力百分比（遗器主/副词条，如 "6.9%"） */
  ATK_PCT = 33,

  /** 防御力百分比（遗器主/副词条，如 "9.7%"） */
  DEF_PCT = 34,

  // ── 饰品主词条 ────────────────────────────────────────────────────

  /** 能量恢复效率（饰品主词条，如 "6.2%"） */
  ENERGY_REGEN_ORNAMENT = 24,

  /** 攻击力百分比（饰品主词条，如 "6.9%"） */
  ATK_PCT_ORNAMENT = 32,

  // ── 元素伤害加成（饰品主词条）────────────────────────────────────

  /** 物理属性伤害提高（如 "6.2%"） */
  PHYSICAL_DMG_BONUS = 51,

  /** 火属性伤害提高 */
  FIRE_DMG_BONUS = 52,

  /** 冰属性伤害提高 */
  ICE_DMG_BONUS = 53,

  /** 雷属性伤害提高 */
  LIGHTNING_DMG_BONUS = 54,

  /** 风属性伤害提高 */
  WIND_DMG_BONUS = 55,

  /** 量子属性伤害提高 */
  QUANTUM_DMG_BONUS = 56,

  /** 虚数属性伤害提高（如 "7.3%"） */
  IMAGINARY_DMG_BONUS = 57,

  // ── 特殊属性 ──────────────────────────────────────────────────────

  /** 治疗量加成（如 "6.2%"） */
  HEALING_BONUS = 58,

  /** 速度百分比（遗器副词条，如 "5.8%"） */
  SPD_PCT = 59,

  /** 未知属性 71（base: "0.0%"，具体含义待确认） */
  UNKNOWN_71 = 71,

  // ── 待确认属性（来自实际 API 数据，名称为推断值）────────────────

  /** 冰属性伤害提高（待确认，pt=12） */
  UNKNOWN_ICE_DMG = 12,

  /** 火属性伤害提高（待确认，pt=14） */
  UNKNOWN_FIRE_DMG = 14,

  /** 量子属性伤害提高（待确认，pt=16） */
  UNKNOWN_QUANTUM_DMG = 16,

  /** 虚数属性伤害提高（待确认，pt=18） */
  UNKNOWN_IMAGINARY_DMG = 18,
}
