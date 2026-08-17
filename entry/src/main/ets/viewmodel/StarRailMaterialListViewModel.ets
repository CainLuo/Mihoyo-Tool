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
import {
  MaterialListViewMode,
  CharacterMaterialVM,
  MaterialSummaryVM,
  MaterialItemVM,
  MaterialItemRaw,
  RelatedCharacterVM,
  WeaponMaterialVM,
  MaterialSectionVM,
  MaterialSectionType,
} from '../models/MaterialListModels';

const TAG: string = 'StarRailMaterialListViewModel';

/** 星铁养成计算参数 */
class StarRailComputeAvatar {
  id: number = 0;
  level_current: number = 1;
  level_target: number = 80;
}

class StarRailComputeSkill {
  id: number = 0;
  level_current: number = 1;
  level_target: number = 10;
}

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

  // ─── 公开方法 ────────────────────────────────────────────────

  /**
   * 初始化：加载星铁材料汇总数据。
   */
  async init(): Promise<void> {
    this.viewState = ViewState.LOADING;
    await this.loadData();
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
   * 触发材料计算同步。
   * 遍历所有账号的星铁角色，调用 Repository 的同步方法。
   */
  async syncComputeData(): Promise<void> {
    Logger.info(TAG, `syncComputeData called, isSyncing=${this.isSyncing}`);
    if (this.isSyncing) {
      Logger.info(TAG, `syncComputeData skipped - already syncing`);
      return;
    }
    this.isSyncing = true;
    this.syncErrorMsg = '';
    Logger.info(TAG, `syncComputeData started`);

    try {
      const accounts = await CoreInitializer.bbsRepository.getAllAccounts();
      Logger.info(TAG, `syncComputeData: found ${accounts.length} accounts`);
      
      if (accounts.length === 0) {
        Logger.warn(TAG, `syncComputeData: no accounts found`);
        this.syncErrorMsg = 'no_account';
        return;
      }

      let syncCount = 0;

      for (let i = 0; i < accounts.length; i++) {
        const account = accounts[i];
        Logger.info(TAG, `syncComputeData: processing account[${i}] uid=${account.uid}`);
        
        const roles = await CoreInitializer.bbsRepository.getGameRolesByGame(account.uid, GameId.STARRAIL);
        Logger.info(TAG, `syncComputeData: found ${roles.length} StarRail roles`);

        for (let j = 0; j < roles.length; j++) {
          const role = roles[j];
          Logger.info(TAG, `syncComputeData: syncing role[${j}] roleId=${role.roleId}`);
          
          const success = await this.syncRoleCompute(account.uid, account.cookie, role.roleId, role.server);
          Logger.info(TAG, `syncComputeData: role[${j}] sync result=${success}`);
          
          if (success) {
            syncCount++;
          }
        }
      }

      Logger.info(TAG, `syncComputeData: total syncCount=${syncCount}`);
      
      if (syncCount === 0) {
        this.syncErrorMsg = 'no_roles';
        return;
      }

      // 同步完成后重新加载数据
      Logger.info(TAG, `syncComputeData: reloading data...`);
      await this.loadData();
      Logger.info(TAG, `syncComputeData: reload done, viewState=${this.viewState}`);
    } catch (error) {
      const msg = error instanceof Error ? error.message : `${error}`;
      Logger.error(TAG, `syncComputeData failed: ${msg}`);
      this.syncErrorMsg = msg;
    } finally {
      this.isSyncing = false;
      Logger.info(TAG, `syncComputeData finished`);
    }
  }

  // ─── 私有方法 ────────────────────────────────────────────────

  /**
   * 同步单个星铁角色的材料计算数据。
   * 星铁 compute API 参数格式：
   *   avatar: { id, level_current, level_target }
   *   skillList: [{ id, level_current, level_target }]
   */
  private async syncRoleCompute(accountId: string, cookie: string, roleUid: string, server: string): Promise<boolean> {
    const avatarList = await CoreInitializer.starRailRepository.getAvatarList(accountId, roleUid);
    Logger.info(TAG, `syncRoleCompute: avatarList.length=${avatarList.length}`);
    
    if (avatarList.length === 0) {
      Logger.warn(TAG, `syncRoleCompute: no avatarList`);
      return false;
    }

    let successCount = 0;

    // 星铁需要逐个角色同步
    for (let i = 0; i < avatarList.length; i++) {
      const avatar = avatarList[i];
      try {
        // 构建 avatar 参数
        const avatarParam = new StarRailComputeAvatar();
        avatarParam.id = parseInt(avatar.avatarId, 10);
        avatarParam.level_current = avatar.level;
        avatarParam.level_target = 80; // 星铁最高 80 级

        // 构建 skillList 参数（普攻、战技、终结技、天赋 4 个技能）
        // 星铁技能 ID 规则：角色 ID * 100 + 技能序号
        const avatarIdNum = parseInt(avatar.avatarId, 10);
        const skillList: StarRailComputeSkill[] = [];
        
        const skill1 = new StarRailComputeSkill();
        skill1.id = avatarIdNum * 100 + 1;
        skill1.level_current = 1;
        skill1.level_target = 10;
        skillList[skillList.length] = skill1;
        
        const skill2 = new StarRailComputeSkill();
        skill2.id = avatarIdNum * 100 + 2;
        skill2.level_current = 1;
        skill2.level_target = 10;
        skillList[skillList.length] = skill2;
        
        const skill3 = new StarRailComputeSkill();
        skill3.id = avatarIdNum * 100 + 3;
        skill3.level_current = 1;
        skill3.level_target = 10;
        skillList[skillList.length] = skill3;
        
        const skill4 = new StarRailComputeSkill();
        skill4.id = avatarIdNum * 100 + 4;
        skill4.level_current = 1;
        skill4.level_target = 10;
        skillList[skillList.length] = skill4;

        Logger.info(TAG, `syncRoleCompute: syncing avatarId=${avatar.avatarId}, level=${avatar.level}`);

        await CoreInitializer.starRailRepository.syncAvatarCompute(
          accountId,
          roleUid,
          avatar.avatarId,
          avatarParam,
          skillList,
          roleUid,
          server,
          cookie
        );
        
        successCount++;
        Logger.info(TAG, `syncRoleCompute: avatarId=${avatar.avatarId} sync success`);
      } catch (error) {
        const msg = error instanceof Error ? error.message : `${error}`;
        Logger.warn(TAG, `syncRoleCompute: avatarId=${avatar.avatarId} failed: ${msg}`);
      }
    }

    Logger.info(TAG, `syncRoleCompute: total success=${successCount}/${avatarList.length}`);
    return successCount > 0;
  }

  private async loadData(): Promise<void> {
    Logger.info(TAG, `loadData: start`);
    try {
      const accounts = await CoreInitializer.bbsRepository.getAllAccounts();
      Logger.info(TAG, `loadData: found ${accounts.length} accounts`);
      
      if (accounts.length === 0) {
        Logger.warn(TAG, `loadData: no accounts`);
        this.viewState = ViewState.EMPTY;
        return;
      }

      const allCharacterMaterials: CharacterMaterialVM[] = [];

      // 遍历所有账号，收集角色材料数据
      for (let i = 0; i < accounts.length; i++) {
        const account = accounts[i];
        const roles = await CoreInitializer.bbsRepository.getGameRolesByGame(account.uid, GameId.STARRAIL);
        Logger.info(TAG, `loadData: account[${i}] has ${roles.length} StarRail roles`);

        for (let j = 0; j < roles.length; j++) {
          const role = roles[j];
          Logger.info(TAG, `loadData: loading material for role[${j}] roleId=${role.roleId}`);
          
          const charMaterials = await this.loadCharacterMaterials(account.uid, role.roleId);
          Logger.info(TAG, `loadData: loadCharacterMaterials result, count=${charMaterials.length}`);
          
          for (let k = 0; k < charMaterials.length; k++) {
            allCharacterMaterials[allCharacterMaterials.length] = charMaterials[k];
          }
        }
      }

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
  private async loadCharacterMaterials(accountId: string, roleUid: string): Promise<CharacterMaterialVM[]> {
    const avatarList = await CoreInitializer.starRailRepository.getAvatarList(accountId, roleUid);
    Logger.info(TAG, `loadCharacterMaterials: avatarList.length=${avatarList.length}`);
    
    if (avatarList.length === 0) {
      return [];
    }

    const result: CharacterMaterialVM[] = [];

    for (let i = 0; i < avatarList.length; i++) {
      const avatar = avatarList[i];
      Logger.info(TAG, `loadCharacterMaterials: [${i}] avatarId=${avatar.avatarId}, name=${avatar.name}`);
      
      const computeRow = await CoreInitializer.starRailRepository.getAvatarCompute(accountId, roleUid, avatar.avatarId);
      Logger.info(TAG, `loadCharacterMaterials: [${i}] computeRow=${computeRow === null ? 'null' : 'exists, rawJson.length=' + computeRow.rawJson.length}`);
      
      if (computeRow === null) {
        continue;
      }

      const vm = new CharacterMaterialVM();
      vm.characterId = avatar.avatarId;
      vm.characterName = avatar.name;
      vm.characterIconUrl = avatar.icon;
      vm.characterLevel = avatar.level;
      vm.characterRarity = avatar.rarity;
      vm.gameId = GameId.STARRAIL;

      const parsed = StarRailComputeParser.parse(computeRow.rawJson);

      if (parsed.avatarConsume.length > 0) {
        vm.avatarMaterials = this.parseMaterialItems(parsed.avatarConsume, parsed.userOwnsMaterials);
      }
      if (parsed.skillConsume.length > 0) {
        vm.skillMaterials = this.parseMaterialItems(parsed.skillConsume, parsed.userOwnsMaterials);
      }
      if (parsed.equipmentConsume.length > 0) {
        vm.weaponMaterials = this.parseMaterialItems(parsed.equipmentConsume, parsed.userOwnsMaterials);
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
   * 将解析后的材料数据转换为 MaterialItemVM 数组。
   * 
   * 星铁 API：返回 user_owns_materials（背包数据），have 从 Map 查询
   * 
   * 过滤规则：已满足或已超过的材料（have >= need）不显示
   */
  private parseMaterialItems(
    items: MaterialItemRaw[],
    userOwnsMaterials: Map<string, number>
  ): MaterialItemVM[] {
    const result: MaterialItemVM[] = [];
    for (let i = 0; i < items.length; i++) {
      const item = items[i];
      const materialId = `${item.id}`;
      
      // 星铁：从背包数据查询 have
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
      vm.rarity = typeof item.rarity === 'string' ? parseInt(item.rarity, 10) || 0 : item.rarity;
      vm.need = need;
      vm.have = have;
      
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
