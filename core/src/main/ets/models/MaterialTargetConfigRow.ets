/**
 * MaterialTargetConfigRow — 养成目标配置数据模型
 *
 * 对应三个游戏的养成目标配置表：
 * - genshin_material_target_config（原神）
 * - starrail_material_target_config（星穹铁道）
 * - zzz_material_target_config（绝区零）
 *
 * 用于存储用户设置的角色/技能/武器目标等级配置。
 * 每个游戏角色一份配置，进入养成目标配置页时读取，离开时保存。
 *
 * 唯一键：(account_id, role_uid)
 * 同一个米游社账号下，不同游戏角色的配置是独立的。
 *
 * config_json 字段结构（JSON 字符串）：
 *
 * 原神（skills 按天赋分别配置，skillType：0=普通攻击, 1=元素战技, 2=元素爆发）：
 * {
 *   "avatar": { "current": 1, "target": 90 },
 *   "skills": [ { "skillType": 0, "current": 1, "target": 10 }, ... ],
 *   "weapon": { "current": 1, "target": 90 }
 * }
 *
 * 星穹铁道（skills 按技能分别配置，skillType 与行迹 point_id 末三位一致：1=普攻, 2=战技, 3=终结技, 4=天赋）：
 * {
 *   "avatar": { "current": 1, "target": 80 },
 *   "skills": [ { "skillType": 1, "current": 1, "target": 6 }, ... ],
 *   "lightCone": { "current": 1, "target": 80 }
 * }
 *
 * 旧版本原神 / 星铁只有统一的 "skill": { current, target }，DB v4 迁移（RdbMigrationV4）已将其拆分为 skills。
 *
 * 绝区零：
 * {
 *   "avatar": { "current": 1, "target": 60 },
 *   "weapon": { "current": 1, "target": 60 },
 *   "skills": [
 *     { "skillType": 0, "current": 1, "target": 12 },
 *     { "skillType": 1, "current": 1, "target": 12 },
 *     ...
 *   ]
 * }
 */

export class MaterialTargetConfigRow {
  /** 自增主键 */
  id: number = 0;

  /** 米游社账号 UID（外键 → account_table.uid） */
  accountId: string = '';

  /** 游戏角色 UID（与 game_role_table.role_id 对应） */
  roleUid: string = '';

  /** 配置 JSON（包含角色/技能/武器的当前等级和目标等级） */
  configJson: string = '';

  /** 数据写入时间戳（Unix 秒） */
  updateTime: number = 0;
}

// ─── 配置 JSON 结构类型（用于类型安全和文档说明）────────────────────────────────

/**
 * 等级配置（当前等级 + 目标等级）
 */
export class LevelConfig {
  /** 当前等级 */
  current: number = 1;
  /** 目标等级 */
  target: number = 1;
}

/**
 * 技能等级配置（按技能区分，含 skillType；三个游戏 skillType 含义见文件头注释）
 */
export class SkillLevelConfig extends LevelConfig {
  /** 技能类型（绝区零 API 使用的 skill_type） */
  skillType: number = 0;
}

/**
 * 原神养成目标配置 JSON 结构
 */
export class GenshinMaterialTargetConfigJson {
  /** 角色等级配置 */
  avatar: LevelConfig = new LevelConfig();
  /** 各天赋等级配置（普通攻击 / 元素战技 / 元素爆发） */
  skills: SkillLevelConfig[] = [];
  /** 武器等级配置 */
  weapon: LevelConfig = new LevelConfig();
}

/**
 * 星穹铁道养成目标配置 JSON 结构
 */
export class StarRailMaterialTargetConfigJson {
  /** 角色等级配置 */
  avatar: LevelConfig = new LevelConfig();
  /** 各技能等级配置（普攻 / 战技 / 终结技 / 天赋） */
  skills: SkillLevelConfig[] = [];
  /** 光锥等级配置 */
  lightCone: LevelConfig = new LevelConfig();
}

/**
 * 绝区零养成目标配置 JSON 结构
 */
export class ZZZMaterialTargetConfigJson {
  /** 代理人等级配置 */
  avatar: LevelConfig = new LevelConfig();
  /** 武器/音擎等级配置 */
  weapon: LevelConfig = new LevelConfig();
  /** 技能等级配置列表（6 个技能） */
  skills: SkillLevelConfig[] = [];
}
