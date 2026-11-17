import { describe, it, expect } from '@ohos/hypium';
import { compareCharacter } from '../main/ets/utils/CharacterSortUtil';

export default function characterSortUtilTest() {
  describe('CharacterSortUtil', () => {

    it('五星排在四星之前', 0, () => {
      expect(compareCharacter(5, '10000001', 4, '99999999') < 0).assertTrue();
      expect(compareCharacter(4, '99999999', 5, '10000001') > 0).assertTrue();
    });

    it('同星级按 ID 从大到小', 0, () => {
      expect(compareCharacter(5, '10000002', 5, '10000001') < 0).assertTrue();
      expect(compareCharacter(4, '10000001', 4, '10000002') > 0).assertTrue();
      expect(compareCharacter(5, '10000001', 5, '10000001')).assertEqual(0);
    });

    it('埃洛伊星级 105 按五星处理', 0, () => {
      expect(compareCharacter(105, '10000001', 5, '10000001')).assertEqual(0);
      expect(compareCharacter(105, '10000001', 4, '99999999') < 0).assertTrue();
    });

    it('非数字 ID 按 0 处理', 0, () => {
      expect(compareCharacter(5, 'abc', 5, '0')).assertEqual(0);
      expect(compareCharacter(5, 'abc', 5, '100') > 0).assertTrue();
    });

    it('排序结果符合星级优先规则', 0, () => {
      const items: string[] = ['4-10000005', '5-10000002', '5-10000001', '4-10000006'];
      items.sort((a: string, b: string): number => {
        const aRarity = parseInt(a.split('-')[0], 10);
        const bRarity = parseInt(b.split('-')[0], 10);
        return compareCharacter(aRarity, a.split('-')[1], bRarity, b.split('-')[1]);
      });
      expect(items[0]).assertEqual('5-10000002');
      expect(items[1]).assertEqual('5-10000001');
      expect(items[2]).assertEqual('4-10000006');
      expect(items[3]).assertEqual('4-10000005');
    });

  });
}
