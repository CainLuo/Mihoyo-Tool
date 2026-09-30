/**
 * GenshinMaterialTargetConfigViewModel.ets — 原神养成目标配置 ViewModel
 *
 * 负责原神养成目标配置的数据管理和同步逻辑。
 * 原神养成计算支持批量请求，可一次请求所有角色的材料数据。
 *
 * 数据流：
 * 1. 用户设置角色/技能/武器的目标等级
 * 2. 点击"开始计算"触发 syncComputeData()
 * 3. 从 DB 读取角色列表，构建批量计算参数
 * 4. 调用 GenshinRepository.syncAvatarCompute() 批量同步
 * 5. 完成后跳转到 GenshinMaterialList 页面
 */

import {
  CoreInitializer,
  Logger,
  GameId,
  GenshinMaterialTargetConfigJson,
  LevelConfig,
} from 'core'
import {
  LevelConfigVM,
  LevelLabelKeys,
} from '../models/MaterialTargetConfigModels'
import { AccountSignal } from '../utils/AccountSignal'

/** 原神养成目标配置 ViewModel */
@ObservedV2
export class GenshinMaterialTargetConfigViewModel {
  /** 同步中状态 */
  @Trace isSyncing: boolean = false

  // 原神配置
  @Trace avatarLevel: LevelConfigVM = new LevelConfigVM()
  @Trace skillLevel: LevelConfigVM = new LevelConfigVM()
  @Trace weaponLevel: LevelConfigVM = new LevelConfigVM()

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
    this.avatarLevel = this.createLevelConfig(1, 90, 90, LevelLabelKeys.AVATAR_LEVEL)
    this.skillLevel = this.createLevelConfig(1, 10, 10, LevelLabelKeys.SKILL_LEVEL)
    this.weaponLevel = this.createLevelConfig(1, 90, 90, LevelLabelKeys.WEAPON_LEVEL)

    // 从 DB 加载已保存的配置
    try {
      const config = await CoreInitializer.materialTargetConfigRepository.getGenshinConfig(this.accountId, this.roleUid)
      // 只有当配置有效时才覆盖默认值（target > 1 表示用户曾经保存过有效配置）
      if (config.avatar && config.avatar.target > 1) {
        this.avatarLevel.current = config.avatar.current
        this.avatarLevel.target = config.avatar.target
      }
      if (config.skill && config.skill.target > 1) {
        this.skillLevel.current = config.skill.current
        this.skillLevel.target = config.skill.target
      }
      if (config.weapon && config.weapon.target > 1) {
        this.weaponLevel.current = config.weapon.current
        this.weaponLevel.target = config.weapon.target
      }
      Logger.info('GenshinMaterialTargetConfigVM', `init: loaded config from DB for account=${this.accountId}, role=${this.roleUid}`)
    } catch (error) {
      const msg = error instanceof Error ? error.message : `${error}`
      Logger.warn('GenshinMaterialTargetConfigVM', `init: failed to load config: ${msg}`)
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
      case 'weapon':
        return this.weaponLevel
      default:
        return null
    }
  }

  /**
   * 保存配置到 DB
   */
  async saveConfig(): Promise<void> {
    const config = new GenshinMaterialTargetConfigJson()
    config.avatar = new LevelConfig()
    config.avatar.current = this.avatarLevel.current
    config.avatar.target = this.avatarLevel.target
    config.skill = new LevelConfig()
    config.skill.current = this.skillLevel.current
    config.skill.target = this.skillLevel.target
    config.weapon = new LevelConfig()
    config.weapon.current = this.weaponLevel.current
    config.weapon.target = this.weaponLevel.target

    try {
      await CoreInitializer.materialTargetConfigRepository.saveGenshinConfig(this.accountId, this.roleUid, config)
      Logger.info('GenshinMaterialTargetConfigVM', `saveConfig: config saved to DB for account=${this.accountId}, role=${this.roleUid}`)
    } catch (error) {
      const msg = error instanceof Error ? error.message : `${error}`
      Logger.error('GenshinMaterialTargetConfigVM', `saveConfig failed: ${msg}`)
    }
  }

  /**
   * 同步原神材料计算数据
   * 遍历所有账号的原神角色，批量调用计算 API。
   * 开始前先保存当前配置到 DB。
   */
  async syncComputeData(): Promise<boolean> {
    const TAG = 'GenshinMaterialTargetConfigVM'
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
        
        const roles = await CoreInitializer.bbsRepository.getGameRolesByGame(account.uid, GameId.GENSHIN)
        Logger.info(TAG, `syncComputeData: found ${roles.length} genshin roles`)

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
   * 构建默认技能列表（当角色详情缺失时使用）
   */
  private buildDefaultSkills(): GenshinComputeSkill[] {
    const list: GenshinComputeSkill[] = []
    const defaultIds = [1001, 1002, 1003]
    for (let i = 0; i < defaultIds.length; i++) {
      const skill = new GenshinComputeSkill()
      skill.id = defaultIds[i]
      skill.level_current = 1
      skill.level_target = this.skillLevel.target
      list[list.length] = skill
    }
    return list
  }

  /**
   * 同步单个角色的材料计算数据
   * 技能参数从角色详情获取真实的技能 ID 和当前等级。
   */
  private async syncRoleCompute(accountId: string, cookie: string, roleUid: string, server: string): Promise<boolean> {
    const TAG = 'GenshinMaterialTargetConfigVM'
    Logger.info(TAG, `syncRoleCompute: start, accountId=${accountId}, roleUid=${roleUid}, server=${server}`)
    
    let avatarList = await CoreInitializer.genshinRepository.getAvatarList(accountId, roleUid)
    Logger.info(TAG, `syncRoleCompute: avatarList.length=${avatarList.length}`)
    
    // 如果 DB 中没有角色列表，先同步角色列表
    if (avatarList.length === 0) {
      Logger.info(TAG, `syncRoleCompute: no avatarList, syncing avatar list first`)
      try {
        await CoreInitializer.genshinRepository.syncAvatarList(accountId, roleUid, server, cookie)
        avatarList = await CoreInitializer.genshinRepository.getAvatarList(accountId, roleUid)
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

    // 构建计算参数
    const items: GenshinComputeItem[] = []
    for (let i = 0; i < avatarList.length; i++) {
      const avatar = avatarList[i]
      const item = new GenshinComputeItem()
      item.avatar_id = parseInt(avatar.avatarId, 10)
      item.avatar_level_current = avatar.level
      item.avatar_level_target = this.avatarLevel.target

      // 获取角色详情中的技能数据
      const detail = await CoreInitializer.genshinRepository.getAvatarDetail(accountId, roleUid, avatar.avatarId)
      
      // ── DEBUG LOG: 角色详情技能数据 ─────────────────────────────────
      Logger.info(TAG, `syncRoleCompute: avatarId=${avatar.avatarId}, skillLevels=${detail?.skillLevels ?? 'null'}`)

      // 技能参数：从角色详情的 rawJson 中解析真实的技能 ID 和当前等级
      if (detail !== null && detail.rawJson.length > 0) {
        try {
          const detailData = JSON.parse(detail.rawJson) as Record<string, Object>
          const skills = detailData['skills'] as Record<string, Object>[] | null
          
          if (skills !== null && skills !== undefined && skills.length > 0) {
            Logger.info(TAG, `syncRoleCompute: found ${skills.length} skills in rawJson`)
            
            for (let k = 0; k < skills.length; k++) {
              const skillTypeRaw = skills[k]['skill_type']
              const skillType = typeof skillTypeRaw === 'number' ? skillTypeRaw : parseInt(`${skillTypeRaw ?? 0}`, 10)
              
              // skill_type=1 是可升级技能(普攻、E、Q)，skill_type=2 是固有天赋/被动
              if (skillType === 1 || skillType === 0) {
                const skill = new GenshinComputeSkill()
                const skillId = skills[k]['skill_id']
                skill.id = typeof skillId === 'number' ? skillId : parseInt(`${skillId ?? 0}`, 10)
                skill.level_current = Number(skills[k]['level'] ?? 1)
                skill.level_target = this.skillLevel.target
                item.skill_list[item.skill_list.length] = skill
              }
            }
            
            Logger.info(TAG, `syncRoleCompute: added ${item.skill_list.length} upgradable skills`)
          } else {
            Logger.warn(TAG, `syncRoleCompute: no skills in rawJson, using defaults`)
            item.skill_list = this.buildDefaultSkills()
          }
        } catch (e) {
          Logger.warn(TAG, `syncRoleCompute: failed to parse rawJson for avatarId=${avatar.avatarId}: ${e}`)
          // fallback: 使用默认技能
          item.skill_list = this.buildDefaultSkills()
        }
      } else {
        // 无角色详情时，使用默认技能
        item.skill_list = this.buildDefaultSkills()
      }

      // 武器参数
      if (avatar.weaponId.length > 0) {
        const weapon = new GenshinComputeWeapon()
        weapon.id = parseInt(avatar.weaponId, 10)
        weapon.level_current = avatar.weaponLevel
        weapon.level_target = this.weaponLevel.target
        item.weapon = weapon
      }

      items[items.length] = item
    }

    Logger.info(TAG, `syncRoleCompute: built ${items.length} compute items`)
    
    // ── DEBUG LOG: 打印前 3 个 item 的完整参数（使用 toJSON 过滤 null 字段）─────────────────
    for (let i = 0; i < Math.min(3, items.length); i++) {
      const it = items[i]
      Logger.info(TAG, `syncRoleCompute: item[${i}] = ${JSON.stringify(it.toJSON())}`)
    }

    try {
      // 将 items 转换为 JSON 格式（weapon 为 null 时不添加该字段）
      const jsonItems: object[] = []
      for (let i = 0; i < items.length; i++) {
        jsonItems[jsonItems.length] = items[i].toJSON()
      }
      await CoreInitializer.genshinRepository.syncAvatarCompute(accountId, roleUid, jsonItems, roleUid, server, cookie)
      Logger.info(TAG, `syncRoleCompute: syncAvatarCompute completed`)
      
      const computeRows = await CoreInitializer.genshinRepository.getAllComputeData(accountId, roleUid)
      Logger.info(TAG, `syncRoleCompute: after sync, computeRows.length=${computeRows.length}`)
      
      return computeRows.length > 0
    } catch (error) {
      const msg = error instanceof Error ? error.message : `${error}`
      Logger.error(TAG, `syncRoleCompute failed: ${msg}`)
      return false
    }
  }
}

// ─── 原神养成计算参数类型 ─────────────────────────────────────────────

class GenshinComputeItem {
  avatar_id: number = 0
  avatar_level_current: number = 1
  avatar_level_target: number = 90
  skill_list: GenshinComputeSkill[] = []
  weapon: GenshinComputeWeapon | null = null

  /** 序列化为 API 请求格式，weapon 为 null 时不添加该字段 */
  toJSON(): GenshinComputeItemJSONObject {
    // 使用普通对象而不是 GenshinComputeItemJSON 实例
    // 因为类实例的字段默认值会被 JSON.stringify 序列化
    const obj: GenshinComputeItemJSONObject = {
      avatar_id: this.avatar_id,
      avatar_level_current: this.avatar_level_current,
      avatar_level_target: this.avatar_level_target,
      skill_list: this.skill_list,
    }
    // 只有 weapon 不为 null 时才添加该字段
    if (this.weapon !== null) {
      obj.weapon = this.weapon
    }
    return obj
  }
}

/** GenshinComputeItem 序列化后的 JSON 对象类型（weapon 字段可选） */
interface GenshinComputeItemJSONObject {
  avatar_id: number;
  avatar_level_current: number;
  avatar_level_target: number;
  skill_list: GenshinComputeSkill[];
  weapon?: GenshinComputeWeapon;  // 可选字段，不添加时不存在
}

/** GenshinComputeItem 序列化后的 JSON 类型（类定义，已废弃，改用 interface） */
class GenshinComputeItemJSON {
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
