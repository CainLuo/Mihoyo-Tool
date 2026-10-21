/**
 * StarRailAvatarDetailRaw — 星穹铁道角色详情 API 响应的 rawJson 数据结构
 *
 * 对应接口：GET /game_record/app/hkrpg/api/avatar/info
 * 数据来源：StarRailAvatarInfoRow.rawJson（DB 存储的原始 API 响应）
 *
 * 字段说明：
 *   ranks      — 命座列表（6个，含激活状态）
 *   skills     — 行迹节点列表（按 point_type 分三组：1=属性加成/2=主技能/3=额外能力）
 *   equip      — 光锥（可为 null）
 *   relics     — 遗器（pos 1-4）
 *   ornaments  — 饰品（pos 5-6）
 *   properties — 属性列表（含 base/add/final）
 */

export interface StarRailRawRankItem {
  id: number;
  pos: number;
  name: string;
  icon: string;
  desc: string;
  is_unlocked: boolean;
}

export interface StarRailRawRelicProperty {
  property_type: number;
  value: string;
  times: number;
}

export interface StarRailRawRelic {
  id: number;
  level: number;
  pos: number;
  name: string;
  desc: string;
  icon: string;
  rarity: number;
  main_property: StarRailRawRelicProperty;
  properties: StarRailRawRelicProperty[];
}

export interface StarRailRawEquip {
  id: number;
  level: number;
  rank: number;
  name: string;
  desc: string;
  icon: string;
  rarity: number;
}

export interface StarRailRawProperty {
  property_type: number;
  base: string;
  add: string;
  final: string;
}

export interface StarRailRawSkillStage {
  name: string;
  desc: string;
  level: number;
  remake: string;
  item_url: string;
  is_activated: boolean;
}

export interface StarRailRawSkillNode {
  point_id: string;
  /** 1=属性加成，2=主技能，3=额外能力 */
  point_type: number;
  item_url: string;
  level: number;
  is_activated: boolean;
  is_rank_work: boolean;
  pre_point: string;
  anchor: string;
  remake: string;
  skill_stages: StarRailRawSkillStage[];
}

/** 星穹铁道角色详情 rawJson 根结构 */
export interface StarRailAvatarDetailRaw {
  id: number;
  level: number;
  name: string;
  element: string;
  icon: string;
  rarity: number;
  rank: number;
  image: string;
  equip: StarRailRawEquip | null;
  relics: StarRailRawRelic[];
  ornaments: StarRailRawRelic[];
  ranks: StarRailRawRankItem[];
  properties: StarRailRawProperty[];
  skills: StarRailRawSkillNode[];
}
