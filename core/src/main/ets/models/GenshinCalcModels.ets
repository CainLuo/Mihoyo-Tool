/**
 * GenshinCalcModels.ets — 原神养成计算器（batch_compute）请求参数模型
 *
 * 所有字段都直接取自计算器自己的 sync/avatar/list 接口，
 * 不能用战绩接口（game_record）的数据拼：两边的技能 ID、元素 ID、武器类型 ID 都不通用，
 * 拼错任一字段 batch_compute 都会返回 -500001。
 * 参考 TeyvatGuide Cultivation.vue createApiRefreshParams。
 */

/** 天赋槽位：sync 接口 skill_list 中 max_level > 1 的天赋依次为 普通攻击、元素战技、元素爆发 */
export const GENSHIN_TALENT_SLOT_COUNT: number = 3;

/** 养成目标等级 */
export class GenshinCalcTargets {
  avatarLevel: number = 90;
  /** 各天赋目标等级：[普通攻击, 元素战技, 元素爆发] */
  skillLevels: number[] = [10, 10, 10];
  weaponLevel: number = 90;
}

/** 技能目标：id 必须是 sync 接口返回的 group_id */
export class GenshinCalcSkillParam {
  id: number = 0;
  level_current: number = 1;
  level_target: number = 1;
}

/** 武器目标：除 level_target 外全部原样取自 sync 接口返回的 weapon */
export class GenshinCalcWeaponParam {
  id: number = 0;
  name: string = '';
  icon: string = '';
  /** 武器类型 ID（1=单手剑, 10=法器, 11=双手剑, 12=弓, 13=长柄） */
  weapon_cat_id: number = 0;
  /** 武器稀有度（星级），不是等级 */
  weapon_level: number = 0;
  max_level: number = 90;
  level_current: number = 1;
  level_target: number = 1;
}

/** 单个角色计算项 */
export class GenshinCalcAvatarParam {
  avatar_id: number = 0;
  avatar_level_current: number = 1;
  avatar_level_target: number = 1;
  /** 元素 ID（1=火, 2=风, 3=岩, 4=草, 5=雷, 6=水, 7=冰） */
  element_attr_id: number = 0;
  skill_list: GenshinCalcSkillParam[] = [];
  weapon: GenshinCalcWeaponParam | null = null;
  from_user_sync: boolean = true;
  avatar_promote_level: number = 0;
}
