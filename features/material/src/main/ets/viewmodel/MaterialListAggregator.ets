/**
 * MaterialListAggregator.ets — 材料汇总页三游戏共用的纯函数聚合器
 *
 * 原神 / 星铁 / 绝区零三个 MaterialListViewModel 的「角色排序」「按材料汇总」
 * 「分组」「材料项转换」逻辑逐行重复，这里收敛为无状态静态方法。
 *
 * 差异通过参数表达，调用方保持原有行为：
 * - 已拥有数量：原神用背包 + 单角色最大已拥有量，星铁 / 绝区零保持 0
 * - 分组：原神分「经验书 / 摩拉 / 魔矿」+「其他材料」，星铁 / 绝区零只有一个 ALL 分组
 *
 * 只做 UIState 组装，不访问 DB / 网络，可直接单测。
 */

import {
  CharacterMaterialVM,
  MaterialItemVM,
  MaterialItemRaw,
  MaterialSectionVM,
  MaterialSectionType,
  MaterialSummaryVM,
  RelatedCharacterVM,
} from '../model/MaterialListModels';

/** 材料「已拥有数量」取值策略 */
export type MaterialHaveResolver = (item: MaterialItemRaw) => number;

/** 材料稀有度字符串 → 数字的转换策略 */
export type MaterialRarityResolver = (raw: number | string) => number;

export class MaterialListAggregator {
  /**
   * 已达成目标的角色永远排在最后（同组内保持原顺序），
   * 并为每个角色生成新的渲染 key，保证刷新后列表按新数据重新渲染。
   */
  static sortCharactersForDisplay(characters: CharacterMaterialVM[], loadVersion: number): CharacterMaterialVM[] {
    const needed = characters.filter((c: CharacterMaterialVM) => !c.isTargetReached);
    const reached = characters.filter((c: CharacterMaterialVM) => c.isTargetReached);
    const sorted = needed.concat(reached);
    for (let i = 0; i < sorted.length; i++) {
      sorted[i].renderKey = `${sorted[i].characterId}_${loadVersion}`;
    }
    return sorted;
  }

  /** 为分组生成渲染 key（type + 本次加载版本号） */
  static stampSectionKeys(sections: MaterialSectionVM[], loadVersion: number): void {
    for (let i = 0; i < sections.length; i++) {
      sections[i].renderKey = `${sections[i].type}_${loadVersion}`;
    }
  }

  /**
   * 将所有角色的材料汇总为按材料视图。
   * 按 materialId 去重，同一材料的需求量累加。
   *
   * @param bagCounts 材料背包（原神）。非 null 时计算「已拥有」：
   *   每个角色的缺口都是计算器针对该角色单独计算的（各自扣除完整背包），不能直接相加，
   *   取 max(背包数量, 单个角色的最大已拥有量)，且不超过总需求。
   *   传 null 时（星铁 / 绝区零）「已拥有」保持 0。
   */
  static aggregateMaterials(characters: CharacterMaterialVM[], bagCounts: Map<string, number> | null): MaterialSummaryVM[] {
    const materialMap: Map<string, MaterialSummaryVM> = new Map();
    /** 单个角色内同一材料的已拥有量之和，在所有角色中的最大值 */
    const maxCharHave: Map<string, number> = new Map();

    for (let i = 0; i < characters.length; i++) {
      const char = characters[i];
      const charHave: Map<string, number> = new Map();
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
        if (bagCounts !== null) {
          charHave.set(mat.materialId, (charHave.get(mat.materialId) ?? 0) + mat.have);
        }
        const existing = materialMap.get(mat.materialId);

        if (existing !== undefined) {
          // 已存在：累加需求量，合并关联角色（已拥有在循环结束后统一计算）
          existing.totalNeed += mat.need;
          MaterialListAggregator.mergeRelatedCharacter(existing, char, mat.need);
        } else {
          const summary = new MaterialSummaryVM();
          summary.materialId = mat.materialId;
          summary.name = mat.name;
          summary.iconUrl = mat.iconUrl;
          summary.rarity = mat.rarity;
          summary.totalHave = 0;
          summary.totalNeed = mat.need;
          summary.relatedCharacters[summary.relatedCharacters.length] =
            MaterialListAggregator.createRelatedCharacter(char, mat.need);
          materialMap.set(mat.materialId, summary);
        }
      }

      if (bagCounts !== null) {
        charHave.forEach((have: number, materialId: string) => {
          maxCharHave.set(materialId, Math.max(maxCharHave.get(materialId) ?? 0, have));
        });
      }
    }

    if (bagCounts !== null) {
      // 已拥有 = min(总需求, max(背包数量, 单个角色的最大已拥有量))
      materialMap.forEach((summary: MaterialSummaryVM, materialId: string) => {
        const have = Math.max(bagCounts.get(materialId) ?? 0, maxCharHave.get(materialId) ?? 0);
        summary.totalHave = Math.min(have, summary.totalNeed);
      });
    }

    const result: MaterialSummaryVM[] = [];
    materialMap.forEach((value: MaterialSummaryVM) => {
      result[result.length] = value;
    });
    result.sort((a: MaterialSummaryVM, b: MaterialSummaryVM) => {
      // 将 materialId 转为数值比较（从大到小）
      const idA = parseInt(a.materialId, 10) || 0;
      const idB = parseInt(b.materialId, 10) || 0;
      return idB - idA;
    });
    return result;
  }

  /**
   * 将材料汇总列表分组为 sections。
   *
   * @param currencyIds 货币类材料 id（经验书 / 魔矿 / 摩拉）。非 null 时分两个分组：
   *   第一个是货币（按总需求量降序），第二个是其他材料。
   *   传 null 时（星铁 / 绝区零）只产生一个 ALL 分组。
   */
  static groupIntoSections(materials: MaterialSummaryVM[], currencyIds: Set<string> | null): MaterialSectionVM[] {
    const sections: MaterialSectionVM[] = [];

    if (currencyIds === null) {
      if (materials.length === 0) {
        return sections;
      }
      const section = new MaterialSectionVM();
      section.type = MaterialSectionType.ALL;
      section.title = $r('app.string.material_section_all');
      section.materials = materials;
      sections[sections.length] = section;
      return sections;
    }

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
    currencyMaterials.sort((a: MaterialSummaryVM, b: MaterialSummaryVM) => b.totalNeed - a.totalNeed);

    // 第一个 section：经验书 / 摩拉 / 魔矿
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
   * 将原始材料项转换为 MaterialItemVM 数组。
   * 过滤规则：已满足或已超过的材料（have >= need）不显示。
   *
   * @param haveOf 已拥有数量的取值策略（原神按 lackNum 反推，绝区零按背包 / 缺口为 0）
   * @param rarityOf 稀有度字符串的转换策略
   */
  static buildMaterialItems(
    items: MaterialItemRaw[],
    haveOf: MaterialHaveResolver,
    rarityOf: MaterialRarityResolver,
  ): MaterialItemVM[] {
    const result: MaterialItemVM[] = [];
    for (let i = 0; i < items.length; i++) {
      const item = items[i];
      const need = item.num;
      const have = haveOf(item);

      // 过滤：已满足或已超过的材料不显示
      if (have >= need) {
        continue;
      }

      const vm = new MaterialItemVM();
      vm.materialId = `${item.id}`;
      vm.name = item.name;
      vm.iconUrl = item.iconUrl;
      vm.rarity = rarityOf(item.rarity);
      vm.need = need;
      vm.have = have;
      result[result.length] = vm;
    }
    return result;
  }

  /** 数字字符串稀有度（原神 / 通用）：'5' → 5，数字原样返回 */
  static rarityFromString(raw: number | string): number {
    return typeof raw === 'string' ? parseInt(raw, 10) || 0 : raw;
  }

  /** 绝区零稀有度：S=5 / A=4 / B=3 / C=2，数字原样返回 */
  static rarityFromZZZString(raw: number | string): number {
    if (typeof raw !== 'string') {
      return raw;
    }
    if (raw === 'S') {
      return 5;
    }
    if (raw === 'A') {
      return 4;
    }
    if (raw === 'B') {
      return 3;
    }
    if (raw === 'C') {
      return 2;
    }
    return 0;
  }

  /** 同一材料在同一角色内累加需求量，首次出现时追加关联角色 */
  private static mergeRelatedCharacter(summary: MaterialSummaryVM, char: CharacterMaterialVM, need: number): void {
    for (let r = 0; r < summary.relatedCharacters.length; r++) {
      if (summary.relatedCharacters[r].characterId === char.characterId) {
        summary.relatedCharacters[r].needCount += need;
        return;
      }
    }
    summary.relatedCharacters[summary.relatedCharacters.length] =
      MaterialListAggregator.createRelatedCharacter(char, need);
  }

  private static createRelatedCharacter(char: CharacterMaterialVM, need: number): RelatedCharacterVM {
    const relatedChar = new RelatedCharacterVM();
    relatedChar.characterId = char.characterId;
    relatedChar.characterName = char.characterName;
    relatedChar.characterIconUrl = char.characterIconUrl;
    relatedChar.needCount = need;
    return relatedChar;
  }
}
