/**
 * MaterialCalcViewModel.test.ets
 *
 * 测试 MaterialCalcViewModel 的初始状态和等级目标修改逻辑。
 */

import { describe, it, expect } from '@ohos/hypium';
import { MaterialCalcViewModel } from '../main/ets/viewmodel/MaterialCalcViewModel';
import { ViewState } from '../main/ets/constants/ViewStates';
import { MaterialCalcCharacterVM } from '../main/ets/models/MaterialCalcModels';

export default function materialCalcViewModelTest() {
  describe('MaterialCalcViewModel', () => {

    // ── 初始状态验证 ─────────────────────────────────────────────

    it('initial_viewState_isLoading', 0, () => {
      const vm = new MaterialCalcViewModel();
      expect(vm.viewState).assertEqual(ViewState.LOADING);
    });

    it('initial_character_notNull', 0, () => {
      const vm = new MaterialCalcViewModel();
      expect(vm.character).not.assertNull();
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

    // ── 等级目标修改逻辑 ─────────────────────────────────────────

    it('setCharTargetLevel_updatesValue', 0, () => {
      const vm = new MaterialCalcViewModel();
      vm.setCharTargetLevel(80);
      expect(vm.charTargetLevel).assertEqual(80);
    });

    it('setCharTargetLevel_multipleTimes', 0, () => {
      const vm = new MaterialCalcViewModel();
      vm.setCharTargetLevel(60);
      expect(vm.charTargetLevel).assertEqual(60);
      
      vm.setCharTargetLevel(70);
      expect(vm.charTargetLevel).assertEqual(70);
      
      vm.setCharTargetLevel(90);
      expect(vm.charTargetLevel).assertEqual(90);
    });

    it('setWeaponTargetLevel_updatesValue', 0, () => {
      const vm = new MaterialCalcViewModel();
      vm.setWeaponTargetLevel(80);
      expect(vm.weaponTargetLevel).assertEqual(80);
    });

    // ── MaterialCalcCharacterVM 初始值 ─────────────────────────────

    it('characterVM_initialValues', 0, () => {
      const char = new MaterialCalcCharacterVM();
      expect(char.characterId).assertEqual('');
      expect(char.characterName).assertEqual('');
      expect(char.characterIconUrl).assertEqual('');
      expect(char.currentLevel).assertEqual(1);
      expect(char.targetLevel).assertEqual(90);
    });

  });
}
