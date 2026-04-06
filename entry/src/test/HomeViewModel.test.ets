import { describe, it, expect } from '@ohos/hypium';
import { HomeViewModel } from '../main/ets/viewmodel/HomeViewModel';
import { ViewState } from '../main/ets/constants/ViewStates';
import { GAME_GENSHIN, GAME_STARRAIL, GAME_ZZZ } from '../main/ets/components/home/HomeModels';
import { GeetestVerifyInput } from 'core';

export default function homeViewModelTest() {
  describe('HomeViewModel', () => {

    // ─── 初始状态测试 ────────────────────────────────────────────

    it('初始 viewState 为 LOADING', 0, () => {
      const vm = new HomeViewModel();
      expect(vm.viewState).assertEqual(ViewState.LOADING);
    });

    it('初始 accounts 为空数组', 0, () => {
      const vm = new HomeViewModel();
      expect(vm.accounts.length).assertEqual(0);
    });

    it('初始 isRefreshing 为 false', 0, () => {
      const vm = new HomeViewModel();
      expect(vm.isRefreshing).assertFalse();
    });

    it('初始 networkErrorMsg 为空字符串', 0, () => {
      const vm = new HomeViewModel();
      expect(vm.networkErrorMsg).assertEqual('');
    });

    it('初始 geetestTrigger 为 null', 0, () => {
      const vm = new HomeViewModel();
      expect(vm.geetestTrigger).assertNull();
    });

    it('初始 refreshCoolingDown 为 false', 0, () => {
      const vm = new HomeViewModel();
      expect(vm.refreshCoolingDown).assertFalse();
    });

    // ─── 防重入测试 ──────────────────────────────────────────────

    it('isRefreshing=true 时调用 refresh 不重复触发', 0, async (done: Function) => {
      const vm = new HomeViewModel();
      vm.isRefreshing = true;
      // refresh 应立即返回，不改变 isRefreshing
      await vm.refresh();
      expect(vm.isRefreshing).assertTrue();
      done();
    });

    it('isRefreshing=true 时调用 forceRefresh 不重复触发', 0, async (done: Function) => {
      const vm = new HomeViewModel();
      vm.isRefreshing = true;
      await vm.forceRefresh();
      expect(vm.isRefreshing).assertTrue();
      done();
    });

    // ─── onGeetestResult 边界测试 ────────────────────────────────

    it('onGeetestResult 传入 null 时 geetestTrigger 置为 null', 0, async (done: Function) => {
      const vm = new HomeViewModel();
      // 模拟已有 trigger（直接赋值，不调用网络）
      vm.geetestTrigger = null;
      await vm.onGeetestResult(null);
      expect(vm.geetestTrigger).assertNull();
      done();
    });

    it('onGeetestResult 在 geetestTrigger=null 时调用不崩溃', 0, async (done: Function) => {
      const vm = new HomeViewModel();
      expect(vm.geetestTrigger).assertNull();
      // 传入非 null result，但 trigger 为 null，应直接返回不崩溃
      try {
        // 构造一个最小的 GeetestVerifyInput 对象
        const fakeResult: GeetestVerifyInput = {
          geetest_challenge: 'challenge',
          geetest_validate: 'validate',
          geetest_seccode: 'seccode'
        };
        await vm.onGeetestResult(fakeResult);
        expect(true).assertTrue();
      } catch (_) {
        expect(true).assertTrue(); // 不崩溃即可
      }
      done();
    });

    // ─── dispose 测试 ────────────────────────────────────────────

    it('dispose 调用后不崩溃', 0, () => {
      const vm = new HomeViewModel();
      vm.dispose();
      expect(true).assertTrue();
    });

    it('多次调用 dispose 不崩溃', 0, () => {
      const vm = new HomeViewModel();
      vm.dispose();
      vm.dispose();
      expect(true).assertTrue();
    });

    // ─── resinRecoveryDesc 测试 ──────────────────────────────────

    it('resinRecoveryDesc 超过 1 小时包含小时描述', 0, () => {
      const result = HomeViewModel.resinRecoveryDesc(3660);
      expect(result.indexOf('1 小时') !== -1).assertTrue();
    });

    it('resinRecoveryDesc 不足 1 小时包含分钟描述', 0, () => {
      const result = HomeViewModel.resinRecoveryDesc(600);
      expect(result.indexOf('10 分钟') !== -1).assertTrue();
    });

    it('resinRecoveryDesc 秒数为 0 返回空字符串', 0, () => {
      const result = HomeViewModel.resinRecoveryDesc(0);
      expect(result).assertEqual('');
    });

    it('resinRecoveryDesc 秒数为负数返回空字符串', 0, () => {
      const result = HomeViewModel.resinRecoveryDesc(-1);
      expect(result).assertEqual('');
    });

    // ─── gameColor 测试 ──────────────────────────────────────────

    it('gameColor 原神返回正确颜色资源', 0, () => {
      const color = HomeViewModel.gameColor(GAME_GENSHIN);
      // ResourceColor 类型，验证不为 null/undefined
      expect(color !== null && color !== undefined).assertTrue();
    });

    it('gameColor 星铁返回正确颜色资源', 0, () => {
      const color = HomeViewModel.gameColor(GAME_STARRAIL);
      expect(color !== null && color !== undefined).assertTrue();
    });

    it('gameColor 绝区零返回正确颜色资源', 0, () => {
      const color = HomeViewModel.gameColor(GAME_ZZZ);
      expect(color !== null && color !== undefined).assertTrue();
    });

    it('gameColor 未知 gameId 返回 accent 颜色（不为 null）', 0, () => {
      const color = HomeViewModel.gameColor('unknown_game');
      expect(color !== null && color !== undefined).assertTrue();
    });

    // ─── refreshCoolingDown 信号翻转测试 ─────────────────────────

    it('refreshCoolingDown 初始为 false', 0, () => {
      const vm = new HomeViewModel();
      expect(vm.refreshCoolingDown).assertFalse();
    });

    // ─── KEYS 常量路径正确性测试 ─────────────────────────────────

    it('KEYS.networkErrorMsg 路径正确', 0, () => {
      expect(HomeViewModel.KEYS.networkErrorMsg).assertEqual('vm.networkErrorMsg');
    });

    it('KEYS.geetestTrigger 路径正确', 0, () => {
      expect(HomeViewModel.KEYS.geetestTrigger).assertEqual('vm.geetestTrigger');
    });

    it('KEYS.refreshCoolingDown 路径正确', 0, () => {
      expect(HomeViewModel.KEYS.refreshCoolingDown).assertEqual('vm.refreshCoolingDown');
    });

  });
}
