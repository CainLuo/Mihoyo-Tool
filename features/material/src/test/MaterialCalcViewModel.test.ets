/**
 * MaterialCalcViewModel.test.ets
 *
 * 测试 MaterialCalcViewModel 的初始状态。目标等级只读，由养成目标配置页写入 DB。
 */

import { describe, it, expect } from '@ohos/hypium';
import { MaterialCalcViewModel } from '../main/ets/viewmodel/MaterialCalcViewModel';
import { MaterialCalcCharacterVM } from '../main/ets/model/MaterialCalcModels';
import { ViewState } from 'basic';

export default function materialCalcViewModelTest() {
  describe('MaterialCalcViewModel', () => {

    // ── 初始状态验证 ─────────────────────────────────────────────

    it('initial_viewState_isLoading', 0, () => {
      const vm = new MaterialCalcViewModel();
      expect(vm.viewState).assertEqual(ViewState.LOADING);
    });

    it('initial_character_notNull', 0, () => {
      const vm = new MaterialCalcViewModel();
      expect(vm.character === null).assertFalse();
    });

    it('initial_skills_isEmpty', 0, () => {
      const vm = new MaterialCalcViewModel();
      expect(vm.skills.length).assertEqual(0);
    });

    it('initial_isRefreshing_isFalse', 0, () => {
      const vm = new MaterialCalcViewModel();
      expect(vm.isRefreshing).assertEqual(false);
    });

    it('initial_charCurrentLevel_is1', 0, () => {
      const vm = new MaterialCalcViewModel();
      expect(vm.charCurrentLevel).assertEqual(1);
    });

    it('initial_charTargetLevel_is90', 0, () => {
      const vm = new MaterialCalcViewModel();
      expect(vm.charTargetLevel).assertEqual(90);
    });

    it('initial_weaponCurrentLevel_is1', 0, () => {
      const vm = new MaterialCalcViewModel();
      expect(vm.weaponCurrentLevel).assertEqual(1);
    });

    it('initial_weaponTargetLevel_is90', 0, () => {
      const vm = new MaterialCalcViewModel();
      expect(vm.weaponTargetLevel).assertEqual(90);
    });

    it('initial_weapon_isNull', 0, () => {
      const vm = new MaterialCalcViewModel();
      expect(vm.weapon).assertNull();
    });

    // ── MaterialCalcCharacterVM 初始值 ─────────────────────────────

    it('characterVM_initialValues', 0, () => {
      const char = new MaterialCalcCharacterVM();
      expect(char.characterId).assertEqual('');
      expect(char.name).assertEqual('');
      expect(char.iconUrl).assertEqual('');
      expect(char.currentLevel).assertEqual(1);
      expect(char.targetLevel).assertEqual(90);
    });

  });
}
