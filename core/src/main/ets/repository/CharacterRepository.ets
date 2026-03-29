/**
 * CharacterRepository.ets
 *
 * 角色数据 Repository，封装所有角色相关的查询语义。
 * 支持原神、崩坏：星穹铁道、绝区零三款游戏。
 *
 * 字段映射（character data_type）：
 *   entity_id   = 角色 ID（字符串）
 *   name        = 角色名称
 *   rarity      = 星级（原神/星铁为数字；绝区零 S=5, A=4）
 *   level       = 等级
 *   extra_int1  = 命座/星魂/影画数（actived_constellation_num / rank）
 *   extra_int2  = 好感度（原神 fetter；星铁/绝区零填 0）
 *   extra_text1 = 元素属性（原神 element；星铁 element；绝区零 element_type 数字字符串）
 *   extra_text2 = 扩展信息（原神 weapon_type；星铁 base_type 命途；绝区零 avatar_profession 职业）
 *   raw_json    = 合并了 detail 数据的完整存储 JSON
 */

import { GameDataDao } from '../database/GameDataDao';
import { GameStatsDao } from '../database/GameStatsDao';
import { SyncMetaDao } from '../database/SyncMetaDao';
import { QueryBuilder } from '../database/QueryBuilder';
import { GameDataSummary, GameDataRow, DataType } from '../models/GameDataRow';
import { ScoredEntity, StatKey } from '../models/GameStatsRow';
import { NetworkFactory } from '../network/NetworkFactory';
import { RequestOptions, RequestParams } from '../network/APIs';

// ─── API 路径 ────────────────────────────────────────────────────
const API_GENSHIN_CHARACTER_LIST = '/game_record/app/genshin/api/character/list';
const API_GENSHIN_CHARACTER_DETAIL = '/game_record/app/genshin/api/character/detail';
const API_STARRAIL_CHARACTER_LIST = '/game_record/app/hkrpg/api/avatar/basic';
const API_STARRAIL_CHARACTER_DETAIL = '/game_record/app/hkrpg/api/avatar/info';
const API_ZZZ_CHARACTER_LIST = '/event/game_record_zzz/api/zzz/avatar/basic';
const API_ZZZ_CHARACTER_DETAIL = '/event/game_record_zzz/api/zzz/avatar/info';

// ─── 原神接口类型 ────────────────────────────────────────────────

interface GenshinWeapon {
  id: number;
  name: string;
  icon: string;
  type: number;
  rarity: number;
  level: number;
  affix_level: number;
}

interface GenshinCharacterListItem {
  id: number;
  name: string;
  element: string;
  fetter: number;
  level: number;
  rarity: number;
  actived_constellation_num: number;
  icon: string;
  image: string;
  side_icon: string;
  weapon_type: number;
  weapon: GenshinWeapon;
}

interface GenshinCharacterListData {
  list: GenshinCharacterListItem[];
}

interface GenshinCharacterListResponse {
  retcode: number;
  message: string;
  data: GenshinCharacterListData;
}

interface GenshinRawProperty {
  property_type: number;
  base: string;
  add: string;
  final: string;
}

interface GenshinDetailWeapon {
  id: number;
  name: string;
  icon: string;
  type: number;
  rarity: number;
  level: number;
  affix_level: number;
  main_property: GenshinRawProperty;
  sub_property: GenshinRawProperty;
}

interface GenshinRelicMainProp {
  property_type: number;
  value: string;
  times: number;
}

interface GenshinRelicSubProp {
  property_type: number;
  value: string;
  times: number;
}

interface GenshinRelicSet {
  id: number;
  name: string;
}

interface GenshinRelic {
  id: number;
  name: string;
  icon: string;
  pos: number;
  rarity: number;
  level: number;
  set: GenshinRelicSet;
  pos_name: string;
  main_property: GenshinRelicMainProp;
  sub_property_list: GenshinRelicSubProp[];
}

interface GenshinSkill {
  skill_type: number;
  level: number;
  icon: string;
}

interface GenshinConstellation {
  id: number;
  name: string;
  icon: string;
  effect: string;
  is_actived: boolean;
  pos: number;
}

interface GenshinSelectedProperty {
  property_type: number;
  base: string;
  add: string;
  final: string;
}

interface GenshinCharacterDetailItem {
  base: GenshinCharacterListItem;
  weapon: GenshinDetailWeapon;
  relics: GenshinRelic[];
  skills: GenshinSkill[];
  selected_properties: GenshinSelectedProperty[];
  constellations: GenshinConstellation[];
}

interface GenshinCharacterDetailData {
  list: GenshinCharacterDetailItem[];
}

interface GenshinCharacterDetailResponse {
  retcode: number;
  message: string;
  data: GenshinCharacterDetailData;
}

// ─── 原神存储结构 ────────────────────────────────────────────────

interface GenshinStorageSubStat {
  property_type: number;
  value: string;
}

interface GenshinStorageRelic {
  pos: number;
  icon: string;
  set_name: string;
  level: number;
  rarity: number;
  main_property_type: number;
  main_property_value: string;
  sub_stats: GenshinStorageSubStat[];
}

interface GenshinStorageProperty {
  property_type: number;
  final: string;
}

interface GenshinStorageConstellation {
  pos: number;
  name: string;
  icon: string;
  effect: string;
  is_actived: boolean;
}

interface GenshinCharacterStorage {
  id: number;
  name: string;
  element: string;
  fetter: number;
  level: number;
  rarity: number;
  actived_constellation_num: number;
  icon: string;
  image: string;
  side_icon: string;
  weapon_type: number;
  weapon: GenshinWeapon;
  weapon_base_atk: string;
  weapon_sub_type: number;
  weapon_sub_val: string;
  relics_detail: GenshinStorageRelic[];
  relic_icons: string[];
  skill_levels: number[];
  skill_icons: string[];
  selected_properties: GenshinStorageProperty[];
  constellations_detail: GenshinStorageConstellation[];
}

// ─── 星穹铁道接口类型 ────────────────────────────────────────────

interface StarRailEquip {
  id: number;
  level: number;
  rank: number;
  name: string;
  icon: string;
  rarity: number;
}

interface StarRailCharacterListItem {
  id: number;
  level: number;
  name: string;
  element: string;
  icon: string;
  rarity: number;
  rank: number;
  base_type: number;
  figure_path: string;
  element_id: number;
  equip: StarRailEquip | null;
}

interface StarRailCharacterListData {
  avatar_list: StarRailCharacterListItem[];
}

interface StarRailCharacterListResponse {
  retcode: number;
  message: string;
  data: StarRailCharacterListData;
}

interface StarRailRelicMainProp {
  property_type: number;
  value: string;
  times: number;
}

interface StarRailRelicSubProp {
  property_type: number;
  value: string;
  times: number;
}

interface StarRailRelic {
  id: number;
  level: number;
  pos: number;
  name: string;
  icon: string;
  rarity: number;
  main_property: StarRailRelicMainProp;
  properties: StarRailRelicSubProp[];
}

interface StarRailOrnament {
  id: number;
  level: number;
  pos: number;
  name: string;
  icon: string;
  rarity: number;
  main_property: StarRailRelicMainProp;
  properties: StarRailRelicSubProp[];
}

interface StarRailRank {
  id: number;
  pos: number;
  name: string;
  icon: string;
  desc: string;
  is_unlocked: boolean;
}

interface StarRailProperty {
  property_type: number;
  base: string;
  add: string;
  final: string;
}

interface StarRailSkillStage {
  name: string;
  level: number;
  remake: string;
  item_url: string;
  is_activated: boolean;
}

interface StarRailSkill {
  point_id: string;
  point_type: number;
  item_url: string;
  level: number;
  is_activated: boolean;
  remake: string;
  skill_stages: StarRailSkillStage[];
}

interface StarRailCharacterDetailItem {
  id: number;
  level: number;
  name: string;
  element: string;
  icon: string;
  rarity: number;
  rank: number;
  image: string;
  equip: StarRailEquip | null;
  relics: StarRailRelic[];
  ornaments: StarRailOrnament[];
  ranks: StarRailRank[];
  properties: StarRailProperty[];
  skills: StarRailSkill[];
  base_type: number;
  figure_path: string;
  element_id: number;
}

interface StarRailCharacterDetailData {
  avatar_list: StarRailCharacterDetailItem[];
}

interface StarRailCharacterDetailResponse {
  retcode: number;
  message: string;
  data: StarRailCharacterDetailData;
}

// ─── 星穹铁道存储结构 ────────────────────────────────────────────

interface StarRailStorageSubStat {
  property_type: number;
  value: string;
}

interface StarRailStorageRelic {
  pos: number;
  icon: string;
  name: string;
  level: number;
  rarity: number;
  main_property_type: number;
  main_property_value: string;
  sub_stats: StarRailStorageSubStat[];
}

interface StarRailStorageProperty {
  property_type: number;
  final: string;
}

interface StarRailCharacterStorage {
  id: number;
  name: string;
  element: string;
  element_id: number;
  level: number;
  rarity: number;
  rank: number;
  base_type: number;
  icon: string;
  figure_path: string;
  equip: StarRailEquip | null;
  relics_detail: StarRailStorageRelic[];
  relic_icons: string[];
  skill_levels: number[];
  skill_icons: string[];
  properties: StarRailStorageProperty[];
  ranks: StarRailRank[];
}

// ─── 绝区零接口类型 ────────────────────────────────────────────

interface ZZZCharacterListItem {
  id: number;
  level: number;
  name_mi18n: string;
  full_name_mi18n: string;
  element_type: number;
  camp_name_mi18n: string;
  avatar_profession: number;
  rarity: string;
  group_icon_path: string;
  hollow_icon_path: string;
  rank: number;
  role_square_url: string;
  awaken_state: string;
}

interface ZZZCharacterListData {
  avatar_list: ZZZCharacterListItem[];
}

interface ZZZCharacterListResponse {
  retcode: number;
  message: string;
  data: ZZZCharacterListData;
}

interface ZZZEquipProperty {
  property_name: string;
  property_id: number;
  base: string;
  level: number;
  valid: boolean;
  system_id: number;
  add: number;
}

interface ZZZEquipSuit {
  suit_id: number;
  name: string;
  own: number;
  desc1: string;
  desc2: string;
}

interface ZZZEquip {
  id: number;
  level: number;
  name: string;
  icon: string;
  rarity: string;
  properties: ZZZEquipProperty[];
  main_properties: ZZZEquipProperty[];
  equip_suit: ZZZEquipSuit;
  equipment_type: number;
}

interface ZZZWeaponProperty {
  property_name: string;
  property_id: number;
  base: string;
  level: number;
  valid: boolean;
  system_id: number;
  add: number;
}

interface ZZZWeapon {
  id: number;
  level: number;
  name: string;
  star: number;
  icon: string;
  rarity: string;
  properties: ZZZWeaponProperty[];
  main_properties: ZZZWeaponProperty[];
  talent_title: string;
  talent_content: string;
  profession: number;
}

interface ZZZCharacterProperty {
  property_name: string;
  property_id: number;
  base: string;
  add: string;
  final: string;
}

interface ZZZSkillItem {
  title: string;
  text: string;
  awaken: boolean;
}

interface ZZZSkill {
  level: number;
  skill_type: number;
  items: ZZZSkillItem[];
}

interface ZZZRank {
  id: number;
  name: string;
  desc: string;
  pos: number;
  is_unlocked: boolean;
}

interface ZZZCharacterDetailItem {
  id: number;
  level: number;
  name_mi18n: string;
  full_name_mi18n: string;
  element_type: number;
  camp_name_mi18n: string;
  avatar_profession: number;
  rarity: string;
  group_icon_path: string;
  hollow_icon_path: string;
  rank: number;
  role_square_url: string;
  equip: ZZZEquip[];
  weapon: ZZZWeapon;
  properties: ZZZCharacterProperty[];
  skills: ZZZSkill[];
  ranks: ZZZRank[];
  role_vertical_painting_url: string;
}

interface ZZZCharacterDetailData {
  avatar_list: ZZZCharacterDetailItem[];
}

interface ZZZCharacterDetailResponse {
  retcode: number;
  message: string;
  data: ZZZCharacterDetailData;
}

// ─── 绝区零存储结构 ────────────────────────────────────────────

interface ZZZStorageEquipSubStat {
  property_id: number;
  property_name: string;
  base: string;
  valid: boolean;
}

interface ZZZStorageEquip {
  equipment_type: number;
  id: number;
  name: string;
  icon: string;
  rarity: string;
  level: number;
  suit_id: number;
  suit_name: string;
  main_property_id: number;
  main_property_value: string;
  sub_stats: ZZZStorageEquipSubStat[];
}

interface ZZZStorageProperty {
  property_id: number;
  property_name: string;
  final: string;
}

interface ZZZCharacterStorage {
  id: number;
  name: string;
  full_name: string;
  element_type: number;
  camp_name: string;
  avatar_profession: number;
  rarity: string;
  rarity_num: number;
  level: number;
  rank: number;
  icon: string;
  square_icon: string;
  vertical_painting_url: string;
  weapon: ZZZWeapon | null;
  equip_list: ZZZStorageEquip[];
  relic_icons: string[];
  skill_levels: number[];
  properties: ZZZStorageProperty[];
  ranks: ZZZRank[];
}

// ─── 通用响应 ────────────────────────────────────────────────────

interface ApiResponse {
  retcode: number;
  message: string;
}

// ─── Repository ──────────────────────────────────────────────────

export class CharacterRepository {

  /**
   * 查询角色摘要列表（不含 raw_json），按稀有度+等级降序。
   */
  static async findAll(gameId: string, roleUid: string): Promise<GameDataSummary[]> {
    const builder = new QueryBuilder('game_data')
      .equalTo('game_id', gameId)
      .equalTo('role_uid', roleUid)
      .equalTo('data_type', DataType.CHARACTER)
      .orderByDesc('rarity');
    const rows = await GameDataDao.findByBuilder(builder);
    const summaries: GameDataSummary[] = [];
    for (let i = 0; i < rows.length; i++) {
      const row = rows[i];
      const s = CharacterRepository.rowToSummary(row, gameId);
      summaries[summaries.length] = s;
    }
    return summaries;
  }

  /** 查询单个角色完整数据（含 raw_json），适用于详情页。 */
  static async findById(gameId: string, roleUid: string, entityId: string): Promise<GameDataRow | null> {
    return GameDataDao.findOne(gameId, roleUid, DataType.CHARACTER, entityId);
  }

  /** 按元素属性过滤角色。 */
  static async findByElement(gameId: string, roleUid: string, element: string): Promise<GameDataSummary[]> {
    return GameDataDao.findSummaries(gameId, roleUid, DataType.CHARACTER, 'level', true)
      .then(rows => rows.filter(r => r.extraText1 === element));
  }

  /** 按稀有度过滤角色。 */
  static async findByRarity(gameId: string, roleUid: string, rarity: number): Promise<GameDataSummary[]> {
    const builder = new QueryBuilder('game_data')
      .equalTo('game_id', gameId)
      .equalTo('role_uid', roleUid)
      .equalTo('data_type', DataType.CHARACTER)
      .equalTo('rarity', rarity)
      .orderByDesc('level');
    return GameDataDao.findSummariesByBuilder(builder);
  }

  /** 按装备分排行，返回前 N 名角色。 */
  static async findTopByRelicScore(gameId: string, roleUid: string, topN?: number): Promise<ScoredEntity[]> {
    return GameStatsDao.findRanking(gameId, roleUid, StatKey.RELIC_SCORE, topN);
  }

  /** 查询未毕业的角色列表。 */
  static async findNotGraduated(gameId: string, roleUid: string): Promise<ScoredEntity[]> {
    return GameStatsDao.findNotGraduated(gameId, roleUid);
  }

  /** 按名称搜索角色（跨游戏）。 */
  static async search(keyword: string, gameId?: string): Promise<GameDataSummary[]> {
    return GameDataDao.searchByName(keyword, gameId, DataType.CHARACTER);
  }

  /** 全量写入角色数据。 */
  static async saveAll(rows: GameDataRow[]): Promise<void> {
    return GameDataDao.batchUpsert(rows);
  }

  /** 清空指定游戏+用户的所有角色数据。 */
  static async clearAll(gameId: string, roleUid: string): Promise<void> {
    await GameDataDao.deleteByType(gameId, roleUid, DataType.CHARACTER);
  }

  /**
   * 从网络拉取角色数据并写入 DB。
   * 支持 genshin / starrail / zzz 三款游戏。
   */
  static async syncCharacters(
    gameId: string,
    roleUid: string,
    server: string,
    cookie: string
  ): Promise<void> {
    if (gameId === 'genshin') {
      await CharacterRepository.syncGenshinCharacters(roleUid, server, cookie);
    } else if (gameId === 'starrail') {
      await CharacterRepository.syncStarRailCharacters(roleUid, server, cookie);
    } else if (gameId === 'zzz') {
      await CharacterRepository.syncZZZCharacters(roleUid, server, cookie);
    } else {
      throw new Error(`CharacterRepository.syncCharacters: unsupported gameId "${gameId}"`);
    }
  }

  // ─── 私有：原神同步 ──────────────────────────────────────────

  private static async syncGenshinCharacters(roleUid: string, server: string, cookie: string): Promise<void> {
    const gameId = 'genshin';
    try { await SyncMetaDao.markSyncing(gameId, roleUid, DataType.CHARACTER); } catch (_) {}

    const options = new RequestOptions();
    options.extraHeaders.set('Cookie', cookie);

    const listParams = new RequestParams();
    listParams.set('role_id', roleUid);
    listParams.set('server', server);
    listParams.set('sort_type', 1);

    let listRaw: object;
    try {
      listRaw = await NetworkFactory.getInstance().post(API_GENSHIN_CHARACTER_LIST, listParams, options);
    } catch (error) {
      const msg = error instanceof Error ? error.message : `${error}`;
      try { await SyncMetaDao.markFailed(gameId, roleUid, DataType.CHARACTER, msg); } catch (_) {}
      throw new Error(msg);
    }

    const listResp = listRaw as GenshinCharacterListResponse;
    if (listResp.retcode !== 0) {
      const errMsg = `CharacterRepository(genshin): retcode=${listResp.retcode} ${listResp.message}`;
      try { await SyncMetaDao.markFailed(gameId, roleUid, DataType.CHARACTER, errMsg); } catch (_) {}
      throw new Error(errMsg);
    }

    const items = listResp.data.list;
    const now = Math.floor(Date.now() / 1000);

    // 拉取 detail（批量，传所有角色 ID）
    const charIds: string[] = [];
    for (let i = 0; i < items.length; i++) {
      charIds[charIds.length] = `${items[i].id}`;
    }

    const detailParams = new RequestParams();
    detailParams.set('role_id', roleUid);
    detailParams.set('server', server);
    detailParams.set('character_ids', charIds.join(','));

    // detail 数据 map，key = 角色 id 字符串
    const relicIconsMap: Record<string, string[]> = {};
    const relicsDetailMap: Record<string, GenshinStorageRelic[]> = {};
    const skillLevelsMap: Record<string, number[]> = {};
    const skillIconsMap: Record<string, string[]> = {};
    const selectedPropsMap: Record<string, GenshinStorageProperty[]> = {};
    const weaponBaseAtkMap: Record<string, string> = {};
    const weaponSubTypeMap: Record<string, number> = {};
    const weaponSubValMap: Record<string, string> = {};
    const constellationsMap: Record<string, GenshinStorageConstellation[]> = {};

    try {
      const detailRaw = await NetworkFactory.getInstance().post(API_GENSHIN_CHARACTER_DETAIL, detailParams, options);
      const detailResp = detailRaw as GenshinCharacterDetailResponse;
      if (detailResp.retcode === 0 && detailResp.data && detailResp.data.list) {
        for (let i = 0; i < detailResp.data.list.length; i++) {
          const d = detailResp.data.list[i];
          const cid = `${d.base.id}`;
          if (d.weapon) {
            weaponBaseAtkMap[cid] = d.weapon.main_property ? d.weapon.main_property.final : '';
            weaponSubTypeMap[cid] = d.weapon.sub_property ? d.weapon.sub_property.property_type : 0;
            weaponSubValMap[cid] = d.weapon.sub_property ? d.weapon.sub_property.final : '';
          }
          const icons: string[] = [];
          const relicsDetail: GenshinStorageRelic[] = [];
          if (d.relics) {
            for (let j = 0; j < d.relics.length; j++) {
              const r = d.relics[j];
              icons[icons.length] = r.icon;
              const subs: GenshinStorageSubStat[] = [];
              if (r.sub_property_list) {
                for (let k = 0; k < r.sub_property_list.length; k++) {
                  subs[subs.length] = { property_type: r.sub_property_list[k].property_type, value: r.sub_property_list[k].value };
                }
              }
              relicsDetail[relicsDetail.length] = {
                pos: r.pos, icon: r.icon, set_name: r.set ? r.set.name : '',
                level: r.level, rarity: r.rarity,
                main_property_type: r.main_property ? r.main_property.property_type : 0,
                main_property_value: r.main_property ? r.main_property.value : '',
                sub_stats: subs
              };
            }
          }
          relicIconsMap[cid] = icons;
          relicsDetailMap[cid] = relicsDetail;
          const levels: number[] = [];
          const sIcons: string[] = [];
          if (d.skills) {
            for (let j = 0; j < d.skills.length; j++) {
              if (d.skills[j].skill_type === 1 && levels.length < 3) {
                levels[levels.length] = d.skills[j].level;
                sIcons[sIcons.length] = d.skills[j].icon;
              }
            }
          }
          skillLevelsMap[cid] = levels;
          skillIconsMap[cid] = sIcons;
          const props: GenshinStorageProperty[] = [];
          if (d.selected_properties) {
            for (let j = 0; j < d.selected_properties.length; j++) {
              props[props.length] = { property_type: d.selected_properties[j].property_type, final: d.selected_properties[j].final };
            }
          }
          selectedPropsMap[cid] = props;
          const consts: GenshinStorageConstellation[] = [];
          if (d.constellations) {
            for (let j = 0; j < d.constellations.length; j++) {
              const c = d.constellations[j];
              consts[consts.length] = { pos: c.pos, name: c.name, icon: c.icon, effect: c.effect, is_actived: c.is_actived };
            }
          }
          constellationsMap[cid] = consts;
        }
      }
    } catch (_) {}

    const rows: GameDataRow[] = [];
    for (let i = 0; i < items.length; i++) {
      const item = items[i];
      const cid = `${item.id}`;
      const storage: GenshinCharacterStorage = {
        id: item.id, name: item.name, element: item.element, fetter: item.fetter,
        level: item.level, rarity: item.rarity,
        actived_constellation_num: item.actived_constellation_num,
        icon: item.icon, image: item.image, side_icon: item.side_icon,
        weapon_type: item.weapon_type, weapon: item.weapon,
        weapon_base_atk: weaponBaseAtkMap[cid] ?? '',
        weapon_sub_type: weaponSubTypeMap[cid] ?? 0,
        weapon_sub_val: weaponSubValMap[cid] ?? '',
        relics_detail: relicsDetailMap[cid] ?? [],
        relic_icons: relicIconsMap[cid] ?? [],
        skill_levels: skillLevelsMap[cid] ?? [],
        skill_icons: skillIconsMap[cid] ?? [],
        selected_properties: selectedPropsMap[cid] ?? [],
        constellations_detail: constellationsMap[cid] ?? [],
      };
      const row = new GameDataRow();
      row.gameId = gameId;
      row.roleUid = roleUid;
      row.dataType = DataType.CHARACTER;
      row.entityId = cid;
      row.name = item.name;
      row.rarity = item.rarity;
      row.level = item.level;
      row.extraInt1 = item.actived_constellation_num;
      row.extraInt2 = item.fetter;
      row.extraText1 = item.element;
      row.extraText2 = `${item.weapon_type}`;
      row.rawJson = JSON.stringify(storage);
      row.updateTime = now;
      rows[rows.length] = row;
    }
    await GameDataDao.batchUpsert(rows);
    try { await SyncMetaDao.markSuccess(gameId, roleUid, DataType.CHARACTER); } catch (_) {}
  }

  // ─── 私有：星穹铁道同步 ──────────────────────────────────────

  private static async syncStarRailCharacters(roleUid: string, server: string, cookie: string): Promise<void> {
    const gameId = 'starrail';
    try { await SyncMetaDao.markSyncing(gameId, roleUid, DataType.CHARACTER); } catch (_) {}

    const options = new RequestOptions();
    options.extraHeaders.set('Cookie', cookie);

    const listParams = new RequestParams();
    listParams.set('role_id', roleUid);
    listParams.set('server', server);
    listParams.set('rolePageAccessNotAllowed', '');

    let listRaw: object;
    try {
      listRaw = await NetworkFactory.getInstance().get(API_STARRAIL_CHARACTER_LIST, listParams, options);
    } catch (error) {
      const msg = error instanceof Error ? error.message : `${error}`;
      try { await SyncMetaDao.markFailed(gameId, roleUid, DataType.CHARACTER, msg); } catch (_) {}
      throw new Error(msg);
    }

    const listResp = listRaw as StarRailCharacterListResponse;
    if (listResp.retcode !== 0) {
      const errMsg = `CharacterRepository(starrail): retcode=${listResp.retcode} ${listResp.message}`;
      try { await SyncMetaDao.markFailed(gameId, roleUid, DataType.CHARACTER, errMsg); } catch (_) {}
      throw new Error(errMsg);
    }

    const items = listResp.data.avatar_list;
    const now = Math.floor(Date.now() / 1000);

    // 逐个拉取 detail（星铁 detail 接口每次只查一个角色）
    const detailMap: Record<string, StarRailCharacterDetailItem> = {};
    for (let i = 0; i < items.length; i++) {
      const detailParams = new RequestParams();
      detailParams.set('role_id', roleUid);
      detailParams.set('server', server);
      detailParams.set('id', items[i].id);
      detailParams.set('need_wiki', 'true');
      try {
        const detailRaw = await NetworkFactory.getInstance().get(API_STARRAIL_CHARACTER_DETAIL, detailParams, options);
        const detailResp = detailRaw as StarRailCharacterDetailResponse;
        if (detailResp.retcode === 0 && detailResp.data && detailResp.data.avatar_list && detailResp.data.avatar_list.length > 0) {
          detailMap[`${items[i].id}`] = detailResp.data.avatar_list[0];
        }
      } catch (_) {}
    }

    const rows: GameDataRow[] = [];
    for (let i = 0; i < items.length; i++) {
      const item = items[i];
      const cid = `${item.id}`;
      const detail = detailMap[cid];

      // 遗器图标（relics + ornaments，共6个槽位）
      const relicIcons: string[] = [];
      const relicsDetail: StarRailStorageRelic[] = [];
      if (detail) {
        const allRelics: Array<StarRailRelic | StarRailOrnament> = [];
        if (detail.relics) {
          for (let j = 0; j < detail.relics.length; j++) {
            allRelics[allRelics.length] = detail.relics[j];
          }
        }
        if (detail.ornaments) {
          for (let j = 0; j < detail.ornaments.length; j++) {
            allRelics[allRelics.length] = detail.ornaments[j];
          }
        }
        for (let j = 0; j < allRelics.length; j++) {
          const r = allRelics[j];
          relicIcons[relicIcons.length] = r.icon;
          const subs: StarRailStorageSubStat[] = [];
          if (r.properties) {
            for (let k = 0; k < r.properties.length; k++) {
              subs[subs.length] = { property_type: r.properties[k].property_type, value: r.properties[k].value };
            }
          }
          relicsDetail[relicsDetail.length] = {
            pos: r.pos, icon: r.icon, name: r.name, level: r.level, rarity: r.rarity,
            main_property_type: r.main_property ? r.main_property.property_type : 0,
            main_property_value: r.main_property ? r.main_property.value : '',
            sub_stats: subs
          };
        }
      }

      // 技能等级（point_type === 2 为主动技能：普攻/战技/终结技/天赋/秘技，取前3个主动）
      const skillLevels: number[] = [];
      const skillIcons: string[] = [];
      if (detail && detail.skills) {
        for (let j = 0; j < detail.skills.length; j++) {
          const sk = detail.skills[j];
          if (sk.point_type === 2 && skillLevels.length < 3) {
            skillLevels[skillLevels.length] = sk.level;
            skillIcons[skillIcons.length] = sk.item_url;
          }
        }
      }

      // 属性
      const props: StarRailStorageProperty[] = [];
      if (detail && detail.properties) {
        for (let j = 0; j < detail.properties.length; j++) {
          props[props.length] = { property_type: detail.properties[j].property_type, final: detail.properties[j].final };
        }
      }

      const storage: StarRailCharacterStorage = {
        id: item.id, name: item.name, element: item.element,
        element_id: item.element_id, level: item.level, rarity: item.rarity,
        rank: item.rank, base_type: item.base_type,
        icon: item.icon, figure_path: item.figure_path,
        equip: item.equip,
        relics_detail: relicsDetail, relic_icons: relicIcons,
        skill_levels: skillLevels, skill_icons: skillIcons,
        properties: props,
        ranks: detail ? detail.ranks : [],
      };

      const row = new GameDataRow();
      row.gameId = gameId;
      row.roleUid = roleUid;
      row.dataType = DataType.CHARACTER;
      row.entityId = cid;
      row.name = item.name;
      row.rarity = item.rarity;
      row.level = item.level;
      row.extraInt1 = item.rank;
      row.extraInt2 = 0;
      row.extraText1 = item.element;
      row.extraText2 = `${item.base_type}`;
      row.rawJson = JSON.stringify(storage);
      row.updateTime = now;
      rows[rows.length] = row;
    }
    await GameDataDao.batchUpsert(rows);
    try { await SyncMetaDao.markSuccess(gameId, roleUid, DataType.CHARACTER); } catch (_) {}
  }

  // ─── 私有：绝区零同步 ────────────────────────────────────────

  private static async syncZZZCharacters(roleUid: string, server: string, cookie: string): Promise<void> {
    const gameId = 'zzz';
    try { await SyncMetaDao.markSyncing(gameId, roleUid, DataType.CHARACTER); } catch (_) {}

    const options = new RequestOptions();
    options.extraHeaders.set('Cookie', cookie);

    const listParams = new RequestParams();
    listParams.set('role_id', roleUid);
    listParams.set('server', server);

    let listRaw: object;
    try {
      listRaw = await NetworkFactory.getInstance().get(API_ZZZ_CHARACTER_LIST, listParams, options);
    } catch (error) {
      const msg = error instanceof Error ? error.message : `${error}`;
      try { await SyncMetaDao.markFailed(gameId, roleUid, DataType.CHARACTER, msg); } catch (_) {}
      throw new Error(msg);
    }

    const listResp = listRaw as ZZZCharacterListResponse;
    if (listResp.retcode !== 0) {
      const errMsg = `CharacterRepository(zzz): retcode=${listResp.retcode} ${listResp.message}`;
      try { await SyncMetaDao.markFailed(gameId, roleUid, DataType.CHARACTER, errMsg); } catch (_) {}
      throw new Error(errMsg);
    }

    const items = listResp.data.avatar_list;
    const now = Math.floor(Date.now() / 1000);

    // 拉取 detail（绝区零 detail 接口，传 id_list 数组）
    const detailMap: Record<string, ZZZCharacterDetailItem> = {};
    const idList: number[] = [];
    for (let i = 0; i < items.length; i++) {
      idList[idList.length] = items[i].id;
    }
    if (idList.length > 0) {
      const detailParams = new RequestParams();
      detailParams.set('role_id', roleUid);
      detailParams.set('server', server);
      detailParams.set('id_list', idList);
      try {
        const detailRaw = await NetworkFactory.getInstance().post(API_ZZZ_CHARACTER_DETAIL, detailParams, options);
        const detailResp = detailRaw as ZZZCharacterDetailResponse;
        if (detailResp.retcode === 0 && detailResp.data && detailResp.data.avatar_list) {
          for (let i = 0; i < detailResp.data.avatar_list.length; i++) {
            const d = detailResp.data.avatar_list[i];
            detailMap[`${d.id}`] = d;
          }
        }
      } catch (_) {}
    }

    const rows: GameDataRow[] = [];
    for (let i = 0; i < items.length; i++) {
      const item = items[i];
      const cid = `${item.id}`;
      const detail = detailMap[cid];

      // 绝区零稀有度：S=5, A=4
      const rarityNum = item.rarity === 'S' ? 5 : 4;

      // 驱动盘图标（最多6件）
      const relicIcons: string[] = [];
      const equipList: ZZZStorageEquip[] = [];
      if (detail && detail.equip) {
        for (let j = 0; j < detail.equip.length; j++) {
          const eq = detail.equip[j];
          relicIcons[relicIcons.length] = eq.icon;
          const subs: ZZZStorageEquipSubStat[] = [];
          if (eq.properties) {
            for (let k = 0; k < eq.properties.length; k++) {
              subs[subs.length] = {
                property_id: eq.properties[k].property_id,
                property_name: eq.properties[k].property_name,
                base: eq.properties[k].base,
                valid: eq.properties[k].valid
              };
            }
          }
          const mainProp = eq.main_properties && eq.main_properties.length > 0 ? eq.main_properties[0] : null;
          equipList[equipList.length] = {
            equipment_type: eq.equipment_type,
            id: eq.id, name: eq.name, icon: eq.icon, rarity: eq.rarity, level: eq.level,
            suit_id: eq.equip_suit ? eq.equip_suit.suit_id : 0,
            suit_name: eq.equip_suit ? eq.equip_suit.name : '',
            main_property_id: mainProp ? mainProp.property_id : 0,
            main_property_value: mainProp ? mainProp.base : '',
            sub_stats: subs
          };
        }
      }

      // 技能等级（skill_type: 0=普攻, 1=特殊技, 2=闪避, 3=连携技/终结技, 5=核心被动, 6=支援技）
      const skillLevels: number[] = [];
      if (detail && detail.skills) {
        for (let j = 0; j < detail.skills.length; j++) {
          const sk = detail.skills[j];
          if (sk.skill_type <= 3) {
            skillLevels[skillLevels.length] = sk.level;
          }
        }
      }

      // 属性
      const props: ZZZStorageProperty[] = [];
      if (detail && detail.properties) {
        for (let j = 0; j < detail.properties.length; j++) {
          const p = detail.properties[j];
          props[props.length] = { property_id: p.property_id, property_name: p.property_name, final: p.final };
        }
      }

      const storage: ZZZCharacterStorage = {
        id: item.id, name: item.name_mi18n, full_name: item.full_name_mi18n,
        element_type: item.element_type, camp_name: item.camp_name_mi18n,
        avatar_profession: item.avatar_profession,
        rarity: item.rarity, rarity_num: rarityNum,
        level: item.level, rank: item.rank,
        icon: item.hollow_icon_path, square_icon: item.role_square_url,
        vertical_painting_url: detail ? detail.role_vertical_painting_url : '',
        weapon: detail ? detail.weapon : null,
        equip_list: equipList, relic_icons: relicIcons,
        skill_levels: skillLevels, properties: props,
        ranks: detail ? detail.ranks : [],
      };

      const row = new GameDataRow();
      row.gameId = gameId;
      row.roleUid = roleUid;
      row.dataType = DataType.CHARACTER;
      row.entityId = cid;
      row.name = item.name_mi18n;
      row.rarity = rarityNum;
      row.level = item.level;
      row.extraInt1 = item.rank;
      row.extraInt2 = 0;
      row.extraText1 = `${item.element_type}`;
      row.extraText2 = `${item.avatar_profession}`;
      row.rawJson = JSON.stringify(storage);
      row.updateTime = now;
      rows[rows.length] = row;
    }
    await GameDataDao.batchUpsert(rows);
    try { await SyncMetaDao.markSuccess(gameId, roleUid, DataType.CHARACTER); } catch (_) {}
  }

  // ─── 私有：GameDataRow → GameDataSummary ─────────────────────

  private static rowToSummary(row: GameDataRow, gameId: string): GameDataSummary {
    const s = new GameDataSummary();
    s.id = row.id;
    s.gameId = row.gameId;
    s.roleUid = row.roleUid;
    s.dataType = row.dataType;
    s.entityId = row.entityId;
    s.name = row.name;
    s.rarity = row.rarity;
    s.level = row.level;
    s.extraInt1 = row.extraInt1;
    s.extraInt2 = row.extraInt2;
    s.extraText1 = row.extraText1;
    s.extraText2 = row.extraText2;
    s.updateTime = row.updateTime;
    if (!row.rawJson) {
      return s;
    }
    try {
      if (gameId === 'genshin') {
        const p = JSON.parse(row.rawJson) as GenshinCharacterStorage;
        s.iconUrl = p.icon ?? '';
        s.squareIconUrl = p.side_icon ?? '';
        if (p.weapon) {
          s.weaponName = p.weapon.name ?? '';
          s.weaponLevel = p.weapon.level ?? 0;
          s.weaponIconUrl = p.weapon.icon ?? '';
          s.weaponAffix = p.weapon.affix_level ?? 1;
          s.weaponRarity = p.weapon.rarity ?? 3;
        }
        s.relicIcons = p.relic_icons ?? [];
        s.skillLevels = p.skill_levels ?? [];
        s.skillIcons = p.skill_icons ?? [];
      } else if (gameId === 'starrail') {
        const p = JSON.parse(row.rawJson) as StarRailCharacterStorage;
        s.iconUrl = p.icon ?? '';
        s.squareIconUrl = p.figure_path ?? '';
        if (p.equip) {
          s.weaponName = p.equip.name ?? '';
          s.weaponLevel = p.equip.level ?? 0;
          s.weaponIconUrl = p.equip.icon ?? '';
          s.weaponAffix = p.equip.rank ?? 1;
          s.weaponRarity = p.equip.rarity ?? 3;
        }
        s.relicIcons = p.relic_icons ?? [];
        s.skillLevels = p.skill_levels ?? [];
      } else if (gameId === 'zzz') {
        const p = JSON.parse(row.rawJson) as ZZZCharacterStorage;
        s.iconUrl = p.icon ?? '';
        s.squareIconUrl = p.square_icon ?? '';
        s.fullName = p.full_name ?? '';
        if (p.weapon) {
          s.weaponName = p.weapon.name ?? '';
          s.weaponLevel = p.weapon.level ?? 0;
          s.weaponIconUrl = p.weapon.icon ?? '';
          s.weaponAffix = p.weapon.star ?? 1;
          s.weaponRarity = p.weapon.rarity === 'S' ? 5 : 4;
        }
        s.relicIcons = p.relic_icons ?? [];
        s.skillLevels = p.skill_levels ?? [];
      }
    } catch (_) {}
    return s;
  }
}
