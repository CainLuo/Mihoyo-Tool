/**
 * GenshinPropertyType — 原神属性类型枚举
 *
 * 对应米游社 API 中 property_type 字段的所有已知值。
 * 用于武器词条、圣遗物词条、角色属性面板的统一映射，
 * 禁止在业务代码中直接写 property_type 数字字面量。
 *
 * 数据来源：game_record/app/genshin/api/character/detail 接口
 * 验证方式：对照响应体末尾的 property_map 字段（含 name 和 filter_name），
 *           所有数值均已 100% 验证，无推断值。
 */
export enum GenshinPropertyType {
  // ── 基础属性（base_properties，角色面板基础值）────────────────────

  /** 基础生命值（name: "基础生命值"） */
  BASE_HP = 1,

  /** 基础攻击力（name: "基础攻击力"，武器主词条固定值，如 "674"） */
  BASE_ATK = 4,

  /** 基础防御力（name: "基础防御力"） */
  BASE_DEF = 7,

  // ── 最终属性（selected_properties，含基础+加成的最终值）──────────

  /** 生命值上限（name: "生命值上限"，最终值，如 "17927"） */
  HP_FINAL = 2000,

  /** 攻击力（name: "攻击力"，最终值，如 "2443"） */
  ATK_FINAL = 2001,

  /** 防御力（name: "防御力"，最终值，如 "927"） */
  DEF_FINAL = 2002,

  // ── 圣遗物主词条 / 副词条（固定值）──────────────────────────────

  /** 生命值（name: "生命值"，固定值，如 "4780"） */
  HP_FLAT = 2,

  /** 攻击力（name: "攻击力"，固定值，如 "311"） */
  ATK_FLAT = 5,

  /** 防御力（name: "防御力"，固定值，如 "42"） */
  DEF_FLAT = 8,

  // ── 圣遗物主词条 / 武器副词条（百分比）──────────────────────────

  /** 生命值百分比（filter_name: "生命值百分比"，如 "46.9%"） */
  HP_PCT = 3,

  /** 攻击力百分比（filter_name: "攻击力百分比"，如 "22.7%"） */
  ATK_PCT = 6,

  /** 防御力百分比（filter_name: "防御力百分比"，如 "62.9%"） */
  DEF_PCT = 9,

  // ── 暴击 ──────────────────────────────────────────────────────────

  /** 暴击率（name: "暴击率"，如 "62.0%"） */
  CRIT_RATE = 20,

  /** 暴击伤害（name: "暴击伤害"，如 "240.7%"） */
  CRIT_DMG = 22,

  // ── 充能 / 治疗 ───────────────────────────────────────────────────

  /** 元素充能效率（name: "元素充能效率"，如 "100.0%"） */
  ENERGY_RECHARGE = 23,

  /** 治疗加成（name: "治疗加成"） */
  HEALING_BONUS = 26,

  /** 受治疗加成（name: "受治疗加成"） */
  INCOMING_HEALING_BONUS = 27,

  // ── 元素精通 ──────────────────────────────────────────────────────

  /** 元素精通（name: "元素精通"，固定值，如 "239"） */
  ELEMENTAL_MASTERY = 28,

  // ── 元素伤害加成（element_properties）────────────────────────────

  /** 火元素伤害加成（name: "火元素伤害加成"） */
  PYRO_DMG_BONUS = 40,

  /** 雷元素伤害加成（name: "雷元素伤害加成"） */
  ELECTRO_DMG_BONUS = 41,

  /** 水元素伤害加成（name: "水元素伤害加成"） */
  HYDRO_DMG_BONUS = 42,

  /** 草元素伤害加成（name: "草元素伤害加成"） */
  DENDRO_DMG_BONUS = 43,

  /** 风元素伤害加成（name: "风元素伤害加成"） */
  ANEMO_DMG_BONUS = 44,

  /** 岩元素伤害加成（name: "岩元素伤害加成"） */
  GEO_DMG_BONUS = 45,

  /** 冰元素伤害加成（name: "冰元素伤害加成"） */
  CRYO_DMG_BONUS = 46,

  /** 物理伤害加成（name: "物理伤害加成"） */
  PHYSICAL_DMG_BONUS = 30,

  // ── 元素抗性（element_properties）────────────────────────────────

  /** 火元素抗性（name: "火元素抗性"） */
  PYRO_RES = 50,

  /** 雷元素抗性（name: "雷元素抗性"） */
  ELECTRO_RES = 51,

  /** 水元素抗性（name: "水元素抗性"） */
  HYDRO_RES = 52,

  /** 草元素抗性（name: "草元素抗性"） */
  DENDRO_RES = 53,

  /** 风元素抗性（name: "风元素抗性"） */
  ANEMO_RES = 54,

  /** 岩元素抗性（name: "岩元素抗性"） */
  GEO_RES = 55,

  /** 冰元素抗性（name: "冰元素抗性"） */
  CRYO_RES = 56,

  /** 物理抗性（name: "物理抗性"） */
  PHYSICAL_RES = 29,

  // ── 特殊属性（extra_properties）──────────────────────────────────

  /** 冷却缩减（name: "冷却缩减"） */
  COOLDOWN_REDUCTION = 80,

  /** 护盾强效（name: "护盾强效"） */
  SHIELD_STRENGTH = 81,

  // ── 内部特殊值 ────────────────────────────────────────────────────

  /** 体力上限（name: "体力上限"，base_properties 中的特殊字段） */
  STAMINA = 999999,
}
