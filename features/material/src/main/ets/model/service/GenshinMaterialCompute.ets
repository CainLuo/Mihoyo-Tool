/**
 * GenshinMaterialCompute.ets — 原神养成材料计算
 *
 * 从 `MaterialComputeService` 拆出，由 facade 按 gameId 分派调用。
 */

import {
  CoreInitializer,
  AccountRow,
  GameRoleRow,
  GameId,
  Logger,
} from 'core';
import { MaterialComputeTargets } from '../ToolsModels';
import { MaterialComputeResult } from '../MaterialComputeResult';
import { GENSHIN_TAG, MaterialComputeUtils } from './MaterialComputeUtils';

export class GenshinMaterialCompute {
  /** 原神：一次批量计算选中角色，参数来自计算器 sync/avatar/list */
  static async compute(
    account: AccountRow, role: GameRoleRow, avatarIds: string[], t: MaterialComputeTargets,
  ): Promise<MaterialComputeResult> {
    Logger.info(GENSHIN_TAG, `[Service] start, accountId=${account.uid}, roleUid=${role.roleId}, selected=${avatarIds.join(',')}, ` +
      `target avatar=${t.avatarLevel}, talents(A/E/Q)=[${t.skillLevels.join(',')}], weapon=${t.weaponLevel}`);
    try {
      const skillLevels = t.skillLevels.length > 0 ? t.skillLevels : MaterialComputeTargets.createDefault(GameId.GENSHIN).skillLevels;
      // 计算器角色数据（sync/avatar/list）会先写入 genshin_calc_avatar，再从 DB 读取组装参数
      const items = await CoreInitializer.genshinRepository.buildCalcItems(
        account.uid, role.roleId, role.server, account.cookie, t.avatarLevel, skillLevels, t.weaponLevel, avatarIds);
      // 选中但不需要计算的角色（已达成目标）：写入"已达成目标"记录（覆盖旧的计算结果），保留在历史记录中
      const computedIds: string[] = items.map((it: object) => `${(it as Record<string, Object>)['avatar_id']}`);
      const reachedIds: string[] = avatarIds.filter((id: string) => !computedIds.includes(id));
      if (reachedIds.length > 0) {
        await CoreInitializer.genshinRepository.markTargetReached(account.uid, role.roleId, reachedIds);
        Logger.info(GENSHIN_TAG, `[Service] target reached, marked: ${reachedIds.join(',')}`);
      }
      if (items.length === 0) {
        Logger.warn(GENSHIN_TAG, `[Service] no compute items, selected avatars already reach target`);
        return MaterialComputeResult.NO_NEEDS;
      }
      // 只 upsert 本次计算的角色
      await CoreInitializer.genshinRepository.syncAvatarCompute(
        account.uid, role.roleId, items, role.roleId, role.server, account.cookie);
      Logger.info(GENSHIN_TAG, `[Service] done, items=${items.length}`);
      return MaterialComputeResult.SUCCESS;
    } catch (error) {
      Logger.error(GENSHIN_TAG, `[Service] failed: ${MaterialComputeUtils.getErrorMessage(error)}`);
      return MaterialComputeResult.FAILED;
    }
  }
}
