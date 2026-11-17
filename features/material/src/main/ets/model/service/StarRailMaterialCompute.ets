/**
 * StarRailMaterialCompute.ets — 星穹铁道养成材料计算
 *
 * 从 `MaterialComputeService` 拆出，由 facade 按 gameId 分派调用。
 */

import {
  CoreInitializer,
  AccountRow,
  GameRoleRow,
  Logger,
  StarRailComputeAvatar,
  StarRailComputeEquipment,
  StarRailComputeSkill,
} from 'core';
import { MaterialComputeTargets, StarRailSkillSlot } from '../ToolsModels';
import { MaterialComputeResult } from '../MaterialComputeResult';
import { STARRAIL_TAG, MaterialComputeUtils } from './MaterialComputeUtils';

/** 星铁 skillTreeJson 中的技能项（来自 avatar/info 接口） */
interface StarRailSkillTreeItem {
  point_id: string;
  level: number;
}

/** 星铁 avatar/info rawJson 中的星魂项 */
interface StarRailRawRank {
  pos: number;
  desc: string;
  is_unlocked: boolean;
}

export class StarRailMaterialCompute {
  /**
   * 星铁：逐个角色计算（接口不支持批量）。
   * - 角色等级 / 光锥优先取刚同步的角色详情（avatar/info），避免使用 DB 中过期的角色列表数据
   * - 角色、光锥、全部行迹都已达到目标时不请求接口，视为"已达成目标"（材料页不显示材料）
   * 返回：有角色计算成功 → SUCCESS；全部已达成目标 → NO_NEEDS；其余 → FAILED
   */
  static async compute(
    account: AccountRow, role: GameRoleRow, avatarIds: string[], t: MaterialComputeTargets,
  ): Promise<MaterialComputeResult> {
    Logger.info(STARRAIL_TAG, `[Service] start, accountId=${account.uid}, roleUid=${role.roleId}, server=${role.server}, ` +
      `selected=${avatarIds.join(',')}, target avatar=${t.avatarLevel}, skills(普攻/战技/终结技/天赋)=[${t.skillLevels.join(',')}], lightCone=${t.weaponLevel}`);
    const repo = CoreInitializer.starRailRepository;

    // 先同步角色列表（材料页 / 角色选择页展示的等级、光锥来自这里）和角色详情（等级 / 光锥 / 行迹），失败则用 DB 缓存
    try {
      await repo.syncAvatarList(account.uid, role.roleId, role.server, account.cookie);
    } catch (error) {
      Logger.warn(STARRAIL_TAG, `[Service] syncAvatarList failed, use cached list: ${MaterialComputeUtils.getErrorMessage(error)}`);
    }
    try {
      await repo.syncAvatarInfo(account.uid, role.roleId, role.server, account.cookie);
    } catch (error) {
      Logger.warn(STARRAIL_TAG, `[Service] syncAvatarInfo failed, use cached detail: ${MaterialComputeUtils.getErrorMessage(error)}`);
    }

    const avatarList = await repo.getAvatarList(account.uid, role.roleId);

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
        const equipId = detail !== null && detail.equipId.length > 0 ? detail.equipId : avatar.equipId;
        const equipLevel = detail !== null && detail.equipLevel > 0 ? detail.equipLevel : avatar.equipLevel;

        const avatarParam = new StarRailComputeAvatar();
        avatarParam.item_id = avatar.avatarId;
        avatarParam.cur_level = level;
        avatarParam.target_level = Math.max(t.avatarLevel, level);

        const equipmentParam = new StarRailComputeEquipment();
        equipmentParam.item_id = equipId;
        equipmentParam.cur_level = equipLevel > 0 ? equipLevel : 1;
        equipmentParam.target_level = Math.max(t.weaponLevel, equipmentParam.cur_level);

        // 战绩接口返回的技能等级含星魂（E3 / E5）加成，计算器需要不含加成的基础等级
        const rankBonus = StarRailMaterialCompute.parseRankBonus(detailRaw);
        const skillList: StarRailComputeSkill[] = [];
        if (detail && detail.skillTreeJson !== '') {
          try {
            const skills = JSON.parse(detail.skillTreeJson) as StarRailSkillTreeItem[];
            for (let j = 0; j < skills.length; j++) {
              const skillParam = new StarRailComputeSkill();
              skillParam.item_id = skills[j].point_id;
              skillParam.cur_level = StarRailMaterialCompute.calcBaseLevel(
                avatar.avatarId, skills[j].point_id, skills[j].level, rankBonus);
              skillParam.target_level = StarRailMaterialCompute.calcPointTarget(
                avatar.avatarId, skills[j].point_id, skills[j].level, t.skillLevels);
              skillList.push(skillParam);
            }
          } catch (parseError) {
            Logger.warn(STARRAIL_TAG, `[Service] avatarId=${avatar.avatarId} parse skillTreeJson failed`);
          }
        }
        if (skillList.length === 0) {
          // 无详情时的兜底：avatarId * 1000 + 序号（与 StarRailMaterialListViewModel 一致）
          Logger.warn(STARRAIL_TAG, `[Service] avatarId=${avatar.avatarId} no skillTreeJson, fallback to default 4 skills`);
          const avatarIdNum = parseInt(avatar.avatarId, 10);
          for (let j = 1; j <= StarRailSkillSlot.COUNT; j++) {
            const skillParam = new StarRailComputeSkill();
            skillParam.item_id = `${avatarIdNum * 1000 + j}`;
            skillParam.cur_level = 1;
            skillParam.target_level = StarRailMaterialCompute.calcPointTarget(
              avatar.avatarId, skillParam.item_id, 1, t.skillLevels);
            skillList.push(skillParam);
          }
        }

        Logger.info(STARRAIL_TAG, `[Service] avatarId=${avatar.avatarId} ${avatar.name}, rank bonus(slot→+N)=${JSON.stringify(Array.from(rankBonus.entries()))}, ` +
          `level(db=${avatar.level}, detail=${detailLevel}), ` +
          `equip(db=${avatar.equipLevel}, detail=${detail !== null ? detail.equipLevel : -1}), avatar=${JSON.stringify(avatarParam)}, ` +
          `equipment=${JSON.stringify(equipmentParam)}, skills=${JSON.stringify(skillList)}`);

        // 全部已达到目标：不请求接口
        const skillsReached = skillList.every((sk: StarRailComputeSkill) => sk.cur_level >= sk.target_level);
        if (avatarParam.cur_level >= avatarParam.target_level && equipmentParam.cur_level >= equipmentParam.target_level && skillsReached) {
          reachedIds.push(avatar.avatarId);
          Logger.info(STARRAIL_TAG, `[Service] avatarId=${avatar.avatarId} target reached, skip compute`);
          continue;
        }

        await repo.syncAvatarCompute(account.uid, role.roleId, avatar.avatarId, avatarParam, equipmentParam, skillList,
          role.roleId, role.server, account.cookie);
        successCount++;
        Logger.info(STARRAIL_TAG, `[Service] avatarId=${avatar.avatarId} SUCCESS`);
      } catch (error) {
        Logger.error(STARRAIL_TAG, `[Service] avatarId=${avatar.avatarId} FAILED: ${MaterialComputeUtils.getErrorMessage(error)}`);
      }
    }

    // 已达成目标的选中角色：写入"已达成目标"记录（覆盖旧的计算结果），保留在历史记录中
    if (reachedIds.length > 0) {
      try {
        await repo.markTargetReached(account.uid, role.roleId, reachedIds);
      } catch (error) {
        Logger.warn(STARRAIL_TAG, `[Service] mark target reached failed: ${MaterialComputeUtils.getErrorMessage(error)}`);
      }
    }
    Logger.info(STARRAIL_TAG, `[Service] done, success=${successCount}, reached=${reachedIds.length}(${reachedIds.join(',')}), selected=${avatarIds.length}`);
    return MaterialComputeUtils.toResult(successCount, reachedIds.length, avatarIds.length);
  }

  /**
   * 星铁单个行迹点的目标等级。
   * point_id = avatarId + 三位序号：001 普攻 / 002 战技 / 003 终结技 / 004 天赋 按 skillLevels 分别设置；
   * 其余（秘技、额外能力、属性加成、忆灵技能等）只能解锁，目标 = max(当前, 1)。
   */
  private static calcPointTarget(avatarId: string, pointId: string, current: number, skillLevels: number[]): number {
    const suffix = pointId.startsWith(avatarId) ? pointId.substring(avatarId.length) : '';
    const slot = suffix.length === 3 ? parseInt(suffix, 10) - 1 : -1;
    if (slot >= 0 && slot < StarRailSkillSlot.COUNT) {
      const maxLevel = StarRailSkillSlot.MAX_LEVELS[slot];
      const target = skillLevels[slot] ?? maxLevel;
      return Math.max(Math.min(target, maxLevel), current);
    }
    return Math.max(current, 1);
  }

  /**
   * 星铁：从角色详情（avatar/info）已激活星魂的说明中解析技能等级加成。
   * 说明格式固定，例如"战技等级+2，最多不超过15级；普攻等级+1，最多不超过10级"。
   * @returns 技能槽位（1 普攻 / 2 战技 / 3 终结技 / 4 天赋，与 point_id 末三位一致）→ 加成等级
   */
  private static parseRankBonus(detailRaw: Record<string, Object> | null): Map<number, number> {
    const bonus = new Map<number, number>();
    if (detailRaw === null) {
      return bonus;
    }
    const ranks = detailRaw['ranks'] as StarRailRawRank[] | undefined;
    if (!Array.isArray(ranks)) {
      return bonus;
    }
    const pattern = /(普攻|普通攻击|战技|终结技|天赋)等级\+(\d+)/g;
    for (let i = 0; i < ranks.length; i++) {
      if (ranks[i].is_unlocked !== true || typeof ranks[i].desc !== 'string') {
        continue;
      }
      pattern.lastIndex = 0;
      let m = pattern.exec(ranks[i].desc);
      while (m !== null) {
        const name = m[1];
        const slot = name === '战技' ? 2 : name === '终结技' ? 3 : name === '天赋' ? 4 : 1;
        bonus.set(slot, (bonus.get(slot) ?? 0) + parseInt(m[2], 10));
        m = pattern.exec(ranks[i].desc);
      }
    }
    return bonus;
  }

  /** 星铁：point_id 对应的技能扣除星魂加成后的基础等级（非 001~004 的节点不受星魂影响） */
  private static calcBaseLevel(avatarId: string, pointId: string, level: number, rankBonus: Map<number, number>): number {
    const suffix = pointId.startsWith(avatarId) ? pointId.substring(avatarId.length) : '';
    const slot = suffix.length === 3 ? parseInt(suffix, 10) : -1;
    if (slot >= 1 && slot <= StarRailSkillSlot.COUNT) {
      const base = level - (rankBonus.get(slot) ?? 0);
      return Math.min(Math.max(base, 1), StarRailSkillSlot.MAX_LEVELS[slot - 1]);
    }
    return level;
  }
}
