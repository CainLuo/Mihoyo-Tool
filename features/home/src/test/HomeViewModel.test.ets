import { describe, it, expect } from '@ohos/hypium';
import { HomeViewModel, buildDailyDetailRoute } from '../main/ets/viewmodel/HomeViewModel';
import { ViewState, getGameColorByStr, AppRoutes } from 'basic';
import { GameId } from 'core';

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

    it('初始 refreshCoolingDown 为 false', 0, () => {
      const vm = new HomeViewModel();
      expect(vm.isRefreshCoolingDown).assertFalse();
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

    // ─── getGameColor 测试 ──────────────────────────────────────────

    it('getGameColor 原神返回正确颜色资源', 0, () => {
      const color = HomeViewModel.getGameColor(GameId.GENSHIN);
      // ResourceColor 类型，验证不为 null/undefined
      expect(color !== null && color !== undefined).assertTrue();
    });

    it('getGameColor 星铁返回正确颜色资源', 0, () => {
      const color = HomeViewModel.getGameColor(GameId.STARRAIL);
      expect(color !== null && color !== undefined).assertTrue();
    });

    it('getGameColor 绝区零返回正确颜色资源', 0, () => {
      const color = HomeViewModel.getGameColor(GameId.ZZZ);
      expect(color !== null && color !== undefined).assertTrue();
    });

    it('getGameColorByStr 未知 gameId 返回兜底颜色（不为 null）', 0, () => {
      // GameId 是枚举，类型上传不进未知值；兜底分支用字符串版本验证
      const color = getGameColorByStr('unknown_game');
      expect(color !== null && color !== undefined).assertTrue();
    });

    // ─── isRefreshCoolingDown 信号翻转测试 ─────────────────────────

    it('refreshCoolingDown 初始为 false', 0, () => {
      const vm = new HomeViewModel();
      expect(vm.isRefreshCoolingDown).assertFalse();
    });

    // ─── buildDailyDetailRoute（首页与桌面卡片共用）──────────────────

    it('buildDailyDetailRoute 原神返回原神便笺详情路由', 0, () => {
      const route = buildDailyDetailRoute(GameId.GENSHIN, 'acc1', 'uid1');
      expect(route !== null).assertTrue();
      expect(route?.routeName).assertEqual(AppRoutes.GENSHIN_DAILY_DETAIL);
      expect(route?.param.accountId).assertEqual('acc1');
      expect(route?.param.roleUid).assertEqual('uid1');
    });

    it('buildDailyDetailRoute 星铁返回星铁便笺详情路由', 0, () => {
      const route = buildDailyDetailRoute(GameId.STARRAIL, 'acc2', 'uid2');
      expect(route?.routeName).assertEqual(AppRoutes.STARRAIL_DAILY_DETAIL);
      expect(route?.param.accountId).assertEqual('acc2');
    });

    it('buildDailyDetailRoute 绝区零返回绝区零便笺详情路由', 0, () => {
      const route = buildDailyDetailRoute(GameId.ZZZ, 'acc3', 'uid3');
      expect(route?.routeName).assertEqual(AppRoutes.ZZZ_DAILY_DETAIL);
      expect(route?.param.roleUid).assertEqual('uid3');
    });

    it('buildDailyDetailRoute 未知游戏返回 null', 0, () => {
      expect(buildDailyDetailRoute('unknown', 'acc', 'uid') === null).assertTrue();
    });




  });
}
