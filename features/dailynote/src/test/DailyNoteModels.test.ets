import { describe, it, expect } from '@ohos/hypium';
import { GenshinDailyNoteVM, StarRailDailyNoteVM, ZZZDailyNoteVM, ExpeditionVM, GenshinDailyTaskVM } from '../main/ets/model/DailyNoteModels';

export default function dailyNoteModelsTest() {
  describe('DailyNoteModels', () => {

    it('ExpeditionVM 构造函数赋值', 0, () => {
      const vm = new ExpeditionVM('https://example.com/a.png', 120, false);
      expect(vm.avatarUrl).assertEqual('https://example.com/a.png');
      expect(vm.remainSeconds).assertEqual(120);
      expect(vm.isFinished).assertFalse();
    });

    it('GenshinDailyTaskVM 构造函数赋值', 0, () => {
      const vm = new GenshinDailyTaskVM(2, 4, true, 3);
      expect(vm.finishedNum).assertEqual(2);
      expect(vm.totalNum).assertEqual(4);
      expect(vm.isExtraTaskRewardReceived).assertTrue();
      expect(vm.storedAdventure).assertEqual(3);
    });

    it('原神便签默认值', 0, () => {
      const vm = new GenshinDailyNoteVM();
      expect(vm.currentResin).assertEqual(0);
      expect(vm.maxResin).assertEqual(200);
      expect(vm.maxHomeCoin).assertEqual(2400);
      expect(vm.dailyTask.totalNum).assertEqual(4);
      expect(vm.resinDiscountNumLimit).assertEqual(3);
      expect(vm.maxExpeditionNum).assertEqual(5);
      expect(vm.expeditions.length).assertEqual(0);
      expect(vm.transformerDay).assertEqual(0);
    });

    it('星铁便签默认值', 0, () => {
      const vm = new StarRailDailyNoteVM();
      expect(vm.currentStamina).assertEqual(0);
      expect(vm.maxStamina).assertEqual(240);
      expect(vm.totalExpeditionNum).assertEqual(4);
      expect(vm.maxTrainScore).assertEqual(500);
      expect(vm.maxRogueScore).assertEqual(14000);
      expect(vm.weeklyCocoonLimit).assertEqual(3);
      expect(vm.rogueTournWeeklyMax).assertEqual(1000);
      expect(vm.expeditions.length).assertEqual(0);
    });

    it('绝区零便签默认值', 0, () => {
      const vm = new ZZZDailyNoteVM();
      expect(vm.currentEnergy).assertEqual(0);
      expect(vm.maxEnergy).assertEqual(240);
      expect(vm.maxVitality).assertEqual(400);
      expect(vm.cardSign).assertEqual('');
      expect(vm.isMemberCardOpen).assertFalse();
      expect(vm.templeCurrentCurrency).assertEqual(0);
    });

  });
}
