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
 * - MaterialTargetConfigVM 的字段也使用 @Trace，追踪嵌套的 LevelConfigVM 对象
 * - 更新时直接修改 LevelConfigVM 的字段，由响应式系统自动传播到 UI
 */

import { GameId } from 'core'

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
 * 页面参数
 */
export class MaterialTargetConfigParam {
  gameId: GameId = GameId.GENSHIN
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

/**
 * 养成目标配置页 ViewModel
 */
@ObservedV2
export class MaterialTargetConfigVM {
  /** 当前选择的游戏（从外部传入） */
  @Trace selectedGame: GameId = GameId.GENSHIN

  // 原神配置
  @Trace genshinAvatar: LevelConfigVM = new LevelConfigVM()
  @Trace genshinSkill: LevelConfigVM = new LevelConfigVM()
  @Trace genshinWeapon: LevelConfigVM = new LevelConfigVM()

  // 星铁配置
  @Trace starrailAvatar: LevelConfigVM = new LevelConfigVM()
  @Trace starrailSkill: LevelConfigVM = new LevelConfigVM()
  @Trace starrailLightCone: LevelConfigVM = new LevelConfigVM()

  // 绝区零配置
  @Trace zzzAvatar: LevelConfigVM = new LevelConfigVM()
  @Trace zzzWeapon: LevelConfigVM = new LevelConfigVM()
  @Trace zzzSkills: SkillLevelConfigVM[] = []

  /**
   * 初始化
   */
  init(gameId: GameId): void {
    this.selectedGame = gameId
    this.initLevelConfigs()
  }

  /**
   * 初始化等级配置
   */
  private initLevelConfigs(): void {
    // 原神
    this.genshinAvatar = this.createLevelConfig(1, 90, 90, LevelLabelKeys.AVATAR_LEVEL)
    this.genshinSkill = this.createLevelConfig(1, 10, 10, LevelLabelKeys.SKILL_LEVEL)
    this.genshinWeapon = this.createLevelConfig(1, 90, 90, LevelLabelKeys.WEAPON_LEVEL)

    // 星铁
    this.starrailAvatar = this.createLevelConfig(1, 80, 80, LevelLabelKeys.AVATAR_LEVEL)
    this.starrailSkill = this.createLevelConfig(1, 10, 10, LevelLabelKeys.TRACE_LEVEL)
    this.starrailLightCone = this.createLevelConfig(1, 80, 80, LevelLabelKeys.LIGHT_CONE_LEVEL)

    // 绝区零
    this.zzzAvatar = this.createLevelConfig(1, 60, 60, LevelLabelKeys.AVATAR_LEVEL)
    this.zzzWeapon = this.createLevelConfig(1, 60, 60, LevelLabelKeys.WEAPON_LEVEL)

    // 绝区零 6 个技能
    this.zzzSkills = [
      this.createZZZSkill(0, LevelLabelKeys.ZZZ_SKILL_NORMAL),
      this.createZZZSkill(1, LevelLabelKeys.ZZZ_SKILL_DODGE),
      this.createZZZSkill(2, LevelLabelKeys.ZZZ_SKILL_ASSIST),
      this.createZZZSkill(3, LevelLabelKeys.ZZZ_SKILL_SPECIAL),
      this.createZZZSkill(5, LevelLabelKeys.ZZZ_SKILL_CHAIN),
      this.createZZZSkill(6, LevelLabelKeys.ZZZ_SKILL_CORE)
    ]
  }

  /**
   * 创建等级配置
   */
  private createLevelConfig(current: number, target: number, max: number, labelKey: string): LevelConfigVM {
    const config = new LevelConfigVM()
    config.current = current
    config.target = target
    config.max = max
    config.labelKey = labelKey
    return config
  }

  /**
   * 创建绝区零技能配置
   */
  private createZZZSkill(skillType: number, labelKey: string): SkillLevelConfigVM {
    const config = new SkillLevelConfigVM()
    config.current = 1
    config.target = 12
    config.max = 12
    config.labelKey = labelKey
    config.skillType = skillType
    return config
  }

  /**
   * 选择游戏
   */
  selectGame(gameId: GameId): void {
    this.selectedGame = gameId
  }

  /**
   * 更新当前等级
   * 直接修改字段值，由 @Trace 触发响应式更新
   */
  updateCurrent(key: string, value: number): void {
    if (key.startsWith('zzzSkill')) {
      const skillType = parseInt(key.replace('zzzSkill', ''))
      this.updateZZZSkillCurrent(skillType, value)
      return
    }

    const config = this.getConfigByKey(key)
    if (config) {
      config.setCurrent(value)
    }
  }

  /**
   * 更新目标等级
   */
  updateTarget(key: string, value: number): void {
    if (key.startsWith('zzzSkill')) {
      const skillType = parseInt(key.replace('zzzSkill', ''))
      this.updateZZZSkillTarget(skillType, value)
      return
    }

    const config = this.getConfigByKey(key)
    if (config) {
      config.setTarget(value)
    }
  }

  /**
   * 根据 key 获取等级配置
   */
  private getConfigByKey(key: string): LevelConfigVM | null {
    switch (key) {
      case 'genshinAvatar':
        return this.genshinAvatar
      case 'genshinSkill':
        return this.genshinSkill
      case 'genshinWeapon':
        return this.genshinWeapon
      case 'starrailAvatar':
        return this.starrailAvatar
      case 'starrailSkill':
        return this.starrailSkill
      case 'starrailLightCone':
        return this.starrailLightCone
      case 'zzzAvatar':
        return this.zzzAvatar
      case 'zzzWeapon':
        return this.zzzWeapon
      default:
        return null
    }
  }

  /**
   * 更新绝区零技能当前等级
   * 直接修改字段值，由 @Trace 触发响应式更新
   */
  private updateZZZSkillCurrent(skillType: number, value: number): void {
    for (let i = 0; i < this.zzzSkills.length; i++) {
      if (this.zzzSkills[i].skillType === skillType) {
        this.zzzSkills[i].setCurrent(value)
        break
      }
    }
  }

  /**
   * 更新绝区零技能目标等级
   */
  private updateZZZSkillTarget(skillType: number, value: number): void {
    for (let i = 0; i < this.zzzSkills.length; i++) {
      if (this.zzzSkills[i].skillType === skillType) {
        this.zzzSkills[i].setTarget(value)
        break
      }
    }
  }
}
