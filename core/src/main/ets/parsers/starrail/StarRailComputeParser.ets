/**
 * StarRailComputeParser.ets
 *
 * 解析星穹铁道养成计算 API 响应，提取材料消耗数据和玩家背包数据。
 * 星铁 API 特有：返回 user_owns_materials 字段，包含玩家真实背包数据。
 */

// ─── 纯数据模型（core 对外暴露）────────────────────────────────

/** 单个材料项 */
export class StarRailMaterialItem {
  itemId: string = '';      // 星铁使用字符串 ID
  itemName: string = '';
  itemUrl: string = '';
  num: number = 0;         // 所需数量
  rarity: string = '';     // 星铁返回字符串 "2", "3", "4"
  itemPurpose: string = ''; // 材料用途描述
  
  // 兼容字段（映射到标准字段名）
  get id(): string { return this.itemId; }
  get name(): string { return this.itemName; }
  get iconUrl(): string { return this.itemUrl; }
}

/** 星铁计算结果 */
export class StarRailComputeData {
  /** 角色本体升级材料 */
  avatarConsume: StarRailMaterialItem[] = [];

  /** 技能升级材料 */
  skillConsume: StarRailMaterialItem[] = [];

  /** 光锥升级材料 */
  equipmentConsume: StarRailMaterialItem[] = [];

  /** 玩家拥有的材料（背包数据） */
  userOwnsMaterials: Map<string, number> = new Map();
}

// ─── JSON 接口声明（仅用于 parse）────────────────────────────

interface RawMaterialItem {
  item_id: string;
  item_name: string;
  item_url: string;
  num: number;
  rarity: string;
  item_purpose: string;
}

interface RawComputeData {
  avatar_consume: RawMaterialItem[];
  skill_consume: RawMaterialItem[];
  equipment_consume: RawMaterialItem[];
  user_owns_materials: Record<string, number>;
}

// ─── Parser ──────────────────────────────────────────────────────

export class StarRailComputeParser {

  /**
   * 解析单角色计算 API 响应
   * @param rawJson API 返回的 data 部分 JSON 字符串
   * @returns 角色计算结果
   */
  static parse(rawJson: string): StarRailComputeData {
    try {
      const raw = JSON.parse(rawJson) as RawComputeData;
      return StarRailComputeParser.fromRaw(raw);
    } catch (_e) {
      return new StarRailComputeData();
    }
  }

  private static fromRaw(raw: RawComputeData): StarRailComputeData {
    const data = new StarRailComputeData();

    data.avatarConsume = StarRailComputeParser.parseMaterials(raw.avatar_consume);
    data.skillConsume = StarRailComputeParser.parseMaterials(raw.skill_consume);
    data.equipmentConsume = StarRailComputeParser.parseMaterials(raw.equipment_consume);

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

  private static parseMaterials(raws: RawMaterialItem[]): StarRailMaterialItem[] {
    const result: StarRailMaterialItem[] = [];
    if (!raws || raws.length === 0) {
      return result;
    }

    for (let i = 0; i < raws.length; i++) {
      const r = raws[i];
      const item = new StarRailMaterialItem();
      item.itemId = r.item_id;
      item.itemName = r.item_name;
      item.itemUrl = r.item_url;
      item.num = r.num;
      item.rarity = r.rarity;
      item.itemPurpose = r.item_purpose ?? '';
      result[result.length] = item;
    }

    return result;
  }
}
