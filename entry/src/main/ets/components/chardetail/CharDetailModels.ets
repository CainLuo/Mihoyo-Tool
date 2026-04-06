/**
 * CharDetailModels — 角色详情页展示模型
 *
 * 职责：定义角色详情页的纯 UI 数据结构，
 * 由 GenshinCharacterDetailViewModel 解析 rawJson 后填充，传入各 UI 组件。
 */

/** 武器详情 */
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

/** 圣遗物副词条 */
export class RelicSubStat {
  label: Resource | null = null;
  value: string = '';
}

/** 圣遗物详情 */
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

/** 技能详情 */
export class CharDetailSkill {
  iconUrl: string = '';
  level: number = 0;
}

/** 命座详情 */
export class CharDetailConstellation {
  /** 命座位置（1-6） */
  pos: number = 0;
  /** 命座名称 */
  name: string = '';
  /** 命座图标 URL */
  iconUrl: string = '';
  /** 命座效果描述 */
  effect: string = '';
  /** 是否已激活 */
  isActived: boolean = false;
}

/** 属性行 */
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
