/**
 * ZZZComputeParser.ets
 *
 * 解析绝区零养成计算 API 响应，提取材料消耗数据和玩家背包数据。
 * 绝区零 API 特有：返回 user_owns_materials 字段，包含玩家真实背包数据。
 */

// ─── 纯数据模型（core 对外暴露）────────────────────────────────

/** 单个材料项 */
export class ZZZMaterialItem {
  id: string = '';          // 绝区零 ID（可能是数字字符串）
  name: string = '';
  icon: string = '';
  iconUrl: string = '';     // 兼容字段，与 icon 相同
  num: number = 0;         // 所需数量
  rarity: string = '';     // 绝区零返回 "S", "A", "B", "C"
  type: number = 0;        // 材料类型
}

/** 技能消耗项（含技能信息） */
export class ZZZSkillConsumeItem {
  skillId: number = 0;
  levelCurrent: number = 1;
  levelTarget: number = 12;
  consumeList: ZZZMaterialItem[] = [];
}

/** 绝区零计算结果 */
export class ZZZComputeData {
  /** 代理人本体升级材料 */
  avatarConsume: ZZZMaterialItem[] = [];

  /** 技能升级材料（汇总） */
  skillConsume: ZZZMaterialItem[] = [];

  /** 武器（音擎）升级材料 */
  weaponConsume: ZZZMaterialItem[] = [];

  /** 各技能单独的消耗 */
  skillsConsume: ZZZSkillConsumeItem[] = [];

  /** 玩家拥有的材料（背包数据） */
  userOwnsMaterials: Map<string, number> = new Map();

  /** 货币 ID（丁尼的 ID） */
  coinId: number = 10;
}

// ─── JSON 接口声明（仅用于 parse）────────────────────────────

interface RawMaterialItem {
  id: string | number;
  name: string;
  icon: string;
  num: number;
  rarity: string;
  type: number;
}

interface RawSkillInfo {
  id: number;
  level_current: number;
  level_target: number;
}

interface RawSkillConsume {
  consume_list: RawMaterialItem[];
  skill_info: RawSkillInfo;
}

interface RawComputeData {
  avatar_consume: RawMaterialItem[];
  skill_consume: RawMaterialItem[];
  weapon_consume: RawMaterialItem[];
  skills_consume: RawSkillConsume[];
  user_owns_materials: Record<string, number>;
  coin_id: number;
}

// ─── Parser ──────────────────────────────────────────────────────

export class ZZZComputeParser {

  /**
   * 解析单角色计算 API 响应
   * @param rawJson API 返回的 data 部分 JSON 字符串
   * @returns 角色计算结果
   */
  static parse(rawJson: string): ZZZComputeData {
    try {
      const raw = JSON.parse(rawJson) as RawComputeData;
      return ZZZComputeParser.fromRaw(raw);
    } catch (_e) {
      return new ZZZComputeData();
    }
  }

  private static fromRaw(raw: RawComputeData): ZZZComputeData {
    const data = new ZZZComputeData();

    data.avatarConsume = ZZZComputeParser.parseMaterials(raw.avatar_consume);
    data.skillConsume = ZZZComputeParser.parseMaterials(raw.skill_consume);
    data.weaponConsume = ZZZComputeParser.parseMaterials(raw.weapon_consume);
    data.skillsConsume = ZZZComputeParser.parseSkillsConsume(raw.skills_consume);
    data.coinId = raw.coin_id ?? 10;

    // 解析 user_owns_materials
    if (raw.user_owns_materials) {
      const keys = Object.keys(raw.user_owns_materials);
      for (let i = 0; i < keys.length; i++) {
        const key = keys[i];
        data.userOwnsMaterials.set(key, raw.user_owns_materials[key]);
      }
    }

    return data;
  }

  private static parseMaterials(raws: RawMaterialItem[]): ZZZMaterialItem[] {
    const result: ZZZMaterialItem[] = [];
    if (!raws || raws.length === 0) {
      return result;
    }

    for (let i = 0; i < raws.length; i++) {
      const r = raws[i];
      const item = new ZZZMaterialItem();
      // 绝区零 ID 可能是 number 或 string，统一转为 string
      item.id = typeof r.id === 'number' ? String(r.id) : r.id;
      item.name = r.name;
      item.icon = r.icon;
      item.iconUrl = r.icon;  // 兼容字段
      item.num = r.num;
      item.rarity = r.rarity;
      item.type = r.type ?? 0;
      result[result.length] = item;
    }

    return result;
  }

  private static parseSkillsConsume(raws: RawSkillConsume[]): ZZZSkillConsumeItem[] {
    const result: ZZZSkillConsumeItem[] = [];
    if (!raws || raws.length === 0) {
      return result;
    }

    for (let i = 0; i < raws.length; i++) {
      const r = raws[i];
      const item = new ZZZSkillConsumeItem();
      item.skillId = r.skill_info.id;
      item.levelCurrent = r.skill_info.level_current ?? 1;
      item.levelTarget = r.skill_info.level_target ?? 12;
      item.consumeList = ZZZComputeParser.parseMaterials(r.consume_list);
      result[result.length] = item;
    }

    return result;
  }
}
