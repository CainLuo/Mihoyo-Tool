/**
 * ZZZCharacterDetailViewModel.ets
 *
 * 绝区零角色详情页 ViewModel。
 * 从 DB 读取 rawJson，解析为详情展示模型。
 */

import { CoreInitializer, ZZZAvatarInfoRow } from 'core';
import {
  ZZZAvatarDetailRaw,
  ZZZRawEquip
} from 'core';
import { Logger } from 'core';
import { ViewState } from '../constants/ViewStates';
import {
  CharDetailRankItem,
  CharDetailHeroInfo,
  ZZZCharDetailSkill,
  ZZZSkillItem,
  ZZZCharDetailWeapon,
  ZZZSubStat,
  ZZZCharDetailEquip,
  ZZZSuitSummary,
  ZZZCharDetailProperty
} from '../models/CharDetailModels';

const TAG: string = 'ZZZCharacterDetailViewModel';

// ─── @Monitor 路径常量 ───────────────────────────────────────────

export class ZZZCharacterDetailViewModelKeys {
  viewState: string = 'vm.viewState';
  networkErrorMsg: string = 'vm.networkErrorMsg';
}

// ─── ViewModel ───────────────────────────────────────────────────

@ObservedV2
export class ZZZCharacterDetailViewModel {
  static readonly KEYS: ZZZCharacterDetailViewModelKeys = new ZZZCharacterDetailViewModelKeys();

  @Trace viewState: ViewState = ViewState.LOADING;
  /** 非空时 View 弹 Snackbar，弹完后 View 应将其清空 */
  @Trace networkErrorMsg: string = '';

  // 基础信息
  @Trace heroInfo: CharDetailHeroInfo = new CharDetailHeroInfo();
  @Trace charName: string = '';
  @Trace charFullName: string = '';
  @Trace charLevel: number = 0;
  @Trace charRarity: string = '';
  @Trace charRank: number = 0;
  @Trace charVerticalPaintingUrl: string = '';

  // 影画列表
  @Trace ranks: CharDetailRankItem[] = [];

  // 技能（按 skill_type 分组）
  @Trace skills: ZZZCharDetailSkill[] = [];

  // 音擎（武器）
  @Trace weapon: ZZZCharDetailWeapon | null = null;

  // 驱动盘（6件）
  @Trace equips: ZZZCharDetailEquip[] = [];

  // 套装摘要
  @Trace suitSummaries: ZZZSuitSummary[] = [];

  // 属性列表
  @Trace properties: ZZZCharDetailProperty[] = [];

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
      const row: ZZZAvatarInfoRow | null =
        await CoreInitializer.zzzRepository.getAvatarDetail(this.accountId, this.roleUid, this.entityId);
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
      this.networkErrorMsg = msg;
    }
  }

  private parseRawJson(rawJson: string): void {
    try {
      const parsed = JSON.parse(rawJson) as ZZZAvatarDetailRaw;

      this.charName = parsed.name_mi18n ?? '';
      this.charFullName = parsed.full_name_mi18n ?? '';
      this.charLevel = parsed.level ?? 0;
      this.charRarity = parsed.rarity ?? '';
      this.charRank = parsed.rank ?? 0;
      this.charVerticalPaintingUrl = parsed.role_vertical_painting_url ?? '';

      const hi = new CharDetailHeroInfo();
      hi.charName = this.charName;
      hi.level = this.charLevel;
      this.heroInfo = hi;

      // 影画列表
      const rankList: CharDetailRankItem[] = [];
      if (parsed.ranks) {
        for (let i = 0; i < parsed.ranks.length; i++) {
          const r = parsed.ranks[i];
          const item = new CharDetailRankItem();
          item.pos = r.pos;
          item.name = r.name ?? '';
          item.iconUrl = '';
          item.isActived = r.is_unlocked;
          rankList[rankList.length] = item;
        }
      }
      this.ranks = rankList;

      // 技能（按 skill_type 分组）
      const skillList: ZZZCharDetailSkill[] = [];
      if (parsed.skills) {
        for (let i = 0; i < parsed.skills.length; i++) {
          const s = parsed.skills[i];
          const skill = new ZZZCharDetailSkill();
          skill.skillType = s.skill_type ?? 0;
          skill.level = s.level ?? 0;
          const items: ZZZSkillItem[] = [];
          if (s.items) {
            for (let j = 0; j < s.items.length; j++) {
              const si = new ZZZSkillItem();
              si.title = s.items[j].title ?? '';
              si.text = s.items[j].text ?? '';
              items[items.length] = si;
            }
          }
          skill.items = items;
          skillList[skillList.length] = skill;
        }
      }
      this.skills = skillList;

      // 音擎（武器）
      if (parsed.weapon) {
        const w = new ZZZCharDetailWeapon();
        w.id = parsed.weapon.id ?? 0;
        w.name = parsed.weapon.name ?? '';
        w.iconUrl = parsed.weapon.icon ?? '';
        w.level = parsed.weapon.level ?? 0;
        w.star = parsed.weapon.star ?? 1;
        w.rarity = parsed.weapon.rarity ?? '';
        w.talentTitle = parsed.weapon.talent_title ?? '';
        this.weapon = w;
      } else {
        this.weapon = null;
      }

      // 驱动盘（6件）
      const equipList: ZZZCharDetailEquip[] = [];
      if (parsed.equip) {
        for (let i = 0; i < parsed.equip.length; i++) {
          const e = parsed.equip[i];
          const equip = new ZZZCharDetailEquip();
          equip.pos = e.equipment_type ?? (i + 1);
          equip.name = e.name ?? '';
          equip.iconUrl = e.icon ?? '';
          equip.rarity = e.rarity ?? '';
          equip.level = e.level ?? 0;
          if (e.equip_suit) {
            equip.suitId = e.equip_suit.suit_id ?? 0;
            equip.suitName = e.equip_suit.name ?? '';
            equip.suitOwn = e.equip_suit.own ?? 0;
          }
          // 主词条
          if (e.main_properties && e.main_properties.length > 0) {
            equip.mainStatName = e.main_properties[0].property_name ?? '';
            equip.mainStatValue = e.main_properties[0].base ?? '';
          }
          // 副词条
          const subs: ZZZSubStat[] = [];
          if (e.properties) {
            for (let j = 0; j < e.properties.length; j++) {
              const sub = new ZZZSubStat();
              sub.name = e.properties[j].property_name ?? '';
              sub.value = e.properties[j].base ?? '';
              sub.valid = e.properties[j].valid;
              subs[subs.length] = sub;
            }
          }
          equip.subStats = subs;
          equipList[equipList.length] = equip;
        }
      }
      this.equips = equipList;

      // 套装摘要（按 suitId 分组统计）
      this.suitSummaries = this.buildSuitSummaries(equipList, parsed.equip ?? []);

      // 属性
      const propList: ZZZCharDetailProperty[] = [];
      if (parsed.properties) {
        for (let i = 0; i < parsed.properties.length; i++) {
          const p = parsed.properties[i];
          const prop = new ZZZCharDetailProperty();
          prop.name = p.property_name ?? '';
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

  private buildSuitSummaries(equipList: ZZZCharDetailEquip[], rawEquips: ZZZRawEquip[]): ZZZSuitSummary[] {
    // 用数组模拟 Map，按 suitId 分组
    const suitIds: number[] = [];
    const suitMap: ZZZSuitSummary[] = [];

    for (let i = 0; i < equipList.length; i++) {
      const eq = equipList[i];
      if (eq.suitId === 0) { continue; }
      let found = false;
      for (let j = 0; j < suitIds.length; j++) {
        if (suitIds[j] === eq.suitId) {
          suitMap[j].count += 1;
          found = true;
          break;
        }
      }
      if (!found) {
        const summary = new ZZZSuitSummary();
        summary.suitId = eq.suitId;
        summary.suitName = eq.suitName;
        summary.count = 1;
        summary.suitOwn = eq.suitOwn;
        // 从 rawEquips 中找到对应的 desc1/desc2
        for (let k = 0; k < rawEquips.length; k++) {
          if (rawEquips[k].equip_suit && rawEquips[k].equip_suit.suit_id === eq.suitId) {
            summary.desc1 = rawEquips[k].equip_suit.desc1 ?? '';
            summary.desc2 = rawEquips[k].equip_suit.desc2 ?? '';
            break;
          }
        }
        suitIds[suitIds.length] = eq.suitId;
        suitMap[suitMap.length] = summary;
      }
    }
    return suitMap;
  }
}
