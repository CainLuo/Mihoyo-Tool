/**
 * ToolsViewModel.test.ets
 *
 * 测试 ToolsViewModel 的初始状态和基础逻辑。
 * 注意：ViewModel 依赖 CoreInitializer，单元测试只验证初始状态和纯函数。
 */

import { describe, it, expect } from '@ohos/hypium';
import { ToolsViewModel } from '../main/ets/viewmodel/ToolsViewModel';
import { ViewState } from '../main/ets/constants/ViewStates';
import { GameEntryVM } from '../main/ets/models/ToolsModels';
import { GameId } from 'core';

export default function toolsViewModelTest() {
  describe('ToolsViewModel', () => {

    // ── 初始状态验证 ─────────────────────────────────────────────

    it('initial_viewState_isLoading', 0, () => {
      const vm = new ToolsViewModel();
      expect(vm.viewState).assertEqual(ViewState.LOADING);
    });

    it('initial_accountCount_isZero', 0, () => {
      const vm = new ToolsViewModel();
      expect(vm.accountCount).assertEqual(0);
    });

    it('initial_gameEntries_isEmpty', 0, () => {
      const vm = new ToolsViewModel();
      expect(vm.gameEntries.length).assertEqual(0);
    });

    // ── GameEntryVM 初始值 ───────────────────────────────────────

    it('gameEntryVM_initialValues', 0, () => {
      const entry = new GameEntryVM();
      expect(entry.accountId).assertEqual('');
      expect(entry.gameId).assertEqual(GameId.GENSHIN);
      expect(entry.gameName).not.assertNull();
      expect(entry.characterCount).assertEqual(0);
      expect(entry.computedCount).assertEqual(0);
      expect(entry.hasData).assertEqual(false);
    });

  });
}
