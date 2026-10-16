/**
 * StarRailMaterialListViewModel.ets — 星穹铁道材料汇总页 ViewModel
 *
 * 星穹铁道材料汇总页展示所有角色的材料需求汇总。
 * 星铁 compute API 只支持逐个角色请求，返回 user_owns_materials 和 consume 数据。
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
  StarRailComputeParser,
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
  RelatedCharacterVM,
  WeaponMaterialVM,
  MaterialSectionVM,
  MaterialSectionType,
} from '../models/MaterialListModels';

const TAG: string = 'StarRailMaterialListViewModel';
/** 材料页日志 tag，过滤：hilog | grep 🚀🚀🚀 */
const PAGE_CALC_TAG: string = '🚀🚀🚀 MaterialList';

/** StarRailMaterialListViewModel @Monitor 路径常量类型 */
export class StarRailMaterialListViewModelKeys {
  viewMode: string = 'vm.viewMode';
}

@ObservedV2
export class StarRailMaterialListViewModel {
  /** @Monitor 路径常量 */
  static readonly KEYS: StarRailMaterialListViewModelKeys = new StarRailMaterialListViewModelKeys();

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
   * 加载星铁角色材料数据。
   */
  /**
   * 加载选中角色的材料数据。
   * 选中但没有计算结果的角色：计算时已判定达到目标（MaterialComputeService 跳过），显示为"已达成目标"。
   */
  private async loadCharacterMaterials(accountId: string, roleUid: string, onlyAvatarIds: string[]): Promise<CharacterMaterialVM[]> {
    const avatarList = await CoreInitializer.starRailRepository.getAvatarList(accountId, roleUid);
    Logger.info(TAG, `loadCharacterMaterials: avatarList.length=${avatarList.length}`);
    
    if (avatarList.length === 0) {
      return [];
    }

    const result: CharacterMaterialVM[] = [];

    for (let i = 0; i < avatarList.length; i++) {
      const avatar = avatarList[i];
      if (!onlyAvatarIds.includes(avatar.avatarId)) {
        continue;
      }
      Logger.info(TAG, `loadCharacterMaterials: [${i}] avatarId=${avatar.avatarId}, name=${avatar.name}`);
      
      const computeRow = await CoreInitializer.starRailRepository.getAvatarCompute(accountId, roleUid, avatar.avatarId);
      Logger.info(TAG, `loadCharacterMaterials: [${i}] computeRow=${computeRow === null ? 'null' : 'exists, rawJson.length=' + computeRow.rawJson.length}`);
      
      if (computeRow === null) {
        const reached = new CharacterMaterialVM();
        reached.characterId = avatar.avatarId;
        reached.characterName = avatar.name;
        reached.characterIconUrl = avatar.icon;
        reached.characterLevel = avatar.level;
        reached.characterRarity = avatar.rarity;
        reached.gameId = GameId.STARRAIL;
        reached.isTargetReached = true;
        if (avatar.equipName.length > 0) {
          const lc = new WeaponMaterialVM();
          lc.weaponId = avatar.equipId;
          lc.weaponName = avatar.equipName;
          lc.weaponIconUrl = avatar.equipIconUrl;
          lc.weaponLevel = avatar.equipLevel;
          lc.weaponRarity = avatar.equipRarity;
          reached.lightCone = lc;
        }
        result[result.length] = reached;
        continue;
      }

      // 🔍 输出完整的 rawJson（分段，每段 2000 字符，避免日志截断）
      const rawJsonFull = computeRow.rawJson;
      const totalLen = rawJsonFull.length;
      
      // 针对 1510 输出完整内容
      if (avatar.avatarId === '1510') {
        const chunkSize = 2000;
        let offset = 0;
        let chunkIndex = 0;
        while (offset < totalLen) {
          const end = offset + chunkSize < totalLen ? offset + chunkSize : totalLen;
          const chunk = rawJsonFull.substring(offset, end);
          offset = end;
          chunkIndex++;
        }
      }

      const vm = new CharacterMaterialVM();
      vm.characterId = avatar.avatarId;
      vm.characterName = avatar.name;
      vm.characterIconUrl = avatar.icon;
      vm.characterLevel = avatar.level;
      vm.characterRarity = avatar.rarity;
      vm.gameId = GameId.STARRAIL;

      const parsed = StarRailComputeParser.parse(computeRow.rawJson);

      // 打印 need_get_materials 用于调试
      if (parsed.needGetMaterials.length > 0) {
      }

      // need_get_materials 是 API 计算好的"仍需获取"列表
      // item.num 已经是最终需要的数量，直接使用即可
      for (let j = 0; j < parsed.needGetMaterials.length; j++) {
        const item = parsed.needGetMaterials[j];
        
        const materialVM = new MaterialItemVM();
        materialVM.materialId = item.itemId;
        materialVM.name = item.itemName;
        materialVM.iconUrl = item.itemUrl;
        materialVM.rarity = parseInt(item.rarity, 10) || 0;
        materialVM.need = item.num;  // 直接使用 API 返回的 num
        materialVM.have = 0;  // 不再显示背包数量，避免混淆
        
        vm.avatarMaterials[vm.avatarMaterials.length] = materialVM;
      }

      // 光锥信息
      if (avatar.equipName.length > 0) {
        const lightCone = new WeaponMaterialVM();
        lightCone.weaponId = avatar.equipId;
        lightCone.weaponName = avatar.equipName;
        lightCone.weaponIconUrl = avatar.equipIconUrl;
        lightCone.weaponLevel = avatar.equipLevel;
        lightCone.weaponRarity = avatar.equipRarity;
        vm.lightCone = lightCone;
      }

      vm.isExpanded = true;
      result[result.length] = vm;
    }

    return result;
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
