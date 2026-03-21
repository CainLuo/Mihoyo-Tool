/**
 * CharacterRepository.ets
 *
 * 角色数据 Repository，封装所有角色相关的查询语义。
 * entry 模块调用此类，完全不感知底层 SQL 和 DAO 细节。
 *
 * 使用示例（entry 模块）：
 *   import { CharacterRepository } from 'core';
 *   const list = await CharacterRepository.findAll('genshin', '123456789');
 *   const detail = await CharacterRepository.findById('genshin', '123456789', '10000120');
 *   const top10 = await CharacterRepository.findTopByRelicScore('genshin', '123456789', 10);
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

// ─── 响应接口（仅声明需要的字段）────────────────────────────────

interface CharacterWeapon {
  id: number;
  name: string;
  icon: string;
  type: number;
  rarity: number;
  level: number;
  affix_level: number;
}

interface CharacterListItem {
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
  weapon: CharacterWeapon;
}

interface CharacterListData {
  list: CharacterListItem[];
}

interface CharacterListResponse {
  retcode: number;
  message: string;
  data: CharacterListData;
}

// ─── Detail 接口类型 ────────────────────────────────────────────

interface RawMainProperty {
  property_type: number;
  value: string;
  times: number;
}

interface RawSubProperty {
  property_type: number;
  value: string;
  times: number;
}

interface RawSelectedProperty {
  property_type: number;
  base: string;
  add: string;
  final: string;
}

interface RawWeaponMainProperty {
  property_type: number;
  base: string;
  add: string;
  final: string;
}

interface DetailWeapon {
  id: number;
  name: string;
  icon: string;
  type: number;
  rarity: number;
  level: number;
  affix_level: number;
  main_property: RawWeaponMainProperty;
  sub_property: RawWeaponMainProperty;
}

interface CharacterRelic {
  id: number;
  name: string;
  icon: string;
  pos: number;
  rarity: number;
  level: number;
  set: RelicSet;
  pos_name: string;
  main_property: RawMainProperty;
  sub_property_list: RawSubProperty[];
}

interface RelicSet {
  id: number;
  name: string;
}

/** 命座原始数据 */
interface RawConstellation {
  id: number;
  name: string;
  icon: string;
  effect: string;
  is_actived: boolean;
  pos: number;
}

interface CharacterSkill {
  skill_type: number;
  level: number;
  icon: string;
}

interface CharacterDetailItem {
  base: CharacterListItem;
  weapon: DetailWeapon;
  relics: CharacterRelic[];
  skills: CharacterSkill[];
  selected_properties: RawSelectedProperty[];
  constellations: RawConstellation[];
}

interface CharacterDetailData {
  list: CharacterDetailItem[];
}

interface CharacterDetailResponse {
  retcode: number;
  message: string;
  data: CharacterDetailData;
}

/** 存储用的圣遗物副词条 */
interface StorageSubStat {
  property_type: number;
  value: string;
}

/** 存储用的完整圣遗物 */
interface StorageRelic {
  pos: number;
  icon: string;
  set_name: string;
  level: number;
  rarity: number;
  main_property_type: number;
  main_property_value: string;
  sub_stats: StorageSubStat[];
}

/** 存储用的属性条目 */
interface StorageProperty {
  property_type: number;
  final: string;
}

/** 合并了 detail 数据的扩展存储结构（存入 raw_json） */
interface CharacterStorageItem {
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
  weapon: CharacterWeapon;
  /** 武器基础攻击力（来自 detail 接口 weapon.main_property.final） */
  weapon_base_atk: string;
  /** 武器副词条 property_type */
  weapon_sub_type: number;
  /** 武器副词条值（来自 detail 接口 weapon.sub_property.final） */
  weapon_sub_val: string;
  /** 完整圣遗物数据（含主副词条），来自 detail 接口 */
  relics_detail: StorageRelic[];
  /** 圣遗物图标 URL 数组（最多5个），来自 detail 接口（兼容列表页） */
  relic_icons: string[];
  /** 技能等级数组 [普攻, 战技, 爆发]，来自 detail 接口 */
  skill_levels: number[];
  /** 技能图标 URL 数组 [普攻, 战技, 爆发]，来自 detail 接口 */
  skill_icons: string[];
  /** selected_properties 数组，来自 detail 接口 */
  selected_properties: StorageProperty[];
  /** 命座完整数据（含 icon、名称、效果描述、是否已激活），来自 detail 接口 */
  constellations_detail: StorageConstellation[];
}

/** 存储用的命座数据 */
interface StorageConstellation {
  /** 命座位置（1-6） */
  pos: number;
  /** 命座名称 */
  name: string;
  /** 命座图标 URL */
  icon: string;
  /** 命座效果描述 */
  effect: string;
  /** 是否已激活 */
  is_actived: boolean;
}

export class CharacterRepository {

  /**
   * 查询角色摘要列表（不含 raw_json），按稀有度+等级降序。
   * 适用于角色列表页，性能最优。
   *
   * @param gameId  游戏标识
   * @param roleUid 游戏内 UID
   */
  static async findAll(
    gameId: string,
    roleUid: string
  ): Promise<GameDataSummary[]> {
    // 查询完整行（含 raw_json），以便解析 icon URL
    const builder = new QueryBuilder('game_data')
      .equalTo('game_id', gameId)
      .equalTo('role_uid', roleUid)
      .equalTo('data_type', DataType.CHARACTER)
      .orderByDesc('rarity');
    const rows = await GameDataDao.findByBuilder(builder);
    // 将 GameDataRow 转为 GameDataSummary，并从 raw_json 解析 icon URL
    const summaries: GameDataSummary[] = [];
    for (let i = 0; i < rows.length; i++) {
      const row = rows[i];
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
      s.updateTime = row.updateTime;
      // 从 raw_json 解析 icon URL、武器字段、圣遗物图标、技能等级
      if (row.rawJson) {
        try {
          const parsed = JSON.parse(row.rawJson) as CharacterStorageItem;
          s.iconUrl = parsed.icon ?? '';
          if (parsed.weapon) {
            s.weaponName = parsed.weapon.name ?? '';
            s.weaponLevel = parsed.weapon.level ?? 0;
            s.weaponIconUrl = parsed.weapon.icon ?? '';
            s.weaponAffix = parsed.weapon.affix_level ?? 1;
            s.weaponRarity = parsed.weapon.rarity ?? 3;
          }
          if (parsed.relic_icons) {
            s.relicIcons = parsed.relic_icons;
          }
          if (parsed.skill_levels) {
            s.skillLevels = parsed.skill_levels;
          }
          if (parsed.skill_icons) {
            s.skillIcons = parsed.skill_icons;
          }
        } catch (_) {
          s.iconUrl = '';
        }
      }
      summaries[summaries.length] = s;
    }
    return summaries;
  }

  /**
   * 查询单个角色完整数据（含 raw_json）。
   * 适用于角色详情页，按需加载。
   *
   * @returns 找到返回 GameDataRow，未找到返回 null
   */
  static async findById(
    gameId: string,
    roleUid: string,
    entityId: string
  ): Promise<GameDataRow | null> {
    return GameDataDao.findOne(gameId, roleUid, DataType.CHARACTER, entityId);
  }

  /**
   * 按元素属性过滤角色（不含 raw_json）。
   * extra_text1 存储元素属性（"Electro" / "Pyro" 等）。
   *
   * @param element 元素名称，如 "Electro"
   */
  static async findByElement(
    gameId: string,
    roleUid: string,
    element: string
  ): Promise<GameDataSummary[]> {
    return GameDataDao.findSummaries(
      gameId, roleUid, DataType.CHARACTER, 'level', true
    ).then(rows => rows.filter(r => r.extraText1 === element));
  }

  /**
   * 按稀有度过滤角色（不含 raw_json）。
   *
   * @param rarity 稀有度，如 5
   */
  static async findByRarity(
    gameId: string,
    roleUid: string,
    rarity: number
  ): Promise<GameDataSummary[]> {
    const builder = new QueryBuilder('game_data')
      .equalTo('game_id', gameId)
      .equalTo('role_uid', roleUid)
      .equalTo('data_type', DataType.CHARACTER)
      .equalTo('rarity', rarity)
      .orderByDesc('level')
      .columns(['entity_id', 'name', 'rarity', 'level', 'extra_int1', 'extra_int2', 'extra_text1', 'update_time',
        'game_id', 'role_uid', 'data_type', 'id']);
    return GameDataDao.findSummariesByBuilder(builder);
  }

  /**
   * 按装备分排行，返回前 N 名角色。
   * 直接查 game_stats 表，不需要 parse JSON，性能极佳。
   *
   * @param topN 返回前 N 名，不传则返回全部
   */
  static async findTopByRelicScore(
    gameId: string,
    roleUid: string,
    topN?: number
  ): Promise<ScoredEntity[]> {
    return GameStatsDao.findRanking(gameId, roleUid, StatKey.RELIC_SCORE, topN);
  }

  /**
   * 查询未毕业的角色列表。
   * is_graduated = 0 表示未毕业。
   */
  static async findNotGraduated(
    gameId: string,
    roleUid: string
  ): Promise<ScoredEntity[]> {
    return GameStatsDao.findNotGraduated(gameId, roleUid);
  }

  /**
   * 按名称搜索角色（跨游戏）。
   *
   * @param keyword 搜索关键词
   * @param gameId  可选，限定游戏
   */
  static async search(
    keyword: string,
    gameId?: string
  ): Promise<GameDataSummary[]> {
    return GameDataDao.searchByName(keyword, gameId, DataType.CHARACTER);
  }

  /**
   * 全量写入角色数据（网络拉取后调用）。
   * 在单个事务中完成，保证原子性。
   *
   * @param rows 角色数据数组
   */
  static async saveAll(rows: GameDataRow[]): Promise<void> {
    return GameDataDao.batchUpsert(rows);
  }

  /**
   * 清空指定游戏+用户的所有角色数据。
   * 切换账号时调用。
   */
  static async clearAll(gameId: string, roleUid: string): Promise<void> {
    await GameDataDao.deleteByType(gameId, roleUid, DataType.CHARACTER);
  }

  /**
   * 从网络拉取角色列表，解析后批量写入 game_data 表。
   * 同步前后更新 sync_meta 状态。
   *
   * 字段映射（对应 database-architecture.md character data_type）：
   *   entity_id   = id（角色数字 ID，转字符串）
   *   name        = name
   *   rarity      = rarity
   *   level       = level
   *   extra_int1  = actived_constellation_num（命座数）
   *   extra_int2  = fetter（好感度）
   *   extra_text1 = element（元素属性）
   *   raw_json    = 单条角色对象的完整 JSON
   *
   * TODO: 目前只支持原神（gameId = "genshin"）。
   *       星穹铁道 / 绝区零的 API 路径待确认后在此处扩展。
   *
   * @param gameId   游戏标识（当前仅 "genshin"）
   * @param roleUid  游戏内 UID
   * @param server   服务器标识（用于构造请求参数）
   * @param cookie   账号 Cookie
   * @throws 网络失败或 retcode != 0 时抛出 Error
   */
  static async syncCharacters(
    gameId: string,
    roleUid: string,
    server: string,
    cookie: string
  ): Promise<void> {
    if (gameId !== 'genshin') {
      throw new Error(`CharacterRepository.syncCharacters: unsupported gameId "${gameId}"`);
    }

    try {
      await SyncMetaDao.markSyncing(gameId, roleUid, DataType.CHARACTER);
    } catch (_) {}

    const options = new RequestOptions();
    options.extraHeaders.set('Cookie', cookie);

    const params = new RequestParams();
    params.set('role_id', roleUid);
    params.set('server', server);

    let raw: object;
    try {
      raw = await NetworkFactory.getInstance().get(API_GENSHIN_CHARACTER_LIST, params, options);
    } catch (error) {
      const msg = error instanceof Error ? error.message : `${error}`;
      try {
        await SyncMetaDao.markFailed(gameId, roleUid, DataType.CHARACTER, msg);
      } catch (_) {}
      throw new Error(msg);
    }

    const resp = raw as CharacterListResponse;
    if (resp.retcode !== 0) {
      const errMsg = `CharacterRepository: API error retcode=${resp.retcode} msg=${resp.message}`;
      try {
        await SyncMetaDao.markFailed(gameId, roleUid, DataType.CHARACTER, errMsg);
      } catch (_) {}
      throw new Error(errMsg);
    }

    const now = Math.floor(Date.now() / 1000);
    const rows: GameDataRow[] = [];
    const items = resp.data.list;

    // 拉取 detail 接口，获取圣遗物和技能数据
    // detail 接口需要传入所有角色 ID
    const characterIds: string[] = [];
    for (let i = 0; i < items.length; i++) {
      characterIds[characterIds.length] = `${items[i].id}`;
    }

    // 构建 detail 请求参数（character_ids 为逗号分隔字符串）
    const detailParams = new RequestParams();
    detailParams.set('role_id', roleUid);
    detailParams.set('server', server);
    detailParams.set('character_ids', characterIds.join(','));

    // detail 接口返回的圣遗物/技能数据，key 为角色 id 字符串
    const relicIconsMap: Record<string, string[]> = {};
    const relicsDetailMap: Record<string, StorageRelic[]> = {};
    const skillLevelsMap: Record<string, number[]> = {};
    const skillIconsMap: Record<string, string[]> = {};
    const selectedPropsMap: Record<string, StorageProperty[]> = {};
    const weaponBaseAtkMap: Record<string, string> = {};
    const weaponSubTypeMap: Record<string, number> = {};
    const weaponSubValMap: Record<string, string> = {};
    const constellationsMap: Record<string, StorageConstellation[]> = {};

    try {
      const detailRaw = await NetworkFactory.getInstance().post(
        API_GENSHIN_CHARACTER_DETAIL, detailParams, options
      );
      const detailResp = detailRaw as CharacterDetailResponse;
      if (detailResp.retcode === 0 && detailResp.data && detailResp.data.list) {
        const detailList = detailResp.data.list;
        for (let i = 0; i < detailList.length; i++) {
          const detail = detailList[i];
          const charId = `${detail.base.id}`;

          // 武器详情（顶层 weapon，含 main_property/sub_property）
          if (detail.weapon) {
            weaponBaseAtkMap[charId] = detail.weapon.main_property ? detail.weapon.main_property.final : '';
            weaponSubTypeMap[charId] = detail.weapon.sub_property ? detail.weapon.sub_property.property_type : 0;
            weaponSubValMap[charId] = detail.weapon.sub_property ? detail.weapon.sub_property.final : '';
          }

          // 解析完整圣遗物（含主副词条）
          const icons: string[] = [];
          const relicsDetail: StorageRelic[] = [];
          if (detail.relics) {
            for (let j = 0; j < detail.relics.length; j++) {
              const r = detail.relics[j];
              icons[icons.length] = r.icon;
              const subs: StorageSubStat[] = [];
              if (r.sub_property_list) {
                for (let k = 0; k < r.sub_property_list.length; k++) {
                  const sub: StorageSubStat = {
                    property_type: r.sub_property_list[k].property_type,
                    value: r.sub_property_list[k].value
                  };
                  subs[subs.length] = sub;
                }
              }
              const sr: StorageRelic = {
                pos: r.pos,
                icon: r.icon,
                set_name: r.set ? r.set.name : '',
                level: r.level,
                rarity: r.rarity,
                main_property_type: r.main_property ? r.main_property.property_type : 0,
                main_property_value: r.main_property ? r.main_property.value : '',
                sub_stats: subs
              };
              relicsDetail[relicsDetail.length] = sr;
            }
          }
          relicIconsMap[charId] = icons;
          relicsDetailMap[charId] = relicsDetail;

          // 解析主动技能（skill_type === 1），取前3个（普攻/战技/爆发）
          const levels: number[] = [];
          const skillIcons: string[] = [];
          if (detail.skills) {
            for (let j = 0; j < detail.skills.length; j++) {
              const skill = detail.skills[j];
              if (skill.skill_type === 1 && levels.length < 3) {
                levels[levels.length] = skill.level;
                skillIcons[skillIcons.length] = skill.icon;
              }
            }
          }
          skillLevelsMap[charId] = levels;
          skillIconsMap[charId] = skillIcons;

          // 解析 selected_properties
          const props: StorageProperty[] = [];
          if (detail.selected_properties) {
            for (let j = 0; j < detail.selected_properties.length; j++) {
              const sp = detail.selected_properties[j];
              const p: StorageProperty = {
                property_type: sp.property_type,
                final: sp.final
              };
              props[props.length] = p;
            }
          }
          selectedPropsMap[charId] = props;

          // 解析命座完整数据（icon、名称、效果、是否已激活）
          const constellations: StorageConstellation[] = [];
          if (detail.constellations) {
            for (let j = 0; j < detail.constellations.length; j++) {
              const c = detail.constellations[j];
              const sc: StorageConstellation = {
                pos: c.pos,
                name: c.name,
                icon: c.icon,
                effect: c.effect,
                is_actived: c.is_actived
              };
              constellations[constellations.length] = sc;
            }
          }
          constellationsMap[charId] = constellations;
        }
      }
    } catch (_) {
      // detail 接口失败不影响主流程，圣遗物/技能数据留空
    }

    for (let i = 0; i < items.length; i++) {
      const item = items[i];
      const charId = `${item.id}`;
      // 构建合并了 detail 数据的存储对象
      const storage: CharacterStorageItem = {
        id: item.id,
        name: item.name,
        element: item.element,
        fetter: item.fetter,
        level: item.level,
        rarity: item.rarity,
        actived_constellation_num: item.actived_constellation_num,
        icon: item.icon,
        image: item.image,
        side_icon: item.side_icon,
        weapon_type: item.weapon_type,
        weapon: item.weapon,
        weapon_base_atk: weaponBaseAtkMap[charId] ?? '',
        weapon_sub_type: weaponSubTypeMap[charId] ?? 0,
        weapon_sub_val: weaponSubValMap[charId] ?? '',
        relics_detail: relicsDetailMap[charId] ?? [],
        relic_icons: relicIconsMap[charId] ?? [],
        skill_levels: skillLevelsMap[charId] ?? [],
        skill_icons: skillIconsMap[charId] ?? [],
        selected_properties: selectedPropsMap[charId] ?? [],
        constellations_detail: constellationsMap[charId] ?? [],
      };
      const row = new GameDataRow();
      row.gameId = gameId;
      row.roleUid = roleUid;
      row.dataType = DataType.CHARACTER;
      row.entityId = charId;
      row.name = item.name;
      row.rarity = item.rarity;
      row.level = item.level;
      row.extraInt1 = item.actived_constellation_num;
      row.extraInt2 = item.fetter;
      row.extraText1 = item.element;
      row.rawJson = JSON.stringify(storage);
      row.updateTime = now;
      rows[rows.length] = row;
    }

    await GameDataDao.batchUpsert(rows);

    try {
      await SyncMetaDao.markSuccess(gameId, roleUid, DataType.CHARACTER);
    } catch (_) {}
  }
}
