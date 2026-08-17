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

  // ─── 公开方法 ────────────────────────────────────────────────

  /**
   * 初始化：加载绝区零材料汇总数据。
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
   * 遍历所有账号的绝区零角色，调用 Repository 的同步方法。
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
        
        const roles = await CoreInitializer.bbsRepository.getGameRolesByGame(account.uid, GameId.ZZZ);
        Logger.info(TAG, `syncComputeData: found ${roles.length} ZZZ roles`);

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
   * 同步单个绝区零角色的材料计算数据。
   */
  private async syncRoleCompute(accountId: string, cookie: string, roleUid: string, server: string): Promise<boolean> {
    try {
      let avatarList = await CoreInitializer.zzzRepository.getAvatarList(accountId, roleUid);
      Logger.info(TAG, `syncRoleCompute: avatarList.length=${avatarList.length}`);
      
      // 如果 DB 中没有角色列表，先同步角色列表
      if (avatarList.length === 0) {
        Logger.info(TAG, `syncRoleCompute: no avatarList, syncing avatar list first`);
        try {
          await CoreInitializer.zzzRepository.syncAvatarList(accountId, roleUid, server, cookie);
          avatarList = await CoreInitializer.zzzRepository.getAvatarList(accountId, roleUid);
          Logger.info(TAG, `syncRoleCompute: after sync, avatarList.length=${avatarList.length}`);
        } catch (error) {
          const msg = error instanceof Error ? error.message : `${error}`;
          Logger.error(TAG, `syncRoleCompute: failed to sync avatar list: ${msg}`);
          return false;
        }
        
        if (avatarList.length === 0) {
          Logger.warn(TAG, `syncRoleCompute: still no avatarList after sync`);
          return false;
        }
      }

      let successCount = 0;

      // 绝区零需要逐个角色同步
      for (let i = 0; i < avatarList.length; i++) {
        const avatar = avatarList[i];
        try {
          // 计算当前突破阶段
          let currentPromotes = 0;
          if (avatar.level >= 46) {
            currentPromotes = 3;
          } else if (avatar.level >= 31) {
            currentPromotes = 2;
          } else if (avatar.level >= 16) {
            currentPromotes = 1;
          }

          // 构建技能参数
          const skills: ZZZComputeSkill[] = [];
          
          const skill0 = new ZZZComputeSkill();
          skill0.skill_type = 0;
          skill0.init_level = 1;
          skill0.level = 12;
          skills[skills.length] = skill0;
          
          const skill1 = new ZZZComputeSkill();
          skill1.skill_type = 1;
          skill1.init_level = 1;
          skill1.level = 12;
          skills[skills.length] = skill1;
          
          const skill2 = new ZZZComputeSkill();
          skill2.skill_type = 2;
          skill2.init_level = 1;
          skill2.level = 12;
          skills[skills.length] = skill2;
          
          const skill3 = new ZZZComputeSkill();
          skill3.skill_type = 3;
          skill3.init_level = 1;
          skill3.level = 12;
          skills[skills.length] = skill3;
          
          const skill5 = new ZZZComputeSkill();
          skill5.skill_type = 5;
          skill5.init_level = 1;
          skill5.level = 12;
          skills[skills.length] = skill5;
          
          const skill6 = new ZZZComputeSkill();
          skill6.skill_type = 6;
          skill6.init_level = 1;
          skill6.level = 12;
          skills[skills.length] = skill6;

          Logger.info(TAG, `syncRoleCompute: syncing avatarId=${avatar.avatarId}, level=${avatar.level}`);

          await CoreInitializer.zzzRepository.syncAvatarCompute(
            accountId,
            roleUid,
            avatar.avatarId,
            60,
            avatar.level,
            currentPromotes,
            skills,
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
    } catch (error) {
      const msg = error instanceof Error ? error.message : `${error}`;
      Logger.warn(TAG, `syncRoleCompute failed for ${roleUid}: ${msg}`);
    }
    return false;
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
        const roles = await CoreInitializer.bbsRepository.getGameRolesByGame(account.uid, GameId.ZZZ);
        Logger.info(TAG, `loadData: account[${i}] has ${roles.length} ZZZ roles`);

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
   * 加载单个游戏角色的材料数据。
   */
  private async loadCharacterMaterials(accountId: string, roleUid: string): Promise<CharacterMaterialVM[]> {
    const avatarList = await CoreInitializer.zzzRepository.getAvatarList(accountId, roleUid);
    Logger.info(TAG, `💥💥💥 loadCharacterMaterials: avatarList.length=${avatarList.length}`);
    if (avatarList.length === 0) {
      return [];
    }

    const result: CharacterMaterialVM[] = [];

    for (let i = 0; i < avatarList.length; i++) {
      const avatar = avatarList[i];
      Logger.info(TAG, `💥💥💥 loadCharacterMaterials: [${i}] avatarId=${avatar.avatarId}, name=${avatar.nameMi18n}`);
      
      const computeRow = await CoreInitializer.zzzRepository.getAvatarCompute(accountId, roleUid, avatar.avatarId);
      Logger.info(TAG, `💥💥💥 loadCharacterMaterials: [${i}] computeRow=${computeRow === null ? 'null' : 'exists, rawJson.length=' + computeRow.rawJson.length}`);
      
      if (computeRow === null) {
        continue;
      }

      const vm = new CharacterMaterialVM();
      vm.characterId = avatar.avatarId;
      vm.characterName = avatar.nameMi18n;
      vm.characterIconUrl = avatar.hollowIconPath;
      vm.characterLevel = avatar.level;
      vm.characterRarity = avatar.rarity === 'S' ? 5 : 4;
      vm.gameId = GameId.ZZZ;

      Logger.info(TAG, `💥💥💥 loadCharacterMaterials: [${i}] parsing rawJson...`);
      const parsed = ZZZComputeParser.parse(computeRow.rawJson);
      Logger.info(TAG, `💥💥💥 loadCharacterMaterials: [${i}] parsed: needGet=${parsed.needGet.length}, avatarConsume=${parsed.avatarConsume.length}, skillConsume=${parsed.skillConsume.length}, weaponConsume=${parsed.weaponConsume.length}`);

      // 绝区零 API 返回 need_get 字段，直接使用
      if (parsed.needGet.length > 0) {
        Logger.info(TAG, `💥💥💥 loadCharacterMaterials: [${i}] using needGet`);
        vm.avatarMaterials = this.parseNeedGetItems(parsed.needGet);
        Logger.info(TAG, `💥💥💥 loadCharacterMaterials: [${i}] avatarMaterials.length=${vm.avatarMaterials.length}`);
      } else {
        // 如果没有 need_get，则从 consume 和背包数据计算
        Logger.info(TAG, `💥💥💥 loadCharacterMaterials: [${i}] needGet is empty, fallback to consume arrays`);
        if (parsed.avatarConsume.length > 0) {
          vm.avatarMaterials = this.parseMaterialItems(parsed.avatarConsume, parsed.userOwnsMaterials);
          Logger.info(TAG, `💥💥💥 loadCharacterMaterials: [${i}] avatarMaterials.length=${vm.avatarMaterials.length}`);
        }
        if (parsed.skillConsume.length > 0) {
          vm.skillMaterials = this.parseMaterialItems(parsed.skillConsume, parsed.userOwnsMaterials);
          Logger.info(TAG, `💥💥💥 loadCharacterMaterials: [${i}] skillMaterials.length=${vm.skillMaterials.length}`);
        }
        if (parsed.weaponConsume.length > 0) {
          vm.weaponMaterials = this.parseMaterialItems(parsed.weaponConsume, parsed.userOwnsMaterials);
          Logger.info(TAG, `💥💥💥 loadCharacterMaterials: [${i}] weaponMaterials.length=${vm.weaponMaterials.length}`);
        }
      }

      vm.isExpanded = true;
      result[result.length] = vm;
    }

    Logger.info(TAG, `💥💥💥 loadCharacterMaterials: result.length=${result.length}`);
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

/** 绝区零养成计算技能参数 */
class ZZZComputeSkill {
  skill_type: number = 0;
  level: number = 12;
  init_level: number = 1;
}
