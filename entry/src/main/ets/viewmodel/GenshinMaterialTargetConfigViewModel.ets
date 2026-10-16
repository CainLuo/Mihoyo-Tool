/**
 * GenshinMaterialTargetConfigViewModel.ets — 原神养成目标配置 ViewModel
 *
 * 负责原神养成目标配置的数据管理和计算触发。
 * 天赋按 普通攻击 / 元素战技 / 元素爆发 分别配置目标等级。
 *
 * 数据流：
 * 1. 材料汇总页带着选中角色进入本页（MaterialTargetConfigParam）
 * 2. 用户设置角色 / 各天赋 / 武器的目标等级
 * 3. 点击"开始计算"触发 computeSelected()：保存配置 → MaterialComputeService 只计算选中角色
 * 4. 完成后由页面用新的目标等级重新打开材料汇总页
 */

import {
  CoreInitializer,
  GameId,
  Logger,
  GenshinMaterialTargetConfigJson,
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
import { GenshinTalentSlot, MaterialTargetConfigParam } from '../models/ToolsModels'
import { MaterialComputeService, MaterialComputeResult } from '../utils/MaterialComputeService'

const TAG: string = 'GenshinMaterialTargetConfigVM'

/** 养成目标配置日志 tag，过滤：hilog | grep 🚀🚀🚀 */
const CONFIG_TAG: string = '🚀🚀🚀 MaterialTargetConfig'

/** 原神养成目标配置 ViewModel */
@ObservedV2
export class GenshinMaterialTargetConfigViewModel {
  /** 同步中状态 */
  @Trace isSyncing: boolean = false

  // 原神配置
  @Trace avatarLevel: LevelConfigVM = new LevelConfigVM()
  /** 各天赋配置，skillType = GenshinTalentSlot（0 普通攻击 / 1 元素战技 / 2 元素爆发） */
  @Trace skills: SkillLevelConfigVM[] = []
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
    this.skills = [
      this.createSkillConfig(GenshinTalentSlot.NORMAL_ATTACK, LevelLabelKeys.GENSHIN_SKILL_NORMAL),
      this.createSkillConfig(GenshinTalentSlot.ELEMENTAL_SKILL, LevelLabelKeys.GENSHIN_SKILL_ELEMENTAL),
      this.createSkillConfig(GenshinTalentSlot.ELEMENTAL_BURST, LevelLabelKeys.GENSHIN_SKILL_BURST),
    ]
    this.weaponLevel = this.createLevelConfig(1, 90, 90, LevelLabelKeys.WEAPON_LEVEL)

    // 从 DB 加载已保存的配置：有配置记录就完整恢复（按 1 ~ 上限截断），没有记录才使用默认值
    try {
      const repo = CoreInitializer.materialTargetConfigRepository
      const row = await repo.getConfig(this.accountId, this.roleUid, GameId.GENSHIN)
      if (row !== null) {
        const config = await repo.getGenshinConfig(this.accountId, this.roleUid)
        applySavedLevel(this.avatarLevel, config.avatar.current, config.avatar.target)
        for (let i = 0; i < config.skills.length; i++) {
          const skill = this.findSkill(config.skills[i].skillType)
          if (skill !== null) {
            applySavedLevel(skill, config.skills[i].current, config.skills[i].target)
          }
        }
        applySavedLevel(this.weaponLevel, config.weapon.current, config.weapon.target)
        Logger.info(CONFIG_TAG, `[Genshin] init: restored from DB, account=${this.accountId}, role=${this.roleUid}, json=${row.configJson}`)
      } else {
        Logger.info(CONFIG_TAG, `[Genshin] init: no saved config for account=${this.accountId}, role=${this.roleUid}, use defaults`)
      }
    } catch (error) {
      const msg = error instanceof Error ? error.message : `${error}`
      Logger.warn(CONFIG_TAG, `[Genshin] init: failed to load config: ${msg}`)
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
   * 创建天赋配置（1 → 10 级）
   */
  private createSkillConfig(skillType: number, labelKey: string): SkillLevelConfigVM {
    const config = new SkillLevelConfigVM()
    config.current = 1
    config.target = 10
    config.max = 10
    config.labelKey = labelKey
    config.skillType = skillType
    return config
  }

  /**
   * 更新当前等级（key：'avatar' / 'weapon' / 'skill{skillType}'）
   */
  updateCurrent(key: string, value: number): void {
    const config = this.getConfigByKey(key)
    if (config) {
      config.setCurrent(value)
    }
  }

  /**
   * 更新目标等级（key：'avatar' / 'weapon' / 'skill{skillType}'）
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
    if (key.startsWith('skill')) {
      return this.findSkill(parseInt(key.replace('skill', ''), 10))
    }
    switch (key) {
      case 'avatar':
        return this.avatarLevel
      case 'weapon':
        return this.weaponLevel
      default:
        return null
    }
  }

  private findSkill(skillType: number): SkillLevelConfigVM | null {
    for (let i = 0; i < this.skills.length; i++) {
      if (this.skills[i].skillType === skillType) {
        return this.skills[i]
      }
    }
    return null
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
      Logger.info(CONFIG_TAG, `[Genshin] computeSelected avatarIds=${selection.avatarIds.join(',')}`)
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
    const config = new GenshinMaterialTargetConfigJson()
    config.avatar = new LevelConfig()
    config.avatar.current = this.avatarLevel.current
    config.avatar.target = this.avatarLevel.target
    config.skills = []
    for (let i = 0; i < this.skills.length; i++) {
      const s = new SkillLevelConfig()
      s.skillType = this.skills[i].skillType
      s.current = this.skills[i].current
      s.target = this.skills[i].target
      config.skills[config.skills.length] = s
    }
    config.weapon = new LevelConfig()
    config.weapon.current = this.weaponLevel.current
    config.weapon.target = this.weaponLevel.target

    try {
      await CoreInitializer.materialTargetConfigRepository.saveGenshinConfig(this.accountId, this.roleUid, config)
      Logger.info(CONFIG_TAG, `[Genshin] saveConfig OK, account=${this.accountId}, role=${this.roleUid}, json=${JSON.stringify(config)}`)
      return true
    } catch (error) {
      const msg = error instanceof Error ? error.message : `${error}`
      Logger.error(CONFIG_TAG, `[Genshin] saveConfig FAILED, account=${this.accountId}, role=${this.roleUid}: ${msg}`)
      return false
    }
  }
}
