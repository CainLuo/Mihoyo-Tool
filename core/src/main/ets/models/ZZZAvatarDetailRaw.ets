/**
 * ZZZAvatarDetailRaw — 绝区零代理人详情 API 响应的 rawJson 数据结构
 *
 * 对应接口：GET /event/game_record_zzz/api/zzz/avatar/info?id_list[]=xxx
 * 数据来源：ZZZAvatarInfoRow.rawJson（DB 存储的原始 API 响应）
 *
 * 字段说明：
 *   ranks      — 影画列表（6个，含激活状态）
 *   skills     — 技能列表（按 skill_type 分组）
 *   weapon     — 音擎（可为 null）
 *   equip      — 驱动盘列表（最多6件，含主词条/副词条/套装信息）
 *   properties — 属性列表（含 base/add/final）
 */

export interface ZZZRawRankItem {
  id: number;
  pos: number;
  name: string;
  desc: string;
  is_unlocked: boolean;
}

export interface ZZZRawSkillItem {
  title: string;
  text: string;
  awaken: boolean;
}

export interface ZZZRawSkill {
  level: number;
  /** 技能类型：0=普攻/1=特殊技/2=闪避/3=连携技/5=核心被动/6=支援技 */
  skill_type: number;
  items: ZZZRawSkillItem[];
  awaken_state: string;
}

export interface ZZZRawWeaponProperty {
  property_name: string;
  property_id: number;
  base: string;
}

export interface ZZZRawWeapon {
  id: number;
  level: number;
  name: string;
  star: number;
  icon: string;
  rarity: string;
  talent_title: string;
  talent_content: string;
  main_properties: ZZZRawWeaponProperty[];
  properties: ZZZRawWeaponProperty[];
}

export interface ZZZRawEquipProperty {
  property_name: string;
  property_id: number;
  base: string;
  level: number;
  /** true=有效词条（高亮显示） */
  valid: boolean;
  system_id: number;
  add: number;
}

export interface ZZZRawEquipSuit {
  suit_id: number;
  name: string;
  /** 套装总件数（2件套或4件套） */
  own: number;
  desc1: string;
  desc2: string;
}

export interface ZZZRawEquip {
  id: number;
  level: number;
  name: string;
  icon: string;
  rarity: string;
  properties: ZZZRawEquipProperty[];
  main_properties: ZZZRawEquipProperty[];
  equip_suit: ZZZRawEquipSuit;
  /** 驱动盘槽位编号（1-6） */
  equipment_type: number;
}

export interface ZZZRawProperty {
  property_name: string;
  property_id: number;
  base: string;
  add: string;
  final: string;
}

/** 绝区零代理人详情 rawJson 根结构 */
export interface ZZZAvatarDetailRaw {
  id: number;
  level: number;
  name_mi18n: string;
  full_name_mi18n: string;
  element_type: number;
  rarity: string;
  rank: number;
  ranks: ZZZRawRankItem[];
  skills: ZZZRawSkill[];
  weapon: ZZZRawWeapon | null;
  equip: ZZZRawEquip[];
  properties: ZZZRawProperty[];
  role_vertical_painting_url: string;
}
