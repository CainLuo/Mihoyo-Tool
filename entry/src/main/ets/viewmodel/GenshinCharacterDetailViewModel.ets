/**
 * GenshinCharacterDetailViewModel.ets
 *
 * 角色详情页 ViewModel。
 * 从 DB 读取 rawJson，解析为详情展示模型。
 * 所有 property_type 数字必须通过 GenshinPropertyType enum 引用，禁止写字面量。
 */

import { CoreInitializer, GenshinPropertyType, GenshinCharacterDetailRow } from 'core';
import { GenshinCharacterDetailRaw } from 'core';
import { Logger } from 'core';
import { ViewState } from '../constants/ViewStates';
import { GenshinElement, elementFromString } from '../constants/GenshinElement';
import {
  CharDetailWeapon,
  CharDetailRelic,
  RelicSubStat,
  CharDetailSkill,
  CharDetailRankItem,
  CharDetailStat
} from '../components/chardetail/CharDetailModels';
import {
  genshinPropertyTypeToResource,
  GENSHIN_STAT_ORDER,
  GENSHIN_STAT_LABELS,
  GENSHIN_HIGHLIGHT_PROPS
} from '../utils/GenshinPropertyUtil';

const TAG: string = 'GenshinCharacterDetailViewModel';

// ─── @Monitor 路径常量 ───────────────────────────────────────────

/** GenshinCharacterDetailViewModel @Monitor 路径常量类型 */
export class GenshinCharacterDetailViewModelKeys {
  viewState: string = 'vm.viewState';
}

// ─── ViewModel ───────────────────────────────────────────────────

@ObservedV2
export class GenshinCharacterDetailViewModel {
  static readonly KEYS: GenshinCharacterDetailViewModelKeys = new GenshinCharacterDetailViewModelKeys();

  @Trace viewState: ViewState = ViewState.LOADING;

  // 基础信息
  @Trace charName: string = '';
  @Trace charLevel: number = 0;
  @Trace charFetter: number = 0;
  @Trace charElement: GenshinElement = GenshinElement.UNKNOWN;
  @Trace charImageUrl: string = '';
  @Trace charIconUrl: string = '';
  @Trace activatedConstellations: number = 0;

  // 命座（含 icon / 名称 / 效果 / 是否已激活）
  @Trace constellations: CharDetailRankItem[] = [];

  // 武器
  @Trace weapon: CharDetailWeapon = new CharDetailWeapon();

  // 属性列表
  @Trace stats: CharDetailStat[] = [];

  // 圣遗物（最多5个）
  @Trace relics: CharDetailRelic[] = [];

  // 技能（普攻/战技/爆发，最多3个）
  @Trace skills: CharDetailSkill[] = [];

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
      const row: GenshinCharacterDetailRow | null = await CoreInitializer.genshinRepository.getAvatarDetail(this.accountId, this.roleUid, this.entityId);
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
      const parsed = JSON.parse(rawJson) as GenshinCharacterDetailRaw;
      const base = parsed.base;
      this.charName = base.name ?? '';
      this.charLevel = base.level ?? 0;
      this.charFetter = base.fetter ?? 0;
      this.charElement = elementFromString(base.element ?? '');
      this.charImageUrl = base.image ?? '';
      this.charIconUrl = base.icon ?? '';
      this.activatedConstellations = base.actived_constellation_num ?? 0;

      // 命座
      const cons: CharDetailRankItem[] = [];
      if (parsed.constellations && parsed.constellations.length > 0) {
        for (let i = 0; i < parsed.constellations.length; i++) {
          const c = parsed.constellations[i];
          const cd = new CharDetailRankItem();
          cd.pos = c.pos;
          cd.name = c.name;
          cd.iconUrl = c.icon;
          cd.effect = c.effect;
          cd.isActived = c.is_actived;
          cons[cons.length] = cd;
        }
      } else {
        for (let i = 0; i < 6; i++) {
          const cd = new CharDetailRankItem();
          cd.pos = i + 1;
          cd.isActived = i < this.activatedConstellations;
          cons[cons.length] = cd;
        }
      }
      this.constellations = cons;

      // 武器
      if (parsed.weapon) {
        const w = new CharDetailWeapon();
        w.name = parsed.weapon.name ?? '';
        w.iconUrl = parsed.weapon.icon ?? '';
        w.level = parsed.weapon.level ?? 0;
        w.affix = parsed.weapon.affix_level ?? 1;
        w.rarity = parsed.weapon.rarity ?? 3;
        if (parsed.weapon.main_property) {
          const baseAtkStr = parsed.weapon.main_property.final ?? '';
          w.baseAtk = baseAtkStr !== '' ? parseInt(baseAtkStr) : 0;
        }
        if (parsed.weapon.sub_property) {
          w.subLabel = genshinPropertyTypeToResource(parsed.weapon.sub_property.property_type ?? 0);
          w.subVal = parsed.weapon.sub_property.final ?? '';
        }
        this.weapon = w;
      }

      // 属性列表
      this.stats = this.buildStats(parsed);

      // 圣遗物
      const relics: CharDetailRelic[] = [];
      if (parsed.relics) {
        for (let i = 0; i < parsed.relics.length; i++) {
          const r = parsed.relics[i];
          const relic = new CharDetailRelic();
          relic.pos = r.pos ?? (i + 1);
          relic.iconUrl = r.icon ?? '';
          relic.setName = r.set ? r.set.name : '';
          relic.level = r.level ?? 0;
          relic.rarity = r.rarity ?? 5;
          if (r.main_property) {
            relic.mainStatLabel = genshinPropertyTypeToResource(r.main_property.property_type ?? 0);
            relic.mainStatValue = r.main_property.value ?? '';
          }
          const subs: RelicSubStat[] = [];
          if (r.sub_property_list) {
            for (let j = 0; j < r.sub_property_list.length; j++) {
              const sub = new RelicSubStat();
              sub.label = genshinPropertyTypeToResource(r.sub_property_list[j].property_type ?? 0);
              sub.value = r.sub_property_list[j].value ?? '';
              subs[subs.length] = sub;
            }
          }          relic.subStats = subs;
          relics[relics.length] = relic;
        }
      }
      this.relics = relics;

      // 技能（取前3个）
      const skills: CharDetailSkill[] = [];
      if (parsed.skills) {
        const count = Math.min(3, parsed.skills.length);
        for (let i = 0; i < count; i++) {
          const sk = new CharDetailSkill();
          sk.iconUrl = parsed.skills[i].icon ?? '';
          sk.level = parsed.skills[i].level ?? 0;
          sk.name = parsed.skills[i].name ?? '';
          skills[skills.length] = sk;
        }
      }
      this.skills = skills;
    } catch (error) {
      const msg = error instanceof Error ? error.message : `${error}`;
      Logger.error(TAG, `parseRawJson failed: ${msg}`);
    }
  }

  private buildStats(parsed: GenshinCharacterDetailRaw): CharDetailStat[] {
    const result: CharDetailStat[] = [];
    if (!parsed.selected_properties) {
      return result;
    }
    // 建立 property_type → final 查找表
    const ptArr: number[] = [];
    const valArr: string[] = [];
    for (let i = 0; i < parsed.selected_properties.length; i++) {
      const sp = parsed.selected_properties[i];
      ptArr[ptArr.length] = sp.property_type;
      valArr[valArr.length] = sp.final;
    }
    for (let i = 0; i < GENSHIN_STAT_ORDER.length; i++) {
      const pt = GENSHIN_STAT_ORDER[i];
      let val: string = '';
      for (let k = 0; k < ptArr.length; k++) {
        if (ptArr[k] === pt) {
          val = valArr[k];
          break;
        }
      }
      if (val === '') { continue; }
      let isHighlight = false;
      for (let j = 0; j < GENSHIN_HIGHLIGHT_PROPS.length; j++) {
        if (GENSHIN_HIGHLIGHT_PROPS[j] === pt) {
          isHighlight = true;
          break;
        }
      }
      result[result.length] = new CharDetailStat(GENSHIN_STAT_LABELS[i], val, isHighlight);
    }
    return result;
  }

}
