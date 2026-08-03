/**
 * MaterialCalcViewModel.ets — 材料计算页 ViewModel
 *
 * 材料计算页展示单个角色的材料需求，支持：
 * 1. 设置角色目标等级
 * 2. 设置武器/光锥目标等级
 * 3. 设置技能目标等级
 * 4. 查看材料缺口
 *
 * 数据流：
 *   init(accountId, roleUid, avatarId) → 读本地 DB → 渲染
 *
 * 状态机：
 *   LOADING → DATA    有数据
 *   LOADING → EMPTY   无数据
 */

import {
  CoreInitializer,
  GameId,
  Logger,
  GenshinComputeParser,
  StarRailComputeParser,
  ZZZComputeParser,
} from 'core';
import { ViewState } from '../constants/ViewStates';
import {
  SkillTargetVM,
  MaterialCalcItemVM,
  MaterialSectionVM,
  MaterialCalcCharacterVM,
  MaterialCalcWeaponVM,
  LevelOptionVM,
  MaterialItemRaw,
  SkillTypeDefinition,
} from '../models/MaterialCalcModels';

const TAG: string = 'MaterialCalcViewModel';

/** MaterialCalcViewModel @Monitor 路径常量类型 */
export class MaterialCalcViewModelKeys {
  charCurrentLevel: string = 'vm.charCurrentLevel';
  charTargetLevel: string = 'vm.charTargetLevel';
  weaponCurrentLevel: string = 'vm.weaponCurrentLevel';
  weaponTargetLevel: string = 'vm.weaponTargetLevel';
}

@ObservedV2
export class MaterialCalcViewModel {
  /** @Monitor 路径常量 */
  static readonly KEYS: MaterialCalcViewModelKeys = new MaterialCalcViewModelKeys();

  @Trace viewState: ViewState = ViewState.LOADING;
  @Trace character: MaterialCalcCharacterVM = new MaterialCalcCharacterVM();
  @Trace weapon: MaterialCalcWeaponVM | null = null;
  @Trace skills: SkillTargetVM[] = [];
  @Trace avatarSection: MaterialSectionVM = new MaterialSectionVM();
  @Trace weaponSection: MaterialSectionVM = new MaterialSectionVM();
  @Trace isRefreshing: boolean = false;

  @Trace charCurrentLevel: number = 1;
  @Trace charTargetLevel: number = 90;
  @Trace weaponCurrentLevel: number = 1;
  @Trace weaponTargetLevel: number = 90;

  private accountId: string = '';
  private roleUid: string = '';
  private avatarId: string = '';
  private gameId: GameId = GameId.GENSHIN;

  // ─── 公开方法 ────────────────────────────────────────────────

  /**
   * 初始化：加载角色材料数据。
   */
  async init(accountId: string, roleUid: string, avatarId: string): Promise<void> {
    this.accountId = accountId;
    this.roleUid = roleUid;
    this.avatarId = avatarId;
    this.viewState = ViewState.LOADING;

    // 先获取游戏类型
    const roles = await CoreInitializer.bbsRepository.getGameRoles(accountId);
    for (let i = 0; i < roles.length; i++) {
      if (roles[i].roleId === roleUid) {
        this.gameId = roles[i].gameId;
        break;
      }
    }

    await this.loadData();
  }

  /**
   * 设置角色目标等级。
   */
  setCharTargetLevel(level: number): void {
    this.charTargetLevel = level;
    // 触发重新计算材料需求
    this.recalculateMaterials();
  }

  /**
   * 设置武器目标等级。
   */
  setWeaponTargetLevel(level: number): void {
    this.weaponTargetLevel = level;
    this.recalculateMaterials();
  }

  /**
   * 设置技能目标等级。
   */
  setSkillTarget(skillId: string, targetLevel: number): void {
    for (let i = 0; i < this.skills.length; i++) {
      if (this.skills[i].skillId === skillId) {
        this.skills[i].targetLevel = targetLevel;
        break;
      }
    }
    this.recalculateMaterials();
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
   * 获取可用的等级选项列表。
   */
  getLevelOptions(): LevelOptionVM[] {
    const options: LevelOptionVM[] = [];
    const levels = [1, 20, 40, 50, 60, 70, 80, 90];
    for (let i = 0; i < levels.length; i++) {
      const opt = new LevelOptionVM();
      opt.level = levels[i];
      opt.label = `Lv.${levels[i]}`;
      options[options.length] = opt;
    }
    return options;
  }

  // ─── 私有方法 ────────────────────────────────────────────────

  private async loadData(): Promise<void> {
    try {
      if (this.gameId === GameId.GENSHIN) {
        await this.loadGenshinData();
      } else if (this.gameId === GameId.STARRAIL) {
        await this.loadStarRailData();
      } else if (this.gameId === GameId.ZZZ) {
        await this.loadZZZData();
      }
      this.viewState = ViewState.DATA;
    } catch (error) {
      const msg = error instanceof Error ? error.message : `${error}`;
      Logger.error(TAG, `loadData failed: ${msg}`);
      this.viewState = ViewState.EMPTY;
    }
  }

  /**
   * 加载原神角色材料数据。
   */
  private async loadGenshinData(): Promise<void> {
    const avatarList = await CoreInitializer.genshinRepository.getAvatarList(this.accountId, this.roleUid);
    const avatar = avatarList.find((a) => a.avatarId === this.avatarId);
    if (avatar === undefined) {
      this.viewState = ViewState.EMPTY;
      return;
    }

    // 角色信息
    this.character.characterId = avatar.avatarId;
    this.character.name = avatar.name;
    this.character.iconUrl = avatar.icon;
    this.character.rarity = avatar.rarity;
    this.character.element = avatar.element;
    this.character.gameId = GameId.GENSHIN;
    this.character.currentLevel = avatar.level;
    this.character.targetLevel = 90;
    this.charCurrentLevel = avatar.level;
    this.charTargetLevel = 90;

    // 武器信息
    if (avatar.weaponName.length > 0) {
      this.weapon = new MaterialCalcWeaponVM();
      this.weapon.weaponId = avatar.weaponId;
      this.weapon.name = avatar.weaponName;
      this.weapon.iconUrl = avatar.weaponIconUrl;
      this.weapon.rarity = avatar.weaponRarity;
      this.weapon.affix = avatar.weaponAffixLevel;
      this.weapon.currentLevel = avatar.weaponLevel;
      this.weapon.targetLevel = 90;
      this.weaponCurrentLevel = avatar.weaponLevel;
      this.weaponTargetLevel = 90;
    }

    // 技能目标（原神：普攻、战技、爆发）
    this.skills = this.buildGenshinSkills();

    // 材料数据
    const computeRows = await CoreInitializer.genshinRepository.getAllComputeData(this.accountId, this.roleUid);
    if (computeRows.length > 0) {
      const row = computeRows.find((r) => r.avatarId === this.avatarId) ?? computeRows[0];
      const parsedArray = GenshinComputeParser.parse(row.rawJson);
      const parsed = parsedArray.length > 0 ? parsedArray[0] : null;

      if (parsed !== null) {
        this.avatarSection = this.buildSection(
          $r('app.string.material_section_avatar'),
          parsed.avatarConsume
        );

        this.weaponSection = this.buildSection(
          $r('app.string.material_section_weapon'),
          parsed.weaponConsume
        );
      }
    }
  }

  /**
   * 加载星铁角色材料数据。
   */
  private async loadStarRailData(): Promise<void> {
    const avatarList = await CoreInitializer.starRailRepository.getAvatarList(this.accountId, this.roleUid);
    const avatar = avatarList.find((a) => a.avatarId === this.avatarId);
    if (avatar === undefined) {
      this.viewState = ViewState.EMPTY;
      return;
    }

    this.character.characterId = avatar.avatarId;
    this.character.name = avatar.name;
    this.character.iconUrl = avatar.icon;
    this.character.rarity = avatar.rarity;
    this.character.gameId = GameId.STARRAIL;
    this.character.currentLevel = avatar.level;
    this.character.targetLevel = 80;
    this.charCurrentLevel = avatar.level;
    this.charTargetLevel = 80;

    // 光锥信息
    if (avatar.equipName.length > 0) {
      this.weapon = new MaterialCalcWeaponVM();
      this.weapon.weaponId = avatar.equipId;
      this.weapon.name = avatar.equipName;
      this.weapon.iconUrl = avatar.equipIconUrl;
      this.weapon.rarity = avatar.equipRarity;
      this.weapon.affix = avatar.equipRank;
      this.weapon.currentLevel = avatar.equipLevel;
      this.weapon.targetLevel = 80;
      this.weaponCurrentLevel = avatar.equipLevel;
      this.weaponTargetLevel = 80;
    }

    this.skills = this.buildStarRailSkills();

    const computeRow = await CoreInitializer.starRailRepository.getAvatarCompute(this.accountId, this.roleUid, this.avatarId);
    if (computeRow !== null) {
      const parsed = StarRailComputeParser.parse(computeRow.rawJson);

      this.avatarSection = this.buildSection(
        $r('app.string.material_section_avatar'),
        parsed.avatarConsume,
        parsed.userOwnsMaterials
      );

      this.weaponSection = this.buildSection(
        $r('app.string.material_section_light_cone'),
        parsed.equipmentConsume,
        parsed.userOwnsMaterials
      );
    }
  }

  /**
   * 加载绝区零角色材料数据。
   */
  private async loadZZZData(): Promise<void> {
    const avatarList = await CoreInitializer.zzzRepository.getAvatarList(this.accountId, this.roleUid);
    const avatar = avatarList.find((a) => a.avatarId === this.avatarId);
    if (avatar === undefined) {
      this.viewState = ViewState.EMPTY;
      return;
    }

    this.character.characterId = avatar.avatarId;
    this.character.name = avatar.nameMi18n;
    this.character.iconUrl = avatar.hollowIconPath;
    this.character.rarity = avatar.rarity === 'S' ? 5 : 4;
    this.character.gameId = GameId.ZZZ;
    this.character.currentLevel = avatar.level;
    this.character.targetLevel = 60;
    this.charCurrentLevel = avatar.level;
    this.charTargetLevel = 60;

    this.skills = this.buildZZZSkills();

    const computeRow = await CoreInitializer.zzzRepository.getAvatarCompute(this.accountId, this.roleUid, this.avatarId);
    if (computeRow !== null) {
      const parsed = ZZZComputeParser.parse(computeRow.rawJson);

      this.avatarSection = this.buildSection(
        $r('app.string.material_section_avatar'),
        parsed.avatarConsume,
        parsed.userOwnsMaterials
      );

      this.weaponSection = this.buildSection(
        $r('app.string.material_section_weapon'),
        parsed.weaponConsume,
        parsed.userOwnsMaterials
      );
    }
  }

  /**
   * 构建原神技能目标列表。
   */
  private buildGenshinSkills(): SkillTargetVM[] {
    const result: SkillTargetVM[] = [];
    const skillTypes: SkillTypeDefinition[] = [];
    
    const skill1: SkillTypeDefinition = { id: 'normal', name: $r('app.string.skill_normal') };
    const skill2: SkillTypeDefinition = { id: 'skill', name: $r('app.string.skill_skill') };
    const skill3: SkillTypeDefinition = { id: 'burst', name: $r('app.string.skill_burst') };
    skillTypes[skillTypes.length] = skill1;
    skillTypes[skillTypes.length] = skill2;
    skillTypes[skillTypes.length] = skill3;

    for (let i = 0; i < skillTypes.length; i++) {
      const vm = new SkillTargetVM();
      vm.skillId = skillTypes[i].id;
      vm.skillName = skillTypes[i].name;
      vm.currentLevel = 10;
      vm.targetLevel = 10;
      vm.maxLevel = 10;
      result[result.length] = vm;
    }
    return result;
  }

  /**
   * 构建星铁技能目标列表。
   */
  private buildStarRailSkills(): SkillTargetVM[] {
    const result: SkillTargetVM[] = [];
    const skillTypes: SkillTypeDefinition[] = [];
    
    const skill1: SkillTypeDefinition = { id: 'basic', name: $r('app.string.skill_basic') };
    const skill2: SkillTypeDefinition = { id: 'skill', name: $r('app.string.skill_skill') };
    const skill3: SkillTypeDefinition = { id: 'ultimate', name: $r('app.string.skill_ultimate') };
    const skill4: SkillTypeDefinition = { id: 'talent', name: $r('app.string.skill_talent') };
    skillTypes[skillTypes.length] = skill1;
    skillTypes[skillTypes.length] = skill2;
    skillTypes[skillTypes.length] = skill3;
    skillTypes[skillTypes.length] = skill4;

    for (let i = 0; i < skillTypes.length; i++) {
      const vm = new SkillTargetVM();
      vm.skillId = skillTypes[i].id;
      vm.skillName = skillTypes[i].name;
      vm.currentLevel = 10;
      vm.targetLevel = 10;
      vm.maxLevel = 10;
      result[result.length] = vm;
    }
    return result;
  }

  /**
   * 构建绝区零技能目标列表。
   *
   * 绝区零有 6 个独立技能，对应 skill_type：
   * - 0: 普通攻击 (normal)
   * - 1: 闪避 (dodge)
   * - 2: 支援技 (assist)
   * - 3: 特殊技 (special)
   * - 5: 连携技 (chain)
   * - 6: 核心技 (core)
   */
  private buildZZZSkills(): SkillTargetVM[] {
    const result: SkillTargetVM[] = [];

    // 按照原型顺序：普通攻击、闪避、支援技、特殊技、连携技、核心技
    const skillTypes: SkillTypeDefinition[] = [
      { id: '0', name: $r('app.string.skill_normal') },       // skill_type=0
      { id: '1', name: $r('app.string.skill_dodge') },       // skill_type=1
      { id: '2', name: $r('app.string.skill_assist') },      // skill_type=2
      { id: '3', name: $r('app.string.skill_special') },     // skill_type=3
      { id: '5', name: $r('app.string.skill_chain') },       // skill_type=5
      { id: '6', name: $r('app.string.skill_core') },        // skill_type=6
    ];

    for (let i = 0; i < skillTypes.length; i++) {
      const vm = new SkillTargetVM();
      vm.skillId = skillTypes[i].id;
      vm.skillName = skillTypes[i].name;
      vm.currentLevel = 1;
      vm.targetLevel = 12;
      vm.maxLevel = 12;
      result[result.length] = vm;
    }
    return result;
  }

  /**
   * 构建材料 Section。
   * 
   * 原神 API：返回 lack_num（缺少数量），have = num - lackNum
   * 星铁/绝区零 API：返回 user_owns_materials（背包数据），have 从 Map 查询
   * 
   * 过滤规则：已满足或已超过的材料（have >= need）不显示
   * 
   * @param userOwnsMaterials 可选的背包数据 Map（星铁/绝区零专用）
   */
  private buildSection(
    title: ResourceStr,
    items: MaterialItemRaw[],
    userOwnsMaterials?: Map<string, number>
  ): MaterialSectionVM {
    const section = new MaterialSectionVM();
    section.title = title;

    let totalHave = 0;
    let totalNeed = 0;
    const materialItems: MaterialCalcItemVM[] = [];

    for (let i = 0; i < items.length; i++) {
      const item = items[i];
      const materialId = `${item.id}`;
      
      // 计算拥有量
      let have = 0;
      if (userOwnsMaterials !== undefined && userOwnsMaterials !== null) {
        // 星铁/绝区零：从背包数据查询
        have = userOwnsMaterials.get(materialId) ?? 0;
      } else {
        // 原神：使用 lackNum 计算
        const lackNum = item.lackNum ?? 0;
        have = item.num - lackNum;
      }

      const need = item.num;
      
      // 过滤：已满足或已超过的材料不显示
      if (have >= need) {
        continue;
      }

      const vm = new MaterialCalcItemVM();
      vm.materialId = materialId;
      vm.name = item.name;
      vm.iconUrl = item.iconUrl;
      vm.rarity = typeof item.rarity === 'string' ? parseInt(item.rarity, 10) || 0 : item.rarity;
      vm.need = need;
      vm.have = have;

      totalHave += have;
      totalNeed += need;
      materialItems[materialItems.length] = vm;
    }

    section.items = materialItems;
    section.hasData = materialItems.length > 0;
    section.progressPercent = totalNeed > 0 ? Math.round((totalHave / totalNeed) * 100) : 0;
    section.deficitCount = totalNeed - totalHave;

    return section;
  }

  /**
   * 重新计算材料需求（目标等级变化时调用）。
   */
  private recalculateMaterials(): void {
    // 简化实现：目标等级变化后，需要重新调用计算接口
    // 这里暂不实现，保持现有数据不变
    // 完整实现需要重新调用 batchCompute API
  }
}
