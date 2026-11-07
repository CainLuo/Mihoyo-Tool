import { describe, it, expect } from '@ohos/hypium';
import {
  WidgetSettingsStep,
  WidgetSettingsViewModel,
} from '../main/ets/viewmodel/WidgetSettingsViewModel';
import { WidgetSize } from '../main/ets/model/WidgetConfigModels';
import {
  WidgetAccountDataV2,
  WidgetDataStore,
  WidgetSlotRef,
  WidgetSlotSnapshot,
} from '../main/ets/model/WidgetDataStoreModels';
import { GameId } from 'core';

function makeSlot(accountId: string, gameId: string, roleId: string, nickname: string): WidgetSlotRef {
  const slot = new WidgetSlotRef();
  slot.accountId = accountId;
  slot.accountName = accountId;
  slot.gameId = gameId;
  slot.roleId = roleId;
  slot.nickname = nickname;
  slot.server = 'cn_gf01';
  return slot;
}

function makeStore(): WidgetDataStore {
  const store = new WidgetDataStore();
  const account = new WidgetAccountDataV2();
  account.accountName = 'A1';
  store.data['a1'] = account;

  const genshin = new WidgetSlotSnapshot();
  genshin.gameId = GameId.GENSHIN;
  genshin.nickname = '原神角色';
  genshin.server = 'cn_gf01';
  account.slots['r_gi'] = genshin;

  const starRail = new WidgetSlotSnapshot();
  starRail.gameId = GameId.STARRAIL;
  starRail.nickname = '星铁角色';
  starRail.server = 'prod_gf_cn';
  account.slots['r_sr'] = starRail;

  const zzz = new WidgetSlotSnapshot();
  zzz.gameId = GameId.ZZZ;
  zzz.nickname = '绝区零角色';
  zzz.server = 'prod_gf_cn';
  account.slots['r_zzz'] = zzz;

  return store;
}

export default function widgetSettingsViewModelTest() {
  describe('WidgetSettingsViewModel', () => {

    it('初始状态为 SIZE / 2x2 / 2 个槽位', 0, () => {
      const vm = new WidgetSettingsViewModel();
      expect(vm.currentStep).assertEqual(WidgetSettingsStep.SIZE);
      expect(vm.selectedSize).assertEqual(WidgetSize.SIZE_2X2);
      expect(vm.selectedGameType).assertEqual(GameId.GENSHIN);
      expect(vm.selectedSlots.length).assertEqual(0);
      expect(vm.getMaxSlots()).assertEqual(2);
      expect(vm.canGoNext()).assertTrue();
      expect(vm.canGoPrev()).assertFalse();
    });

    it('2x2 流程：SIZE → SLOT → DONE', 0, () => {
      const vm = new WidgetSettingsViewModel();
      vm.goNext();
      expect(vm.currentStep).assertEqual(WidgetSettingsStep.SLOT);
      expect(vm.canGoNext()).assertFalse();

      vm.toggleSlot(makeSlot('a1', GameId.GENSHIN, 'r1', '角色1'));
      expect(vm.canGoNext()).assertTrue();
      vm.goNext();
      expect(vm.currentStep).assertEqual(WidgetSettingsStep.DONE);
      expect(vm.canGoNext()).assertFalse();

      vm.goPrev();
      expect(vm.currentStep).assertEqual(WidgetSettingsStep.SLOT);
    });

    it('1x2 流程包含 GAME 步骤且只能选 1 个', 0, () => {
      const vm = new WidgetSettingsViewModel();
      vm.selectSize(WidgetSize.SIZE_1X2);
      vm.goNext();
      expect(vm.currentStep).assertEqual(WidgetSettingsStep.GAME);

      vm.selectGameType(GameId.STARRAIL);
      vm.goNext();
      expect(vm.currentStep).assertEqual(WidgetSettingsStep.SLOT);

      const first = makeSlot('a1', GameId.STARRAIL, 'r1', '角色1');
      const second = makeSlot('a1', GameId.STARRAIL, 'r2', '角色2');
      vm.toggleSlot(first);
      vm.toggleSlot(second);
      expect(vm.selectedSlots.length).assertEqual(1);
      expect(vm.selectedSlots[0].key).assertEqual(second.key);
      expect(vm.getMaxSlots()).assertEqual(1);
    });

    it('切换尺寸时按新上限截断已选 slots', 0, () => {
      const vm = new WidgetSettingsViewModel();
      vm.toggleSlot(makeSlot('a1', GameId.GENSHIN, 'r1', '角色1'));
      vm.toggleSlot(makeSlot('a1', GameId.STARRAIL, 'r2', '角色2'));
      expect(vm.selectedSlots.length).assertEqual(2);

      vm.selectSize(WidgetSize.SIZE_1X2);
      expect(vm.selectedSlots.length).assertEqual(1);
      expect(vm.getMaxSlots()).assertEqual(1);
    });

    it('多选尺寸下 toggleSlot 支持取消与上限', 0, () => {
      const vm = new WidgetSettingsViewModel();
      vm.selectSize(WidgetSize.SIZE_4X4);
      const first = makeSlot('a1', GameId.GENSHIN, 'r1', '角色1');
      const second = makeSlot('a1', GameId.STARRAIL, 'r2', '角色2');
      const third = makeSlot('a1', GameId.ZZZ, 'r3', '角色3');

      expect(vm.toggleSlot(first)).assertTrue();
      expect(vm.toggleSlot(second)).assertTrue();
      expect(vm.toggleSlot(third)).assertFalse();
      expect(vm.selectedSlots.length).assertEqual(2);

      expect(vm.toggleSlot(first)).assertFalse();
      expect(vm.selectedSlots.length).assertEqual(1);
      expect(vm.isSlotSelected('a1', GameId.STARRAIL, 'r2')).assertTrue();
      expect(vm.isSlotSelected('a1', GameId.GENSHIN, 'r1')).assertFalse();
    });

    it('1x2 点击已选中的项保持选中', 0, () => {
      const vm = new WidgetSettingsViewModel();
      vm.selectSize(WidgetSize.SIZE_1X2);
      const slot = makeSlot('a1', GameId.GENSHIN, 'r1', '角色1');

      expect(vm.toggleSlot(slot)).assertTrue();
      expect(vm.toggleSlot(slot)).assertTrue();
      expect(vm.selectedSlots.length).assertEqual(1);
      expect(vm.selectedSlots[0].key).assertEqual(slot.key);
    });

    it('selectGameType 清空已选 slots', 0, () => {
      const vm = new WidgetSettingsViewModel();
      vm.toggleSlot(makeSlot('a1', GameId.GENSHIN, 'r1', '角色1'));
      vm.selectGameType(GameId.STARRAIL);
      expect(vm.selectedSlots.length).assertEqual(0);
      expect(vm.selectedGameType).assertEqual(GameId.STARRAIL);
    });

    it('getSelectedSummary 展示昵称与游戏名', 0, () => {
      const vm = new WidgetSettingsViewModel();
      vm.selectedSlots = [
        makeSlot('a1', GameId.GENSHIN, 'r1', '旅行者'),
        makeSlot('a1', GameId.STARRAIL, 'r2', '开拓者'),
      ];
      expect(vm.getSelectedSummary()).assertEqual('旅行者 (原神)、开拓者 (星穹铁道)');
    });

    it('空选择时 getSelectedSummary 为空字符串', 0, () => {
      const vm = new WidgetSettingsViewModel();
      expect(vm.getSelectedSummary()).assertEqual('');
    });

    it('getAvailableGameTypes 返回三个游戏', 0, () => {
      const vm = new WidgetSettingsViewModel();
      const games = vm.getAvailableGameTypes();
      expect(games.length).assertEqual(3);
      expect(games[0]).assertEqual(GameId.GENSHIN);
      expect(games[1]).assertEqual(GameId.STARRAIL);
      expect(games[2]).assertEqual(GameId.ZZZ);
    });

    it('按游戏过滤 slots / hasDataForGame', 0, () => {
      const vm = new WidgetSettingsViewModel();
      vm.dataStore = makeStore();

      expect(vm.getSlotsForGame(GameId.GENSHIN).length).assertEqual(1);
      expect(vm.getSlotsForGame(GameId.STARRAIL).length).assertEqual(1);
      expect(vm.getSlotsForGame(GameId.ZZZ).length).assertEqual(1);
      expect(vm.getSlotsForGame('missing').length).assertEqual(0);

      expect(vm.hasDataForGame(GameId.GENSHIN)).assertTrue();
      expect(vm.hasDataForGame('missing')).assertFalse();
    });

    it('1x2 的 getAllSlots 只显示当前游戏', 0, () => {
      const vm = new WidgetSettingsViewModel();
      vm.dataStore = makeStore();
      vm.selectSize(WidgetSize.SIZE_1X2);
      vm.selectedGameType = GameId.STARRAIL;

      const slots = vm.getAllSlots();
      expect(slots.length).assertEqual(1);
      expect(slots[0].gameId).assertEqual(GameId.STARRAIL);
    });

    it('2x2 的 getAllSlots 显示全部游戏', 0, () => {
      const vm = new WidgetSettingsViewModel();
      vm.dataStore = makeStore();
      expect(vm.getAllSlots().length).assertEqual(3);
    });

    it('1x2 不返回账号分组，2x2 返回分组并按游戏排序', 0, () => {
      const vm = new WidgetSettingsViewModel();
      vm.dataStore = makeStore();

      vm.selectSize(WidgetSize.SIZE_1X2);
      expect(vm.getAccountGroups().length).assertEqual(0);

      vm.selectSize(WidgetSize.SIZE_2X2);
      const groups = vm.getAccountGroups();
      expect(groups.length).assertEqual(1);
      expect(groups[0].accountId).assertEqual('a1');
      expect(groups[0].roles.length).assertEqual(3);
      expect(groups[0].roles[0].gameId).assertEqual(GameId.GENSHIN);
      expect(groups[0].roles[1].gameId).assertEqual(GameId.STARRAIL);
      expect(groups[0].roles[2].gameId).assertEqual(GameId.ZZZ);
    });

    it('clearSlots 与 reset 恢复初始状态', 0, () => {
      const vm = new WidgetSettingsViewModel();
      vm.selectSize(WidgetSize.SIZE_1X2);
      vm.selectGameType(GameId.ZZZ);
      vm.toggleSlot(makeSlot('a1', GameId.ZZZ, 'r1', '角色1'));
      vm.goNext();
      vm.goNext();

      vm.reset();
      expect(vm.currentStep).assertEqual(WidgetSettingsStep.SIZE);
      expect(vm.selectedSize).assertEqual(WidgetSize.SIZE_2X2);
      expect(vm.selectedGameType).assertEqual(GameId.GENSHIN);
      expect(vm.selectedSlots.length).assertEqual(0);
    });

    it('clearSlots 只清空选择，不改变步骤', 0, () => {
      const vm = new WidgetSettingsViewModel();
      vm.goNext();
      vm.toggleSlot(makeSlot('a1', GameId.GENSHIN, 'r1', '角色1'));
      vm.clearSlots();
      expect(vm.selectedSlots.length).assertEqual(0);
      expect(vm.currentStep).assertEqual(WidgetSettingsStep.SLOT);
    });

    it('DONE 步骤不能再前进，但可以后退', 0, () => {
      const vm = new WidgetSettingsViewModel();
      vm.currentStep = WidgetSettingsStep.DONE;
      expect(vm.canGoNext()).assertFalse();
      expect(vm.canGoPrev()).assertTrue();
      vm.goNext();
      expect(vm.currentStep).assertEqual(WidgetSettingsStep.DONE);
      vm.goPrev();
      expect(vm.currentStep).assertEqual(WidgetSettingsStep.SLOT);
    });

  });
}
