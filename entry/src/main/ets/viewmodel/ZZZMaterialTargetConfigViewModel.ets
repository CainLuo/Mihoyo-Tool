/**
 * ZZZMaterialTargetConfigViewModel.ets — 绝区零养成目标配置 ViewModel
 *
 * 负责绝区零养成目标配置的数据管理和计算触发。
 * 6 个技能按 skill_type 分别配置目标等级；计算时技能当前等级优先取代理人详情中的真实等级。
 *
 * 数据流：
 * 1. 材料汇总页带着选中代理人进入本页（MaterialTargetConfigParam）
 * 2. 用户设置代理人 / 音擎 / 6 个技能的目标等级
 * 3. 点击"开始计算"触发 computeSelected()：保存配置 → MaterialComputeService 只计算选中代理人
 * 4. 完成后由页面用新的目标等级重新打开材料汇总页
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
  applySavedLevel,
} from '../models/MaterialTargetConfigModels'
import { AccountSignal } from '../utils/AccountSignal'
import { MaterialTargetConfigParam, ZZZSkillType } from '../models/ToolsModels'
import { MaterialComputeService, MaterialComputeResult } from '../utils/MaterialComputeService'

/** 养成目标配置日志 tag，过滤：hilog | grep 🚀🚀🚀 */
const CONFIG_TAG: string = '🚀🚀🚀 MaterialTargetConfig'

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

    // 绝区零 6 个技能（skill_type 含义见 ZZZSkillType：1 特殊技 / 2 闪避 / 3 连携技 / 5 核心技 / 6 支援技）
    this.skills = [
      this.createSkillConfig(ZZZSkillType.NORMAL_ATTACK, LevelLabelKeys.ZZZ_SKILL_NORMAL),
      this.createSkillConfig(ZZZSkillType.SPECIAL, LevelLabelKeys.ZZZ_SKILL_SPECIAL),
      this.createSkillConfig(ZZZSkillType.DODGE, LevelLabelKeys.ZZZ_SKILL_DODGE),
      this.createSkillConfig(ZZZSkillType.CHAIN, LevelLabelKeys.ZZZ_SKILL_CHAIN),
      this.createSkillConfig(ZZZSkillType.CORE, LevelLabelKeys.ZZZ_SKILL_CORE),
      this.createSkillConfig(ZZZSkillType.ASSIST, LevelLabelKeys.ZZZ_SKILL_ASSIST)
    ]

    // 从 DB 加载已保存的配置：有配置记录就完整恢复（按 1 ~ 上限截断，核心技最高 7 级），没有记录才使用默认值
    try {
      const repo = CoreInitializer.materialTargetConfigRepository
      const row = await repo.getConfig(this.accountId, this.roleUid, GameId.ZZZ)
      if (row !== null) {
        const config = await repo.getZZZConfig(this.accountId, this.roleUid)
        applySavedLevel(this.avatarLevel, config.avatar.current, config.avatar.target)
        applySavedLevel(this.weaponLevel, config.weapon.current, config.weapon.target)
        for (let i = 0; i < config.skills.length; i++) {
          const saved = config.skills[i]
          for (let j = 0; j < this.skills.length; j++) {
            if (this.skills[j].skillType === saved.skillType) {
              applySavedLevel(this.skills[j], saved.current, saved.target)
              break
            }
          }
        }
        Logger.info(CONFIG_TAG, `[ZZZ] init: restored from DB, account=${this.accountId}, role=${this.roleUid}, json=${row.configJson}`)
      } else {
        Logger.info(CONFIG_TAG, `[ZZZ] init: no saved config for account=${this.accountId}, role=${this.roleUid}, use defaults`)
      }
    } catch (error) {
      const msg = error instanceof Error ? error.message : `${error}`
      Logger.warn(CONFIG_TAG, `[ZZZ] init: failed to load config: ${msg}`)
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
    const maxLevel = ZZZSkillType.maxLevel(skillType)
    const config = new SkillLevelConfigVM()
    config.current = 1
    config.target = maxLevel
    config.max = maxLevel
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
   * 保存配置到 DB 后只计算选中的角色。
   * 目标等级不从页面直接传给计算，而是由 MaterialComputeService 从 DB 读取（DB 是唯一来源）。
   * @param selection 选中的账号 / 游戏 UID / 角色
   * @returns 保存失败时返回 FAILED，不进行计算
   */
  async computeSelected(selection: MaterialTargetConfigParam): Promise<MaterialComputeResult> {
    if (this.isSyncing) {
      return MaterialComputeResult.BUSY
    }
    this.isSyncing = true
    try {
      const saved = await this.saveConfig()
      if (!saved) {
        return MaterialComputeResult.FAILED
      }
      Logger.info(CONFIG_TAG, `[ZZZ] computeSelected avatarIds=${selection.avatarIds.join(',')}`)
      const result = await MaterialComputeService.compute(selection)
      if (result === MaterialComputeResult.SUCCESS) {
        AccountSignal.instance().notify()
      }
      return result
    } finally {
      this.isSyncing = false
    }
  }

  /**
   * 保存配置到 DB
   * @returns 是否保存成功
   */
  async saveConfig(): Promise<boolean> {
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
      Logger.info(CONFIG_TAG, `[ZZZ] saveConfig OK, account=${this.accountId}, role=${this.roleUid}, json=${JSON.stringify(config)}`)
      return true
    } catch (error) {
      const msg = error instanceof Error ? error.message : `${error}`
      Logger.error(CONFIG_TAG, `[ZZZ] saveConfig FAILED, account=${this.accountId}, role=${this.roleUid}: ${msg}`)
      return false
    }
  }
}
