/**
 * GenshinComputeParser.ets
 *
 * 解析原神养成计算 API 响应，提取材料消耗数据。
 * 用于材料计算功能，展示角色/武器/技能升级所需材料。
 *
 * API 返回结构：
 * - data.items[].avatar_consume — 模板数据（lack_num 全是 0，无用）
 * - data.overall_consume — 汇总的材料缺口数据（有真实 lack_num）
 * - data.overall_material_consume — 按来源分组的详细缺口数据
 * - data.available_material — 用户当前拥有的材料库存
 *
 * 正确做法：从 overall_consume 提取材料缺口数据。
 */

// ─── 纯数据模型（core 对外暴露）────────────────────────────────

/** 单个材料项 */
export class GenshinMaterialItem {
  id: number = 0;
  name: string = '';
  icon: string = '';
  iconUrl: string = '';    // 兼容字段
  num: number = 0;        // 所需数量
  lackNum: number = 0;    // 缺少数量
  level: number = 0;      // 稀有度/等级
  rarity: number = 0;     // 稀有度（与 level 相同）
}

/** 技能消耗项（含技能信息） */
export class GenshinSkillConsumeItem {
  skillId: string = '';
  levelCurrent: number = 1;
  levelTarget: number = 10;
  consumeList: GenshinMaterialItem[] = [];
}

/** 单个角色的计算结果 */
export class GenshinComputeItem {
  avatarId: string = '';

  /** 角色本体升级材料 */
  avatarConsume: GenshinMaterialItem[] = [];

  /** 技能升级材料（汇总） */
  skillConsume: GenshinMaterialItem[] = [];

  /** 武器升级材料 */
  weaponConsume: GenshinMaterialItem[] = [];

  /** 各技能单独的消耗（含技能 ID 和等级信息） */
  skillsConsume: GenshinSkillConsumeItem[] = [];
}

// ─── JSON 接口声明（仅用于 parse）────────────────────────────

interface RawMaterialItem {
  id: number;
  name: string;
  icon: string;
  num: number;
  lack_num: number;
  level: number;
  rarity: number;
}

interface RawSkillInfo {
  id: string;
  level_current: string;
  level_target: string;
}

interface RawSkillConsume {
  consume_list: RawMaterialItem[];
  skill_info: RawSkillInfo;
}

/**
 * 原始计算项接口
 * 注意：API 返回的字段名与文档有差异
 * - avatar_id: 角色ID
 * - avatar_consume: 角色突破材料（模板数据，lack_num 全是 0）
 * - skill_consume: 技能材料（实际返回）
 * - avatar_skill_consume: 技能材料（文档中的字段名，但实际返回的是 skill_consume）
 * - weapon_consume: 武器材料
 * - skills_consume: 各技能单独消耗
 */
interface RawComputeItem {
  avatar_id?: string | number;
  avatar_consume: RawMaterialItem[];
  skill_consume?: RawMaterialItem[];       // 实际返回的字段名
  avatar_skill_consume?: RawMaterialItem[]; // 文档中的字段名
  weapon_consume: RawMaterialItem[];
  skills_consume: RawSkillConsume[];
}

interface RawComputeData {
  items: RawComputeItem[];
  list?: RawComputeItem[];  // 有些 API 返回 list 而不是 items
  /** 汇总的材料缺口数据（这才是真实数据） */
  overall_consume?: RawMaterialItem[];
}

// ─── Parser ──────────────────────────────────────────────────────

export class GenshinComputeParser {

  /**
   * 解析批量计算 API 响应
   * @param rawJson API 返回的 data 部分 JSON 字符串
   * @returns 角色计算结果数组
   */
  static parse(rawJson: string): GenshinComputeItem[] {
    try {
      const raw = JSON.parse(rawJson) as RawComputeData;
      return GenshinComputeParser.fromRaw(raw);
    } catch (_e) {
      return [];
    }
  }

  /**
   * 解析单个角色的计算数据（存储在 DB 中的 rawJson 格式）
   * 
   * rawJson 格式：
   * - avatar_consume: 材料数组（已合并 lack_num）
   * - overall_consume: 原始缺口数据（可选）
   * 
   * @param rawJson 单个 item 的 JSON 字符串
   * @returns 单个角色计算结果
   */
  static parseItem(rawJson: string): GenshinComputeItem | null {
    try {
      const raw = JSON.parse(rawJson) as Record<string, Object>;
      const computeItem = new GenshinComputeItem();
      
      // avatar_id
      const avatarId = raw['avatar_id'];
      if (typeof avatarId === 'number') {
        computeItem.avatarId = `${avatarId}`;
      } else if (typeof avatarId === 'string') {
        computeItem.avatarId = avatarId;
      }
      
      // 优先使用 overall_consume（真实缺口数据）
      const overallConsume = raw['overall_consume'] as RawMaterialItem[] | undefined;
      if (overallConsume !== undefined && overallConsume.length > 0) {
        // 单角色请求存储的格式：overall_consume 包含所有材料
        computeItem.avatarConsume = GenshinComputeParser.parseMaterials(overallConsume);
      } else {
        // 批量请求存储的格式：avatar_consume 已合并 lack_num
        const avatarConsume = raw['avatar_consume'] as RawMaterialItem[] | undefined;
        computeItem.avatarConsume = GenshinComputeParser.parseMaterials(avatarConsume);
        
        // 技能材料
        const skillConsume = raw['skill_consume'] as RawMaterialItem[] | undefined;
        const avatarSkillConsume = raw['avatar_skill_consume'] as RawMaterialItem[] | undefined;
        computeItem.skillConsume = GenshinComputeParser.parseMaterials(skillConsume ?? avatarSkillConsume);
        
        // 武器材料
        const weaponConsume = raw['weapon_consume'] as RawMaterialItem[] | undefined;
        computeItem.weaponConsume = GenshinComputeParser.parseMaterials(weaponConsume);
      }
      
      return computeItem;
    } catch (_e) {
      return null;
    }
  }

  private static fromRaw(raw: RawComputeData): GenshinComputeItem[] {
    const result: GenshinComputeItem[] = [];
    
    // 兼容 items 和 list 两种字段名
    const items = raw.items ?? raw.list ?? [];
    if (items.length === 0) {
      return result;
    }

    // 从 overall_consume 提取真实的材料缺口数据
    const overallConsume = raw.overall_consume ?? [];

    for (let i = 0; i < items.length; i++) {
      const item = items[i];
      const computeItem = GenshinComputeParser.fromRawItem(item);
      if (computeItem !== null) {
        // 如果有 overall_consume，用它覆盖 avatarConsume（更准确）
        if (overallConsume.length > 0 && i === 0) {
          // overall_consume 是汇总数据，只赋给第一个 item（代表整个计算结果）
          computeItem.avatarConsume = GenshinComputeParser.parseMaterials(overallConsume);
        }
        result[result.length] = computeItem;
      }
    }

    return result;
  }

  private static fromRawItem(item: RawComputeItem): GenshinComputeItem | null {
    const computeItem = new GenshinComputeItem();

    // avatar_id 可能是 string 或 number
    if (typeof item.avatar_id === 'number') {
      computeItem.avatarId = `${item.avatar_id}`;
    } else {
      computeItem.avatarId = item.avatar_id ?? '';
    }

    computeItem.avatarConsume = GenshinComputeParser.parseMaterials(item.avatar_consume);

    // 兼容两种字段名：skill_consume（实际返回）和 avatar_skill_consume（文档）
    const skillConsume = item.skill_consume ?? item.avatar_skill_consume;
    computeItem.skillConsume = GenshinComputeParser.parseMaterials(skillConsume);

    computeItem.weaponConsume = GenshinComputeParser.parseMaterials(item.weapon_consume);
    computeItem.skillsConsume = GenshinComputeParser.parseSkillsConsume(item.skills_consume);

    return computeItem;
  }

  private static parseMaterials(raws: RawMaterialItem[] | undefined): GenshinMaterialItem[] {
    const result: GenshinMaterialItem[] = [];
    if (!raws || raws.length === 0) {
      return result;
    }

    for (let i = 0; i < raws.length; i++) {
      const r = raws[i];
      const item = new GenshinMaterialItem();
      item.id = r.id;
      item.name = r.name;
      item.icon = r.icon;
      item.iconUrl = r.icon;  // 兼容字段
      item.num = r.num;
      item.lackNum = r.lack_num ?? 0;
      item.level = r.level ?? r.rarity;
      item.rarity = r.rarity ?? r.level;  // 兼容两种字段名
      result[result.length] = item;
    }

    return result;
  }

  private static parseSkillsConsume(raws: RawSkillConsume[] | undefined): GenshinSkillConsumeItem[] {
    const result: GenshinSkillConsumeItem[] = [];
    if (!raws || raws.length === 0) {
      return result;
    }

    for (let i = 0; i < raws.length; i++) {
      const r = raws[i];
      const item = new GenshinSkillConsumeItem();
      item.skillId = r.skill_info.id;
      item.levelCurrent = parseInt(r.skill_info.level_current, 10) || 1;
      item.levelTarget = parseInt(r.skill_info.level_target, 10) || 10;
      item.consumeList = GenshinComputeParser.parseMaterials(r.consume_list);
      result[result.length] = item;
    }

    return result;
  }
}
