import { describe, it, expect } from '@ohos/hypium';
import { MaterialListAggregator } from '../main/ets/viewmodel/MaterialListAggregator';
import {
  CharacterMaterialVM,
  MaterialItemRaw,
  MaterialItemVM,
  MaterialSectionType,
  MaterialSummaryVM,
} from '../main/ets/model/MaterialListModels';

function makeItem(id: string, need: number, have: number, rarity: number): MaterialItemVM {
  const item = new MaterialItemVM();
  item.materialId = id;
  item.name = id;
  item.need = need;
  item.have = have;
  item.rarity = rarity;
  return item;
}

function makeCharacter(id: string, reached: boolean, items: MaterialItemVM[]): CharacterMaterialVM {
  const character = new CharacterMaterialVM();
  character.characterId = id;
  character.characterName = id;
  character.characterIconUrl = `${id}.png`;
  character.isTargetReached = reached;
  character.avatarMaterials = items;
  return character;
}

function makeRaw(id: number, num: number, rarity: number | string, lackNum?: number): MaterialItemRaw {
  const raw: MaterialItemRaw = {
    id: id,
    name: `${id}`,
    iconUrl: `${id}.png`,
    rarity: rarity,
    num: num,
  };
  if (lackNum !== undefined) {
    raw.lackNum = lackNum;
  }
  return raw;
}

function makeSummary(id: string, need: number, have: number): MaterialSummaryVM {
  const summary = new MaterialSummaryVM();
  summary.materialId = id;
  summary.name = id;
  summary.totalNeed = need;
  summary.totalHave = have;
  return summary;
}

export default function materialListAggregatorTest() {
  describe('MaterialListAggregator', () => {

    it('sortCharactersForDisplay 把已达成目标的角色排到最后并刷新 renderKey', 0, () => {
      const reached = makeCharacter('1002', true, []);
      const needed = makeCharacter('1001', false, []);
      const sorted = MaterialListAggregator.sortCharactersForDisplay([reached, needed], 123);

      expect(sorted.length).assertEqual(2);
      expect(sorted[0].characterId).assertEqual('1001');
      expect(sorted[1].characterId).assertEqual('1002');
      expect(sorted[0].renderKey).assertEqual('1001_123');
      expect(sorted[1].renderKey).assertEqual('1002_123');
    });

    it('aggregateMaterials 累加同材料需求并合并关联角色', 0, () => {
      const first = makeCharacter('a', false, [makeItem('11', 3, 0, 5), makeItem('12', 2, 0, 4)]);
      const second = makeCharacter('b', false, [makeItem('11', 4, 0, 5)]);
      const result = MaterialListAggregator.aggregateMaterials([first, second], null);

      expect(result.length).assertEqual(2);
      // 按 materialId 数值降序：12 在前，11 在后
      expect(result[0].materialId).assertEqual('12');
      expect(result[1].materialId).assertEqual('11');
      expect(result[1].totalNeed).assertEqual(7);
      expect(result[1].relatedCharacters.length).assertEqual(2);
      expect(result[1].relatedCharacters[0].characterId).assertEqual('a');
      expect(result[1].relatedCharacters[0].needCount).assertEqual(3);
      expect(result[1].relatedCharacters[1].characterId).assertEqual('b');
      expect(result[1].relatedCharacters[1].needCount).assertEqual(4);
    });

    it('aggregateMaterials 同一角色内同材料合并为一个关联角色', 0, () => {
      const character = makeCharacter('a', false, [makeItem('11', 3, 0, 5), makeItem('11', 2, 0, 5)]);
      const result = MaterialListAggregator.aggregateMaterials([character], null);

      expect(result.length).assertEqual(1);
      expect(result[0].totalNeed).assertEqual(5);
      expect(result[0].relatedCharacters.length).assertEqual(1);
      expect(result[0].relatedCharacters[0].needCount).assertEqual(5);
    });

    it('aggregateMaterials 不传背包时已拥有保持 0（星铁 / 绝区零）', 0, () => {
      const character = makeCharacter('a', false, [makeItem('11', 5, 3, 5)]);
      const result = MaterialListAggregator.aggregateMaterials([character], null);

      expect(result[0].totalHave).assertEqual(0);
      expect(result[0].deficit).assertEqual(5);
    });

    it('aggregateMaterials 原神取 max(背包, 单角色最大已拥有) 且不超过总需求', 0, () => {
      const first = makeCharacter('a', false, [makeItem('11', 5, 4, 5), makeItem('12', 3, 1, 4)]);
      const second = makeCharacter('b', false, [makeItem('11', 2, 1, 5)]);
      const bag = new Map<string, number>();
      bag.set('11', 2);
      bag.set('12', 9);
      const result = MaterialListAggregator.aggregateMaterials([first, second], bag);

      const eleven = result.filter((s: MaterialSummaryVM) => s.materialId === '11')[0];
      const twelve = result.filter((s: MaterialSummaryVM) => s.materialId === '12')[0];
      // 11：max(背包 2, 单角色最大 4) = 4，总需求 7 → 4
      expect(eleven.totalHave).assertEqual(4);
      expect(eleven.totalNeed).assertEqual(7);
      // 12：max(背包 9, 单角色最大 1) = 9，但不超过总需求 3
      expect(twelve.totalHave).assertEqual(3);
    });

    it('aggregateMaterials 合并角色突破 / 技能 / 武器三类材料', 0, () => {
      const character = makeCharacter('a', false, [makeItem('11', 1, 0, 5)]);
      character.skillMaterials = [makeItem('21', 2, 0, 4)];
      character.weaponMaterials = [makeItem('31', 3, 0, 3)];
      const result = MaterialListAggregator.aggregateMaterials([character], null);

      expect(result.length).assertEqual(3);
      expect(result[0].materialId).assertEqual('31');
      expect(result[1].materialId).assertEqual('21');
      expect(result[2].materialId).assertEqual('11');
      expect(result[0].totalNeed).assertEqual(3);
      expect(result[1].totalNeed).assertEqual(2);
    });

    it('aggregateMaterials 空角色列表返回空数组', 0, () => {
      const result = MaterialListAggregator.aggregateMaterials([], null);
      expect(result.length).assertEqual(0);
    });

    it('groupIntoSections 传货币 id 时分货币 / 其他两组，货币按需求降序', 0, () => {
      const materials = [makeSummary('11', 5, 0), makeSummary('202', 10, 0), makeSummary('104003', 30, 0)];
      const currencyIds = new Set<string>(['202', '104003', '104013']);
      const sections = MaterialListAggregator.groupIntoSections(materials, currencyIds);

      expect(sections.length).assertEqual(2);
      expect(sections[0].type).assertEqual(MaterialSectionType.CURRENCY);
      expect(sections[0].materials.length).assertEqual(2);
      expect(sections[0].materials[0].materialId).assertEqual('104003');
      expect(sections[0].materials[1].materialId).assertEqual('202');
      expect(sections[1].type).assertEqual(MaterialSectionType.MATERIALS);
      expect(sections[1].materials.length).assertEqual(1);
    });

    it('groupIntoSections 只有货币时只产生一个分组', 0, () => {
      const materials = [makeSummary('202', 10, 0)];
      const currencyIds = new Set<string>(['202']);
      const sections = MaterialListAggregator.groupIntoSections(materials, currencyIds);

      expect(sections.length).assertEqual(1);
      expect(sections[0].type).assertEqual(MaterialSectionType.CURRENCY);
    });

    it('groupIntoSections 不传货币 id 时只产生一个 ALL 分组', 0, () => {
      const materials = [makeSummary('11', 5, 0), makeSummary('12', 3, 0)];
      const sections = MaterialListAggregator.groupIntoSections(materials, null);

      expect(sections.length).assertEqual(1);
      expect(sections[0].type).assertEqual(MaterialSectionType.ALL);
      expect(sections[0].materials.length).assertEqual(2);
    });

    it('groupIntoSections 空材料列表返回空数组', 0, () => {
      expect(MaterialListAggregator.groupIntoSections([], null).length).assertEqual(0);
      expect(MaterialListAggregator.groupIntoSections([], new Set<string>()).length).assertEqual(0);
    });

    it('stampSectionKeys 按 type + 版本号写入 renderKey', 0, () => {
      const sections = MaterialListAggregator.groupIntoSections([makeSummary('11', 1, 0)], null);
      MaterialListAggregator.stampSectionKeys(sections, 456);
      expect(sections[0].renderKey).assertEqual(`${MaterialSectionType.ALL}_456`);
    });

    it('buildMaterialItems 过滤已满足的材料并按策略取值', 0, () => {
      const raws = [makeRaw(11, 5, '5', 2), makeRaw(12, 4, '4', 0)];
      const items = MaterialListAggregator.buildMaterialItems(
        raws,
        (item: MaterialItemRaw): number => item.num - (item.lackNum ?? 0),
        MaterialListAggregator.rarityFromString);

      expect(items.length).assertEqual(1);
      expect(items[0].materialId).assertEqual('11');
      expect(items[0].need).assertEqual(5);
      expect(items[0].have).assertEqual(3);
      expect(items[0].rarity).assertEqual(5);
    });

    it('buildMaterialItems 已拥有为 0 时等价于过滤缺口 <= 0（绝区零 need_get）', 0, () => {
      const raws = [makeRaw(11, 0, 'S'), makeRaw(12, 3, 'A')];
      const items = MaterialListAggregator.buildMaterialItems(
        raws,
        (_item: MaterialItemRaw): number => 0,
        MaterialListAggregator.rarityFromZZZString);

      expect(items.length).assertEqual(1);
      expect(items[0].materialId).assertEqual('12');
      expect(items[0].have).assertEqual(0);
      expect(items[0].rarity).assertEqual(4);
    });

    it('rarityFromString 处理数字与字符串', 0, () => {
      expect(MaterialListAggregator.rarityFromString('5')).assertEqual(5);
      expect(MaterialListAggregator.rarityFromString(4)).assertEqual(4);
      expect(MaterialListAggregator.rarityFromString('')).assertEqual(0);
    });

    it('rarityFromZZZString 映射 S/A/B/C 并保留数字', 0, () => {
      expect(MaterialListAggregator.rarityFromZZZString('S')).assertEqual(5);
      expect(MaterialListAggregator.rarityFromZZZString('A')).assertEqual(4);
      expect(MaterialListAggregator.rarityFromZZZString('B')).assertEqual(3);
      expect(MaterialListAggregator.rarityFromZZZString('C')).assertEqual(2);
      expect(MaterialListAggregator.rarityFromZZZString('X')).assertEqual(0);
      expect(MaterialListAggregator.rarityFromZZZString(3)).assertEqual(3);
    });

  });
}
