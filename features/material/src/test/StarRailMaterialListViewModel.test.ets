import { describe, it, expect } from '@ohos/hypium';
import { StarRailMaterialListViewModel } from '../main/ets/viewmodel/StarRailMaterialListViewModel';
import {
  CharacterMaterialVM,
  MaterialListViewMode,
} from '../main/ets/model/MaterialListModels';
import { MaterialTargetConfigParam } from '../main/ets/model/ToolsModels';
import { ViewState } from 'basic';
import { GameId } from 'core';

function makeCharacter(id: string): CharacterMaterialVM {
  const character = new CharacterMaterialVM();
  character.characterId = id;
  character.characterName = id;
  character.gameId = GameId.STARRAIL;
  character.isExpanded = false;
  return character;
}

function makeSelection(avatarIds: string[]): MaterialTargetConfigParam {
  const param = new MaterialTargetConfigParam();
  param.accountId = 'account';
  param.roleUid = 'role';
  param.gameId = GameId.STARRAIL;
  param.avatarIds = avatarIds;
  return param;
}

export default function starRailMaterialListViewModelTest() {
  describe('StarRailMaterialListViewModel', () => {

    it('初始状态为 LOADING / CHARACTER', 0, () => {
      const vm = new StarRailMaterialListViewModel();
      expect(vm.viewState).assertEqual(ViewState.LOADING);
      expect(vm.viewMode).assertEqual(MaterialListViewMode.CHARACTER);
      expect(vm.characterMaterials.length).assertEqual(0);
      expect(vm.materialSummaries.length).assertEqual(0);
      expect(vm.materialSections.length).assertEqual(0);
      expect(vm.isSyncing).assertFalse();
      expect(vm.syncErrorMsg).assertEqual('');
      expect(vm.getSelection() === null).assertTrue();
    });

    it('init(null) 进入 EMPTY', 0, async (done: Function) => {
      const vm = new StarRailMaterialListViewModel();
      await vm.init(null);
      expect(vm.viewState).assertEqual(ViewState.EMPTY);
      expect(vm.getSelection() === null).assertTrue();
      done();
    });

    it('init 空 avatarIds 进入 EMPTY 且保留 selection', 0, async (done: Function) => {
      const vm = new StarRailMaterialListViewModel();
      const selection = makeSelection([]);
      await vm.init(selection);
      expect(vm.viewState).assertEqual(ViewState.EMPTY);
      expect(vm.getSelection() === selection).assertTrue();
      done();
    });

    it('toggleViewMode 在 CHARACTER / MATERIAL 间切换', 0, () => {
      const vm = new StarRailMaterialListViewModel();
      vm.toggleViewMode();
      expect(vm.viewMode).assertEqual(MaterialListViewMode.MATERIAL);
      vm.toggleViewMode();
      expect(vm.viewMode).assertEqual(MaterialListViewMode.CHARACTER);
    });

    it('toggleCharacterExpand 只切换匹配角色', 0, () => {
      const vm = new StarRailMaterialListViewModel();
      const first = makeCharacter('1001');
      const second = makeCharacter('1002');
      vm.characterMaterials = [first, second];

      vm.toggleCharacterExpand('1001');
      expect(first.isExpanded).assertTrue();
      expect(second.isExpanded).assertFalse();

      vm.toggleCharacterExpand('1001');
      expect(first.isExpanded).assertFalse();
    });

    it('无 selection 时 syncComputeData 设置 no_selection', 0, async (done: Function) => {
      const vm = new StarRailMaterialListViewModel();
      await vm.init(null);
      await vm.syncComputeData();
      expect(vm.syncErrorMsg).assertEqual('no_selection');
      expect(vm.isSyncing).assertFalse();
      done();
    });

    it('isSyncing=true 时 syncComputeData 直接返回', 0, async (done: Function) => {
      const vm = new StarRailMaterialListViewModel();
      vm.isSyncing = true;
      await vm.syncComputeData();
      expect(vm.syncErrorMsg).assertEqual('');
      expect(vm.isSyncing).assertTrue();
      done();
    });

  });
}
