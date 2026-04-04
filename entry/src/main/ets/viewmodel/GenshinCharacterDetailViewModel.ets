/**
 * GenshinCharacterDetailViewModel.ets
 *
 * 角色详情页 ViewModel。
 * 从 DB 读取 rawJson，解析为详情展示模型。
 * 所有 property_type 数字必须通过 GenshinPropertyType enum 引用，禁止写字面量。
 */

import { CoreInitializerV2, GenshinPropertyType } from 'core';
import { Logger } from '../utils/Logger';
import { ViewState } from '../constants/ViewStates';
import { GenshinElement, elementFromString } from '../constants/GenshinElement';

const TAG: string = 'GenshinCharacterDetailViewModel';

// ─── 展示模型 ────────────────────────────────────────────────────

/** 武器详情 */
export class CharDetailWeapon {
  name: string = '';
  iconUrl: string = '';
  level: number = 0;
  maxLevel: number = 90;
  affix: number = 1;
  rarity: number = 3;
  /** 武器基础攻击力（来自 weapon.main_property.final，property_type = BASE_ATK = 4） */
  baseAtk: number = 0;
  /** 武器副词条标签（Resource，由 GenshinPropertyType enum 映射；无副词条时为 null） */
  subLabel: Resource | null = null;
  /** 武器副词条值（如"22.1%"） */
  subVal: string = '';
}

/** 圣遗物副词条 */
export class RelicSubStat {
  label: Resource | null = null;
  value: string = '';
}

/** 圣遗物详情 */
export class CharDetailRelic {
  pos: number = 0;
  iconUrl: string = '';
  setName: string = '';
  level: number = 0;
  rarity: number = 5;
  mainStatLabel: Resource | null = null;
  mainStatValue: string = '';
  subStats: RelicSubStat[] = [];
}

/** 技能详情 */
export class CharDetailSkill {
  iconUrl: string = '';
  level: number = 0;
}

/** 命座详情（含完整信息） */
export class CharDetailConstellation {
  /** 命座位置（1-6） */
  pos: number = 0;
  /** 命座名称 */
  name: string = '';
  /** 命座图标 URL */
  iconUrl: string = '';
  /** 命座效果描述 */
  effect: string = '';
  /** 是否已激活 */
  isActived: boolean = false;
}

/** 属性行 */
export class CharDetailStat {
  labelKey: Resource;
  value: string = '';
  isHighlight: boolean = false;

  constructor(labelKey: Resource, value: string, isHighlight: boolean = false) {
    this.labelKey = labelKey;
    this.value = value;
    this.isHighlight = isHighlight;
  }
}

// ─── @Monitor 路径常量 ───────────────────────────────────────────

/** GenshinCharacterDetailViewModel @Monitor 路径常量类型 */
export class GenshinCharacterDetailViewModelKeys {
  viewState: string = 'vm.viewState';
}

// ─── rawJson 内部接口（仅声明需要的字段）────────────────────────

interface RawWeapon {
  name: string;
  icon: string;
  level: number;
  affix_level: number;
  rarity: number;
}

interface RawStorageSubStat {
  property_type: number;
  value: string;
}

interface RawStorageRelic {
  pos: number;
  icon: string;
  set_name: string;
  level: number;
  rarity: number;
  main_property_type: number;
  main_property_value: string;
  sub_stats: RawStorageSubStat[];
}

interface RawStorageProperty {
  property_type: number;
  final: string;
}

/** 存储在 raw_json 中的命座数据 */
interface RawStorageConstellation {
  pos: number;
  name: string;
  icon: string;
  effect: string;
  is_actived: boolean;
}

interface CharacterRawJson {
  name: string;
  level: number;
  fetter: number;
  element: string;
  image: string;
  icon: string;
  actived_constellation_num: number;
  weapon: RawWeapon;
  /** 武器基础攻击力（来自 detail 接口 weapon.main_property.final） */
  weapon_base_atk: string;
  /** 武器副词条 property_type（对应 GenshinPropertyType enum） */
  weapon_sub_type: number;
  /** 武器副词条值（来自 detail 接口 weapon.sub_property.final） */
  weapon_sub_val: string;
  relics_detail: RawStorageRelic[];
  skill_icons: string[];
  skill_levels: number[];
  selected_properties: RawStorageProperty[];
  /** 命座完整数据（含 icon、名称、效果描述、是否已激活） */
  constellations_detail: RawStorageConstellation[];
}

// ─── ViewModel ───────────────────────────────────────────────────

@ObservedV2
export class GenshinCharacterDetailViewModel {
  static readonly KEYS: GenshinCharacterDetailViewModelKeys = new GenshinCharacterDetailViewModelKeys();

  @Trace viewState: ViewState = ViewState.LOADING;

  // 基础信息
  @Trace charName: string = '';
  @Trace charLevel: number = 0;
  @Trace charMaxLevel: number = 90;
  @Trace charFetter: number = 0;
  @Trace charElement: GenshinElement = GenshinElement.UNKNOWN;
  @Trace charImageUrl: string = '';
  @Trace charIconUrl: string = '';
  @Trace activatedConstellations: number = 0;

  // 命座（完整信息，含 icon / 名称 / 效果 / 是否已激活）
  @Trace constellations: CharDetailConstellation[] = [];

  // 武器
  @Trace weapon: CharDetailWeapon = new CharDetailWeapon();

  // 属性列表
  @Trace stats: CharDetailStat[] = [];

  // 圣遗物（最多5个）
  @Trace relics: CharDetailRelic[] = [];

  // 技能（普攻/战技/爆发，最多3个）
  @Trace skills: CharDetailSkill[] = [];

  private accountId: number = 0;
  private roleUid: string = '';
  private entityId: string = '';

  init(accountId: number, roleUid: string, entityId: string): void {
    this.accountId = accountId;
    this.roleUid = roleUid;
    this.entityId = entityId;
  }

  async loadData(): Promise<void> {
    this.viewState = ViewState.LOADING;
    try {
      const row = await CoreInitializerV2.genshinRepository.getAvatarDetail(this.accountId, this.roleUid, this.entityId);
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
      const parsed = JSON.parse(rawJson) as CharacterRawJson;
      this.charName = parsed.name ?? '';
      this.charLevel = parsed.level ?? 0;
      this.charMaxLevel = 90;
      this.charFetter = parsed.fetter ?? 0;
      this.charElement = elementFromString(parsed.element ?? '');
      this.charImageUrl = parsed.image ?? '';
      this.charIconUrl = parsed.icon ?? '';
      this.activatedConstellations = parsed.actived_constellation_num ?? 0;

      // 命座（优先使用 constellations_detail 完整数据）
      const cons: CharDetailConstellation[] = [];
      if (parsed.constellations_detail && parsed.constellations_detail.length > 0) {
        for (let i = 0; i < parsed.constellations_detail.length; i++) {
          const c = parsed.constellations_detail[i];
          const cd = new CharDetailConstellation();
          cd.pos = c.pos;
          cd.name = c.name;
          cd.iconUrl = c.icon;
          cd.effect = c.effect;
          cd.isActived = c.is_actived;
          cons[cons.length] = cd;
        }
      } else {
        // 兼容旧数据：仅有激活数量，无完整命座信息
        for (let i = 0; i < 6; i++) {
          const cd = new CharDetailConstellation();
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
        w.maxLevel = 90;
        w.affix = parsed.weapon.affix_level ?? 1;
        w.rarity = parsed.weapon.rarity ?? 3;
        // 武器基础攻击力：weapon_base_atk 字段（property_type = BASE_ATK = 4）
        const baseAtkStr = parsed.weapon_base_atk ?? '';
        w.baseAtk = baseAtkStr !== '' ? parseInt(baseAtkStr) : 0;
        // 武器副词条：weapon_sub_type 对应 GenshinPropertyType enum
        w.subLabel = GenshinCharacterDetailViewModel.propertyTypeToResource(parsed.weapon_sub_type ?? 0);
        w.subVal = parsed.weapon_sub_val ?? '';
        this.weapon = w;
      }

      // 属性列表（从 selected_properties 按 GenshinPropertyType 映射）
      this.stats = this.buildStats(parsed);

      // 圣遗物（从 relics_detail 解析完整词条）
      const relics: CharDetailRelic[] = [];
      if (parsed.relics_detail) {
        for (let i = 0; i < parsed.relics_detail.length; i++) {
          const r = parsed.relics_detail[i];
          const relic = new CharDetailRelic();
          relic.pos = r.pos ?? (i + 1);
          relic.iconUrl = r.icon ?? '';
          relic.setName = r.set_name ?? '';
          relic.level = r.level ?? 0;
          relic.rarity = r.rarity ?? 5;
          relic.mainStatLabel = GenshinCharacterDetailViewModel.propertyTypeToResource(r.main_property_type ?? 0);
          relic.mainStatValue = r.main_property_value ?? '';
          const subs: RelicSubStat[] = [];
          if (r.sub_stats) {
            for (let j = 0; j < r.sub_stats.length; j++) {
              const sub = new RelicSubStat();
              sub.label = GenshinCharacterDetailViewModel.propertyTypeToResource(r.sub_stats[j].property_type ?? 0);
              sub.value = r.sub_stats[j].value ?? '';
              subs[subs.length] = sub;
            }
          }
          relic.subStats = subs;
          relics[relics.length] = relic;
        }
      }
      this.relics = relics;

      // 技能（取前3个：普攻/战技/爆发）
      const skills: CharDetailSkill[] = [];
      if (parsed.skill_icons && parsed.skill_levels) {
        const count = Math.min(3, parsed.skill_icons.length);
        for (let i = 0; i < count; i++) {
          const sk = new CharDetailSkill();
          sk.iconUrl = parsed.skill_icons[i] ?? '';
          sk.level = parsed.skill_levels[i] ?? 0;
          skills[skills.length] = sk;
        }
      }
      this.skills = skills;
    } catch (error) {
      const msg = error instanceof Error ? error.message : `${error}`;
      Logger.error(TAG, `parseRawJson failed: ${msg}`);
    }
  }

  private buildStats(parsed: CharacterRawJson): CharDetailStat[] {
    const result: CharDetailStat[] = [];
    if (!parsed.selected_properties) {
      return result;
    }
    // 展示顺序：HP → ATK → DEF → EM → 暴击率 → 暴击伤害 → 充能效率 → 治疗加成
    const ORDER: number[] = [
      GenshinPropertyType.HP_FINAL,
      GenshinPropertyType.ATK_FINAL,
      GenshinPropertyType.DEF_FINAL,
      GenshinPropertyType.ELEMENTAL_MASTERY,
      GenshinPropertyType.CRIT_RATE,
      GenshinPropertyType.CRIT_DMG,
      GenshinPropertyType.ENERGY_RECHARGE,
      GenshinPropertyType.HEALING_BONUS,
    ];
    // 属性面板标签（与 ORDER 一一对应）
    const LABEL_KEYS: Resource[] = [
      $r('app.string.char_detail_hp'),
      $r('app.string.char_detail_atk'),
      $r('app.string.char_detail_def'),
      $r('app.string.char_detail_em'),
      $r('app.string.char_detail_cr'),
      $r('app.string.char_detail_cd'),
      $r('app.string.char_detail_er'),
      $r('app.string.char_detail_heal'),
    ];
    // 暴击率/暴击伤害高亮显示
    const HIGHLIGHT: number[] = [
      GenshinPropertyType.CRIT_RATE,
      GenshinPropertyType.CRIT_DMG,
    ];
    // 建立 property_type → final 查找表（用数组模拟，避免 Map）
    const ptArr: number[] = [];
    const valArr: string[] = [];
    for (let i = 0; i < parsed.selected_properties.length; i++) {
      const sp = parsed.selected_properties[i];
      ptArr[ptArr.length] = sp.property_type;
      valArr[valArr.length] = sp.final;
    }
    for (let i = 0; i < ORDER.length; i++) {
      const pt = ORDER[i];
      let val: string = '';
      for (let k = 0; k < ptArr.length; k++) {
        if (ptArr[k] === pt) {
          val = valArr[k];
          break;
        }
      }
      if (val === '') {
        continue;
      }
      let isHighlight = false;
      for (let j = 0; j < HIGHLIGHT.length; j++) {
        if (HIGHLIGHT[j] === pt) {
          isHighlight = true;
          break;
        }
      }
      result[result.length] = new CharDetailStat(LABEL_KEYS[i], val, isHighlight);
    }
    return result;
  }

  /**
   * GenshinPropertyType → Resource（用于圣遗物词条、武器副词条、属性面板等所有场景）
   * 未知 property_type 返回 null。
   */
  static propertyTypeToResource(pt: number): Resource | null {
    if (pt === GenshinPropertyType.HP_FLAT) { return $r('app.string.prop_hp_flat'); }
    if (pt === GenshinPropertyType.HP_PCT) { return $r('app.string.prop_hp_pct'); }
    if (pt === GenshinPropertyType.BASE_ATK) { return $r('app.string.prop_base_atk'); }
    if (pt === GenshinPropertyType.ATK_FLAT) { return $r('app.string.prop_atk_flat'); }
    if (pt === GenshinPropertyType.ATK_PCT) { return $r('app.string.prop_atk_pct'); }
    if (pt === GenshinPropertyType.DEF_FLAT) { return $r('app.string.prop_def_flat'); }
    if (pt === GenshinPropertyType.DEF_PCT) { return $r('app.string.prop_def_pct'); }
    if (pt === GenshinPropertyType.BASE_HP) { return $r('app.string.prop_base_hp'); }
    if (pt === GenshinPropertyType.BASE_DEF) { return $r('app.string.prop_base_def'); }
    if (pt === GenshinPropertyType.CRIT_RATE) { return $r('app.string.prop_crit_rate'); }
    if (pt === GenshinPropertyType.CRIT_DMG) { return $r('app.string.prop_crit_dmg'); }
    if (pt === GenshinPropertyType.ENERGY_RECHARGE) { return $r('app.string.prop_energy_recharge'); }
    if (pt === GenshinPropertyType.HEALING_BONUS) { return $r('app.string.prop_healing_bonus'); }
    if (pt === GenshinPropertyType.INCOMING_HEALING_BONUS) { return $r('app.string.prop_incoming_healing'); }
    if (pt === GenshinPropertyType.ELEMENTAL_MASTERY) { return $r('app.string.prop_elemental_mastery'); }
    if (pt === GenshinPropertyType.HP_FINAL) { return $r('app.string.prop_hp_flat'); }
    if (pt === GenshinPropertyType.ATK_FINAL) { return $r('app.string.prop_atk_flat'); }
    if (pt === GenshinPropertyType.DEF_FINAL) { return $r('app.string.prop_def_flat'); }
    if (pt === GenshinPropertyType.PYRO_DMG_BONUS) { return $r('app.string.prop_pyro_dmg'); }
    if (pt === GenshinPropertyType.ELECTRO_DMG_BONUS) { return $r('app.string.prop_electro_dmg'); }
    if (pt === GenshinPropertyType.HYDRO_DMG_BONUS) { return $r('app.string.prop_hydro_dmg'); }
    if (pt === GenshinPropertyType.DENDRO_DMG_BONUS) { return $r('app.string.prop_dendro_dmg'); }
    if (pt === GenshinPropertyType.ANEMO_DMG_BONUS) { return $r('app.string.prop_anemo_dmg'); }
    if (pt === GenshinPropertyType.GEO_DMG_BONUS) { return $r('app.string.prop_geo_dmg'); }
    if (pt === GenshinPropertyType.CRYO_DMG_BONUS) { return $r('app.string.prop_cryo_dmg'); }
    if (pt === GenshinPropertyType.PHYSICAL_DMG_BONUS) { return $r('app.string.prop_physical_dmg'); }
    if (pt === GenshinPropertyType.COOLDOWN_REDUCTION) { return $r('app.string.prop_cooldown_reduction'); }
    if (pt === GenshinPropertyType.SHIELD_STRENGTH) { return $r('app.string.prop_shield_strength'); }
    return null;
  }
}
