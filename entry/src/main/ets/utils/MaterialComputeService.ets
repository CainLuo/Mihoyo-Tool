/**
 * MaterialComputeService.ets — 选中角色的养成材料计算
 *
 * 角色选择页、材料汇总页（刷新）、养成目标配置页共用。
 * 只计算 MaterialTargetConfigParam.avatarIds 中的角色，计算结果按角色 upsert 到 DB；
 * 其他角色以前的计算结果保留（角色选择页的"历史记录"会列出全部）。
 * 材料汇总页只展示路由参数中的角色，所以不需要清空其他角色的数据。
 */

import {
  CoreInitializer,
  AccountRow,
  GameRoleRow,
  GameId,
  Logger,
  StarRailComputeAvatar,
  StarRailComputeEquipment,
  StarRailComputeSkill,
} from 'core';
import { MaterialComputeTargets, MaterialTargetConfigParam, StarRailSkillSlot, ZZZSkillTarget, ZZZSkillType } from '../models/ToolsModels';
import { ZZZComputeSkill } from '../models/MaterialTargetConfigModels';

const GENSHIN_TAG: string = 'GenshinCalc';
const SR_TAG: string = 'StarRailCalc';
const ZZZ_TAG: string = 'ZZZCalc';

/** 计算结果 */
export enum MaterialComputeResult {
  /** 计算完成，可跳转 / 刷新材料页 */
  SUCCESS = 'SUCCESS',
  /** 选中角色都已达到目标，没有需要计算的内容 */
  NO_NEEDS = 'NO_NEEDS',
  /** 请求或写库失败 */
  FAILED = 'FAILED',
  /** 正在计算中，忽略重复点击 */
  BUSY = 'BUSY',
  /** DB 中没有该游戏 UID 的养成目标配置，需要先去配置页设置 */
  NO_CONFIG = 'NO_CONFIG',
}

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

/** 绝区零 avatar/info rawJson 中的技能项 */
interface ZZZRawSkill {
  level: number;
  skill_type: number;
}

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
    const t = MaterialComputeTargets.defaults(gameId);
    const repo = CoreInitializer.materialTargetConfigRepository;
    const row = await repo.getConfig(accountId, roleUid, gameId);
    if (row === null) {
      Logger.warn(GENSHIN_TAG, `[Service] loadSavedTargets gameId=${gameId}, account=${accountId}, role=${roleUid}: no saved config`);
      return null;
    }
    if (gameId === GameId.GENSHIN) {
      const config = await repo.getGenshinConfig(accountId, roleUid);
      t.avatarLevel = MaterialComputeService.clampLevel(config.avatar.target, 90);
      for (let i = 0; i < config.skills.length; i++) {
        const s = config.skills[i];
        // skillType = 天赋槽位 0 / 1 / 2
        if (s.skillType >= 0 && s.skillType < t.skillLevels.length) {
          t.skillLevels[s.skillType] = MaterialComputeService.clampLevel(s.target, 10);
        }
      }
      t.weaponLevel = MaterialComputeService.clampLevel(config.weapon.target, 90);
    } else if (gameId === GameId.STARRAIL) {
      const config = await repo.getStarRailConfig(accountId, roleUid);
      t.avatarLevel = MaterialComputeService.clampLevel(config.avatar.target, 80);
      for (let i = 0; i < config.skills.length; i++) {
        const s = config.skills[i];
        // skillType = 行迹 point_id 末三位 1 / 2 / 3 / 4，对应 skillLevels 下标 0 / 1 / 2 / 3
        const slot = s.skillType - 1;
        if (slot >= 0 && slot < t.skillLevels.length) {
          t.skillLevels[slot] = MaterialComputeService.clampLevel(s.target, StarRailSkillSlot.MAX_LEVELS[slot]);
        }
      }
      t.weaponLevel = MaterialComputeService.clampLevel(config.lightCone.target, 80);
    } else if (gameId === GameId.ZZZ) {
      const config = await repo.getZZZConfig(accountId, roleUid);
      t.avatarLevel = MaterialComputeService.clampLevel(config.avatar.target, 60);
      t.weaponLevel = MaterialComputeService.clampLevel(config.weapon.target, 60);
      for (let i = 0; i < config.skills.length; i++) {
        const saved = config.skills[i];
        for (let j = 0; j < t.zzzSkills.length; j++) {
          if (t.zzzSkills[j].skillType === saved.skillType) {
            const maxLevel = ZZZSkillType.maxLevel(saved.skillType);
            t.zzzSkills[j].current = MaterialComputeService.clampLevel(saved.current, maxLevel);
            t.zzzSkills[j].target = MaterialComputeService.clampLevel(saved.target, maxLevel);
            break;
          }
        }
      }
    }
    Logger.info(GENSHIN_TAG, `[Service] loadSavedTargets gameId=${gameId}, account=${accountId}, role=${roleUid}: saved=${row.configJson} → ${JSON.stringify(t)}`);
    return t;
  }

  /** 等级截断到 1 ~ max */
  private static clampLevel(level: number, max: number): number {
    return Math.min(Math.max(level, 1), max);
  }

  /**
   * 计算选中角色的养成材料。目标等级每次都从 DB 读取。
   * @param param 选中的账号 / 游戏 UID / 角色 ID
   * @returns DB 没有养成目标配置时返回 NO_CONFIG
   */
  static async compute(param: MaterialTargetConfigParam): Promise<MaterialComputeResult> {
    let loaded: MaterialComputeTargets | null;
    try {
      loaded = await MaterialComputeService.loadSavedTargets(param.gameId, param.accountId, param.roleUid);
    } catch (error) {
      Logger.error(GENSHIN_TAG, `[Service] gameId=${param.gameId} read target config failed: ${MaterialComputeService.msg(error)}`);
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
      return MaterialComputeService.computeGenshin(account, role, param.avatarIds, t);
    } else if (param.gameId === GameId.STARRAIL) {
      return MaterialComputeService.computeStarRail(account, role, param.avatarIds, t);
    } else if (param.gameId === GameId.ZZZ) {
      return MaterialComputeService.computeZZZ(account, role, param.avatarIds, t);
    }
    return MaterialComputeResult.FAILED;
  }

  // ─── 原神 ────────────────────────────────────────────────────

  /** 原神：一次批量计算选中角色，参数来自计算器 sync/avatar/list */
  private static async computeGenshin(
    account: AccountRow, role: GameRoleRow, avatarIds: string[], t: MaterialComputeTargets,
  ): Promise<MaterialComputeResult> {
    Logger.info(GENSHIN_TAG, `[Service] start, accountId=${account.uid}, roleUid=${role.roleId}, selected=${avatarIds.join(',')}, ` +
      `target avatar=${t.avatarLevel}, talents(A/E/Q)=[${t.skillLevels.join(',')}], weapon=${t.weaponLevel}`);
    try {
      const skillLevels = t.skillLevels.length > 0 ? t.skillLevels : MaterialComputeTargets.defaults(GameId.GENSHIN).skillLevels;
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
      Logger.error(GENSHIN_TAG, `[Service] failed: ${MaterialComputeService.msg(error)}`);
      return MaterialComputeResult.FAILED;
    }
  }

  // ─── 星铁 ────────────────────────────────────────────────────

  /**
   * 星铁：逐个角色计算（接口不支持批量）。
   * - 角色等级 / 光锥优先取刚同步的角色详情（avatar/info），避免使用 DB 中过期的角色列表数据
   * - 角色、光锥、全部行迹都已达到目标时不请求接口，视为"已达成目标"（材料页不显示材料）
   * 返回：有角色计算成功 → SUCCESS；全部已达成目标 → NO_NEEDS；其余 → FAILED
   */
  private static async computeStarRail(
    account: AccountRow, role: GameRoleRow, avatarIds: string[], t: MaterialComputeTargets,
  ): Promise<MaterialComputeResult> {
    Logger.info(SR_TAG, `[Service] start, accountId=${account.uid}, roleUid=${role.roleId}, server=${role.server}, ` +
      `selected=${avatarIds.join(',')}, target avatar=${t.avatarLevel}, skills(普攻/战技/终结技/天赋)=[${t.skillLevels.join(',')}], lightCone=${t.weaponLevel}`);
    const repo = CoreInitializer.starRailRepository;

    // 先同步角色列表（材料页 / 角色选择页展示的等级、光锥来自这里）和角色详情（等级 / 光锥 / 行迹），失败则用 DB 缓存
    try {
      await repo.syncAvatarList(account.uid, role.roleId, role.server, account.cookie);
    } catch (error) {
      Logger.warn(SR_TAG, `[Service] syncAvatarList failed, use cached list: ${MaterialComputeService.msg(error)}`);
    }
    try {
      await repo.syncAvatarInfo(account.uid, role.roleId, role.server, account.cookie);
    } catch (error) {
      Logger.warn(SR_TAG, `[Service] syncAvatarInfo failed, use cached detail: ${MaterialComputeService.msg(error)}`);
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
        const detailRaw = detail !== null ? MaterialComputeService.parseObject(detail.rawJson) : null;
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
        const rankBonus = MaterialComputeService.starRailRankBonus(detailRaw);
        const skillList: StarRailComputeSkill[] = [];
        if (detail && detail.skillTreeJson !== '') {
          try {
            const skills = JSON.parse(detail.skillTreeJson) as StarRailSkillTreeItem[];
            for (let j = 0; j < skills.length; j++) {
              const skillParam = new StarRailComputeSkill();
              skillParam.item_id = skills[j].point_id;
              skillParam.cur_level = MaterialComputeService.starRailBaseLevel(
                avatar.avatarId, skills[j].point_id, skills[j].level, rankBonus);
              skillParam.target_level = MaterialComputeService.starRailPointTarget(
                avatar.avatarId, skills[j].point_id, skills[j].level, t.skillLevels);
              skillList.push(skillParam);
            }
          } catch (parseError) {
            Logger.warn(SR_TAG, `[Service] avatarId=${avatar.avatarId} parse skillTreeJson failed`);
          }
        }
        if (skillList.length === 0) {
          // 无详情时的兜底：avatarId * 1000 + 序号（与 StarRailMaterialListViewModel 一致）
          Logger.warn(SR_TAG, `[Service] avatarId=${avatar.avatarId} no skillTreeJson, fallback to default 4 skills`);
          const avatarIdNum = parseInt(avatar.avatarId, 10);
          for (let j = 1; j <= StarRailSkillSlot.COUNT; j++) {
            const skillParam = new StarRailComputeSkill();
            skillParam.item_id = `${avatarIdNum * 1000 + j}`;
            skillParam.cur_level = 1;
            skillParam.target_level = MaterialComputeService.starRailPointTarget(
              avatar.avatarId, skillParam.item_id, 1, t.skillLevels);
            skillList.push(skillParam);
          }
        }

        Logger.info(SR_TAG, `[Service] avatarId=${avatar.avatarId} ${avatar.name}, rank bonus(slot→+N)=${JSON.stringify(Array.from(rankBonus.entries()))}, ` +
          `level(db=${avatar.level}, detail=${detailLevel}), ` +
          `equip(db=${avatar.equipLevel}, detail=${detail !== null ? detail.equipLevel : -1}), avatar=${JSON.stringify(avatarParam)}, ` +
          `equipment=${JSON.stringify(equipmentParam)}, skills=${JSON.stringify(skillList)}`);

        // 全部已达到目标：不请求接口
        const skillsReached = skillList.every((sk: StarRailComputeSkill) => sk.cur_level >= sk.target_level);
        if (avatarParam.cur_level >= avatarParam.target_level && equipmentParam.cur_level >= equipmentParam.target_level && skillsReached) {
          reachedIds.push(avatar.avatarId);
          Logger.info(SR_TAG, `[Service] avatarId=${avatar.avatarId} target reached, skip compute`);
          continue;
        }

        await repo.syncAvatarCompute(account.uid, role.roleId, avatar.avatarId, avatarParam, equipmentParam, skillList,
          role.roleId, role.server, account.cookie);
        successCount++;
        Logger.info(SR_TAG, `[Service] avatarId=${avatar.avatarId} SUCCESS`);
      } catch (error) {
        Logger.error(SR_TAG, `[Service] avatarId=${avatar.avatarId} FAILED: ${MaterialComputeService.msg(error)}`);
      }
    }

    // 已达成目标的选中角色：写入"已达成目标"记录（覆盖旧的计算结果），保留在历史记录中
    if (reachedIds.length > 0) {
      try {
        await repo.markTargetReached(account.uid, role.roleId, reachedIds);
      } catch (error) {
        Logger.warn(SR_TAG, `[Service] mark target reached failed: ${MaterialComputeService.msg(error)}`);
      }
    }
    Logger.info(SR_TAG, `[Service] done, success=${successCount}, reached=${reachedIds.length}(${reachedIds.join(',')}), selected=${avatarIds.length}`);
    return MaterialComputeService.toResult(successCount, reachedIds.length, avatarIds.length);
  }

  // ─── 绝区零 ──────────────────────────────────────────────────

  /**
   * 绝区零：逐个代理人计算（接口不支持批量）。
   * 参数规则以 mihoyo_apis.md 的 avatar_calc 请求样本为准：
   * - skill_type 5 为核心技，最高 7 级（超过会返回 -400005 提交的参数错误）；其余最高 12 级
   * - 技能当前等级、代理人等级优先取刚同步的代理人详情（avatar/info），并按上限截断
   * - avatar_current_promotes 优先取详情中的 promotes，没有时按等级估算（样本：40 级 → 4）
   * - 代理人等级和全部技能都已达到目标时不请求接口，视为"已达成目标"
   * 返回：有代理人计算成功 → SUCCESS；全部已达成目标 → NO_NEEDS；其余 → FAILED
   */
  private static async computeZZZ(
    account: AccountRow, role: GameRoleRow, avatarIds: string[], t: MaterialComputeTargets,
  ): Promise<MaterialComputeResult> {
    Logger.info(ZZZ_TAG, `[Service] start, accountId=${account.uid}, roleUid=${role.roleId}, server=${role.server}, ` +
      `selected=${avatarIds.join(',')}, target avatar=${t.avatarLevel}, skills=${JSON.stringify(t.zzzSkills)}`);
    const repo = CoreInitializer.zzzRepository;
    // 先同步代理人列表（材料页 / 角色选择页展示的等级来自这里），失败则用 DB 缓存
    try {
      await repo.syncAvatarList(account.uid, role.roleId, role.server, account.cookie);
    } catch (error) {
      Logger.warn(ZZZ_TAG, `[Service] syncAvatarList failed, use cached list: ${MaterialComputeService.msg(error)}`);
    }
    const avatarList = await repo.getAvatarList(account.uid, role.roleId);

    // 技能配置为空时用默认
    const skillTargets = t.zzzSkills.length > 0 ? t.zzzSkills : MaterialComputeTargets.defaults(GameId.ZZZ).zzzSkills;

    // 同步选中代理人的详情，拿到真实等级 / 技能等级（失败则用 DB 缓存 / 配置页的当前等级）
    // 照 ZZZ-Plugin（dist/lib/avatar.js）：逐个请求间隔 3000ms（panel.roleInterval 默认值）
    for (let i = 0; i < avatarIds.length; i++) {
      if (i > 0) {
        await new Promise<void>((resolve: () => void) => setTimeout(resolve, 3000));
      }
      try {
        await repo.syncAvatarInfo(account.uid, role.roleId, role.server, account.cookie, avatarIds[i]);
      } catch (error) {
        Logger.warn(ZZZ_TAG, `[Service] syncAvatarInfo avatarId=${avatarIds[i]} failed, use cached: ${MaterialComputeService.msg(error)}`);
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
        const detailRaw = detail !== null ? MaterialComputeService.parseObject(detail.rawJson) : null;
        const detailLevel = detailRaw !== null && typeof detailRaw['level'] === 'number' ? detailRaw['level'] as number : 0;
        const level = detailLevel > 0 ? detailLevel : avatar.level;
        const rawPromotes = detailRaw !== null && typeof detailRaw['promotes'] === 'number' ? detailRaw['promotes'] as number : -1;
        const currentPromotes = rawPromotes >= 0 ? rawPromotes : Math.min(Math.floor(level / 10), 5);

        const realLevels = MaterialComputeService.zzzSkillLevels(detailRaw);
        const skills: ZZZComputeSkill[] = [];
        for (let j = 0; j < skillTargets.length; j++) {
          const target: ZZZSkillTarget = skillTargets[j];
          const maxLevel = ZZZSkillType.maxLevel(target.skillType);
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
        Logger.error(ZZZ_TAG, `[Service] avatarId=${avatar.avatarId} FAILED: ${MaterialComputeService.msg(error)}`);
      }
    }

    // 已达成目标的选中角色：写入"已达成目标"记录（覆盖旧的计算结果），保留在历史记录中
    if (reachedIds.length > 0) {
      try {
        await repo.markTargetReached(account.uid, role.roleId, reachedIds);
      } catch (error) {
        Logger.warn(ZZZ_TAG, `[Service] mark target reached failed: ${MaterialComputeService.msg(error)}`);
      }
    }
    Logger.info(ZZZ_TAG, `[Service] done, success=${successCount}, reached=${reachedIds.length}(${reachedIds.join(',')}), selected=${avatarIds.length}`);
    return MaterialComputeService.toResult(successCount, reachedIds.length, avatarIds.length);
  }

  // ─── 工具 ────────────────────────────────────────────────────

  /**
   * 星铁单个行迹点的目标等级。
   * point_id = avatarId + 三位序号：001 普攻 / 002 战技 / 003 终结技 / 004 天赋 按 skillLevels 分别设置；
   * 其余（秘技、额外能力、属性加成、忆灵技能等）只能解锁，目标 = max(当前, 1)。
   */
  private static starRailPointTarget(avatarId: string, pointId: string, current: number, skillLevels: number[]): number {
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
  private static starRailRankBonus(detailRaw: Record<string, Object> | null): Map<number, number> {
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
  private static starRailBaseLevel(avatarId: string, pointId: string, level: number, rankBonus: Map<number, number>): number {
    const suffix = pointId.startsWith(avatarId) ? pointId.substring(avatarId.length) : '';
    const slot = suffix.length === 3 ? parseInt(suffix, 10) : -1;
    if (slot >= 1 && slot <= StarRailSkillSlot.COUNT) {
      const base = level - (rankBonus.get(slot) ?? 0);
      return Math.min(Math.max(base, 1), StarRailSkillSlot.MAX_LEVELS[slot - 1]);
    }
    return level;
  }

  /** 绝区零：从 avatar/info rawJson 读取 skill_type → 当前等级 */
  private static zzzSkillLevels(detailRaw: Record<string, Object> | null): Map<number, number> {
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

  /** 有成功 → SUCCESS；全部已达成目标 → NO_NEEDS；其余 → FAILED */
  private static toResult(successCount: number, reachedCount: number, selectedCount: number): MaterialComputeResult {
    if (successCount > 0) {
      return MaterialComputeResult.SUCCESS;
    }
    if (reachedCount > 0 && reachedCount === selectedCount) {
      return MaterialComputeResult.NO_NEEDS;
    }
    return MaterialComputeResult.FAILED;
  }

  private static parseObject(json: string): Record<string, Object> | null {
    if (json.length === 0) {
      return null;
    }
    try {
      return JSON.parse(json) as Record<string, Object>;
    } catch (_) {
      return null;
    }
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

  private static msg(error: Object): string {
    return error instanceof Error ? error.message : `${error}`;
  }
}
