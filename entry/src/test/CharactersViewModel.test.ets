import { describe, it, expect } from '@ohos/hypium';
import { CharactersViewModel, AccountOption } from '../main/ets/viewmodel/CharactersViewModel';
import { ViewState } from '../main/ets/constants/ViewStates';

/**
 * CharactersViewModel 单元测试
 *
 * 只测试纯逻辑（初始状态、静态方法、KEYS 常量），
 * 不依赖设备、不调用 Repository 或 ApiService。
 */
export default function charactersViewModelTest() {
  describe('CharactersViewModel', () => {

    // ─── 初始状态 ────────────────────────────────────────────────

    it('初始 viewState 为 LOADING', 0, () => {
      const vm = new CharactersViewModel();
      expect(vm.viewState).assertEqual(ViewState.LOADING);
    });

    it('初始 selectedAccountIdx 为 0', 0, () => {
      const vm = new CharactersViewModel();
      expect(vm.selectedAccountIdx).assertEqual(0);
    });

    it('初始 selectedGameIdx 为 0', 0, () => {
      const vm = new CharactersViewModel();
      expect(vm.selectedGameIdx).assertEqual(0);
    });

    it('初始 characters 为空数组', 0, () => {
      const vm = new CharactersViewModel();
      expect(vm.characters.length).assertEqual(0);
    });

    it('初始 isRefreshing 为 false', 0, () => {
      const vm = new CharactersViewModel();
      expect(vm.isRefreshing).assertFalse();
    });

    it('初始 networkErrorMsg 为空字符串', 0, () => {
      const vm = new CharactersViewModel();
      expect(vm.networkErrorMsg).assertEqual('');
    });

    it('初始 accountOptions 为空数组', 0, () => {
      const vm = new CharactersViewModel();
      expect(vm.accountOptions.length).assertEqual(0);
    });

    it('初始 gameTabs 为空数组', 0, () => {
      const vm = new CharactersViewModel();
      expect(vm.gameTabs.length).assertEqual(0);
    });

    it('初始 refreshCoolingDown 为 false', 0, () => {
      const vm = new CharactersViewModel();
      expect(vm.refreshCoolingDown).assertFalse();
    });

    it('初始 showAccountSwitcher 为 false', 0, () => {
      const vm = new CharactersViewModel();
      expect(vm.showAccountSwitcher).assertFalse();
    });

    it('初始 showRefreshButton 为 false', 0, () => {
      const vm = new CharactersViewModel();
      expect(vm.showRefreshButton).assertFalse();
    });

    // ─── selectAccount 防重 ──────────────────────────────────────

    it('selectAccount 相同 idx 不改变 selectedAccountIdx', 0, async () => {
      const vm = new CharactersViewModel();
      vm.selectedAccountIdx = 0;
      // 相同 idx，不触发重载，selectedAccountIdx 保持不变
      await vm.selectAccount(0);
      expect(vm.selectedAccountIdx).assertEqual(0);
    });

    // ─── selectGame 防重 ─────────────────────────────────────────

    it('selectGame 相同 idx 不改变 selectedGameIdx', 0, async () => {
      const vm = new CharactersViewModel();
      vm.selectedGameIdx = 0;
      await vm.selectGame(0);
      expect(vm.selectedGameIdx).assertEqual(0);
    });

    // ─── refresh 防重 ────────────────────────────────────────────

    it('refresh 时 isRefreshing 已为 true 则跳过', 0, async () => {
      const vm = new CharactersViewModel();
      vm.isRefreshing = true;
      // 调用 refresh 不应改变 isRefreshing（防重保护）
      await vm.refresh();
      expect(vm.isRefreshing).assertTrue();
    });

    it('refresh 时 gameTabs 为空则跳过', 0, async () => {
      const vm = new CharactersViewModel();
      vm.isRefreshing = false;
      // gameTabs 为空，refresh 直接返回，isRefreshing 不变
      await vm.refresh();
      expect(vm.isRefreshing).assertFalse();
    });

    // ─── forceRefresh 防重 ───────────────────────────────────────

    it('forceRefresh 时 isRefreshing 已为 true 则跳过', 0, async () => {
      const vm = new CharactersViewModel();
      vm.isRefreshing = true;
      await vm.forceRefresh();
      expect(vm.isRefreshing).assertTrue();
    });

    it('forceRefresh 时 gameTabs 为空则跳过', 0, async () => {
      const vm = new CharactersViewModel();
      vm.isRefreshing = false;
      await vm.forceRefresh();
      expect(vm.isRefreshing).assertFalse();
    });

    // ─── toSelectOptions 静态方法 ────────────────────────────────

    it('toSelectOptions 空数组返回空数组', 0, () => {
      const result = CharactersViewModel.toSelectOptions([]);
      expect(result.length).assertEqual(0);
    });

    it('toSelectOptions 转换正确（使用 username）', 0, () => {
      const ao1 = new AccountOption(1, 'u1', '旅行者', '', 'uid001');
      const ao2 = new AccountOption(2, 'u2', '', '', '');
      const result = CharactersViewModel.toSelectOptions([ao1, ao2]);
      expect(result.length).assertEqual(2);
      expect(result[0].value).assertEqual('u1');
      expect(result[1].value).assertEqual('u2');
    });

    // ─── AccountOption 字段默认值 ────────────────────────────────

    it('AccountOption 构造函数仅传 accountId 和 username 时其余字段为空字符串', 0, () => {
      const opt = new AccountOption(1, 'user1');
      expect(opt.accountId).assertEqual(1);
      expect(opt.username).assertEqual('user1');
      expect(opt.nickname).assertEqual('');
      expect(opt.avatarUrl).assertEqual('');
      expect(opt.uid).assertEqual('');
    });

    it('AccountOption 构造函数传全部字段时正确赋值', 0, () => {
      const opt = new AccountOption(2, 'user2', '旅行者', 'https://example.com/avatar.png', 'uid123');
      expect(opt.nickname).assertEqual('旅行者');
      expect(opt.avatarUrl).assertEqual('https://example.com/avatar.png');
      expect(opt.uid).assertEqual('uid123');
    });

    // ─── selectAccount 越界保护 ──────────────────────────────────

    it('selectAccount 超出范围的 idx 不崩溃', 0, async () => {
      const vm = new CharactersViewModel();
      let threw = false;
      try {
        await vm.selectAccount(999);
      } catch (_) {
        threw = true;
      }
      expect(threw).assertFalse();
    });

    // ─── KEYS 路径常量 ───────────────────────────────────────────

    it('KEYS.networkErrorMsg 路径正确', 0, () => {
      expect(CharactersViewModel.KEYS.networkErrorMsg).assertEqual('vm.networkErrorMsg');
    });

    it('KEYS.refreshCoolingDown 路径正确', 0, () => {
      expect(CharactersViewModel.KEYS.refreshCoolingDown).assertEqual('vm.refreshCoolingDown');
    });

  });
}
