/**
 * MaterialListModels.ets — 材料汇总页 UI State 模型
 *
 * 定义材料汇总页所需的数据结构，支持两种视图模式：
 * 1. 按角色分组：CharacterMaterialVM
 * 2. 按材料汇总：MaterialSummaryVM
 */

import { GameId } from 'core';

/**
 * 材料项原始数据接口
 * 用于 parseMaterialItems 方法的参数类型
 * 
 * 注意：字段名使用驼峰命名，与 Parser 返回的字段名一致。
 * 
 * 原神 API 返回 lack_num 字段，星铁/绝区零 API 不返回。
 */
export interface MaterialItemRaw {
  id: number | string;
  name: string;
  iconUrl: string;
  rarity: number | string;
  /** 从当前等级升到目标等级需要的总数量 */
  num: number;
  /** 缺少数量（原神专用，星铁/绝区零不使用此字段） */
  lackNum?: number;
}

/**
 * 单个材料 UI State
 */
export class MaterialItemVM {
  /** 材料ID（API返回的id或material_id） */
  materialId: string = '';
  /** 材料名称 */
  name: ResourceStr = '';
  /** 材料图标URL */
  iconUrl: string = '';
  /** 稀有度 */
  rarity: number = 1;
  /** 拥有数量 */
  have: number = 0;
  /** 需求数量 */
  need: number = 0;
  /** 缺少数量（need - have，负数表示多余） */
  get deficit(): number {
    return Math.max(0, this.need - this.have);
  }
  /** 是否足够 */
  get isEnough(): boolean {
    return this.have >= this.need;
  }
}

/**
 * 武器材料 UI State
 */
export class WeaponMaterialVM {
  /** 武器ID */
  weaponId: string = '';
  /** 武器名称 */
  weaponName: ResourceStr = '';
  /** 武器图标URL */
  weaponIconUrl: string = '';
  /** 武器等级 */
  weaponLevel: number = 1;
  /** 武器稀有度 */
  weaponRarity: number = 1;
  /** 材料列表 */
  materials: MaterialItemVM[] = [];
  /** 当前等级 */
  currentLevel: number = 1;
  /** 目标等级 */
  targetLevel: number = 90;
}

/**
 * 技能项 UI State
 */
export class SkillItemVM {
  /** 技能图标URL */
  iconUrl: string = '';
  /** 技能等级 */
  level: number = 1;
}

/**
 * 角色材料 UI State（按角色视图）
 * 使用 @ObservedV2 使其成为响应式对象，支持 isExpanded 的动态更新。
 */
@ObservedV2
export class CharacterMaterialVM {
  /** 角色ID */
  characterId: string = '';
  /** 角色名称 */
  characterName: ResourceStr = '';
  /** 角色图标URL */
  characterIconUrl: string = '';
  /** 角色等级 */
  characterLevel: number = 1;
  /** 角色稀有度 */
  characterRarity: number = 4;
  /** 元素属性（原神专用） */
  element: string = '';
  /** 游戏标识 */
  gameId: GameId = GameId.GENSHIN;
  /** 技能列表（原神：普攻/E/Q，星铁：战技/终结技/天赋） */
  skills: SkillItemVM[] = [];
  /** 角色突破材料 */
  avatarMaterials: MaterialItemVM[] = [];
  /** 技能材料 */
  skillMaterials: MaterialItemVM[] = [];
  /** 武器材料（原神/绝区零）或光锥材料（星铁） */
  weaponMaterials: MaterialItemVM[] = [];
  /** 武器信息（原神/绝区零） */
  weapon: WeaponMaterialVM | null = null;
  /** 光锥信息（星铁） */
  lightCone: WeaponMaterialVM | null = null;
  /** 是否展开 — 使用 @Trace 标记为响应式字段 */
  @Trace isExpanded: boolean = false;
}

/**
 * 材料汇总 UI State（按材料视图）
 */
export class MaterialSummaryVM {
  /** 材料ID */
  materialId: string = '';
  /** 材料名称 */
  name: ResourceStr = '';
  /** 材料图标URL */
  iconUrl: string = '';
  /** 稀有度 */
  rarity: number = 1;
  /** 总拥有数量（来自多个账号的汇总） */
  totalHave: number = 0;
  /** 总需求数量（所有角色的需求汇总） */
  totalNeed: number = 0;
  /** 缺少数量 */
  get deficit(): number {
    return Math.max(0, this.totalNeed - this.totalHave);
  }
  /** 是否足够 */
  get isEnough(): boolean {
    return this.totalHave >= this.totalNeed;
  }
  /** 需要该材料的角色列表（简化的角色信息） */
  relatedCharacters: RelatedCharacterVM[] = [];
}

/**
 * 材料汇总分组类型
 */
export enum MaterialSectionType {
  /** 经验书和摩拉 */
  CURRENCY = 'currency',
  /** 其他材料 */
  MATERIALS = 'materials',
  /** 全部材料（绝区零使用） */
  ALL = 'all',
}

/**
 * 材料汇总分组 UI State
 */
export class MaterialSectionVM {
  /** 分组类型 */
  type: MaterialSectionType = MaterialSectionType.MATERIALS;
  /** 分组标题 */
  title: ResourceStr = '';
  /** 材料列表 */
  materials: MaterialSummaryVM[] = [];
}

/**
 * 关联角色简化信息
 */
export class RelatedCharacterVM {
  characterId: string = '';
  characterName: ResourceStr = '';
  characterIconUrl: string = '';
  /** 该角色对此材料的需求量 */
  needCount: number = 0;
}

/**
 * 视图模式枚举
 */
export enum MaterialListViewMode {
  /** 按角色分组 */
  CHARACTER = 'character',
  /** 按材料汇总 */
  MATERIAL = 'material',
}
