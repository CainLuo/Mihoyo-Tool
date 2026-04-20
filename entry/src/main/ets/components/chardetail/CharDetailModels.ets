/**
 * CharDetailModels — 角色详情页展示模型
 *
 * 职责：定义角色详情页的纯 UI 数据结构，
 * 由各游戏 CharacterDetailViewModel 解析 rawJson 后填充，传入各 UI 组件。
 */

// ─── 通用路由参数 ─────────────────────────────────────────────────

/** 角色详情页路由参数（三个游戏通用） */
export class CharDetailRouterParam {
  accountId: string = '';
  roleUid: string = '';
  entityId: string = '';
}

// ─── 通用展示模型 ─────────────────────────────────────────────────

/** 命座/影画列表项（三个游戏通用） */
export class CharDetailRankItem {
  /** 位置（1-6） */
  pos: number = 0;
  /** 名称 */
  name: string = '';
  /** 图标 URL */
  iconUrl: string = '';
  /** 是否已激活/解锁 */
  isActived: boolean = false;
  /** 效果描述（原神命座专用，其他游戏为空字符串） */
  effect: string = '';
}

/** 英雄区基础信息（三个游戏通用） */
export class CharDetailHeroInfo {
  /** 角色名 */
  charName: string = '';
  /** 等级 */
  level: number = 0;
}

// ─── 原神专用模型 ─────────────────────────────────────────────────

/** 武器详情（原神） */
export class CharDetailWeapon {
  name: string = '';
  iconUrl: string = '';
  level: number = 0;
  affix: number = 1;
  rarity: number = 3;
  /** 武器基础攻击力（来自 weapon.main_property.final，property_type = BASE_ATK = 4） */
  baseAtk: number = 0;
  /** 武器副词条标签（Resource，由 GenshinPropertyType enum 映射；无副词条时为 null） */
  subLabel: Resource | null = null;
  /** 武器副词条值（如"22.1%"） */
  subVal: string = '';
}

/** 圣遗物副词条（原神） */
export class RelicSubStat {
  label: Resource | null = null;
  value: string = '';
}

/** 圣遗物详情（原神） */
export class CharDetailRelic {
  pos: number = 0;
  iconUrl: string = '';
  setName: string = '';
  level: number = 0;
  rarity: number = 5;
  mainStatLabel: Resource | null = null;
  mainStatValue: string = '';
  subStats: RelicSubStat[] = [];
}

/** 技能详情（原神） */
export class CharDetailSkill {
  iconUrl: string = '';
  level: number = 0;
  name: string = '';
}

/** 属性行（原神） */
export class CharDetailStat {
  labelKey: Resource;
  value: string = '';
  isHighlight: boolean = false;

  constructor(labelKey: Resource, value: string, isHighlight: boolean = false) {
    this.labelKey = labelKey;
    this.value = value;
    this.isHighlight = isHighlight;
  }
}

// ─── 星穹铁道专用模型 ─────────────────────────────────────────────

/** 星铁行迹节点（单个技能点） */
export class StarRailCharDetailSkillNode {
  /** 技能点 ID */
  pointId: string = '';
  /** 技能类型：1=属性加成，2=主技能，3=额外能力 */
  pointType: number = 0;
  /** 图标 URL */
  iconUrl: string = '';
  /** 等级 */
  level: number = 0;
  /** 是否已激活 */
  isActivated: boolean = false;
  /** 技能名称（取 skill_stages[0].name） */
  name: string = '';
  /** 技能描述（取 skill_stages[0].desc） */
  desc: string = '';
  /** 技能类型标签（如"普攻"、"战技"、"终结技"等） */
  remake: string = '';
}

/** 星铁遗器副词条 */
export class StarRailRelicSubStat {
  /** 词条名称 */
  name: string = '';
  /** 词条值 */
  value: string = '';
  /** 强化次数 */
  times: number = 0;
}

/** 星铁遗器/饰品详情 */
export class StarRailCharDetailRelic {
  /** 位置（1-4 遗器，5-6 饰品） */
  pos: number = 0;
  /** 遗器名称 */
  name: string = '';
  /** 图标 URL */
  iconUrl: string = '';
  /** 套装名称 */
  setName: string = '';
  /** 等级 */
  level: number = 0;
  /** 稀有度 */
  rarity: number = 5;
  /** 主词条类型 */
  mainPropertyType: number = 0;
  /** 主词条值 */
  mainPropertyValue: string = '';
  /** 副词条列表 */
  subStats: StarRailRelicSubStat[] = [];
}

/** 星铁光锥详情 */
export class StarRailCharDetailEquip {
  /** 光锥 ID */
  id: number = 0;
  /** 光锥名称 */
  name: string = '';
  /** 图标 URL */
  iconUrl: string = '';
  /** 等级 */
  level: number = 0;
  /** 叠影（精炼）等级 */
  rank: number = 1;
  /** 稀有度 */
  rarity: number = 3;
}

/** 星铁属性行 */
export class StarRailCharDetailProperty {
  /** 属性类型 ID */
  propertyType: number = 0;
  /** 属性名称 */
  name: string = '';
  /** 最终值 */
  final: string = '';
}

// ─── 绝区零专用模型 ─────────────────────────────────────────────

/** 绝区零技能条目（skills[].items[] 中的单个技能） */
export class ZZZSkillItem {
  /** 技能标题 */
  title: string = '';
  /** 技能描述 */
  text: string = '';
}

/** 绝区零技能组（按 skill_type 分组） */
export class ZZZCharDetailSkill {
  /** 技能类型：0=普攻，1=特殊技，2=闪避，3=连携技/终结技，5=核心被动，6=支援技 */
  skillType: number = 0;
  /** 等级 */
  level: number = 0;
  /** 技能条目列表 */
  items: ZZZSkillItem[] = [];
}

/** 绝区零音擎（武器）详情 */
export class ZZZCharDetailWeapon {
  /** 音擎 ID */
  id: number = 0;
  /** 音擎名称 */
  name: string = '';
  /** 图标 URL */
  iconUrl: string = '';
  /** 等级 */
  level: number = 0;
  /** 精炼等级（star） */
  star: number = 1;
  /** 稀有度（"S"/"A"） */
  rarity: string = '';
  /** 天赋名称 */
  talentTitle: string = '';
}

/** 绝区零驱动盘副词条 */
export class ZZZSubStat {
  /** 词条名称 */
  name: string = '';
  /** 词条值 */
  value: string = '';
  /** 是否有效（valid=true 时高亮显示） */
  valid: boolean = false;
}

/** 绝区零驱动盘详情 */
export class ZZZCharDetailEquip {
  /** 位置（1-6） */
  pos: number = 0;
  /** 驱动盘名称 */
  name: string = '';
  /** 图标 URL */
  iconUrl: string = '';
  /** 稀有度（"S"/"A"） */
  rarity: string = '';
  /** 等级 */
  level: number = 0;
  /** 套装 ID */
  suitId: number = 0;
  /** 套装名称 */
  suitName: string = '';
  /** 套装当前件数 */
  suitOwn: number = 0;
  /** 主词条名称 */
  mainStatName: string = '';
  /** 主词条值 */
  mainStatValue: string = '';
  /** 副词条列表 */
  subStats: ZZZSubStat[] = [];
}

/** 绝区零套装摘要（用于驱动盘区块顶部展示） */
export class ZZZSuitSummary {
  /** 套装 ID */
  suitId: number = 0;
  /** 套装名称 */
  suitName: string = '';
  /** 实际件数 */
  count: number = 0;
  /** 套装 own 值（来自 equip_suit.own） */
  suitOwn: number = 0;
  /** 2件效果描述 */
  desc1: string = '';
  /** 4件效果描述 */
  desc2: string = '';
}

/** 绝区零属性行 */
export class ZZZCharDetailProperty {
  /** 属性名称 */
  name: string = '';
  /** 最终值 */
  final: string = '';
}
