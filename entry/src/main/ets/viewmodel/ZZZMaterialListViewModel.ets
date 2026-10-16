/**
 * ZZZMaterialListViewModel.ets — 绝区零材料汇总页 ViewModel
 *
 * 绝区零材料汇总页展示所有代理人的材料需求汇总。
 * 绝区零 API 直接返回 need_get 字段，包含缺口汇总，无需前端计算。
 *
 * 数据流：
 *   init() → 读本地 DB（角色 + 计算数据） → 解析 need_get → 渲染
 *
 * 状态机：
 *   LOADING → DATA    有计算数据
 *   LOADING → EMPTY   无计算数据
 */

import {
  CoreInitializer,
  Logger,
  ZZZComputeParser,
  GameId,
} from 'core';
import { ViewState } from '../constants/ViewStates';
import { MaterialTargetConfigParam } from '../models/ToolsModels';
import { MaterialComputeService, MaterialComputeResult } from '../utils/MaterialComputeService';
import {
  MaterialListViewMode,
  CharacterMaterialVM,
  MaterialSummaryVM,
  MaterialItemVM,
  MaterialItemRaw,
  RelatedCharacterVM,
  MaterialSectionVM,
  MaterialSectionType,
} from '../models/MaterialListModels';

const TAG: string = 'ZZZMaterialListViewModel';
/** 材料页日志 tag，过滤：hilog | grep 🚀🚀🚀 */
const PAGE_CALC_TAG: string = '🚀🚀🚀 MaterialList';

/** ZZZMaterialListViewModel @Monitor 路径常量类型 */
export class ZZZMaterialListViewModelKeys {
  viewMode: string = 'vm.viewMode';
}

@ObservedV2
export class ZZZMaterialListViewModel {
  /** @Monitor 路径常量 */
  static readonly KEYS: ZZZMaterialListViewModelKeys = new ZZZMaterialListViewModelKeys();

  @Trace viewState: ViewState = ViewState.LOADING;
  @Trace viewMode: MaterialListViewMode = MaterialListViewMode.CHARACTER;
  @Trace characterMaterials: CharacterMaterialVM[] = [];
  @Trace materialSummaries: MaterialSummaryVM[] = [];
  @Trace materialSections: MaterialSectionVM[] = [];
  @Trace isRefreshing: boolean = false;
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
    if (this.viewMode === MaterialListViewMode.CHARACTER) {
      this.viewMode = MaterialListViewMode.MATERIAL;
    } else {
      this.viewMode = MaterialListViewMode.CHARACTER;
    }
  }

  /**
   * 下拉刷新：重新加载数据。
   */
  async refresh(): Promise<void> {
    if (this.isRefreshing) {
      return;
    }
    this.isRefreshing = true;
    try {
      await this.loadData();
    } finally {
      this.isRefreshing = false;
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
      const charMaterials = await this.loadCharacterMaterials(sel.accountId, sel.roleUid, sel.avatarIds);
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

      this.characterMaterials = allCharacterMaterials;
      this.materialSummaries = this.aggregateMaterials(allCharacterMaterials);
      this.materialSections = this.groupMaterialsIntoSections(this.materialSummaries);
      this.viewState = ViewState.DATA;
    } catch (error) {
      const msg = error instanceof Error ? error.message : `${error}`;
      Logger.error(TAG, `loadData failed: ${msg}`);
      this.viewState = ViewState.EMPTY;
    }
  }

  /**
   * 加载单个游戏角色的材料数据。
   */
  /**
   * 加载选中角色的材料数据。
   * 选中但没有计算结果的角色：计算时已判定达到目标（MaterialComputeService 跳过），显示为"已达成目标"。
   */
  private async loadCharacterMaterials(accountId: string, roleUid: string, onlyAvatarIds: string[]): Promise<CharacterMaterialVM[]> {
    const avatarList = await CoreInitializer.zzzRepository.getAvatarList(accountId, roleUid);
    if (avatarList.length === 0) {
      return [];
    }

    const result: CharacterMaterialVM[] = [];

    for (let i = 0; i < avatarList.length; i++) {
      const avatar = avatarList[i];
      if (!onlyAvatarIds.includes(avatar.avatarId)) {
        continue;
      }
      const computeRow = await CoreInitializer.zzzRepository.getAvatarCompute(accountId, roleUid, avatar.avatarId);

      if (computeRow === null) {
        const reached = new CharacterMaterialVM();
        reached.characterId = avatar.avatarId;
        reached.characterName = avatar.nameMi18n;
        reached.characterIconUrl = avatar.hollowIconPath;
        reached.characterLevel = avatar.level;
        reached.characterRarity = avatar.rarity === 'S' ? 5 : 4;
        reached.gameId = GameId.ZZZ;
        reached.isTargetReached = true;
        result[result.length] = reached;
        continue;
      }

      const vm = new CharacterMaterialVM();
      vm.characterId = avatar.avatarId;
      vm.characterName = avatar.nameMi18n;
      vm.characterIconUrl = avatar.hollowIconPath;
      vm.characterLevel = avatar.level;
      vm.characterRarity = avatar.rarity === 'S' ? 5 : 4;
      vm.gameId = GameId.ZZZ;
      // 绝区零显示"所需材料"而非"角色材料"
      vm.avatarSectionTitle = $r('app.string.material_section_needed');

      const parsed = ZZZComputeParser.parse(computeRow.rawJson);

      // 绝区零 API 返回 need_get 字段，直接使用
      if (parsed.needGet.length > 0) {
        vm.avatarMaterials = this.parseNeedGetItems(parsed.needGet);
      } else {
        if (parsed.avatarConsume.length > 0) {
          vm.avatarMaterials = this.parseMaterialItems(parsed.avatarConsume, parsed.userOwnsMaterials);
        }
        if (parsed.skillConsume.length > 0) {
          vm.skillMaterials = this.parseMaterialItems(parsed.skillConsume, parsed.userOwnsMaterials);
        }
        if (parsed.weaponConsume.length > 0) {
          vm.weaponMaterials = this.parseMaterialItems(parsed.weaponConsume, parsed.userOwnsMaterials);
        }
      }

      vm.isExpanded = true;
      result[result.length] = vm;
    }

    return result;
  }

  /**
   * 解析 need_get 字段（API 已计算好的缺口列表）。
   * need_get 中的 num 字段就是缺少数量（cnt）。
   */
  private parseNeedGetItems(items: MaterialItemRaw[]): MaterialItemVM[] {
    Logger.info(TAG, `parseNeedGetItems: items.length=${items.length}`);
    const result: MaterialItemVM[] = [];
    for (let i = 0; i < items.length; i++) {
      const item = items[i];
      const need = item.num;
      
      Logger.info(TAG, `parseNeedGetItems: [${i}] id=${item.id}, name=${item.name}, num=${need}`);
      
      // 过滤：缺口为 0 的材料不显示
      if (need <= 0) {
        Logger.info(TAG, `parseNeedGetItems: [${i}] skipped (need <= 0)`);
        continue;
      }

      const vm = new MaterialItemVM();
      vm.materialId = `${item.id}`;
      vm.name = item.name;
      vm.iconUrl = item.iconUrl;
      vm.rarity = typeof item.rarity === 'string' ? this.zzzRarityToInt(item.rarity) : item.rarity;
      vm.need = need;
      vm.have = 0; // need_get 是缺口，have = 0
      
      result[result.length] = vm;
    }
    Logger.info(TAG, `parseNeedGetItems: result.length=${result.length}`);
    return result;
  }

  /**
   * 将材料数据转换为 MaterialItemVM 数组（从 consume 和背包数据计算）。
   */
  private parseMaterialItems(
    items: MaterialItemRaw[],
    userOwnsMaterials: Map<string, number>
  ): MaterialItemVM[] {
    const result: MaterialItemVM[] = [];
    for (let i = 0; i < items.length; i++) {
      const item = items[i];
      const materialId = `${item.id}`;
      
      const have = userOwnsMaterials.get(materialId) ?? 0;
      const need = item.num;
      
      // 过滤：已满足或已超过的材料不显示
      if (have >= need) {
        continue;
      }

      const vm = new MaterialItemVM();
      vm.materialId = materialId;
      vm.name = item.name;
      vm.iconUrl = item.iconUrl;
      vm.rarity = typeof item.rarity === 'string' ? this.zzzRarityToInt(item.rarity) : item.rarity;
      vm.need = need;
      vm.have = have;
      
      result[result.length] = vm;
    }
    return result;
  }

  /**
   * 绝区零稀有度字符串转数字（S=5, A=4, B=3, C=2）。
   */
  private zzzRarityToInt(rarity: string): number {
    if (rarity === 'S') return 5;
    if (rarity === 'A') return 4;
    if (rarity === 'B') return 3;
    if (rarity === 'C') return 2;
    return 0;
  }

  /**
   * 将所有角色的材料汇总为按材料视图。
   */
  private aggregateMaterials(characters: CharacterMaterialVM[]): MaterialSummaryVM[] {
    const materialMap: Map<string, MaterialSummaryVM> = new Map();

    for (let i = 0; i < characters.length; i++) {
      const char = characters[i];
      const allMaterials: MaterialItemVM[] = [];
      
      for (let k = 0; k < char.avatarMaterials.length; k++) {
        allMaterials[allMaterials.length] = char.avatarMaterials[k];
      }
      for (let k = 0; k < char.skillMaterials.length; k++) {
        allMaterials[allMaterials.length] = char.skillMaterials[k];
      }
      for (let k = 0; k < char.weaponMaterials.length; k++) {
        allMaterials[allMaterials.length] = char.weaponMaterials[k];
      }

      for (let j = 0; j < allMaterials.length; j++) {
        const mat = allMaterials[j];
        const existing = materialMap.get(mat.materialId);

        if (existing !== undefined) {
          existing.totalNeed += mat.need;
          
          let charExists = false;
          for (let r = 0; r < existing.relatedCharacters.length; r++) {
            if (existing.relatedCharacters[r].characterId === char.characterId) {
              existing.relatedCharacters[r].needCount += mat.need;
              charExists = true;
              break;
            }
          }
          
          if (!charExists) {
            const relatedChar = new RelatedCharacterVM();
            relatedChar.characterId = char.characterId;
            relatedChar.characterName = char.characterName;
            relatedChar.characterIconUrl = char.characterIconUrl;
            relatedChar.needCount = mat.need;
            existing.relatedCharacters[existing.relatedCharacters.length] = relatedChar;
          }
        } else {
          const summary = new MaterialSummaryVM();
          summary.materialId = mat.materialId;
          summary.name = mat.name;
          summary.iconUrl = mat.iconUrl;
          summary.rarity = mat.rarity;
          summary.totalNeed = mat.need;
          
          const relatedChar = new RelatedCharacterVM();
          relatedChar.characterId = char.characterId;
          relatedChar.characterName = char.characterName;
          relatedChar.characterIconUrl = char.characterIconUrl;
          relatedChar.needCount = mat.need;
          summary.relatedCharacters[summary.relatedCharacters.length] = relatedChar;
          
          materialMap.set(mat.materialId, summary);
        }
      }
    }

    const result: MaterialSummaryVM[] = [];
    materialMap.forEach((value: MaterialSummaryVM) => {
      result[result.length] = value;
    });

    // 按 materialId 数值降序排序
    result.sort((a: MaterialSummaryVM, b: MaterialSummaryVM) => {
      const idA = parseInt(a.materialId, 10) || 0;
      const idB = parseInt(b.materialId, 10) || 0;
      return idB - idA;
    });

    return result;
  }

  /**
   * 将材料汇总分组为 Section。
   */
  private groupMaterialsIntoSections(summaries: MaterialSummaryVM[]): MaterialSectionVM[] {
    const sections: MaterialSectionVM[] = [];

    if (summaries.length === 0) {
      return sections;
    }

    const section = new MaterialSectionVM();
    section.type = MaterialSectionType.ALL;
    section.title = $r('app.string.material_section_all');
    section.materials = summaries;
    sections[sections.length] = section;

    return sections;
  }
}
