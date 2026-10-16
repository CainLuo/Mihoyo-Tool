/**
 * ToolsModels.ets — 工具页 UI State 模型
 *
 * 定义工具页所需的数据结构，由 ViewModel 组装后传给 View 层。
 */

import { GameId } from 'core';

/**
 * 绝区零技能类型（API 的 skill_type，以 mihoyo_apis.md 养成计算请求样本与 ZZZAvatarDetailRaw 为准）
 * 0 普攻 / 1 特殊技 / 2 闪避 / 3 连携技 / 5 核心技（最高 7 级）/ 6 支援技；其余最高 12 级
 */
export class ZZZSkillType {
  static readonly NORMAL_ATTACK: number = 0;
  static readonly SPECIAL: number = 1;
  static readonly DODGE: number = 2;
  static readonly CHAIN: number = 3;
  static readonly CORE: number = 5;
  static readonly ASSIST: number = 6;
  /** 计算器支持的技能类型（顺序即配置页展示顺序） */
  static readonly ALL: number[] = [0, 1, 2, 3, 5, 6];

  /** 各技能最高等级：核心技 7，其余 12 */
  static maxLevel(skillType: number): number {
    return skillType === ZZZSkillType.CORE ? 7 : 12;
  }
}

/** 绝区零单个技能的计算目标 */
export class ZZZSkillTarget {
  /** 技能类型（API 的 skill_type） */
  skillType: number = 0;
  /** 当前等级（API 的 init_level） */
  current: number = 1;
  /** 目标等级（API 的 level） */
  target: number = 12;
}

/** 原神天赋槽位（与 skillLevels 下标一致） */
export class GenshinTalentSlot {
  static readonly NORMAL_ATTACK: number = 0;
  static readonly ELEMENTAL_SKILL: number = 1;
  static readonly ELEMENTAL_BURST: number = 2;
  static readonly COUNT: number = 3;
}

/** 星铁可升级技能槽位（下标 = 行迹 point_id 末三位 - 1：001 普攻 / 002 战技 / 003 终结技 / 004 天赋） */
export class StarRailSkillSlot {
  static readonly BASIC_ATTACK: number = 0;
  static readonly SKILL: number = 1;
  static readonly ULTIMATE: number = 2;
  static readonly TALENT: number = 3;
  static readonly COUNT: number = 4;
  /** 各槽位最高等级（普攻 6 级，其余 10 级） */
  static readonly MAX_LEVELS: number[] = [6, 10, 10, 10];
}

/**
 * 养成计算目标等级（按技能区分）。
 * - skillLevels：原神为 [普通攻击, 元素战技, 元素爆发]；星铁为 [普攻, 战技, 终结技, 天赋]
 * - weaponLevel：原神为武器、星铁为光锥、绝区零暂不使用
 * - zzzSkills：仅绝区零使用（按 skill_type 区分）
 */
export class MaterialComputeTargets {
  avatarLevel: number = 90;
  skillLevels: number[] = [];
  weaponLevel: number = 90;
  zzzSkills: ZZZSkillTarget[] = [];

  /** 各游戏的默认目标（满级） */
  static defaults(gameId: GameId): MaterialComputeTargets {
    const t = new MaterialComputeTargets();
    if (gameId === GameId.GENSHIN) {
      t.avatarLevel = 90;
      t.skillLevels = [10, 10, 10];
      t.weaponLevel = 90;
    } else if (gameId === GameId.STARRAIL) {
      t.avatarLevel = 80;
      t.skillLevels = StarRailSkillSlot.MAX_LEVELS.slice();
      t.weaponLevel = 80;
    } else if (gameId === GameId.ZZZ) {
      t.avatarLevel = 60;
      t.weaponLevel = 60;
      for (let i = 0; i < ZZZSkillType.ALL.length; i++) {
        const s = new ZZZSkillTarget();
        s.skillType = ZZZSkillType.ALL[i];
        s.current = 1;
        s.target = ZZZSkillType.maxLevel(s.skillType);
        t.zzzSkills[t.zzzSkills.length] = s;
      }
    }
    return t;
  }
}

/**
 * 材料计算链路的路由参数（角色选择页 → 材料汇总页 ⇄ 养成目标配置页）。
 * 材料汇总页只展示 avatarIds 中的角色；刷新 / 修改目标时也只重新计算这些角色。
 * 目标等级不在参数中传递，每次计算都从 DB（material_target_config）读取。
 */
export class MaterialTargetConfigParam {
  /** 米游社账号 UID */
  accountId: string = '';
  /** 游戏角色 UID */
  roleUid: string = '';
  /** 游戏标识 */
  gameId: GameId = GameId.GENSHIN;
  /** 选中的角色 ID（为空表示没有选择） */
  avatarIds: string[] = [];
}

/**
 * 游戏入口 UI State
 */
@ObservedV2
export class GameEntryVM {
  /** 账号 UID（米游社 UID） */
  accountId: string = '';
  /** 游戏角色 UID（第一个角色的 UID，用于跳转配置页） */
  roleUid: string = '';
  /** 游戏标识 */
  gameId: GameId = GameId.GENSHIN;
  /** 游戏名称 */
  gameName: ResourceStr = '';
  /** 游戏图标 */
  gameIcon: Resource = $r('app.media.logo_genshin');
  /** 游戏主题色 */
  gameColor: ResourceColor = $r('app.color.blue_400');
  /** 角色数量 */
  @Trace characterCount: number = 0;
  /** 已计算角色数量 */
  @Trace computedCount: number = 0;
  /** 是否有数据 */
  @Trace hasData: boolean = false;
}
