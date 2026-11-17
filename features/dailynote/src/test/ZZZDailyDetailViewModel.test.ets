import { describe, it, expect } from '@ohos/hypium';
import { ZZZDailyDetailViewModel } from '../main/ets/viewmodel/ZZZDailyDetailViewModel';
import { ViewState } from 'basic';

/**
 * ZZZDailyDetailViewModel 单元测试。
 *
 * loadData 依赖 CoreInitializer / DB，不能在 Local Test 中执行；
 * 这里覆盖初始状态、默认便笺值与 init 的入参行为。
 */
export default function zzzDailyDetailViewModelTest() {
  describe('ZZZDailyDetailViewModel', () => {

    it('初始 viewState 为 LOADING', 0, () => {
      const vm = new ZZZDailyDetailViewModel();
      expect(vm.viewState).assertEqual(ViewState.LOADING);
    });

    it('初始 note 为默认 ZZZDailyNoteVM', 0, () => {
      const vm = new ZZZDailyDetailViewModel();
      expect(vm.note.currentEnergy).assertEqual(0);
      expect(vm.note.maxEnergy).assertEqual(240);
      expect(vm.note.energyRecoverySeconds).assertEqual(0);
      expect(vm.note.currentVitality).assertEqual(0);
      expect(vm.note.maxVitality).assertEqual(400);
      expect(vm.note.vhsSaleState).assertEqual('');
      expect(vm.note.cardSign).assertEqual('');
      expect(vm.note.abyssRefresh).assertEqual(0);
      expect(vm.note.isMemberCardOpen).assertFalse();
      expect(vm.note.memberCardState).assertEqual('');
      expect(vm.note.cafeState).assertEqual('');
      expect(vm.note.templeExpeditionState).assertEqual('');
      expect(vm.note.templeCurrentCurrency).assertEqual(0);
    });

    it('init 设置账号与角色 UID 不崩溃', 0, () => {
      const vm = new ZZZDailyDetailViewModel();
      vm.init('100000001', '800000001');
      expect(true).assertTrue();
    });

    it('init 不改变初始 viewState', 0, () => {
      const vm = new ZZZDailyDetailViewModel();
      vm.init('account', 'role');
      expect(vm.viewState).assertEqual(ViewState.LOADING);
    });

  });
}
