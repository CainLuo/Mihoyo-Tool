/**
 * MaterialComputeService.ets — 选中角色的养成材料计算（facade）
 *
 * 角色选择页、材料汇总页（刷新）、养成目标配置页共用。
 * 只计算 MaterialTargetConfigParam.avatarIds 中的角色，计算结果按角色 upsert 到 DB；
 * 其他角色以前的计算结果保留（角色选择页的"历史记录"会列出全部）。
 * 材料汇总页只展示路由参数中的角色，所以不需要清空其他角色的数据。
 *
 * 各游戏的请求组装与结果判定在 GenshinMaterialCompute / StarRailMaterialCompute /
 * ZZZMaterialCompute 中实现，本类只负责读取配置、查找账号 / 角色与按 gameId 分派。
 */

import {
  CoreInitializer,
  AccountRow,
  GameRoleRow,
  GameId,
  Logger,
} from 'core';
import { MaterialComputeTargets, MaterialTargetConfigParam, StarRailSkillSlot, ZZZSkillType } from '../ToolsModels';
import { MaterialComputeResult } from '../MaterialComputeResult';
import { GENSHIN_TAG, MaterialComputeUtils } from './MaterialComputeUtils';
import { GenshinMaterialCompute } from './GenshinMaterialCompute';
import { StarRailMaterialCompute } from './StarRailMaterialCompute';
import { ZZZMaterialCompute } from './ZZZMaterialCompute';

export { MaterialComputeResult } from '../MaterialComputeResult';

export class MaterialComputeService {
  /** 该游戏 UID 是否已在 DB 中保存过养成目标配置 */
  static async hasSavedConfig(gameId: GameId, accountId: string, roleUid: string): Promise<boolean> {
    const row = await CoreInitializer.materialTargetConfigRepository.getConfig(accountId, roleUid, gameId);
    return row !== null;
  }

  /**
   * 从 DB 读取该游戏 UID 的养成目标配置（material_target_config），转换为计算目标。
   * DB 是目标等级的唯一来源：每次计算都调用本方法，不使用路由参数或内存中的值。
   * 保存的目标按 1 ~ 上限截断；技能结构（槽位 / skill_type）以默认值为模板补齐。
   * @returns 没有配置记录时返回 null（由调用方提示用户先去配置）
   */
  static async loadSavedTargets(gameId: GameId, accountId: string, roleUid: string): Promise<MaterialComputeTargets | null> {
    const t = MaterialComputeTargets.createDefault(gameId);
    const repo = CoreInitializer.materialTargetConfigRepository;
    const row = await repo.getConfig(accountId, roleUid, gameId);
    if (row === null) {
      Logger.warn(GENSHIN_TAG, `[Service] loadSavedTargets gameId=${gameId}, account=${accountId}, role=${roleUid}: no saved config`);
      return null;
    }
    if (gameId === GameId.GENSHIN) {
      const config = await repo.getGenshinConfig(accountId, roleUid);
      t.avatarLevel = MaterialComputeUtils.clampLevel(config.avatar.target, 90);
      for (let i = 0; i < config.skills.length; i++) {
        const s = config.skills[i];
        // skillType = 天赋槽位 0 / 1 / 2
        if (s.skillType >= 0 && s.skillType < t.skillLevels.length) {
          t.skillLevels[s.skillType] = MaterialComputeUtils.clampLevel(s.target, 10);
        }
      }
      t.weaponLevel = MaterialComputeUtils.clampLevel(config.weapon.target, 90);
    } else if (gameId === GameId.STARRAIL) {
      const config = await repo.getStarRailConfig(accountId, roleUid);
      t.avatarLevel = MaterialComputeUtils.clampLevel(config.avatar.target, 80);
      for (let i = 0; i < config.skills.length; i++) {
        const s = config.skills[i];
        // skillType = 行迹 point_id 末三位 1 / 2 / 3 / 4，对应 skillLevels 下标 0 / 1 / 2 / 3
        const slot = s.skillType - 1;
        if (slot >= 0 && slot < t.skillLevels.length) {
          t.skillLevels[slot] = MaterialComputeUtils.clampLevel(s.target, StarRailSkillSlot.MAX_LEVELS[slot]);
        }
      }
      t.weaponLevel = MaterialComputeUtils.clampLevel(config.lightCone.target, 80);
    } else if (gameId === GameId.ZZZ) {
      const config = await repo.getZZZConfig(accountId, roleUid);
      t.avatarLevel = MaterialComputeUtils.clampLevel(config.avatar.target, 60);
      t.weaponLevel = MaterialComputeUtils.clampLevel(config.weapon.target, 60);
      for (let i = 0; i < config.skills.length; i++) {
        const saved = config.skills[i];
        for (let j = 0; j < t.zzzSkills.length; j++) {
          if (t.zzzSkills[j].skillType === saved.skillType) {
            const maxLevel = ZZZSkillType.getMaxLevel(saved.skillType);
            t.zzzSkills[j].current = MaterialComputeUtils.clampLevel(saved.current, maxLevel);
            t.zzzSkills[j].target = MaterialComputeUtils.clampLevel(saved.target, maxLevel);
            break;
          }
        }
      }
    }
    Logger.info(GENSHIN_TAG, `[Service] loadSavedTargets gameId=${gameId}, account=${accountId}, role=${roleUid}: saved=${row.configJson} → ${JSON.stringify(t)}`);
    return t;
  }

  /**
   * 计算选中角色的养成材料。目标等级每次都从 DB 读取。
   * @param param 选中的账号 / 游戏 UID / 角色 ID
   * @returns DB 没有养成目标配置时返回 NO_CONFIG
   */
  static async compute(param: MaterialTargetConfigParam): Promise<MaterialComputeResult> {
    // 调用方只处理返回值、不 catch：任何未预期的异常（如读 DB 失败）都转为 FAILED，让页面能提示"计算失败"
    try {
      return await MaterialComputeService.computeInternal(param);
    } catch (error) {
      Logger.error(GENSHIN_TAG, `[Service] gameId=${param.gameId} compute failed: ${MaterialComputeUtils.getErrorMessage(error)}`);
      return MaterialComputeResult.FAILED;
    }
  }

  private static async computeInternal(param: MaterialTargetConfigParam): Promise<MaterialComputeResult> {
    let loaded: MaterialComputeTargets | null;
    try {
      loaded = await MaterialComputeService.loadSavedTargets(param.gameId, param.accountId, param.roleUid);
    } catch (error) {
      Logger.error(GENSHIN_TAG, `[Service] gameId=${param.gameId} read target config failed: ${MaterialComputeUtils.getErrorMessage(error)}`);
      return MaterialComputeResult.FAILED;
    }
    if (loaded === null) {
      return MaterialComputeResult.NO_CONFIG;
    }
    const t: MaterialComputeTargets = loaded;
    if (param.avatarIds.length === 0) {
      Logger.error(GENSHIN_TAG, `[Service] gameId=${param.gameId} no avatarIds`);
      return MaterialComputeResult.FAILED;
    }

    const account = await MaterialComputeService.findAccount(param.accountId);
    const role = account !== null
      ? await MaterialComputeService.findRole(account.uid, param.gameId, param.roleUid)
      : null;
    if (account === null || role === null) {
      Logger.error(GENSHIN_TAG, `[Service] account=${param.accountId} or role=${param.roleUid} not found`);
      return MaterialComputeResult.FAILED;
    }

    if (param.gameId === GameId.GENSHIN) {
      return GenshinMaterialCompute.compute(account, role, param.avatarIds, t);
    } else if (param.gameId === GameId.STARRAIL) {
      return StarRailMaterialCompute.compute(account, role, param.avatarIds, t);
    } else if (param.gameId === GameId.ZZZ) {
      return ZZZMaterialCompute.compute(account, role, param.avatarIds, t);
    }
    return MaterialComputeResult.FAILED;
  }

  private static async findAccount(accountId: string): Promise<AccountRow | null> {
    const accounts = await CoreInitializer.bbsRepository.getAllAccounts();
    for (let i = 0; i < accounts.length; i++) {
      if (accounts[i].uid === accountId) {
        return accounts[i];
      }
    }
    return null;
  }

  private static async findRole(accountId: string, gameId: GameId, roleUid: string): Promise<GameRoleRow | null> {
    const roles = await CoreInitializer.bbsRepository.getGameRolesByGame(accountId, gameId);
    for (let i = 0; i < roles.length; i++) {
      if (roles[i].roleId === roleUid) {
        return roles[i];
      }
    }
    return null;
  }
}
