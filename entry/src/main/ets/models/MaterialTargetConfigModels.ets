/**
 * MaterialTargetConfigModels.ets — 养成目标配置页 UI State 模型
 *
 * 定义养成目标配置页所需的数据结构。
 * 
 * 注意：Model 文件放在 entry/models/ 目录，不应该包含 ArkUI 特定类型（ResourceStr、$r 等）。
 * 标签资源 key 存储为字符串，由 View 层转换为 Resource。
 * 
 * 设计决策：
 * - LevelConfigVM 使用 @ObservedV2 + @Trace，确保字段修改时能正确触发 UI 更新
 * - 更新时直接修改 LevelConfigVM 的字段，由响应式系统自动传播到 UI
 */

import {
  GameId,
  CoreInitializer,
  Logger,
} from 'core'

/** 标签资源 key 常量 */
export class LevelLabelKeys {
  static readonly AVATAR_LEVEL: string = 'material_target_config_avatar_level'
  static readonly SKILL_LEVEL: string = 'material_target_config_skill_level'
  static readonly WEAPON_LEVEL: string = 'material_target_config_weapon_level'
  static readonly TRACE_LEVEL: string = 'material_target_config_trace_level'
  static readonly LIGHT_CONE_LEVEL: string = 'material_target_config_light_cone_level'
  static readonly ZZZ_SKILL_NORMAL: string = 'zzz_skill_normal_attack'
  static readonly ZZZ_SKILL_DODGE: string = 'zzz_skill_dodge'
  static readonly ZZZ_SKILL_ASSIST: string = 'zzz_skill_assist'
  static readonly ZZZ_SKILL_SPECIAL: string = 'zzz_skill_special'
  static readonly ZZZ_SKILL_CHAIN: string = 'zzz_skill_chain'
  static readonly ZZZ_SKILL_CORE: string = 'zzz_skill_core'
}

/**
 * 等级配置 UI State
 * 
 * 使用 @ObservedV2 + @Trace 确保响应式更新能正确传播到 UI。
 * 当字段改变时，会触发父级 @Trace 字段的更新。
 */
@ObservedV2
export class LevelConfigVM {
  /** 当前等级 */
  @Trace current: number = 1
  /** 目标等级 */
  @Trace target: number = 1
  /** 最大等级 */
  max: number = 90
  /** 标签资源 key */
  labelKey: string = ''

  /**
   * 更新当前等级（直接修改字段，触发响应式）
   */
  setCurrent(value: number): void {
    this.current = value
    // 如果当前等级 > 目标等级，自动调高目标等级
    if (value > this.target) {
      this.target = value
    }
  }

  /**
   * 更新目标等级（直接修改字段，触发响应式）
   */
  setTarget(value: number): void {
    this.target = value
  }
}

/**
 * 技能等级配置 UI State（绝区零专用，包含 skillType）
 */
@ObservedV2
export class SkillLevelConfigVM extends LevelConfigVM {
  /** 技能类型（绝区零 API 使用的 skill_type） */
  skillType: number = 0
}

// ─── 养成计算参数类型 ─────────────────────────────────────────────

/** 原神养成计算参数 */
export class GenshinComputeItem {
  avatar_id: number = 0
  avatar_level_current: number = 1
  avatar_level_target: number = 90
  skill_list: GenshinComputeSkill[] = []
  weapon: GenshinComputeWeapon | null = null
}

export class GenshinComputeSkill {
  id: number = 0
  level_current: number = 1
  level_target: number = 10
}

export class GenshinComputeWeapon {
  id: number = 0
  level_current: number = 1
  level_target: number = 90
}

/** 绝区零养成计算技能参数 */
export class ZZZComputeSkill {
  skill_type: number = 0
  level: number = 12
  init_level: number = 1
}
