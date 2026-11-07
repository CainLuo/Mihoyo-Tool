import { describe, it, expect } from '@ohos/hypium';
import { ZZZCharacterDetailViewModel } from '../main/ets/viewmodel/ZZZCharacterDetailViewModel';
import { ViewState } from 'basic';

/**
 * ZZZCharacterDetailViewModel 单元测试。
 *
 * loadData / parseRawJson 依赖 CoreInitializer 与 DB，不能在 Local Test 中执行；
 * 这里覆盖初始状态、默认值与 init 的入参行为。
 */
export default function zzzCharacterDetailViewModelTest() {
  describe('ZZZCharacterDetailViewModel', () => {

    it('初始 viewState 为 LOADING', 0, () => {
      const vm = new ZZZCharacterDetailViewModel();
      expect(vm.viewState).assertEqual(ViewState.LOADING);
    });

    it('初始 networkErrorMsg 为空字符串', 0, () => {
      const vm = new ZZZCharacterDetailViewModel();
      expect(vm.networkErrorMsg).assertEqual('');
    });

    it('初始基础字段为空 / 默认值', 0, () => {
      const vm = new ZZZCharacterDetailViewModel();
      expect(vm.charName).assertEqual('');
      expect(vm.charFullName).assertEqual('');
      expect(vm.charLevel).assertEqual(0);
      expect(vm.charRarity).assertEqual('');
      expect(vm.charRank).assertEqual(0);
      expect(vm.charVerticalPaintingUrl).assertEqual('');
    });

    it('初始数组字段为空', 0, () => {
      const vm = new ZZZCharacterDetailViewModel();
      expect(vm.ranks.length).assertEqual(0);
      expect(vm.skills.length).assertEqual(0);
      expect(vm.equips.length).assertEqual(0);
      expect(vm.suitSummaries.length).assertEqual(0);
      expect(vm.properties.length).assertEqual(0);
    });

    it('初始音擎为 null', 0, () => {
      const vm = new ZZZCharacterDetailViewModel();
      expect(vm.weapon).assertNull();
    });

    it('init 设置三个参数不崩溃', 0, () => {
      const vm = new ZZZCharacterDetailViewModel();
      vm.init('100000001', '800000001', '1011');
      expect(true).assertTrue();
    });

    it('init 不改变初始 viewState', 0, () => {
      const vm = new ZZZCharacterDetailViewModel();
      vm.init('account', 'role', 'entity');
      expect(vm.viewState).assertEqual(ViewState.LOADING);
    });

  });
}
