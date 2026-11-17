import { describe, it, expect } from '@ohos/hypium';
import { WidgetSettingsCallbacks, WidgetSettingsSlotHelper, WidgetSettingsStep, WidgetSettingsUIState } from '../main/ets/model/WidgetSettingsModels';
import { WidgetSize } from '../main/ets/model/WidgetConfigModels';
import { WidgetSlotRef } from '../main/ets/model/WidgetDataStoreModels';

export default function widgetSettingsModelsTest() {
  describe('WidgetSettingsModels', () => {

    it('UIState 默认值', 0, () => {
      const state = new WidgetSettingsUIState();
      expect(state.currentStep).assertEqual(WidgetSettingsStep.SIZE);
      expect(state.selectedSize).assertEqual(WidgetSize.SIZE_2X2);
      expect(state.selectedGameType).assertEqual('');
      expect(state.allSlots.length).assertEqual(0);
      expect(state.accountGroups.length).assertEqual(0);
      expect(state.selectedSlots.length).assertEqual(0);
      expect(state.maxSlots).assertEqual(4);
      expect(state.selectedSummary).assertEqual('');
      expect(state.canGoPrev).assertFalse();
      expect(state.canGoNext).assertTrue();
    });

    it('UIState 字段可写', 0, () => {
      const state = new WidgetSettingsUIState();
      state.currentStep = WidgetSettingsStep.SLOT;
      state.selectedSize = WidgetSize.SIZE_4X4;
      state.selectedGameType = 'genshin';
      state.maxSlots = 1;
      state.canGoPrev = true;
      state.canGoNext = false;
      expect(state.currentStep).assertEqual(WidgetSettingsStep.SLOT);
      expect(state.selectedSize).assertEqual(WidgetSize.SIZE_4X4);
      expect(state.selectedGameType).assertEqual('genshin');
      expect(state.maxSlots).assertEqual(1);
      expect(state.canGoPrev).assertTrue();
      expect(state.canGoNext).assertFalse();
    });

    it('默认回调可安全调用', 0, () => {
      const callbacks = new WidgetSettingsCallbacks();
      callbacks.onSizeSelect(WidgetSize.SIZE_1X2);
      callbacks.onGameSelect('genshin');
      callbacks.onSlotToggle(new WidgetSlotRef());
      callbacks.onPrev();
      callbacks.onNext();
      callbacks.onComplete();
      expect(true).assertTrue();
    });

    it('默认 SlotHelper 返回空结果', 0, () => {
      const helper = new WidgetSettingsSlotHelper();
      expect(helper.getSlotsForGame('genshin').length).assertEqual(0);
      expect(helper.hasDataForGame('genshin')).assertFalse();
      expect(helper.isSlotSelected('acc', 'genshin', 'role')).assertFalse();
    });

  });
}
