import { describe, it, expect } from '@ohos/hypium';
import { StarRailCharacterDetailViewModel } from '../main/ets/viewmodel/StarRailCharacterDetailViewModel';
import { ViewState } from 'basic';

/**
 * StarRailCharacterDetailViewModel 单元测试。
 *
 * loadData / parseRawJson 依赖 CoreInitializer 与 DB，不能在 Local Test 中执行；
 * 这里覆盖初始状态、默认值与 init 的入参行为，解析回归由设备端/冒烟覆盖。
 */
export default function starRailCharacterDetailViewModelTest() {
  describe('StarRailCharacterDetailViewModel', () => {

    it('初始 viewState 为 LOADING', 0, () => {
      const vm = new StarRailCharacterDetailViewModel();
      expect(vm.viewState).assertEqual(ViewState.LOADING);
    });

    it('初始 networkErrorMsg 为空字符串', 0, () => {
      const vm = new StarRailCharacterDetailViewModel();
      expect(vm.networkErrorMsg).assertEqual('');
    });

    it('初始基础字段为空 / 默认值', 0, () => {
      const vm = new StarRailCharacterDetailViewModel();
      expect(vm.charName).assertEqual('');
      expect(vm.charLevel).assertEqual(0);
      expect(vm.charElement).assertEqual('');
      expect(vm.charIconUrl).assertEqual('');
      expect(vm.charImageUrl).assertEqual('');
      expect(vm.charRarity).assertEqual(5);
      expect(vm.charRank).assertEqual(0);
    });

    it('初始数组字段为空', 0, () => {
      const vm = new StarRailCharacterDetailViewModel();
      expect(vm.ranks.length).assertEqual(0);
      expect(vm.skillsMain.length).assertEqual(0);
      expect(vm.skillsExtra.length).assertEqual(0);
      expect(vm.skillsAttr.length).assertEqual(0);
      expect(vm.relics.length).assertEqual(0);
      expect(vm.ornaments.length).assertEqual(0);
      expect(vm.properties.length).assertEqual(0);
    });

    it('初始光锥为 null', 0, () => {
      const vm = new StarRailCharacterDetailViewModel();
      expect(vm.equip).assertNull();
    });

    it('init 设置三个参数不崩溃', 0, () => {
      const vm = new StarRailCharacterDetailViewModel();
      vm.init('100000001', '800000001', '1302');
      expect(true).assertTrue();
    });

    it('init 不改变初始 viewState', 0, () => {
      const vm = new StarRailCharacterDetailViewModel();
      vm.init('account', 'role', 'entity');
      expect(vm.viewState).assertEqual(ViewState.LOADING);
    });

  });
}
