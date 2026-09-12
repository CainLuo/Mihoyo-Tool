/**
 * StarRailComputeParser.ets
 *
 * 解析星穹铁道养成计算 API 响应，提取材料消耗数据和玩家背包数据。
 * 星铁 API 特有：返回 user_owns_materials 字段，包含玩家真实背包数据。
 */

import { Logger } from '../../utils/Logger';

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

  /** 仍需获取的材料（API 计算好的差值） */
  needGetMaterials: StarRailMaterialItem[] = [];
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
  need_get_materials: RawMaterialItem[];
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
      // 打印完整 rawJson 用于调试（分 1000 字符一段，避免日志截断）
      Logger.info('StarRailComputeParser', `💥💥💥 RAW_JSON_START length=${rawJson.length}`);
      for (let i = 0; i < rawJson.length; i += 1000) {
        const chunk = rawJson.substring(i, Math.min(i + 1000, rawJson.length));
        Logger.info('StarRailComputeParser', `💥💥💥 RAW_JSON[${i}]: ${chunk}`);
      }
      Logger.info('StarRailComputeParser', `💥💥💥 RAW_JSON_END`);
      
      const raw = JSON.parse(rawJson) as RawComputeData;
      return StarRailComputeParser.fromRaw(raw);
    } catch (_e) {
      Logger.error('StarRailComputeParser', `💥💥💥 PARSE_ERROR: ${String(_e)}`);
      return new StarRailComputeData();
    }
  }

  private static fromRaw(raw: RawComputeData): StarRailComputeData {
    const data = new StarRailComputeData();

    // 先解析 user_owns_materials（背包数据）
    if (raw.user_owns_materials) {
      const keys = Object.keys(raw.user_owns_materials);
      for (let i = 0; i < keys.length; i++) {
        const key = keys[i];
        data.userOwnsMaterials.set(key, raw.user_owns_materials[key]);
      }
    }

    // 解析材料
    data.avatarConsume = StarRailComputeParser.parseMaterials(raw.avatar_consume);
    data.skillConsume = StarRailComputeParser.parseMaterials(raw.skill_consume);
    data.equipmentConsume = StarRailComputeParser.parseMaterials(raw.equipment_consume);

    // 解析 need_get_materials（仍需获取的材料）
    if (raw.need_get_materials) {
      data.needGetMaterials = StarRailComputeParser.parseMaterials(raw.need_get_materials);
    }

    return data;
  }

  /**
   * 解析材料列表。
   * 
   * 注意：星铁 API 不返回 lack_num，只返回 num（需求量）。
   * 缺少数量在汇总时计算：总缺口 = Σ(num) - userOwnsMaterials[id]
   */
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
