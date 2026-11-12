/**
 * ZZZMaterialCompute.ets — 绝区零养成材料计算
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
import { MaterialComputeTargets, ZZZSkillTarget, ZZZSkillType } from '../ToolsModels';
import { ZZZComputeSkill } from '../MaterialTargetConfigModels';
import { MaterialComputeResult } from '../MaterialComputeResult';
import { ZZZ_TAG, MaterialComputeUtils } from './MaterialComputeUtils';

/** 绝区零 avatar/info rawJson 中的技能项 */
interface ZZZRawSkill {
  level: number;
  skill_type: number;
}

export class ZZZMaterialCompute {
  /**
   * 绝区零：逐个代理人计算（接口不支持批量）。
   *
   * 参数规则以 mihoyo_apis.md 的 avatar_calc 请求样本为准：
   * - skill_type 5 为核心技，最高 7 级（超过会返回 -400005 提交的参数错误）；其余最高 12 级
   * - 技能当前等级、代理人等级优先取刚同步的代理人详情（avatar/info），并按上限截断
   * - avatar_current_promotes 优先取详情中的 promotes，没有时按等级估算（样本：40 级 → 4）
   * - 代理人等级和全部技能都已达到目标时不请求接口，视为"已达成目标"
   * 返回：有代理人计算成功 → SUCCESS；全部已达成目标 → NO_NEEDS；其余 → FAILED
   */
  static async compute(
    account: AccountRow, role: GameRoleRow, avatarIds: string[], t: MaterialComputeTargets,
  ): Promise<MaterialComputeResult> {
    Logger.info(ZZZ_TAG, `[Service] start, accountId=${account.uid}, roleUid=${role.roleId}, server=${role.server}, ` +
      `selected=${avatarIds.join(',')}, target avatar=${t.avatarLevel}, skills=${JSON.stringify(t.zzzSkills)}`);
    const repo = CoreInitializer.zzzRepository;
    // 先同步代理人列表（材料页 / 角色选择页展示的等级来自这里），失败则用 DB 缓存
    try {
      await repo.syncAvatarList(account.uid, role.roleId, role.server, account.cookie);
    } catch (error) {
      Logger.warn(ZZZ_TAG, `[Service] syncAvatarList failed, use cached list: ${MaterialComputeUtils.getErrorMessage(error)}`);
    }
    const avatarList = await repo.getAvatarList(account.uid, role.roleId);

    // 技能配置为空时用默认
    const skillTargets = t.zzzSkills.length > 0 ? t.zzzSkills : MaterialComputeTargets.createDefault(GameId.ZZZ).zzzSkills;

    // 同步选中代理人的详情，拿到真实等级 / 技能等级（失败则用 DB 缓存 / 配置页的当前等级）
    // 照 ZZZ-Plugin（dist/lib/avatar.js）：逐个请求间隔 3000ms（panel.roleInterval 默认值）
    for (let i = 0; i < avatarIds.length; i++) {
      if (i > 0) {
        await new Promise<void>((resolve: () => void) => setTimeout(resolve, 3000));
      }
      try {
        await repo.syncAvatarInfo(account.uid, role.roleId, role.server, account.cookie, avatarIds[i]);
      } catch (error) {
        Logger.warn(ZZZ_TAG, `[Service] syncAvatarInfo avatarId=${avatarIds[i]} failed, use cached: ${MaterialComputeUtils.getErrorMessage(error)}`);
      }
    }

    let successCount = 0;
    const reachedIds: string[] = [];
    for (let i = 0; i < avatarList.length; i++) {
      const avatar = avatarList[i];
      if (!avatarIds.includes(avatar.avatarId)) {
        continue;
      }
      try {
        const detail = await repo.getAvatarDetail(account.uid, role.roleId, avatar.avatarId);
        const detailRaw = detail !== null ? MaterialComputeUtils.parseObject(detail.rawJson) : null;
        const detailLevel = detailRaw !== null && typeof detailRaw['level'] === 'number' ? detailRaw['level'] as number : 0;
        const level = detailLevel > 0 ? detailLevel : avatar.level;
        const rawPromotes = detailRaw !== null && typeof detailRaw['promotes'] === 'number' ? detailRaw['promotes'] as number : -1;
        const currentPromotes = rawPromotes >= 0 ? rawPromotes : Math.min(Math.floor(level / 10), 5);

        const realLevels = ZZZMaterialCompute.parseSkillLevels(detailRaw);
        const skills: ZZZComputeSkill[] = [];
        for (let j = 0; j < skillTargets.length; j++) {
          const target: ZZZSkillTarget = skillTargets[j];
          const maxLevel = ZZZSkillType.getMaxLevel(target.skillType);
          const real = realLevels.get(target.skillType);
          const current = Math.min(real !== undefined && real > 0 ? real : target.current, maxLevel);
          const skill = new ZZZComputeSkill();
          skill.skill_type = target.skillType;
          skill.init_level = current;
          skill.level = Math.max(Math.min(target.target, maxLevel), current);
          skills[skills.length] = skill;
        }
        const avatarTarget = Math.max(t.avatarLevel, level);

        Logger.info(ZZZ_TAG, `[Service] avatarId=${avatar.avatarId} ${avatar.nameMi18n}, level(db=${avatar.level}, detail=${detailLevel})=${level}->${avatarTarget}, ` +
          `promotes=${currentPromotes}${rawPromotes >= 0 ? '' : '(estimated)'}, real skills=${JSON.stringify(Array.from(realLevels.entries()))}, skills=${JSON.stringify(skills)}`);

        // 全部已达到目标：不请求接口
        const skillsReached = skills.every((sk: ZZZComputeSkill) => sk.init_level >= sk.level);
        if (level >= avatarTarget && skillsReached) {
          reachedIds.push(avatar.avatarId);
          Logger.info(ZZZ_TAG, `[Service] avatarId=${avatar.avatarId} target reached, skip compute`);
          continue;
        }

        await repo.syncAvatarCompute(account.uid, role.roleId, avatar.avatarId, avatarTarget, level, currentPromotes,
          skills, role.roleId, role.server, account.cookie);
        successCount++;
        Logger.info(ZZZ_TAG, `[Service] avatarId=${avatar.avatarId} SUCCESS`);
      } catch (error) {
        Logger.error(ZZZ_TAG, `[Service] avatarId=${avatar.avatarId} FAILED: ${MaterialComputeUtils.getErrorMessage(error)}`);
      }
    }

    // 已达成目标的选中角色：写入"已达成目标"记录（覆盖旧的计算结果），保留在历史记录中
    if (reachedIds.length > 0) {
      try {
        await repo.markTargetReached(account.uid, role.roleId, reachedIds);
      } catch (error) {
        Logger.warn(ZZZ_TAG, `[Service] mark target reached failed: ${MaterialComputeUtils.getErrorMessage(error)}`);
      }
    }
    Logger.info(ZZZ_TAG, `[Service] done, success=${successCount}, reached=${reachedIds.length}(${reachedIds.join(',')}), selected=${avatarIds.length}`);
    return MaterialComputeUtils.toResult(successCount, reachedIds.length, avatarIds.length);
  }

  /** 绝区零：从 avatar/info rawJson 读取 skill_type → 当前等级 */
  private static parseSkillLevels(detailRaw: Record<string, Object> | null): Map<number, number> {
    const result = new Map<number, number>();
    if (detailRaw === null) {
      return result;
    }
    const skills = detailRaw['skills'] as ZZZRawSkill[] | undefined;
    if (Array.isArray(skills)) {
      for (let i = 0; i < skills.length; i++) {
        result.set(skills[i].skill_type, skills[i].level);
      }
    }
    return result;
  }
}
