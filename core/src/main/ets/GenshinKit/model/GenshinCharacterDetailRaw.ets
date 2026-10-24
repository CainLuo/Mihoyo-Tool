/**
 * GenshinCharacterDetailRaw — 原神角色详情 API 响应的 rawJson 数据结构
 *
 * 对应接口：GET /game_record/app/genshin/api/character/detail
 * 数据来源：GenshinCharacterDetailRow.rawJson（DB 存储的原始 API 响应）
 *
 * 字段说明：
 *   base         — 角色基础信息（id/name/element/level/rarity/命座数等）
 *   weapon       — 装备的武器（含主词条/副词条）
 *   relics       — 圣遗物列表（最多5件，含主词条/副词条列表）
 *   skills       — 技能列表（普攻/战技/爆发，取前3个）
 *   constellations — 命座列表（6个，含激活状态）
 *   selected_properties — 选中展示的属性列表（HP/ATK/DEF/EM/暴击率等）
 */

export interface GenshinRawWeaponProperty {
  property_type: number;
  final: string;
}

export interface GenshinRawWeapon {
  name: string;
  icon: string;
  level: number;
  affix_level: number;
  rarity: number;
  main_property: GenshinRawWeaponProperty;
  sub_property: GenshinRawWeaponProperty;
}

export interface GenshinRawRelicSubStat {
  property_type: number;
  value: string;
}

export interface GenshinRawRelicMainProp {
  property_type: number;
  value: string;
}

export interface GenshinRawRelicSet {
  name: string;
}

export interface GenshinRawRelic {
  pos: number;
  icon: string;
  set: GenshinRawRelicSet;
  level: number;
  rarity: number;
  main_property: GenshinRawRelicMainProp;
  sub_property_list: GenshinRawRelicSubStat[];
}

export interface GenshinRawSkill {
  name: string;
  icon: string;
  level: number;
  /** 技能类型：1=可升级技能（普攻、E、Q），2=固有天赋/被动 */
  skill_type?: number;
}

export interface GenshinRawConstellation {
  pos: number;
  name: string;
  icon: string;
  effect: string;
  is_actived: boolean;
}

export interface GenshinRawProperty {
  property_type: number;
  final: string;
}

export interface GenshinRawBase {
  id: number;
  name: string;
  icon: string;
  element: string;
  fetter: number;
  level: number;
  rarity: number;
  actived_constellation_num: number;
  image: string;
}

/** 原神角色详情 rawJson 根结构 */
export interface GenshinCharacterDetailRaw {
  base: GenshinRawBase;
  weapon: GenshinRawWeapon;
  relics: GenshinRawRelic[];
  skills: GenshinRawSkill[];
  constellations: GenshinRawConstellation[];
  selected_properties: GenshinRawProperty[];
}
