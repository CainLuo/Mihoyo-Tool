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
  /** 同步中状态 */
  @Trace isSyncing: boolean = false

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

  // ─── 同步方法 ─────────────────────────────────────────────────────

  /**
   * 同步材料计算数据
   * 遍历所有账号的角色，调用 Repository 的同步方法。
   */
  async syncComputeData(gameId: GameId): Promise<boolean> {
    const TAG = 'MaterialTargetConfigVM'
    Logger.info(TAG, `syncComputeData called, gameId=${gameId}, isSyncing=${this.isSyncing}`)
    
    if (this.isSyncing) {
      Logger.info(TAG, `syncComputeData skipped - already syncing`)
      return false
    }
    
    this.isSyncing = true
    Logger.info(TAG, `syncComputeData started`)

    try {
      const accounts = await CoreInitializer.bbsRepository.getAllAccounts()
      Logger.info(TAG, `syncComputeData: found ${accounts.length} accounts`)
      
      if (accounts.length === 0) {
        Logger.warn(TAG, `syncComputeData: no accounts found`)
        return false
      }

      let syncCount = 0

      for (let i = 0; i < accounts.length; i++) {
        const account = accounts[i]
        Logger.info(TAG, `syncComputeData: processing account[${i}] uid=${account.uid}`)
        
        const roles = await CoreInitializer.bbsRepository.getGameRolesByGame(account.uid, gameId)
        Logger.info(TAG, `syncComputeData: found ${roles.length} roles for gameId=${gameId}`)

        for (let j = 0; j < roles.length; j++) {
          const role = roles[j]
          Logger.info(TAG, `syncComputeData: syncing role[${j}] roleId=${role.roleId}`)
          
          const success = await this.syncRoleCompute(gameId, account.uid, account.cookie, role.roleId, role.server)
          Logger.info(TAG, `syncComputeData: role[${j}] sync result=${success}`)
          
          if (success) {
            syncCount++
          }
        }
      }

      Logger.info(TAG, `syncComputeData: total syncCount=${syncCount}`)
      return syncCount > 0
    } catch (error) {
      const msg = error instanceof Error ? error.message : `${error}`
      Logger.error(TAG, `syncComputeData failed: ${msg}`)
      return false
    } finally {
      this.isSyncing = false
      Logger.info(TAG, `syncComputeData finished`)
    }
  }

  /**
   * 同步单个角色的材料计算数据
   */
  private async syncRoleCompute(gameId: GameId, accountId: string, cookie: string, roleUid: string, server: string): Promise<boolean> {
    const TAG = 'MaterialTargetConfigVM'
    try {
      if (gameId === GameId.GENSHIN) {
        return await this.syncGenshinRoleCompute(accountId, cookie, roleUid, server)
      } else if (gameId === GameId.STARRAIL) {
        return await this.syncStarRailRoleCompute(accountId, cookie, roleUid, server)
      } else if (gameId === GameId.ZZZ) {
        return await this.syncZZZRoleCompute(accountId, cookie, roleUid, server)
      }
    } catch (error) {
      const msg = error instanceof Error ? error.message : `${error}`
      Logger.warn(TAG, `syncRoleCompute failed for ${roleUid}: ${msg}`)
    }
    return false
  }

  /**
   * 同步原神角色的材料计算数据
   */
  private async syncGenshinRoleCompute(accountId: string, cookie: string, roleUid: string, server: string): Promise<boolean> {
    const TAG = 'MaterialTargetConfigVM'
    Logger.info(TAG, `syncGenshinRoleCompute: start, accountId=${accountId}, roleUid=${roleUid}, server=${server}`)
    
    const avatarList = await CoreInitializer.genshinRepository.getAvatarList(accountId, roleUid)
    Logger.info(TAG, `syncGenshinRoleCompute: avatarList.length=${avatarList.length}`)
    
    if (avatarList.length === 0) {
      Logger.warn(TAG, `syncGenshinRoleCompute: no avatarList`)
      return false
    }

    // 构建计算参数
    const items: GenshinComputeItem[] = []
    for (let i = 0; i < avatarList.length; i++) {
      const avatar = avatarList[i]
      const item = new GenshinComputeItem()
      item.avatar_id = parseInt(avatar.avatarId, 10)
      item.avatar_level_current = avatar.level
      item.avatar_level_target = this.genshinAvatar.target

      // 技能参数
      const skill1 = new GenshinComputeSkill()
      skill1.id = 1001
      skill1.level_current = this.genshinSkill.current
      skill1.level_target = this.genshinSkill.target
      const skill2 = new GenshinComputeSkill()
      skill2.id = 1002
      skill2.level_current = this.genshinSkill.current
      skill2.level_target = this.genshinSkill.target
      const skill3 = new GenshinComputeSkill()
      skill3.id = 1003
      skill3.level_current = this.genshinSkill.current
      skill3.level_target = this.genshinSkill.target
      item.skill_list = [skill1, skill2, skill3]

      // 武器参数
      if (avatar.weaponId.length > 0) {
        const weapon = new GenshinComputeWeapon()
        weapon.id = parseInt(avatar.weaponId, 10)
        weapon.level_current = avatar.weaponLevel
        weapon.level_target = this.genshinWeapon.target
        item.weapon = weapon
      }

      items[items.length] = item
    }

    Logger.info(TAG, `syncGenshinRoleCompute: built ${items.length} compute items`)

    try {
      await CoreInitializer.genshinRepository.syncAvatarCompute(accountId, roleUid, items, roleUid, server, cookie)
      Logger.info(TAG, `syncGenshinRoleCompute: syncAvatarCompute completed`)
      
      const computeRows = await CoreInitializer.genshinRepository.getAllComputeData(accountId, roleUid)
      Logger.info(TAG, `syncGenshinRoleCompute: after sync, computeRows.length=${computeRows.length}`)
      
      return computeRows.length > 0
    } catch (error) {
      const msg = error instanceof Error ? error.message : `${error}`
      Logger.error(TAG, `syncGenshinRoleCompute failed: ${msg}`)
      return false
    }
  }

  /**
   * 同步星铁角色的材料计算数据
   */
  private async syncStarRailRoleCompute(accountId: string, cookie: string, roleUid: string, server: string): Promise<boolean> {
    const TAG = 'MaterialTargetConfigVM'
    const avatarList = await CoreInitializer.starRailRepository.getAvatarList(accountId, roleUid)
    Logger.info(TAG, `syncStarRailRoleCompute: avatarList.length=${avatarList.length}`)
    
    if (avatarList.length === 0) {
      Logger.warn(TAG, `syncStarRailRoleCompute: no avatarList`)
      return false
    }

    let successCount = 0

    for (let i = 0; i < avatarList.length; i++) {
      const avatar = avatarList[i]
      try {
        const avatarParam = new StarRailComputeAvatar()
        avatarParam.id = parseInt(avatar.avatarId, 10)
        avatarParam.level_current = avatar.level
        avatarParam.level_target = this.starrailAvatar.target

        const avatarIdNum = parseInt(avatar.avatarId, 10)
        const skillList: StarRailComputeSkill[] = []
        
        const skill1 = new StarRailComputeSkill()
        skill1.id = avatarIdNum * 100 + 1
        skill1.level_current = this.starrailSkill.current
        skill1.level_target = this.starrailSkill.target
        skillList[skillList.length] = skill1
        
        const skill2 = new StarRailComputeSkill()
        skill2.id = avatarIdNum * 100 + 2
        skill2.level_current = this.starrailSkill.current
        skill2.level_target = this.starrailSkill.target
        skillList[skillList.length] = skill2
        
        const skill3 = new StarRailComputeSkill()
        skill3.id = avatarIdNum * 100 + 3
        skill3.level_current = this.starrailSkill.current
        skill3.level_target = this.starrailSkill.target
        skillList[skillList.length] = skill3
        
        const skill4 = new StarRailComputeSkill()
        skill4.id = avatarIdNum * 100 + 4
        skill4.level_current = this.starrailSkill.current
        skill4.level_target = this.starrailSkill.target
        skillList[skillList.length] = skill4

        Logger.info(TAG, `syncStarRailRoleCompute: syncing avatarId=${avatar.avatarId}`)

        await CoreInitializer.starRailRepository.syncAvatarCompute(
          accountId,
          roleUid,
          avatarParam,
          skillList,
          roleUid,
          server,
          cookie
        )
        
        successCount++
        Logger.info(TAG, `syncStarRailRoleCompute: avatarId=${avatar.avatarId} sync success`)
      } catch (error) {
        const msg = error instanceof Error ? error.message : `${error}`
        Logger.warn(TAG, `syncStarRailRoleCompute: avatarId=${avatar.avatarId} failed: ${msg}`)
      }
    }

    Logger.info(TAG, `syncStarRailRoleCompute: total success=${successCount}/${avatarList.length}`)
    return successCount > 0
  }

  /**
   * 同步绝区零角色的材料计算数据
   */
  private async syncZZZRoleCompute(accountId: string, cookie: string, roleUid: string, server: string): Promise<boolean> {
    const TAG = 'MaterialTargetConfigVM'
    const avatarList = await CoreInitializer.zzzRepository.getAvatarList(accountId, roleUid)
    Logger.info(TAG, `syncZZZRoleCompute: avatarList.length=${avatarList.length}`)
    
    if (avatarList.length === 0) {
      Logger.warn(TAG, `syncZZZRoleCompute: no avatarList`)
      return false
    }

    let successCount = 0

    for (let i = 0; i < avatarList.length; i++) {
      const avatar = avatarList[i]
      try {
        let currentPromotes = 0
        if (avatar.level >= 46) {
          currentPromotes = 3
        } else if (avatar.level >= 31) {
          currentPromotes = 2
        } else if (avatar.level >= 16) {
          currentPromotes = 1
        }

        const skills: ZZZComputeSkill[] = []
        
        for (let k = 0; k < this.zzzSkills.length; k++) {
          const skillConfig = this.zzzSkills[k]
          const skill = new ZZZComputeSkill()
          skill.skill_type = skillConfig.skillType
          skill.init_level = skillConfig.current
          skill.level = skillConfig.target
          skills[skills.length] = skill
        }

        Logger.info(TAG, `syncZZZRoleCompute: syncing avatarId=${avatar.avatarId}`)

        await CoreInitializer.zzzRepository.syncAvatarCompute(
          accountId,
          roleUid,
          avatar.avatarId,
          this.zzzAvatar.target,
          avatar.level,
          currentPromotes,
          skills,
          roleUid,
          server,
          cookie
        )
        
        successCount++
        Logger.info(TAG, `syncZZZRoleCompute: avatarId=${avatar.avatarId} sync success`)
      } catch (error) {
        const msg = error instanceof Error ? error.message : `${error}`
        Logger.warn(TAG, `syncZZZRoleCompute: avatarId=${avatar.avatarId} failed: ${msg}`)
      }
    }

    Logger.info(TAG, `syncZZZRoleCompute: total success=${successCount}/${avatarList.length}`)
    return successCount > 0
  }
}

// ─── 养成计算参数类型 ─────────────────────────────────────────────

/** 原神养成计算参数 */
class GenshinComputeItem {
  avatar_id: number = 0
  avatar_level_current: number = 1
  avatar_level_target: number = 90
  skill_list: GenshinComputeSkill[] = []
  weapon: GenshinComputeWeapon | null = null
}

class GenshinComputeSkill {
  id: number = 0
  level_current: number = 1
  level_target: number = 10
}

class GenshinComputeWeapon {
  id: number = 0
  level_current: number = 1
  level_target: number = 90
}

/** 星铁养成计算参数 */
class StarRailComputeAvatar {
  id: number = 0
  level_current: number = 1
  level_target: number = 80
}

class StarRailComputeSkill {
  id: number = 0
  level_current: number = 1
  level_target: number = 10
}

/** 绝区零养成计算技能参数 */
class ZZZComputeSkill {
  skill_type: number = 0
  level: number = 12
  init_level: number = 1
}
