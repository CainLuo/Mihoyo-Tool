/**
 * GenshinMaterialListViewModel.ets — 原神材料汇总页 ViewModel
 *
 * 原神材料汇总页展示所有角色的材料需求汇总。
 * 原神 compute API 支持批量请求，返回 items[] 数组。
 * 材料缺口通过 overall_consume 字段提供。
 *
 * 数据流：
 *   init() → 读本地 DB（角色 + 计算数据） → 解析材料 → 渲染
 *
 * 状态机：
 *   LOADING → DATA    有计算数据
 *   LOADING → EMPTY   无计算数据
 */

import {
  CoreInitializer,
  Logger,
  GenshinComputeParser,
  GameId,
  GenshinCharacterComputeRow,
  GenshinCharacterDetailRow,
  GenshinCharacterDetailRaw,
} from 'core';
import { ViewState } from 'basic';
import { MaterialTargetConfigParam } from '../model/ToolsModels';
import { MaterialComputeService } from '../model/service/MaterialComputeService'
import { MaterialComputeResult } from '../model/MaterialComputeResult';
import {
  MaterialListViewMode,
  CharacterMaterialVM,
  MaterialSummaryVM,
  MaterialItemVM,
  MaterialItemRaw,
  RelatedCharacterVM,
  WeaponMaterialVM,
  SkillItemVM,
  MaterialSectionVM,
} from '../model/MaterialListModels';
import { MaterialListAggregator } from './MaterialListAggregator';

/** 养成计算链路统一日志 tag，过滤：hilog | grep */
const CALC_TAG: string = 'GenshinCalc';

/** 货币类材料：经验书（104003）、精锻用魔矿（104013）、摩拉（202），单独分组 */
const CURRENCY_MATERIAL_IDS: Set<string> = new Set<string>(['202', '104003', '104013']);

const TAG: string = 'GenshinMaterialListViewModel';

/** genshin_compute_summary.overall_consume_json 中的材料项（API 原样字段） */
interface OverallMaterialRaw {
  id: number;
  name?: string;
  icon?: string;
  icon_url?: string;
  num: number;
  lack_num?: number;
  level?: number;
}
/** 材料页日志 tag，过滤：hilog | grep */
const PAGE_CALC_TAG: string = 'MaterialList';

@ObservedV2
export class GenshinMaterialListViewModel {
  @Trace viewState: ViewState = ViewState.LOADING;
  @Trace viewMode: MaterialListViewMode = MaterialListViewMode.CHARACTER;
  @Trace characterMaterials: CharacterMaterialVM[] = [];
  @Trace materialSummaries: MaterialSummaryVM[] = [];
  @Trace materialSections: MaterialSectionVM[] = [];
  @Trace isSyncing: boolean = false;
  @Trace syncErrorMsg: string = '';

  /** 路由参数：选中的账号 / 游戏 UID / 角色 / 目标等级。只展示、只计算这些角色 */
  private selection: MaterialTargetConfigParam | null = null;

  // ─── 公开方法 ────────────────────────────────────────────────

  /**
   * 初始化：只加载路由参数中选中角色的材料数据。
   */
  async init(selection: MaterialTargetConfigParam | null): Promise<void> {
    this.selection = selection;
    Logger.info(PAGE_CALC_TAG, `[${TAG}] init, selection=${selection === null ? 'null' :
      `account=${selection.accountId}, role=${selection.roleUid}, avatarIds=${selection.avatarIds.join(',')}`}`);
    this.viewState = ViewState.LOADING;
    await this.loadData();
  }

  /** 当前选中信息（给页面跳转养成目标配置页用） */
  getSelection(): MaterialTargetConfigParam | null {
    return this.selection;
  }

  /**
   * 切换视图模式。
   */
  toggleViewMode(): void {
    // 简单切换，不触发任何数据重新计算
    if (this.viewMode === MaterialListViewMode.CHARACTER) {
      this.viewMode = MaterialListViewMode.MATERIAL;
    } else {
      this.viewMode = MaterialListViewMode.CHARACTER;
    }
  }

  /**
   * 展开/折叠角色材料卡片。
   */
  toggleCharacterExpand(characterId: string): void {
    for (let i = 0; i < this.characterMaterials.length; i++) {
      if (this.characterMaterials[i].characterId === characterId) {
        this.characterMaterials[i].isExpanded = !this.characterMaterials[i].isExpanded;
        break;
      }
    }
  }

  /**
   * 重新计算：只重新计算路由参数中选中的角色（目标等级从 DB 读取），完成后重新加载。
   */
  async syncComputeData(): Promise<void> {
    const sel = this.selection;
    if (this.isSyncing) {
      return;
    }
    if (sel === null || sel.avatarIds.length === 0) {
      Logger.warn(PAGE_CALC_TAG, `[${TAG}] syncComputeData: no selection, skip`);
      this.syncErrorMsg = 'no_selection';
      return;
    }
    this.isSyncing = true;
    this.syncErrorMsg = '';
    try {
      // 目标等级由 MaterialComputeService 从 DB 读取
      const result = await MaterialComputeService.compute(sel);
      Logger.info(PAGE_CALC_TAG, `[${TAG}] syncComputeData result=${result}`);
      if (result === MaterialComputeResult.FAILED) {
        this.syncErrorMsg = 'compute_failed';
      } else if (result === MaterialComputeResult.NO_CONFIG) {
        this.syncErrorMsg = 'no_config';
      }
      await this.loadData();
    } finally {
      this.isSyncing = false;
    }
  }

  // ─── 私有方法 ────────────────────────────────────────────────

  private async loadData(): Promise<void> {
    Logger.info(TAG, `loadData: start`);
    try {
      // 只加载选中的账号 / 游戏 UID / 角色（全部角色的材料汇总是后续需求）
      const sel = this.selection;
      if (sel === null || sel.avatarIds.length === 0) {
        Logger.warn(PAGE_CALC_TAG, `[${TAG}] loadData: no selection`);
        this.viewState = ViewState.EMPTY;
        return;
      }

      const allCharacterMaterials: CharacterMaterialVM[] = [];
      /** avatarId → (materialId → 该角色需求量)，用于汇总视图的关联角色 */
      const charNeeds = new Map<string, Map<string, number>>();
      const charMaterials = await this.loadCharacterMaterials(sel.accountId, sel.roleUid, sel.avatarIds, charNeeds);
      for (let k = 0; k < charMaterials.length; k++) {
        if (sel.avatarIds.includes(charMaterials[k].characterId)) {
          allCharacterMaterials[allCharacterMaterials.length] = charMaterials[k];
        }
      }
      Logger.info(PAGE_CALC_TAG, `[${TAG}] loadData: selected=${sel.avatarIds.length}, loaded=${charMaterials.length}, ` +
        `shown=${allCharacterMaterials.length} (${allCharacterMaterials.map((c: CharacterMaterialVM) => c.characterId).join(',')})`);

      Logger.info(TAG, `loadData: total allCharacterMaterials.length=${allCharacterMaterials.length}`);
      
      if (allCharacterMaterials.length === 0) {
        this.viewState = ViewState.EMPTY;
        return;
      }

      // 材料背包（batch_compute 的 available_material，DB：genshin_material_bag），用于汇总视图的"已拥有"
      const bagCounts = new Map<string, number>();
      try {
        const bag = await CoreInitializer.genshinRepository.getMaterialBag(sel.accountId, sel.roleUid);
        for (let i = 0; i < bag.length; i++) {
          bagCounts.set(bag[i].materialId, bag[i].count);
        }
      } catch (error) {
        Logger.warn(PAGE_CALC_TAG, `[${TAG}] loadData: read material bag failed: ${error instanceof Error ? error.message : `${error}`}`);
      }

      // 已达成目标的角色永远排在最后（同组内保持原顺序）
      // 每次加载生成新的渲染 key，保证刷新后列表按新数据重新渲染（顺序 + 内容）
      const loadVersion = Date.now();
      this.characterMaterials = MaterialListAggregator.sortCharactersForDisplay(allCharacterMaterials, loadVersion);

      // 汇总视图：优先使用整批合计（genshin_compute_summary.overall_consume，接口算好的精确总缺口），
      // 只有当它正好对应当前展示的这批计算结果时才使用；否则回退到按角色估算
      const summaryRow = await CoreInitializer.genshinRepository.getComputeSummary(sel.accountId, sel.roleUid);
      const computedIds: string[] = [];
      charNeeds.forEach((_v: Map<string, number>, avatarId: string) => {
        computedIds[computedIds.length] = avatarId;
      });
      const summaryIds = summaryRow !== null && summaryRow.avatarIds.length > 0 ? summaryRow.avatarIds.split(',') : [];
      const summaryMatches = summaryRow !== null && summaryIds.length === computedIds.length &&
        computedIds.every((id: string) => summaryIds.includes(id));
      if (summaryRow !== null && summaryMatches) {
        this.materialSummaries = this.buildSummariesFromOverall(summaryRow.overallConsumeJson, charNeeds, allCharacterMaterials);
        Logger.info(PAGE_CALC_TAG, `[${TAG}] loadData: summary from overall_consume, materials=${this.materialSummaries.length}`);
      } else {
        this.materialSummaries = MaterialListAggregator.aggregateMaterials(allCharacterMaterials, bagCounts);
        Logger.warn(PAGE_CALC_TAG, `[${TAG}] loadData: no matching compute summary (summary=${summaryIds.join(',')}, computed=${computedIds.join(',')}), use estimate`);
      }
      this.materialSections = MaterialListAggregator.groupIntoSections(this.materialSummaries, CURRENCY_MATERIAL_IDS);
      MaterialListAggregator.stampSectionKeys(this.materialSections, loadVersion);
      this.viewState = ViewState.DATA;
    } catch (error) {
      const msg = error instanceof Error ? error.message : `${error}`;
      Logger.error(TAG, `loadData failed: ${msg}`);
      this.viewState = ViewState.EMPTY;
    }
  }

  /**
   * 加载原神角色材料数据。
   * 原神一个 game_role 包含多个角色，返回 CharacterMaterialVM 数组。
   */
  private async loadCharacterMaterials(
    accountId: string,
    roleUid: string,
    onlyAvatarIds: string[],
    needsOut: Map<string, Map<string, number>>,
  ): Promise<CharacterMaterialVM[]> {
    Logger.info(TAG, `loadCharacterMaterials: accountId=${accountId}, roleUid=${roleUid}`);
    
    // 获取角色基础信息
    const avatarList = await CoreInitializer.genshinRepository.getAvatarList(accountId, roleUid);
    Logger.info(TAG, `loadCharacterMaterials: avatarList.length=${avatarList.length}`);
    
    if (avatarList.length === 0) {
      Logger.warn(TAG, `loadCharacterMaterials: no avatarList`);
      return [];
    }

    // 获取所有计算数据
    const computeRows = await CoreInitializer.genshinRepository.getAllComputeData(accountId, roleUid);
    Logger.info(TAG, `loadCharacterMaterials: computeRows.length=${computeRows.length}`);
    
    // 没有计算结果的选中角色会显示为"已达成目标"，因此这里不提前返回

    // 获取所有角色详情（用于提取技能等级）
    const detailRows = await CoreInitializer.genshinRepository.getAllAvatarDetails(accountId, roleUid);
    const detailMap = new Map<string, GenshinCharacterDetailRow>();
    for (let i = 0; i < detailRows.length; i++) {
      const row = detailRows[i];
      detailMap.set(row.avatarId, row);
    }

    // 构建 avatarId -> computeRow 的映射
    const computeMap = new Map<string, GenshinCharacterComputeRow>();
    for (let i = 0; i < computeRows.length; i++) {
      const row = computeRows[i];
      computeMap.set(row.avatarId, row);
    }

    const result: CharacterMaterialVM[] = [];

    // 遍历 avatarList，为每个选中角色创建 VM
    for (let i = 0; i < avatarList.length; i++) {
      const avatar = avatarList[i];
      if (!onlyAvatarIds.includes(avatar.avatarId)) {
        continue;
      }
      const computeRow = computeMap.get(avatar.avatarId);

      const vm = new CharacterMaterialVM();
      vm.characterId = avatar.avatarId;
      vm.characterName = avatar.name;
      vm.characterIconUrl = avatar.icon;
      vm.characterLevel = avatar.level;
      vm.characterRarity = avatar.rarity;
      vm.element = avatar.element;
      vm.gameId = GameId.GENSHIN;

      // 已达成目标：DB 中标记 target_reached = 1，或选中但没有计算结果
      if (computeRow === undefined || computeRow === null || computeRow.targetReached === 1) {
        vm.isTargetReached = true;
      }

      // 解析材料数据（DB 各列为 API 原样数据，缺口由 Parser 按该角色的 overall_consume 计算）
      const parsed = !vm.isTargetReached && computeRow !== undefined && computeRow !== null
        ? GenshinComputeParser.parseRow(computeRow.avatarId, computeRow.avatarConsumeJson,
          computeRow.avatarSkillConsumeJson, computeRow.weaponConsumeJson, computeRow.overallConsumeJson)
        : null;

      if (parsed !== null) {
        // 该角色各材料的需求量（未过滤，用于汇总视图的关联角色）
        const needs = new Map<string, number>();
        const allConsume = parsed.avatarConsume.concat(parsed.skillConsume, parsed.weaponConsume);
        for (let k = 0; k < allConsume.length; k++) {
          const mid = `${allConsume[k].id}`;
          needs.set(mid, (needs.get(mid) ?? 0) + allConsume[k].num);
        }
        needsOut.set(avatar.avatarId, needs);

        // 角色突破材料
        if (parsed.avatarConsume.length > 0) {
          vm.avatarMaterials = this.parseMaterialItems(parsed.avatarConsume);
        }

        // 技能材料
        if (parsed.skillConsume.length > 0) {
          vm.skillMaterials = this.parseMaterialItems(parsed.skillConsume);
        }

        // 武器材料
        if (parsed.weaponConsume.length > 0) {
          vm.weaponMaterials = this.parseMaterialItems(parsed.weaponConsume);
        }
      }

      // 武器信息
      if (avatar.weaponName.length > 0) {
        const weapon = new WeaponMaterialVM();
        weapon.weaponId = avatar.weaponId;
        weapon.weaponName = avatar.weaponName;
        weapon.weaponIconUrl = avatar.weaponIconUrl;
        weapon.weaponLevel = avatar.weaponLevel;
        weapon.weaponRarity = avatar.weaponRarity;
        vm.weapon = weapon;
      }

      // 技能等级和图标（从角色详情获取）
      const detailRow = detailMap.get(avatar.avatarId);
      if (detailRow !== undefined && detailRow.rawJson.length > 0) {
        vm.skills = this.parseSkillItems(detailRow.rawJson);
      }

      vm.isExpanded = false; // 默认折叠
      result[result.length] = vm;
    }

    Logger.info(TAG, `loadCharacterMaterials: returning ${result.length} VMs`);
    Logger.info(CALC_TAG, `[Page] roleUid=${roleUid}: computeRows=${computeRows.length} (avatarIds=${computeRows.map((r: GenshinCharacterComputeRow) => r.avatarId).join(',')}), matched characters=${result.length}`);
    return result;
  }

  /**
   * 将解析后的材料数据转换为 MaterialItemVM 数组。
   *
   * 原神 API：返回 lack_num（缺少数量），have = num - lackNum
   * 过滤规则：已满足或已超过的材料（have >= need）不显示
   */
  private parseMaterialItems(items: MaterialItemRaw[]): MaterialItemVM[] {
    return MaterialListAggregator.buildMaterialItems(
      items,
      (item: MaterialItemRaw): number => item.num - (item.lackNum ?? 0),
      MaterialListAggregator.rarityFromString);
  }

  /**
   * 解析角色详情 rawJson 中的技能信息（图标 + 等级）。
   * 只取 skill_type=1 的可升级技能（普攻、E、Q）。
   */
  private parseSkillItems(rawJson: string): SkillItemVM[] {
    if (rawJson.length === 0) {
      return [];
    }

    const result: SkillItemVM[] = [];

    try {
      const parsed = JSON.parse(rawJson) as GenshinCharacterDetailRaw;
      if (parsed.skills === undefined || parsed.skills === null) {
        return [];
      }

      for (let i = 0; i < parsed.skills.length; i++) {
        const sk = parsed.skills[i];
        // skill_type=1 是可升级技能（普攻、E、Q），skill_type=2 是固有天赋/被动
        if (sk.skill_type === 1 || sk.skill_type === undefined) {
          const item = new SkillItemVM();
          item.iconUrl = sk.icon ?? '';
          item.level = sk.level ?? 1;
          result[result.length] = item;
        }
      }
    } catch (error) {
      const msg = error instanceof Error ? error.message : `${error}`;
      Logger.warn(TAG, `parseSkillItems failed: ${msg}`);
    }

    return result;
  }

  /**
   * 用整批合计 overall_consume 构建按材料视图（精确值）。
   * - 需求 = num，已拥有 = num - lack_num（接口已扣除背包并计入合成）
   * - 只展示仍有缺口（lack_num > 0）的材料，与按角色视图"已满足不显示"一致
   * - 关联角色取自各角色自己的需求量
   * 排序规则与 aggregateMaterials 一致：按 materialId 从大到小。
   */
  private buildSummariesFromOverall(
    overallConsumeJson: string,
    charNeeds: Map<string, Map<string, number>>,
    characters: CharacterMaterialVM[],
  ): MaterialSummaryVM[] {
    let overall: OverallMaterialRaw[] = [];
    try {
      const parsed = JSON.parse(overallConsumeJson) as OverallMaterialRaw[];
      overall = Array.isArray(parsed) ? parsed : [];
    } catch (_) {
      overall = [];
    }

    const result: MaterialSummaryVM[] = [];
    for (let i = 0; i < overall.length; i++) {
      const m = overall[i];
      const lack = m.lack_num ?? 0;
      if (lack <= 0) {
        continue;
      }
      const materialId = `${m.id}`;
      const summary = new MaterialSummaryVM();
      summary.materialId = materialId;
      summary.name = m.name ?? '';
      summary.iconUrl = m.icon ?? m.icon_url ?? '';
      summary.rarity = m.level ?? 1;
      summary.totalNeed = m.num;
      summary.totalHave = Math.max(m.num - lack, 0);

      const related: RelatedCharacterVM[] = [];
      for (let c = 0; c < characters.length; c++) {
        const need = charNeeds.get(characters[c].characterId)?.get(materialId) ?? 0;
        if (need > 0) {
          const rc = new RelatedCharacterVM();
          rc.characterId = characters[c].characterId;
          rc.characterName = characters[c].characterName;
          rc.characterIconUrl = characters[c].characterIconUrl;
          rc.needCount = need;
          related[related.length] = rc;
        }
      }
      summary.relatedCharacters = related;
      result[result.length] = summary;
    }

    result.sort((a, b) => (parseInt(b.materialId, 10) || 0) - (parseInt(a.materialId, 10) || 0));
    return result;
  }
}
