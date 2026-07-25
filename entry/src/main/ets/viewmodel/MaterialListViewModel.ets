/**
 * MaterialListViewModel.ets — 材料汇总页 ViewModel
 *
 * 材料汇总页展示指定游戏的材料需求汇总，支持两种视图：
 * 1. 按角色分组：每个角色显示突破材料、技能材料、武器材料
 * 2. 按材料汇总：合并所有角色的材料需求
 *
 * 数据流：
 *   init(gameId) → 读本地 DB（角色 + 计算数据） → 解析材料 → 渲染
 *
 * 状态机：
 *   LOADING → DATA    有计算数据
 *   LOADING → EMPTY   无计算数据
 */

import {
  CoreInitializer,
  GameId,
  Logger,
  GenshinComputeParser,
  StarRailComputeParser,
  ZZZComputeParser,
  GenshinCharacterComputeRow,
  GenshinCharacterDetailRow,
  GenshinCharacterDetailRaw,
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
  SkillItemVM,
  MaterialSectionVM,
  MaterialSectionType,
} from '../models/MaterialListModels';

const TAG: string = 'MaterialListViewModel';

/** 原神养成计算参数 */
class GenshinComputeItem {
  avatar_id: number = 0;
  avatar_level_current: number = 1;
  avatar_level_target: number = 90;
  skill_list: GenshinComputeSkill[] = [];
  weapon: GenshinComputeWeapon | null = null;
}

class GenshinComputeSkill {
  id: number = 0;
  level_current: number = 1;
  level_target: number = 10;
}

class GenshinComputeWeapon {
  id: number = 0;
  level_current: number = 1;
  level_target: number = 90;
}

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

/** 绝区零养成计算技能参数 */
class ZZZComputeSkill {
  skill_type: number = 0;  // 技能类型：0=普攻, 1=闪避, 2=支援, 3=特殊, 5=连携, 6=核心
  level: number = 12;       // 目标等级
  init_level: number = 1;   // 当前等级
}

/** MaterialListViewModel @Monitor 路径常量类型 */
export class MaterialListViewModelKeys {
  viewMode: string = 'vm.viewMode';
}

@ObservedV2
export class MaterialListViewModel {
  /** @Monitor 路径常量 */
  static readonly KEYS: MaterialListViewModelKeys = new MaterialListViewModelKeys();

  @Trace viewState: ViewState = ViewState.LOADING;
  @Trace viewMode: MaterialListViewMode = MaterialListViewMode.CHARACTER;
  @Trace characterMaterials: CharacterMaterialVM[] = [];
  @Trace materialSummaries: MaterialSummaryVM[] = [];
  @Trace materialSections: MaterialSectionVM[] = [];
  @Trace isRefreshing: boolean = false;
  @Trace isSyncing: boolean = false;
  @Trace syncErrorMsg: string = '';

  private gameId: GameId = GameId.GENSHIN;

  // ─── 公开方法 ────────────────────────────────────────────────

  /**
   * 初始化：加载指定游戏的材料汇总数据。
   */
  async init(gameId: GameId): Promise<void> {
    this.gameId = gameId;
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
   * 遍历所有账号的角色，调用 Repository 的同步方法。
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
        
        const roles = await CoreInitializer.bbsRepository.getGameRolesByGame(account.uid, this.gameId);
        Logger.info(TAG, `syncComputeData: found ${roles.length} roles for gameId=${this.gameId}`);

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

  /**
   * 同步单个角色的材料计算数据。
   */
  private async syncRoleCompute(accountId: string, cookie: string, roleUid: string, server: string): Promise<boolean> {
    try {
      if (this.gameId === GameId.GENSHIN) {
        return await this.syncGenshinRoleCompute(accountId, cookie, roleUid, server);
      } else if (this.gameId === GameId.STARRAIL) {
        return await this.syncStarRailRoleCompute(accountId, cookie, roleUid, server);
      } else if (this.gameId === GameId.ZZZ) {
        return await this.syncZZZRoleCompute(accountId, cookie, roleUid, server);
      }
    } catch (error) {
      const msg = error instanceof Error ? error.message : `${error}`;
      Logger.warn(TAG, `syncRoleCompute failed for ${roleUid}: ${msg}`);
    }
    return false;
  }

  /**
   * 同步原神角色的材料计算数据。
   */
  private async syncGenshinRoleCompute(accountId: string, cookie: string, roleUid: string, server: string): Promise<boolean> {
    Logger.info(TAG, `syncGenshinRoleCompute: start, accountId=${accountId}, roleUid=${roleUid}, server=${server}`);
    
    // 获取角色列表
    const avatarList = await CoreInitializer.genshinRepository.getAvatarList(accountId, roleUid);
    Logger.info(TAG, `syncGenshinRoleCompute: avatarList.length=${avatarList.length}`);
    
    if (avatarList.length === 0) {
      Logger.warn(TAG, `syncGenshinRoleCompute: no avatarList`);
      return false;
    }

    // 构建计算参数
    const items: GenshinComputeItem[] = [];
    for (let i = 0; i < avatarList.length; i++) {
      const avatar = avatarList[i];
      const item = new GenshinComputeItem();
      item.avatar_id = parseInt(avatar.avatarId, 10);
      item.avatar_level_current = avatar.level;
      item.avatar_level_target = 90;

      // 技能参数
      const skill1 = new GenshinComputeSkill();
      skill1.id = 1001;
      skill1.level_current = 1;
      skill1.level_target = 10;
      const skill2 = new GenshinComputeSkill();
      skill2.id = 1002;
      skill2.level_current = 1;
      skill2.level_target = 10;
      const skill3 = new GenshinComputeSkill();
      skill3.id = 1003;
      skill3.level_current = 1;
      skill3.level_target = 10;
      item.skill_list = [skill1, skill2, skill3];

      // 武器参数
      if (avatar.weaponId.length > 0) {
        const weapon = new GenshinComputeWeapon();
        weapon.id = parseInt(avatar.weaponId, 10);
        weapon.level_current = avatar.weaponLevel;
        weapon.level_target = 90;
        item.weapon = weapon;
      }

      items[items.length] = item;
    }

    Logger.info(TAG, `syncGenshinRoleCompute: built ${items.length} compute items`);

    // 调用 Repository 同步
    try {
      await CoreInitializer.genshinRepository.syncAvatarCompute(accountId, roleUid, items, roleUid, server, cookie);
      Logger.info(TAG, `syncGenshinRoleCompute: syncAvatarCompute completed`);
      
      // 验证数据是否写入
      const computeRows = await CoreInitializer.genshinRepository.getAllComputeData(accountId, roleUid);
      Logger.info(TAG, `syncGenshinRoleCompute: after sync, computeRows.length=${computeRows.length}`);
      
      return computeRows.length > 0;
    } catch (error) {
      const msg = error instanceof Error ? error.message : `${error}`;
      Logger.error(TAG, `syncGenshinRoleCompute failed: ${msg}`);
      return false;
    }
  }

  /**
   * 同步星铁角色的材料计算数据。
   * 星铁 compute API 参数格式：
   *   avatar: { id, level_current, level_target }
   *   skillList: [{ id, level_current, level_target }]
   */
  private async syncStarRailRoleCompute(accountId: string, cookie: string, roleUid: string, server: string): Promise<boolean> {
    const avatarList = await CoreInitializer.starRailRepository.getAvatarList(accountId, roleUid);
    Logger.info(TAG, `syncStarRailRoleCompute: avatarList.length=${avatarList.length}`);
    
    if (avatarList.length === 0) {
      Logger.warn(TAG, `syncStarRailRoleCompute: no avatarList`);
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

        Logger.info(TAG, `syncStarRailRoleCompute: syncing avatarId=${avatar.avatarId}, level=${avatar.level}`);

        await CoreInitializer.starRailRepository.syncAvatarCompute(
          accountId,
          roleUid,
          avatarParam,
          skillList,
          roleUid,
          server,
          cookie
        );
        
        successCount++;
        Logger.info(TAG, `syncStarRailRoleCompute: avatarId=${avatar.avatarId} sync success`);
      } catch (error) {
        const msg = error instanceof Error ? error.message : `${error}`;
        Logger.warn(TAG, `syncStarRailRoleCompute: avatarId=${avatar.avatarId} failed: ${msg}`);
      }
    }

    Logger.info(TAG, `syncStarRailRoleCompute: total success=${successCount}/${avatarList.length}`);
    return successCount > 0;
  }

  /**
   * 同步绝区零角色的材料计算数据。
   * 绝区零 compute API 参数格式：
   *   avatarId: string
   *   avatarLevel: number (目标等级)
   *   avatarCurrentLevel: number (当前等级)
   *   avatarCurrentPromotes: number (当前突破阶段，0-4)
   *   skills: object[] (技能参数数组)
   */
  private async syncZZZRoleCompute(accountId: string, cookie: string, roleUid: string, server: string): Promise<boolean> {
    const avatarList = await CoreInitializer.zzzRepository.getAvatarList(accountId, roleUid);
    Logger.info(TAG, `syncZZZRoleCompute: avatarList.length=${avatarList.length}`);
    
    if (avatarList.length === 0) {
      Logger.warn(TAG, `syncZZZRoleCompute: no avatarList`);
      return false;
    }

    let successCount = 0;

    // 绝区零需要逐个角色同步
    for (let i = 0; i < avatarList.length; i++) {
      const avatar = avatarList[i];
      try {
        // 计算当前突破阶段（绝区零 60 级满级，每 15 级一个突破阶段）
        // 突破阶段：1-15=0, 16-30=1, 31-45=2, 46-60=3
        let currentPromotes = 0;
        if (avatar.level >= 46) {
          currentPromotes = 3;
        } else if (avatar.level >= 31) {
          currentPromotes = 2;
        } else if (avatar.level >= 16) {
          currentPromotes = 1;
        }

        // 绝区零技能结构：6个独立技能
        // skill_type: 0=普通攻击, 1=闪避, 2=支援, 3=特殊技, 5=连携技, 6=核心技
        // 实际应该从 ZZZAvatarInfoRow 的 skillLevelsJson 中解析当前等级
        const skills: ZZZComputeSkill[] = [];
        
        // skill_type = 0: 普通攻击
        const skill0 = new ZZZComputeSkill();
        skill0.skill_type = 0;
        skill0.init_level = 1;
        skill0.level = 12;
        skills[skills.length] = skill0;
        
        // skill_type = 1: 闪避
        const skill1 = new ZZZComputeSkill();
        skill1.skill_type = 1;
        skill1.init_level = 1;
        skill1.level = 12;
        skills[skills.length] = skill1;
        
        // skill_type = 2: 支援技
        const skill2 = new ZZZComputeSkill();
        skill2.skill_type = 2;
        skill2.init_level = 1;
        skill2.level = 12;
        skills[skills.length] = skill2;
        
        // skill_type = 3: 特殊技
        const skill3 = new ZZZComputeSkill();
        skill3.skill_type = 3;
        skill3.init_level = 1;
        skill3.level = 12;
        skills[skills.length] = skill3;
        
        // skill_type = 5: 连携技
        const skill5 = new ZZZComputeSkill();
        skill5.skill_type = 5;
        skill5.init_level = 1;
        skill5.level = 12;
        skills[skills.length] = skill5;
        
        // skill_type = 6: 核心技
        const skill6 = new ZZZComputeSkill();
        skill6.skill_type = 6;
        skill6.init_level = 1;
        skill6.level = 12;
        skills[skills.length] = skill6;

        Logger.info(TAG, `syncZZZRoleCompute: syncing avatarId=${avatar.avatarId}, level=${avatar.level}`);

        await CoreInitializer.zzzRepository.syncAvatarCompute(
          accountId,
          roleUid,
          avatar.avatarId,
          60, // 目标等级（绝区零最高 60 级）
          avatar.level, // 当前等级
          currentPromotes, // 当前突破阶段
          skills,
          roleUid,
          server,
          cookie
        );
        
        successCount++;
        Logger.info(TAG, `syncZZZRoleCompute: avatarId=${avatar.avatarId} sync success`);
      } catch (error) {
        const msg = error instanceof Error ? error.message : `${error}`;
        Logger.warn(TAG, `syncZZZRoleCompute: avatarId=${avatar.avatarId} failed: ${msg}`);
      }
    }

    Logger.info(TAG, `syncZZZRoleCompute: total success=${successCount}/${avatarList.length}`);
    return successCount > 0;
  }

  // ─── 私有方法 ────────────────────────────────────────────────

  private async loadData(): Promise<void> {
    Logger.info(TAG, `loadData: start, gameId=${this.gameId}`);
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
        const roles = await CoreInitializer.bbsRepository.getGameRolesByGame(account.uid, this.gameId);
        Logger.info(TAG, `loadData: account[${i}] has ${roles.length} roles for gameId=${this.gameId}`);

        for (let j = 0; j < roles.length; j++) {
          const role = roles[j];
          Logger.info(TAG, `loadData: loading material for role[${j}] roleId=${role.roleId}`);
          
          const charMaterial = await this.loadCharacterMaterial(account.uid, role.roleId);
          Logger.info(TAG, `loadData: loadCharacterMaterial result=${charMaterial !== null}`);
          
          if (charMaterial !== null) {
            // 原神返回数组，星铁/绝区零返回单个对象
            if (Array.isArray(charMaterial)) {
              for (let k = 0; k < charMaterial.length; k++) {
                allCharacterMaterials[allCharacterMaterials.length] = charMaterial[k];
              }
            } else {
              allCharacterMaterials[allCharacterMaterials.length] = charMaterial;
            }
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
   * 注意：原神返回多个 VM（因为一个 game_role 包含多个角色），
   * 星铁/绝区零返回单个 VM。
   */
  private async loadCharacterMaterial(accountId: string, roleUid: string): Promise<CharacterMaterialVM | null | CharacterMaterialVM[]> {
    try {
      if (this.gameId === GameId.GENSHIN) {
        return await this.loadGenshinCharacterMaterials(accountId, roleUid);
      }
      if (this.gameId === GameId.STARRAIL) {
        return await this.loadStarRailCharacterMaterial(accountId, roleUid);
      }
      if (this.gameId === GameId.ZZZ) {
        return await this.loadZZZCharacterMaterial(accountId, roleUid);
      }
    } catch (error) {
      const msg = error instanceof Error ? error.message : `${error}`;
      Logger.warn(TAG, `loadCharacterMaterial failed for ${roleUid}: ${msg}`);
    }
    return null;
  }

  /**
   * 加载原神角色材料数据。
   * 原神一个 game_role 包含多个角色，返回 CharacterMaterialVM 数组。
   */
  private async loadGenshinCharacterMaterials(accountId: string, roleUid: string): Promise<CharacterMaterialVM[] | null> {
    Logger.info(TAG, `loadGenshinCharacterMaterials: accountId=${accountId}, roleUid=${roleUid}`);
    
    // 获取角色基础信息
    const avatarList = await CoreInitializer.genshinRepository.getAvatarList(accountId, roleUid);
    Logger.info(TAG, `loadGenshinCharacterMaterials: avatarList.length=${avatarList.length}`);
    
    if (avatarList.length === 0) {
      Logger.warn(TAG, `loadGenshinCharacterMaterials: no avatarList`);
      return null;
    }

    // 获取所有计算数据
    const computeRows = await CoreInitializer.genshinRepository.getAllComputeData(accountId, roleUid);
    Logger.info(TAG, `loadGenshinCharacterMaterials: computeRows.length=${computeRows.length}`);
    
    if (computeRows.length === 0) {
      Logger.warn(TAG, `loadGenshinCharacterMaterials: no computeRows`);
      return null;
    }

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

    // 遍历 avatarList，为每个角色创建 VM
    for (let i = 0; i < avatarList.length; i++) {
      const avatar = avatarList[i];
      const computeRow = computeMap.get(avatar.avatarId);
      
      if (computeRow === undefined || computeRow === null) {
        Logger.info(TAG, `loadGenshinCharacterMaterials: no computeRow for avatarId=${avatar.avatarId}, skipping`);
        continue;
      }

      const vm = new CharacterMaterialVM();
      vm.characterId = avatar.avatarId;
      vm.characterName = avatar.name;
      vm.characterIconUrl = avatar.icon;
      vm.characterLevel = avatar.level;
      vm.characterRarity = avatar.rarity;
      vm.element = avatar.element;
      vm.gameId = GameId.GENSHIN;

      // 解析材料数据（DB 中存储的是单个 item）
      const parsed = GenshinComputeParser.parseItem(computeRow.rawJson);
      
      if (parsed !== null) {
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

    Logger.info(TAG, `loadGenshinCharacterMaterials: returning ${result.length} VMs`);
    return result.length > 0 ? result : null;
  }

  /**
   * 加载星铁角色材料数据。
   */
  private async loadStarRailCharacterMaterial(accountId: string, roleUid: string): Promise<CharacterMaterialVM | null> {
    const avatarList = await CoreInitializer.starRailRepository.getAvatarList(accountId, roleUid);
    if (avatarList.length === 0) {
      return null;
    }

    const avatar = avatarList[0];
    const computeRow = await CoreInitializer.starRailRepository.getAvatarCompute(accountId, roleUid, avatar.avatarId);
    if (computeRow === null) {
      return null;
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
      vm.avatarMaterials = this.parseMaterialItems(parsed.avatarConsume);
    }
    if (parsed.skillConsume.length > 0) {
      vm.skillMaterials = this.parseMaterialItems(parsed.skillConsume);
    }
    if (parsed.equipmentConsume.length > 0) {
      vm.weaponMaterials = this.parseMaterialItems(parsed.equipmentConsume);
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
    return vm;
  }

  /**
   * 加载绝区零角色材料数据。
   */
  private async loadZZZCharacterMaterial(accountId: string, roleUid: string): Promise<CharacterMaterialVM | null> {
    const avatarList = await CoreInitializer.zzzRepository.getAvatarList(accountId, roleUid);
    if (avatarList.length === 0) {
      return null;
    }

    const avatar = avatarList[0];
    const computeRow = await CoreInitializer.zzzRepository.getAvatarCompute(accountId, roleUid, avatar.avatarId);
    if (computeRow === null) {
      return null;
    }

    const vm = new CharacterMaterialVM();
    vm.characterId = avatar.avatarId;
    vm.characterName = avatar.nameMi18n;
    vm.characterIconUrl = avatar.hollowIconPath;
    vm.characterLevel = avatar.level;
    vm.characterRarity = avatar.rarity === 'S' ? 5 : 4;
    vm.gameId = GameId.ZZZ;

    const parsed = ZZZComputeParser.parse(computeRow.rawJson);

    if (parsed.avatarConsume.length > 0) {
      vm.avatarMaterials = this.parseMaterialItems(parsed.avatarConsume);
    }
    if (parsed.skillConsume.length > 0) {
      vm.skillMaterials = this.parseMaterialItems(parsed.skillConsume);
    }
    if (parsed.weaponConsume.length > 0) {
      vm.weaponMaterials = this.parseMaterialItems(parsed.weaponConsume);
    }

    vm.isExpanded = true;
    return vm;
  }

  /**
   * 将解析后的材料数据转换为 MaterialItemVM 数组。
   */
  private parseMaterialItems(items: MaterialItemRaw[]): MaterialItemVM[] {
    const result: MaterialItemVM[] = [];
    for (let i = 0; i < items.length; i++) {
      const item = items[i];
      const vm = new MaterialItemVM();
      vm.materialId = `${item.id}`;
      vm.name = item.name;
      vm.iconUrl = item.iconUrl;
      vm.rarity = typeof item.rarity === 'string' ? parseInt(item.rarity, 10) || 0 : item.rarity;
      vm.have = 0; // 暂不读取背包数据
      vm.need = item.num;
      result[result.length] = vm;
    }
    return result;
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
   * 将所有角色的材料汇总为按材料视图。
   * 按 materialId 去重，同一材料的需求量累加。
   * 排序规则：按 materialId 从大到小（数值降序）。
   */
  private aggregateMaterials(characters: CharacterMaterialVM[]): MaterialSummaryVM[] {
    const materialMap: Map<string, MaterialSummaryVM> = new Map();

    for (let i = 0; i < characters.length; i++) {
      const char = characters[i];
      const allMaterials: MaterialItemVM[] = [];
      
      // 手动合并数组，避免展开运算符
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
          // 已存在：累加需求量，添加关联角色
          existing.totalNeed += mat.need;
          
          // 检查是否已添加过该角色（避免同一角色重复添加）
          let charExists = false;
          for (let r = 0; r < existing.relatedCharacters.length; r++) {
            if (existing.relatedCharacters[r].characterId === char.characterId) {
              // 已存在该角色，累加需求量
              existing.relatedCharacters[r].needCount += mat.need;
              charExists = true;
              break;
            }
          }
          
          if (!charExists) {
            // 不存在该角色，添加新的关联角色
            const relatedChar = new RelatedCharacterVM();
            relatedChar.characterId = char.characterId;
            relatedChar.characterName = char.characterName;
            relatedChar.characterIconUrl = char.characterIconUrl;
            relatedChar.needCount = mat.need;
            existing.relatedCharacters[existing.relatedCharacters.length] = relatedChar;
          }
        } else {
          // 不存在：创建新的汇总项
          const summary = new MaterialSummaryVM();
          summary.materialId = mat.materialId;
          summary.name = mat.name;
          summary.iconUrl = mat.iconUrl;
          summary.rarity = mat.rarity;
          summary.totalHave = mat.have;
          summary.totalNeed = mat.need;
          
          const relatedChar = new RelatedCharacterVM();
          relatedChar.characterId = char.characterId;
          relatedChar.characterName = char.characterName;
          relatedChar.characterIconUrl = char.characterIconUrl;
          relatedChar.needCount = mat.need;
          summary.relatedCharacters = [relatedChar];
          
          materialMap.set(mat.materialId, summary);
        }
      }
    }

    // 转换为数组并按 materialId 从大到小排列
    const result: MaterialSummaryVM[] = [];
    materialMap.forEach((value) => {
      result[result.length] = value;
    });
    result.sort((a, b) => {
      // 将 materialId 转为数值比较（从大到小）
      const idA = parseInt(a.materialId, 10) || 0;
      const idB = parseInt(b.materialId, 10) || 0;
      return idB - idA;
    });

    return result;
  }

  /**
   * 将材料汇总列表分组为 sections。
   * 经验书（104003）、精锻用魔矿（104013）、摩拉（202）放在第一个 section。
   * 其他材料放在第二个 section。
   */
  private groupMaterialsIntoSections(materials: MaterialSummaryVM[]): MaterialSectionVM[] {
    const currencyIds = new Set<string>(['202', '104003', '104013']);
    
    const currencyMaterials: MaterialSummaryVM[] = [];
    const otherMaterials: MaterialSummaryVM[] = [];

    for (let i = 0; i < materials.length; i++) {
      const mat = materials[i];
      if (currencyIds.has(mat.materialId)) {
        currencyMaterials[currencyMaterials.length] = mat;
      } else {
        otherMaterials[otherMaterials.length] = mat;
      }
    }

    // 对 currencyMaterials 按总需求量排序（从大到小）
    currencyMaterials.sort((a, b) => b.totalNeed - a.totalNeed);

    const sections: MaterialSectionVM[] = [];

    // 第一个 section：经验书/摩拉/魔矿
    if (currencyMaterials.length > 0) {
      const currencySection = new MaterialSectionVM();
      currencySection.type = MaterialSectionType.CURRENCY;
      currencySection.title = $r('app.string.material_section_currency');
      currencySection.materials = currencyMaterials;
      sections[sections.length] = currencySection;
    }

    // 第二个 section：其他材料
    if (otherMaterials.length > 0) {
      const materialSection = new MaterialSectionVM();
      materialSection.type = MaterialSectionType.MATERIALS;
      materialSection.title = $r('app.string.material_section_materials');
      materialSection.materials = otherMaterials;
      sections[sections.length] = materialSection;
    }

    return sections;
  }

  /**
   * 格式化摩拉/经验书/魔矿的数量显示。
   * 单位转换规则：
   * - < 1万：显示具体数字（如 5000）
   * - >= 1万 且 < 1亿：显示"万"单位，< 10万保留一位小数，>= 10万显示整数
   * - >= 1亿：显示"亿"单位，保留一位小数
   */
  static formatCurrencyAmount(amount: number): string {
    if (amount < 10000) {
      // < 1万：显示具体数字
      return `${amount}`;
    }
    
    const YI = 100000000; // 1亿
    const WAN = 10000;    // 1万
    
    if (amount >= YI) {
      // >= 1亿：显示 X.X亿
      const yiValue = amount / YI;
      const formatted = yiValue.toFixed(1);
      if (formatted.endsWith('.0')) {
        return formatted.substring(0, formatted.length - 2) + '亿';
      }
      return formatted + '亿';
    }
    
    // >= 1万 且 < 1亿：显示万单位
    const wanValue = amount / WAN;
    
    if (wanValue < 10) {
      // < 10万：保留一位小数（如 1.5万）
      const formatted = wanValue.toFixed(1);
      if (formatted.endsWith('.0')) {
        return formatted.substring(0, formatted.length - 2) + '万';
      }
      return formatted + '万';
    }
    
    // >= 10万：显示整数万（如 15万、5932万）
    return Math.floor(wanValue) + '万';
  }
}
