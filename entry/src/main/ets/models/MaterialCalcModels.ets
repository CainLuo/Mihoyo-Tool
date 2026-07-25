/**
 * MaterialCalcModels.ets — 材料计算页 UI State 模型
 *
 * 定义单个角色材料计算页所需的数据结构：
 * 1. 角色信息 + 等级目标
 * 2. 技能目标设置
 * 3. 材料列表（角色材料 + 武器材料）
 */

import { GameId } from 'core';

/**
 * 材料项原始数据接口
 * 用于 buildSection 方法的参数类型
 */
export interface MaterialItemRaw {
  id: number | string;
  name: string;
  iconUrl: string;
  rarity: number | string;
  num: number;
}

/**
 * 技能类型定义接口
 * 用于 buildXxxSkills 方法
 */
export interface SkillTypeDefinition {
  id: string;
  name: ResourceStr;
}

/**
 * 技能目标 UI State
 */
export class SkillTargetVM {
  /** 技能ID */
  skillId: string = '';
  /** 技能名称（普攻/战技/爆发） */
  skillName: ResourceStr = '';
  /** 当前等级 */
  currentLevel: number = 1;
  /** 目标等级 */
  targetLevel: number = 10;
  /** 最大等级 */
  maxLevel: number = 10;
  /** 技能图标URL（可选） */
  iconUrl: string = '';
  /** 是否完成 */
  get isComplete(): boolean {
    return this.currentLevel >= this.targetLevel;
  }
}

/**
 * 材料计算项 UI State
 */
export class MaterialCalcItemVM {
  /** 材料ID */
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
  /** 缺少数量 */
  get deficit(): number {
    return Math.max(0, this.need - this.have);
  }
  /** 进度百分比 */
  get progress(): number {
    if (this.need === 0) return 100;
    return Math.min(100, Math.round((this.have / this.need) * 100));
  }
  /** 是否足够 */
  get isEnough(): boolean {
    return this.have >= this.need;
  }
}

/**
 * 材料 Section UI State
 */
export class MaterialSectionVM {
  /** Section 标题（角色材料/武器材料） */
  title: ResourceStr = '';
  /** Section 图标 */
  iconUrl: string = '';
  /** 总进度百分比 */
  progressPercent: number = 0;
  /** 缺少数量 */
  deficitCount: number = 0;
  /** 材料列表 */
  items: MaterialCalcItemVM[] = [];
  /** 是否有数据 */
  hasData: boolean = false;
}

/**
 * 角色信息 UI State（材料计算页专用）
 */
export class MaterialCalcCharacterVM {
  /** 角色ID */
  characterId: string = '';
  /** 角色名称 */
  name: ResourceStr = '';
  /** 角色图标URL */
  iconUrl: string = '';
  /** 角色稀有度 */
  rarity: number = 4;
  /** 元素属性（原神专用） */
  element: string = '';
  /** 游戏标识 */
  gameId: GameId = GameId.GENSHIN;
  /** 当前等级 */
  currentLevel: number = 1;
  /** 目标等级 */
  targetLevel: number = 90;
  /** 最高可升级等级 */
  maxLevel: number = 90;
}

/**
 * 武器/光锥信息 UI State（材料计算页专用）
 */
export class MaterialCalcWeaponVM {
  /** 武器/光锥ID */
  weaponId: string = '';
  /** 武器/光锥名称 */
  name: ResourceStr = '';
  /** 武器/光锥图标URL */
  iconUrl: string = '';
  /** 稀有度 */
  rarity: number = 4;
  /** 精炼等级/叠影等级 */
  affix: number = 1;
  /** 当前等级 */
  currentLevel: number = 1;
  /** 目标等级 */
  targetLevel: number = 90;
  /** 最高可升级等级 */
  maxLevel: number = 90;
}

/**
 * 等级选项
 */
export class LevelOptionVM {
  /** 等级值 */
  level: number = 1;
  /** 显示文本 */
  label: ResourceStr = '';
}
