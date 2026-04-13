/**
 * StarRailCharacterDetailViewModel.ets
 *
 * 星穹铁道角色详情页 ViewModel。
 * 从 DB 读取 rawJson，解析为详情展示模型。
 */

import { CoreInitializer, StarRailAvatarInfoRow, StarRailPropertyType } from 'core';
import {
  StarRailAvatarDetailRaw,
  StarRailRawRelic,
  StarRailRawSkillNode
} from 'core';
import { starRailPropertyTypeToName } from '../utils/StarRailPropertyUtil';
import { Logger } from 'core';
import { ViewState } from '../constants/ViewStates';
import {
  CharDetailRankItem,
  CharDetailHeroInfo,
  StarRailCharDetailSkillNode,
  StarRailCharDetailRelic,
  StarRailCharDetailEquip,
  StarRailCharDetailProperty,
  StarRailRelicSubStat
} from '../components/chardetail/CharDetailModels';

const TAG: string = 'StarRailCharacterDetailViewModel';

// ─── @Monitor 路径常量 ───────────────────────────────────────────

export class StarRailCharacterDetailViewModelKeys {
  viewState: string = 'vm.viewState';
}

// ─── ViewModel ───────────────────────────────────────────────────

@ObservedV2
export class StarRailCharacterDetailViewModel {
  static readonly KEYS: StarRailCharacterDetailViewModelKeys = new StarRailCharacterDetailViewModelKeys();

  @Trace viewState: ViewState = ViewState.LOADING;

  // 基础信息
  @Trace heroInfo: CharDetailHeroInfo = new CharDetailHeroInfo();
  @Trace charName: string = '';
  @Trace charLevel: number = 0;
  @Trace charElement: string = '';
  @Trace charIconUrl: string = '';
  @Trace charImageUrl: string = '';
  @Trace charRarity: number = 5;
  @Trace charRank: number = 0;

  // 命座列表
  @Trace ranks: CharDetailRankItem[] = [];

  // 行迹（按 point_type 分组）
  /** 主技能（point_type=2）：普攻/战技/终结技/天赋/秘技 */
  @Trace skillsMain: StarRailCharDetailSkillNode[] = [];
  /** 额外能力（point_type=3） */
  @Trace skillsExtra: StarRailCharDetailSkillNode[] = [];
  /** 属性加成（point_type=1） */
  @Trace skillsAttr: StarRailCharDetailSkillNode[] = [];

  // 光锥
  @Trace equip: StarRailCharDetailEquip | null = null;

  // 遗器（pos 1-4）
  @Trace relics: StarRailCharDetailRelic[] = [];
  // 饰品（pos 5-6）
  @Trace ornaments: StarRailCharDetailRelic[] = [];

  // 属性列表
  @Trace properties: StarRailCharDetailProperty[] = [];

  private accountId: string = '';
  private roleUid: string = '';
  private entityId: string = '';

  init(accountId: string, roleUid: string, entityId: string): void {
    this.accountId = accountId;
    this.roleUid = roleUid;
    this.entityId = entityId;
  }

  async loadData(): Promise<void> {
    this.viewState = ViewState.LOADING;
    try {
      const row: StarRailAvatarInfoRow | null =
        await CoreInitializer.starRailRepository.getAvatarDetail(this.accountId, this.roleUid, this.entityId);
      if (row === null || row.rawJson === '') {
        this.viewState = ViewState.EMPTY;
        return;
      }
      this.parseRawJson(row.rawJson);
      this.viewState = ViewState.DATA;
    } catch (error) {
      const msg = error instanceof Error ? error.message : `${error}`;
      Logger.error(TAG, `loadData failed: ${msg}`);
      this.viewState = ViewState.ERROR;
    }
  }

  private parseRawJson(rawJson: string): void {
    try {
      const parsed = JSON.parse(rawJson) as StarRailAvatarDetailRaw;

      this.charName = parsed.name ?? '';
      this.charLevel = parsed.level ?? 0;
      this.charElement = parsed.element ?? '';
      this.charIconUrl = parsed.icon ?? '';
      this.charImageUrl = parsed.image ?? '';
      this.charRarity = parsed.rarity ?? 5;
      this.charRank = parsed.rank ?? 0;

      const hi = new CharDetailHeroInfo();
      hi.charName = this.charName;
      hi.level = this.charLevel;
      this.heroInfo = hi;

      // 命座
      const rankList: CharDetailRankItem[] = [];
      if (parsed.ranks) {
        for (let i = 0; i < parsed.ranks.length; i++) {
          const r = parsed.ranks[i];
          const item = new CharDetailRankItem();
          item.pos = r.pos;
          item.name = r.name ?? '';
          item.iconUrl = r.icon ?? '';
          item.isActived = r.is_unlocked;
          rankList[rankList.length] = item;
        }
      }
      this.ranks = rankList;

      // 行迹（按 point_type 分组）
      const main: StarRailCharDetailSkillNode[] = [];
      const extra: StarRailCharDetailSkillNode[] = [];
      const attr: StarRailCharDetailSkillNode[] = [];
      if (parsed.skills) {
        for (let i = 0; i < parsed.skills.length; i++) {
          const s = parsed.skills[i];
          const node = new StarRailCharDetailSkillNode();
          node.pointId = s.point_id ?? '';
          node.pointType = s.point_type ?? 0;
          node.iconUrl = s.item_url ?? '';
          node.level = s.level ?? 0;
          node.isActivated = s.is_activated;
          node.remake = s.remake ?? '';
          if (s.skill_stages && s.skill_stages.length > 0) {
            node.name = s.skill_stages[0].name ?? '';
            node.desc = s.skill_stages[0].desc ?? '';
          }
          if (s.point_type === 2) {
            main[main.length] = node;
          } else if (s.point_type === 3) {
            extra[extra.length] = node;
          } else if (s.point_type === 1) {
            attr[attr.length] = node;
          }
        }
      }
      this.skillsMain = main;
      this.skillsExtra = extra;
      this.skillsAttr = attr;

      // 光锥
      if (parsed.equip) {
        const eq = new StarRailCharDetailEquip();
        eq.id = parsed.equip.id ?? 0;
        eq.name = parsed.equip.name ?? '';
        eq.iconUrl = parsed.equip.icon ?? '';
        eq.level = parsed.equip.level ?? 0;
        eq.rank = parsed.equip.rank ?? 1;
        eq.rarity = parsed.equip.rarity ?? 3;
        this.equip = eq;
      } else {
        this.equip = null;
      }

      // 遗器（pos 1-4）
      const relicList: StarRailCharDetailRelic[] = [];
      if (parsed.relics) {
        for (let i = 0; i < parsed.relics.length; i++) {
          relicList[relicList.length] = this.parseRelic(parsed.relics[i]);
        }
      }
      this.relics = relicList;

      // 饰品（pos 5-6）
      const ornamentList: StarRailCharDetailRelic[] = [];
      if (parsed.ornaments) {
        for (let i = 0; i < parsed.ornaments.length; i++) {
          ornamentList[ornamentList.length] = this.parseRelic(parsed.ornaments[i]);
        }
      }
      this.ornaments = ornamentList;

      // 属性
      const propList: StarRailCharDetailProperty[] = [];
      if (parsed.properties) {
        for (let i = 0; i < parsed.properties.length; i++) {
          const p = parsed.properties[i];
          const prop = new StarRailCharDetailProperty();
          prop.propertyType = p.property_type ?? 0;
          prop.name = starRailPropertyTypeToName(p.property_type ?? 0);
          prop.final = p.final ?? '';
          propList[propList.length] = prop;
        }
      }
      this.properties = propList;
    } catch (error) {
      const msg = error instanceof Error ? error.message : `${error}`;
      Logger.error(TAG, `parseRawJson failed: ${msg}`);
    }
  }

  private parseRelic(r: StarRailRawRelic): StarRailCharDetailRelic {
    const relic = new StarRailCharDetailRelic();
    relic.pos = r.pos ?? 0;
    relic.name = r.name ?? '';
    relic.iconUrl = r.icon ?? '';
    relic.level = r.level ?? 0;
    relic.rarity = r.rarity ?? 5;
    if (r.main_property) {
      relic.mainPropertyType = r.main_property.property_type ?? 0;
      relic.mainPropertyValue = r.main_property.value ?? '';
    }
    const subs: StarRailRelicSubStat[] = [];
    if (r.properties) {
      for (let j = 0; j < r.properties.length; j++) {
        const sub = new StarRailRelicSubStat();
        sub.name = starRailPropertyTypeToName(r.properties[j].property_type ?? 0);
        sub.value = r.properties[j].value ?? '';
        sub.times = r.properties[j].times ?? 0;
        subs[subs.length] = sub;
      }
    }
    relic.subStats = subs;
    return relic;
  }
}
