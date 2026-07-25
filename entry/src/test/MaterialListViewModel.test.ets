/**
 * MaterialListViewModel.test.ets
 *
 * 测试 MaterialListViewModel 的初始状态和视图切换逻辑。
 */

import { describe, it, expect } from '@ohos/hypium';
import { MaterialListViewModel } from '../main/ets/viewmodel/MaterialListViewModel';
import { ViewState } from '../main/ets/constants/ViewStates';
import { MaterialListViewMode } from '../main/ets/models/MaterialListModels';

export default function materialListViewModelTest() {
  describe('MaterialListViewModel', () => {

    // ── 初始状态验证 ─────────────────────────────────────────────

    it('initial_viewState_isLoading', 0, () => {
      const vm = new MaterialListViewModel();
      expect(vm.viewState).assertEqual(ViewState.LOADING);
    });

    it('initial_viewMode_isCharacter', 0, () => {
      const vm = new MaterialListViewModel();
      expect(vm.viewMode).assertEqual(MaterialListViewMode.CHARACTER);
    });

    it('initial_characterMaterials_isEmpty', 0, () => {
      const vm = new MaterialListViewModel();
      expect(vm.characterMaterials.length).assertEqual(0);
    });

    it('initial_materialSummaries_isEmpty', 0, () => {
      const vm = new MaterialListViewModel();
      expect(vm.materialSummaries.length).assertEqual(0);
    });

    it('initial_isRefreshing_isFalse', 0, () => {
      const vm = new MaterialListViewModel();
      expect(vm.isRefreshing).assertEqual(false);
    });

    // ── 视图切换逻辑 ─────────────────────────────────────────────

    it('toggleViewMode_characterToMaterial', 0, () => {
      const vm = new MaterialListViewModel();
      expect(vm.viewMode).assertEqual(MaterialListViewMode.CHARACTER);
      
      vm.toggleViewMode();
      expect(vm.viewMode).assertEqual(MaterialListViewMode.MATERIAL);
    });

    it('toggleViewMode_materialToCharacter', 0, () => {
      const vm = new MaterialListViewModel();
      vm.toggleViewMode(); // 先切换到 MATERIAL
      
      vm.toggleViewMode();
      expect(vm.viewMode).assertEqual(MaterialListViewMode.CHARACTER);
    });

    it('toggleViewMode_multipleTimes', 0, () => {
      const vm = new MaterialListViewModel();
      
      vm.toggleViewMode();
      expect(vm.viewMode).assertEqual(MaterialListViewMode.MATERIAL);
      
      vm.toggleViewMode();
      expect(vm.viewMode).assertEqual(MaterialListViewMode.CHARACTER);
      
      vm.toggleViewMode();
      expect(vm.viewMode).assertEqual(MaterialListViewMode.MATERIAL);
    });

  });
}
