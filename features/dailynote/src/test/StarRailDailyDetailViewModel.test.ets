import { describe, it, expect } from '@ohos/hypium';
import { StarRailDailyDetailViewModel } from '../main/ets/viewmodel/StarRailDailyDetailViewModel';
import { ViewState } from 'basic';

/**
 * StarRailDailyDetailViewModel 单元测试。
 *
 * loadData 依赖 CoreInitializer / DB，不能在 Local Test 中执行；
 * 这里覆盖初始状态、默认便笺值与 init 的入参行为。
 */
export default function starRailDailyDetailViewModelTest() {
  describe('StarRailDailyDetailViewModel', () => {

    it('初始 viewState 为 LOADING', 0, () => {
      const vm = new StarRailDailyDetailViewModel();
      expect(vm.viewState).assertEqual(ViewState.LOADING);
    });

    it('初始 note 为默认 StarRailDailyNoteVM', 0, () => {
      const vm = new StarRailDailyDetailViewModel();
      expect(vm.note.currentStamina).assertEqual(0);
      expect(vm.note.maxStamina).assertEqual(240);
      expect(vm.note.staminaRecoverySeconds).assertEqual(0);
      expect(vm.note.currentReserveStamina).assertEqual(0);
      expect(vm.note.isReserveStaminaFull).assertFalse();
      expect(vm.note.acceptedExpeditionNum).assertEqual(0);
      expect(vm.note.totalExpeditionNum).assertEqual(4);
      expect(vm.note.expeditions.length).assertEqual(0);
    });

    it('初始星铁专属字段为默认值', 0, () => {
      const vm = new StarRailDailyDetailViewModel();
      expect(vm.note.currentTrainScore).assertEqual(0);
      expect(vm.note.maxTrainScore).assertEqual(500);
      expect(vm.note.currentRogueScore).assertEqual(0);
      expect(vm.note.maxRogueScore).assertEqual(14000);
      expect(vm.note.weeklyCocoonCnt).assertEqual(0);
      expect(vm.note.weeklyCocoonLimit).assertEqual(3);
      expect(vm.note.isRogueTournWeeklyUnlocked).assertFalse();
      expect(vm.note.rogueTournWeeklyCur).assertEqual(0);
      expect(vm.note.rogueTournWeeklyMax).assertEqual(1000);
      expect(vm.note.isRogueTournExpFull).assertFalse();
      expect(vm.note.gridFightWeeklyCur).assertEqual(0);
      expect(vm.note.gridFightWeeklyMax).assertEqual(0);
    });

    it('init 设置账号与角色 UID 不崩溃', 0, () => {
      const vm = new StarRailDailyDetailViewModel();
      vm.init('100000001', '800000001');
      expect(true).assertTrue();
    });

    it('init 不改变初始 viewState', 0, () => {
      const vm = new StarRailDailyDetailViewModel();
      vm.init('account', 'role');
      expect(vm.viewState).assertEqual(ViewState.LOADING);
    });

  });
}
