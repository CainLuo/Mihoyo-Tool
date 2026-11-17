import { describe, it, expect } from '@ohos/hypium';
import {
  MaterialCharacterSelectViewModel,
  SelectableCharacterVM,
} from '../main/ets/viewmodel/MaterialCharacterSelectViewModel';
import { ViewState } from 'basic';
import { GameId } from 'core';

function makeCharacter(id: string): SelectableCharacterVM {
  const character = new SelectableCharacterVM();
  character.avatarId = id;
  character.name = id;
  return character;
}

function makeCharacters(count: number): SelectableCharacterVM[] {
  const result: SelectableCharacterVM[] = [];
  for (let i = 0; i < count; i++) {
    result.push(makeCharacter(`char${i + 1}`));
  }
  return result;
}

export default function materialCharacterSelectViewModelTest() {
  describe('MaterialCharacterSelectViewModel', () => {

    it('初始状态', 0, () => {
      const vm = new MaterialCharacterSelectViewModel();
      expect(vm.gameId).assertEqual(GameId.GENSHIN);
      expect(vm.viewState).assertEqual(ViewState.LOADING);
      expect(vm.characters.length).assertEqual(0);
      expect(vm.accountOptions.length).assertEqual(0);
      expect(vm.shouldShowAccountSwitcher).assertFalse();
      expect(vm.selectedAccountIdx).assertEqual(0);
      expect(vm.selectedCount).assertEqual(0);
      expect(vm.canStart).assertFalse();
      expect(vm.isSyncing).assertFalse();
      expect(vm.historyAvatarIds.length).assertEqual(0);
    });

    it('toggleSelect 选中后更新数量与 canStart', 0, () => {
      const vm = new MaterialCharacterSelectViewModel();
      vm.characters = makeCharacters(2);

      vm.toggleSelect('char1');
      expect(vm.characters[0].isSelected).assertTrue();
      expect(vm.selectedCount).assertEqual(1);
      expect(vm.canStart).assertTrue();
    });

    it('最多只能选 4 个角色', 0, () => {
      const vm = new MaterialCharacterSelectViewModel();
      vm.characters = makeCharacters(5);

      vm.toggleSelect('char1');
      vm.toggleSelect('char2');
      vm.toggleSelect('char3');
      vm.toggleSelect('char4');
      vm.toggleSelect('char5');

      expect(vm.selectedCount).assertEqual(4);
      expect(vm.characters[4].isSelected).assertFalse();
      expect(vm.getSelectedAvatarIds().length).assertEqual(4);
    });

    it('取消选中后更新数量', 0, () => {
      const vm = new MaterialCharacterSelectViewModel();
      vm.characters = makeCharacters(3);

      vm.toggleSelect('char1');
      vm.toggleSelect('char2');
      vm.toggleSelect('char1');
      expect(vm.selectedCount).assertEqual(1);
      expect(vm.characters[0].isSelected).assertFalse();
      expect(vm.canStart).assertTrue();
    });

    it('全部取消后 canStart 为 false', 0, () => {
      const vm = new MaterialCharacterSelectViewModel();
      vm.characters = makeCharacters(2);

      vm.toggleSelect('char1');
      vm.toggleSelect('char1');
      expect(vm.selectedCount).assertEqual(0);
      expect(vm.canStart).assertFalse();
    });

    it('未知角色 toggleSelect 不改变状态', 0, () => {
      const vm = new MaterialCharacterSelectViewModel();
      vm.characters = makeCharacters(2);
      vm.toggleSelect('unknown');
      expect(vm.selectedCount).assertEqual(0);
      expect(vm.canStart).assertFalse();
    });

    it('getSelectedAvatarIds 按列表顺序返回', 0, () => {
      const vm = new MaterialCharacterSelectViewModel();
      vm.characters = makeCharacters(3);

      vm.toggleSelect('char3');
      vm.toggleSelect('char1');
      const ids = vm.getSelectedAvatarIds();
      expect(ids.length).assertEqual(2);
      expect(ids[0]).assertEqual('char1');
      expect(ids[1]).assertEqual('char3');
    });

    it('buildSelectionParam 填入账号、角色、游戏与选中角色', 0, () => {
      const vm = new MaterialCharacterSelectViewModel();
      vm.accountId = 'account';
      vm.roleUid = 'role';
      vm.gameId = GameId.STARRAIL;
      vm.characters = makeCharacters(2);
      vm.toggleSelect('char2');

      const param = vm.buildSelectionParam();
      expect(param.accountId).assertEqual('account');
      expect(param.roleUid).assertEqual('role');
      expect(param.gameId).assertEqual(GameId.STARRAIL);
      expect(param.avatarIds.length).assertEqual(1);
      expect(param.avatarIds[0]).assertEqual('char2');
    });

    it('buildHistoryParam 复制历史记录而不是引用', 0, () => {
      const vm = new MaterialCharacterSelectViewModel();
      vm.accountId = 'account';
      vm.roleUid = 'role';
      vm.gameId = GameId.ZZZ;
      vm.historyAvatarIds = ['a', 'b'];

      const param = vm.buildHistoryParam();
      vm.historyAvatarIds.push('c');
      expect(param.avatarIds.length).assertEqual(2);
      expect(param.avatarIds[0]).assertEqual('a');
      expect(param.avatarIds[1]).assertEqual('b');
      expect(vm.historyAvatarIds.length).assertEqual(3);
    });

    it('loadHistory 在账号或角色为空时清空历史且不访问 DB', 0, async (done: Function) => {
      const vm = new MaterialCharacterSelectViewModel();
      vm.historyAvatarIds = ['a'];
      await vm.loadHistory();
      expect(vm.historyAvatarIds.length).assertEqual(0);
      done();
    });

    it('selectAccount 越界或相同下标直接返回', 0, async (done: Function) => {
      const vm = new MaterialCharacterSelectViewModel();
      vm.selectedAccountIdx = 0;
      await vm.selectAccount(999);
      expect(vm.selectedAccountIdx).assertEqual(0);
      await vm.selectAccount(-1);
      expect(vm.selectedAccountIdx).assertEqual(0);
      await vm.selectAccount(0);
      expect(vm.selectedAccountIdx).assertEqual(0);
      done();
    });

    it('isSyncing=true 时 startCompute 返回 BUSY', 0, async (done: Function) => {
      const vm = new MaterialCharacterSelectViewModel();
      vm.isSyncing = true;
      const result = await vm.startCompute(vm.buildSelectionParam());
      expect(result).assertEqual('BUSY');
      expect(vm.isSyncing).assertTrue();
      done();
    });

  });
}
