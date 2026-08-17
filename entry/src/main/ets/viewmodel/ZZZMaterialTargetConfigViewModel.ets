/**
 * ZZZMaterialTargetConfigViewModel.ets — 绝区零养成目标配置 ViewModel
 *
 * 负责绝区零养成目标配置的数据管理和同步逻辑。
 * 绝区零养成计算只能逐个角色请求，不支持批量。
 * 绝区零有 6 个技能等级需要配置。
 *
 * 数据流：
 * 1. 用户设置角色/武器/6个技能的目标等级
 * 2. 点击"开始计算"触发 syncComputeData()
 * 3. 从 DB 读取角色列表，逐个调用计算 API
 * 4. 完成后跳转到 ZZZMaterialList 页面
 */

import {
  CoreInitializer,
  GameId,
  Logger,
  ZZZMaterialTargetConfigJson,
  LevelConfig,
  SkillLevelConfig,
} from 'core'
import {
  LevelConfigVM,
  LevelLabelKeys,
  SkillLevelConfigVM,
} from '../models/MaterialTargetConfigModels'
import { AccountSignal } from '../utils/AccountSignal'

/** 绝区零养成目标配置 ViewModel */
@ObservedV2
export class ZZZMaterialTargetConfigViewModel {
  /** 同步中状态 */
  @Trace isSyncing: boolean = false

  // 绝区零配置
  @Trace avatarLevel: LevelConfigVM = new LevelConfigVM()
  @Trace weaponLevel: LevelConfigVM = new LevelConfigVM()
  @Trace skills: SkillLevelConfigVM[] = []

  /** 账号 UID（米游社 UID） */
  private accountId: string = ''
  /** 角色 UID（游戏角色 UID） */
  private roleUid: string = ''

  /**
   * 初始化等级配置
   * @param accountId 米游社账号 UID
   * @param roleUid 游戏角色 UID
   * 从 DB 加载已保存的配置，不存在时使用默认值。
   */
  async init(accountId: string, roleUid: string): Promise<void> {
    this.accountId = accountId
    this.roleUid = roleUid

    // 先初始化默认值
    this.avatarLevel = this.createLevelConfig(1, 60, 60, LevelLabelKeys.AVATAR_LEVEL)
    this.weaponLevel = this.createLevelConfig(1, 60, 60, LevelLabelKeys.WEAPON_LEVEL)

    // 绝区零 6 个技能
    this.skills = [
      this.createSkillConfig(0, LevelLabelKeys.ZZZ_SKILL_NORMAL),
      this.createSkillConfig(1, LevelLabelKeys.ZZZ_SKILL_DODGE),
      this.createSkillConfig(2, LevelLabelKeys.ZZZ_SKILL_ASSIST),
      this.createSkillConfig(3, LevelLabelKeys.ZZZ_SKILL_SPECIAL),
      this.createSkillConfig(5, LevelLabelKeys.ZZZ_SKILL_CHAIN),
      this.createSkillConfig(6, LevelLabelKeys.ZZZ_SKILL_CORE)
    ]

    // 从 DB 加载已保存的配置
    try {
      const config = await CoreInitializer.materialTargetConfigRepository.getZZZConfig(this.accountId, this.roleUid)
      // 只有当配置有效时才覆盖默认值（target > 1 表示用户曾经保存过有效配置）
      if (config.avatar && config.avatar.target > 1) {
        this.avatarLevel.current = config.avatar.current
        this.avatarLevel.target = config.avatar.target
      }
      if (config.weapon && config.weapon.target > 1) {
        this.weaponLevel.current = config.weapon.current
        this.weaponLevel.target = config.weapon.target
      }
      if (config.skills && config.skills.length > 0) {
        for (let i = 0; i < config.skills.length; i++) {
          const savedSkill = config.skills[i]
          // 只有当 target > 1 才覆盖（表示有效配置）
          if (savedSkill.target > 1) {
            for (let j = 0; j < this.skills.length; j++) {
              if (this.skills[j].skillType === savedSkill.skillType) {
                this.skills[j].current = savedSkill.current
                this.skills[j].target = savedSkill.target
                break
              }
            }
          }
        }
      }
      Logger.info('ZZZMaterialTargetConfigVM', `init: loaded config from DB for account=${this.accountId}, role=${this.roleUid}`)
    } catch (error) {
      const msg = error instanceof Error ? error.message : `${error}`
      Logger.warn('ZZZMaterialTargetConfigVM', `init: failed to load config: ${msg}`)
    }
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
   * 创建技能配置
   */
  private createSkillConfig(skillType: number, labelKey: string): SkillLevelConfigVM {
    const config = new SkillLevelConfigVM()
    config.current = 1
    config.target = 12
    config.max = 12
    config.labelKey = labelKey
    config.skillType = skillType
    return config
  }

  /**
   * 更新当前等级
   */
  updateCurrent(key: string, value: number): void {
    if (key.startsWith('skill')) {
      const skillType = parseInt(key.replace('skill', ''))
      this.updateSkillCurrent(skillType, value)
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
    if (key.startsWith('skill')) {
      const skillType = parseInt(key.replace('skill', ''))
      this.updateSkillTarget(skillType, value)
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
      case 'avatar':
        return this.avatarLevel
      case 'weapon':
        return this.weaponLevel
      default:
        return null
    }
  }

  /**
   * 更新技能当前等级
   */
  private updateSkillCurrent(skillType: number, value: number): void {
    for (let i = 0; i < this.skills.length; i++) {
      if (this.skills[i].skillType === skillType) {
        this.skills[i].setCurrent(value)
        break
      }
    }
  }

  /**
   * 更新技能目标等级
   */
  private updateSkillTarget(skillType: number, value: number): void {
    for (let i = 0; i < this.skills.length; i++) {
      if (this.skills[i].skillType === skillType) {
        this.skills[i].setTarget(value)
        break
      }
    }
  }

  /**
   * 保存配置到 DB
   */
  async saveConfig(): Promise<void> {
    const config = new ZZZMaterialTargetConfigJson()
    config.avatar = new LevelConfig()
    config.avatar.current = this.avatarLevel.current
    config.avatar.target = this.avatarLevel.target
    config.weapon = new LevelConfig()
    config.weapon.current = this.weaponLevel.current
    config.weapon.target = this.weaponLevel.target

    // 技能配置
    config.skills = []
    for (let i = 0; i < this.skills.length; i++) {
      const skillConfig = this.skills[i]
      const skill = new SkillLevelConfig()
      skill.skillType = skillConfig.skillType
      skill.current = skillConfig.current
      skill.target = skillConfig.target
      config.skills[config.skills.length] = skill
    }

    try {
      await CoreInitializer.materialTargetConfigRepository.saveZZZConfig(this.accountId, this.roleUid, config)
      Logger.info('ZZZMaterialTargetConfigVM', `saveConfig: config saved to DB for account=${this.accountId}, role=${this.roleUid}`)
    } catch (error) {
      const msg = error instanceof Error ? error.message : `${error}`
      Logger.error('ZZZMaterialTargetConfigVM', `saveConfig failed: ${msg}`)
    }
  }

  /**
   * 同步绝区零材料计算数据
   * 遍历所有账号的绝区零角色，逐个调用计算 API。
   * 开始前先保存当前配置到 DB。
   */
  async syncComputeData(): Promise<boolean> {
    const TAG = 'ZZZMaterialTargetConfigVM'
    Logger.info(TAG, `syncComputeData called, isSyncing=${this.isSyncing}`)
    
    if (this.isSyncing) {
      Logger.info(TAG, `syncComputeData skipped - already syncing`)
      return false
    }
    
    // 先保存配置
    await this.saveConfig()
    
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
        
        const roles = await CoreInitializer.bbsRepository.getGameRolesByGame(account.uid, GameId.ZZZ)
        Logger.info(TAG, `syncComputeData: found ${roles.length} zzz roles`)

        for (let j = 0; j < roles.length; j++) {
          const role = roles[j]
          Logger.info(TAG, `syncComputeData: syncing role[${j}] roleId=${role.roleId}`)
          
          const success = await this.syncRoleCompute(account.uid, account.cookie, role.roleId, role.server)
          Logger.info(TAG, `syncComputeData: role[${j}] sync result=${success}`)
          
          if (success) {
            syncCount++
          }
        }
      }

      Logger.info(TAG, `syncComputeData: total syncCount=${syncCount}`)
      
      // 同步成功后通知 Tools 页面刷新
      if (syncCount > 0) {
        AccountSignal.instance().notify()
        Logger.info(TAG, `syncComputeData: notified AccountSignal`)
      }
      
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
  private async syncRoleCompute(accountId: string, cookie: string, roleUid: string, server: string): Promise<boolean> {
    const TAG = 'ZZZMaterialTargetConfigVM'
    let avatarList = await CoreInitializer.zzzRepository.getAvatarList(accountId, roleUid)
    Logger.info(TAG, `syncRoleCompute: avatarList.length=${avatarList.length}`)
    
    // 如果 DB 中没有角色列表，先同步角色列表
    if (avatarList.length === 0) {
      Logger.info(TAG, `syncRoleCompute: no avatarList, syncing avatar list first`)
      try {
        await CoreInitializer.zzzRepository.syncAvatarList(accountId, roleUid, server, cookie)
        avatarList = await CoreInitializer.zzzRepository.getAvatarList(accountId, roleUid)
        Logger.info(TAG, `syncRoleCompute: after sync, avatarList.length=${avatarList.length}`)
      } catch (error) {
        const msg = error instanceof Error ? error.message : `${error}`
        Logger.error(TAG, `syncRoleCompute: failed to sync avatar list: ${msg}`)
        return false
      }
      
      if (avatarList.length === 0) {
        Logger.warn(TAG, `syncRoleCompute: still no avatarList after sync`)
        return false
      }
    }

    let successCount = 0

    // 绝区零需要逐个角色同步
    for (let i = 0; i < avatarList.length; i++) {
      const avatar = avatarList[i]
      try {
        // 计算当前突破阶段
        let currentPromotes = 0
        if (avatar.level >= 46) {
          currentPromotes = 3
        } else if (avatar.level >= 31) {
          currentPromotes = 2
        } else if (avatar.level >= 16) {
          currentPromotes = 1
        }

        // 构建技能参数
        const skills: ZZZComputeSkill[] = []
        
        for (let k = 0; k < this.skills.length; k++) {
          const skillConfig = this.skills[k]
          const skill = new ZZZComputeSkill()
          skill.skill_type = skillConfig.skillType
          skill.init_level = skillConfig.current
          skill.level = skillConfig.target
          skills[skills.length] = skill
        }

        Logger.info(TAG, `syncRoleCompute: syncing avatarId=${avatar.avatarId}, level=${avatar.level}`)

        await CoreInitializer.zzzRepository.syncAvatarCompute(
          accountId,
          roleUid,
          avatar.avatarId,
          this.avatarLevel.target,
          avatar.level,
          currentPromotes,
          skills,
          roleUid,
          server,
          cookie
        )
        
        successCount++
        Logger.info(TAG, `syncRoleCompute: avatarId=${avatar.avatarId} sync success`)
      } catch (error) {
        const msg = error instanceof Error ? error.message : `${error}`
        Logger.warn(TAG, `syncRoleCompute: avatarId=${avatar.avatarId} failed: ${msg}`)
      }
    }

    Logger.info(TAG, `syncRoleCompute: total success=${successCount}/${avatarList.length}`)
    return successCount > 0
  }
}

// ─── 绝区零养成计算技能参数 ─────────────────────────────────────────────

class ZZZComputeSkill {
  skill_type: number = 0
  level: number = 12
  init_level: number = 1
}
