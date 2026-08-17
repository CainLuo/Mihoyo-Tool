/**
 * StarRailMaterialTargetConfigViewModel.ets — 星穹铁道养成目标配置 ViewModel
 *
 * 负责星穹铁道养成目标配置的数据管理和同步逻辑。
 * 星铁养成计算只能逐个角色请求，不支持批量。
 *
 * 数据流：
 * 1. 用户设置角色/命途/光锥的目标等级
 * 2. 点击"开始计算"触发 syncComputeData()
 * 3. 从 DB 读取角色列表，逐个调用计算 API
 * 4. 完成后跳转到 StarRailMaterialList 页面
 */

import {
  CoreInitializer,
  Logger,
  GameId,
  StarRailMaterialTargetConfigJson,
  LevelConfig,
} from 'core'
import {
  LevelConfigVM,
  LevelLabelKeys,
} from '../models/MaterialTargetConfigModels'
import { AccountSignal } from '../utils/AccountSignal'

/** 星穹铁道养成目标配置 ViewModel */
@ObservedV2
export class StarRailMaterialTargetConfigViewModel {
  /** 同步中状态 */
  @Trace isSyncing: boolean = false

  // 星铁配置
  @Trace avatarLevel: LevelConfigVM = new LevelConfigVM()
  @Trace skillLevel: LevelConfigVM = new LevelConfigVM()
  @Trace lightConeLevel: LevelConfigVM = new LevelConfigVM()

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
    this.avatarLevel = this.createLevelConfig(1, 80, 80, LevelLabelKeys.AVATAR_LEVEL)
    this.skillLevel = this.createLevelConfig(1, 10, 10, LevelLabelKeys.TRACE_LEVEL)
    this.lightConeLevel = this.createLevelConfig(1, 80, 80, LevelLabelKeys.LIGHT_CONE_LEVEL)

    // 从 DB 加载已保存的配置
    try {
      const config = await CoreInitializer.materialTargetConfigRepository.getStarRailConfig(this.accountId, this.roleUid)
      // 只有当配置有效时才覆盖默认值（target > 1 表示用户曾经保存过有效配置）
      if (config.avatar && config.avatar.target > 1) {
        this.avatarLevel.current = config.avatar.current
        this.avatarLevel.target = config.avatar.target
      }
      if (config.skill && config.skill.target > 1) {
        this.skillLevel.current = config.skill.current
        this.skillLevel.target = config.skill.target
      }
      if (config.lightCone && config.lightCone.target > 1) {
        this.lightConeLevel.current = config.lightCone.current
        this.lightConeLevel.target = config.lightCone.target
      }
      Logger.info('StarRailMaterialTargetConfigVM', `init: loaded config from DB for account=${this.accountId}, role=${this.roleUid}`)
    } catch (error) {
      const msg = error instanceof Error ? error.message : `${error}`
      Logger.warn('StarRailMaterialTargetConfigVM', `init: failed to load config: ${msg}`)
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
   * 更新当前等级
   */
  updateCurrent(key: string, value: number): void {
    const config = this.getConfigByKey(key)
    if (config) {
      config.setCurrent(value)
    }
  }

  /**
   * 更新目标等级
   */
  updateTarget(key: string, value: number): void {
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
      case 'skill':
        return this.skillLevel
      case 'lightCone':
        return this.lightConeLevel
      default:
        return null
    }
  }

  /**
   * 保存配置到 DB
   */
  async saveConfig(): Promise<void> {
    const config = new StarRailMaterialTargetConfigJson()
    config.avatar = new LevelConfig()
    config.avatar.current = this.avatarLevel.current
    config.avatar.target = this.avatarLevel.target
    config.skill = new LevelConfig()
    config.skill.current = this.skillLevel.current
    config.skill.target = this.skillLevel.target
    config.lightCone = new LevelConfig()
    config.lightCone.current = this.lightConeLevel.current
    config.lightCone.target = this.lightConeLevel.target

    try {
      await CoreInitializer.materialTargetConfigRepository.saveStarRailConfig(this.accountId, this.roleUid, config)
      Logger.info('StarRailMaterialTargetConfigVM', `saveConfig: config saved to DB for account=${this.accountId}, role=${this.roleUid}`)
    } catch (error) {
      const msg = error instanceof Error ? error.message : `${error}`
      Logger.error('StarRailMaterialTargetConfigVM', `saveConfig failed: ${msg}`)
    }
  }

  /**
   * 同步星铁材料计算数据
   * 遍历所有账号的星铁角色，逐个调用计算 API。
   * 开始前先保存当前配置到 DB。
   */
  async syncComputeData(): Promise<boolean> {
    const TAG = 'StarRailMaterialTargetConfigVM'
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
        
        const roles = await CoreInitializer.bbsRepository.getGameRolesByGame(account.uid, GameId.STARRAIL)
        Logger.info(TAG, `syncComputeData: found ${roles.length} starrail roles`)

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
    const TAG = 'StarRailMaterialTargetConfigVM'
    let avatarList = await CoreInitializer.starRailRepository.getAvatarList(accountId, roleUid)
    Logger.info(TAG, `syncRoleCompute: avatarList.length=${avatarList.length}`)
    
    // 如果 DB 中没有角色列表，先同步角色列表
    if (avatarList.length === 0) {
      Logger.info(TAG, `syncRoleCompute: no avatarList, syncing avatar list first`)
      try {
        await CoreInitializer.starRailRepository.syncAvatarList(accountId, roleUid, server, cookie)
        avatarList = await CoreInitializer.starRailRepository.getAvatarList(accountId, roleUid)
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

    // 星铁需要逐个角色同步
    for (let i = 0; i < avatarList.length; i++) {
      const avatar = avatarList[i]
      try {
        const avatarParam = new StarRailComputeAvatar()
        avatarParam.id = parseInt(avatar.avatarId, 10)
        avatarParam.level_current = avatar.level
        avatarParam.level_target = this.avatarLevel.target

        // 构建技能参数（星铁角色有 4 个命途技能）
        const avatarIdNum = parseInt(avatar.avatarId, 10)
        const skillList: StarRailComputeSkill[] = []
        
        // 技能 ID 规则：avatarId * 100 + 技能序号（1-4）
        const skill1 = new StarRailComputeSkill()
        skill1.id = avatarIdNum * 100 + 1
        skill1.level_current = this.skillLevel.current
        skill1.level_target = this.skillLevel.target
        skillList[skillList.length] = skill1
        
        const skill2 = new StarRailComputeSkill()
        skill2.id = avatarIdNum * 100 + 2
        skill2.level_current = this.skillLevel.current
        skill2.level_target = this.skillLevel.target
        skillList[skillList.length] = skill2
        
        const skill3 = new StarRailComputeSkill()
        skill3.id = avatarIdNum * 100 + 3
        skill3.level_current = this.skillLevel.current
        skill3.level_target = this.skillLevel.target
        skillList[skillList.length] = skill3
        
        const skill4 = new StarRailComputeSkill()
        skill4.id = avatarIdNum * 100 + 4
        skill4.level_current = this.skillLevel.current
        skill4.level_target = this.skillLevel.target
        skillList[skillList.length] = skill4

        Logger.info(TAG, `syncRoleCompute: syncing avatarId=${avatar.avatarId}`)

        await CoreInitializer.starRailRepository.syncAvatarCompute(
          accountId,
          roleUid,
          avatar.avatarId,
          avatarParam,
          skillList,
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

// ─── 星铁养成计算参数类型 ─────────────────────────────────────────────

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
