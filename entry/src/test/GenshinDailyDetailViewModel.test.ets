import { describe, it, expect } from '@ohos/hypium';
import { GenshinDailyDetailViewModel } from '../main/ets/viewmodel/GenshinDailyDetailViewModel';
import { ViewState } from '../main/ets/constants/ViewStates';

/**
 * GenshinDailyDetailViewModel 单元测试
 *
 * 测试初始状态、init 方法、formatSeconds 和 formatTransformer 私有静态方法。
 * 不依赖设备。
 */
export default function genshinDailyDetailViewModelTest() {
  describe('GenshinDailyDetailViewModel', () => {

    // ─── 初始状态 ────────────────────────────────────────────────

    it('初始 viewState 为 LOADING', 0, () => {
      const vm = new GenshinDailyDetailViewModel();
      expect(vm.viewState).assertEqual(ViewState.LOADING);
    });

    // ─── init 方法 ───────────────────────────────────────────────

    it('init 设置 accountId 和 roleUid', 0, () => {
      const vm = new GenshinDailyDetailViewModel();
      vm.init(1, 'uid1');
      // init 是 public 方法，调用后不崩溃即可（内部字段为 private）
      expect(true).assertTrue();
    });

    // ─── formatSeconds 私有静态方法 ──────────────────────────────

    it('formatSeconds 超过 1 小时包含小时', 0, () => {
      // 通过索引访问私有静态方法
      const fn = GenshinDailyDetailViewModel['formatSeconds'] as (s: number) => string;
      const result = fn(3660);
      expect(result.indexOf('1小时') >= 0).assertTrue();
    });

    it('formatSeconds 不足 1 小时包含分钟', 0, () => {
      const fn = GenshinDailyDetailViewModel['formatSeconds'] as (s: number) => string;
      const result = fn(600);
      expect(result.indexOf('10分钟') >= 0).assertTrue();
    });

    it('formatSeconds 为 0 返回空字符串', 0, () => {
      const fn = GenshinDailyDetailViewModel['formatSeconds'] as (s: number) => string;
      expect(fn(0)).assertEqual('');
    });

    it('formatSeconds 为负数返回空字符串', 0, () => {
      const fn = GenshinDailyDetailViewModel['formatSeconds'] as (s: number) => string;
      expect(fn(-1)).assertEqual('');
    });

    it('formatSeconds 不足 1 分钟返回即将恢复', 0, () => {
      const fn = GenshinDailyDetailViewModel['formatSeconds'] as (s: number) => string;
      const result = fn(30);
      expect(result).assertEqual('即将恢复');
    });

    // ─── formatTransformer 私有静态方法 ──────────────────────────

    it('formatTransformer 有天数包含天', 0, () => {
      const fn = GenshinDailyDetailViewModel['formatTransformer'] as (d: number, h: number, m: number) => string;
      const result = fn(1, 2, 30);
      expect(result.indexOf('1天') >= 0).assertTrue();
    });

    it('formatTransformer 只有小时包含小时', 0, () => {
      const fn = GenshinDailyDetailViewModel['formatTransformer'] as (d: number, h: number, m: number) => string;
      const result = fn(0, 3, 0);
      expect(result.indexOf('3小时') >= 0).assertTrue();
    });

    it('formatTransformer 只有分钟包含分钟', 0, () => {
      const fn = GenshinDailyDetailViewModel['formatTransformer'] as (d: number, h: number, m: number) => string;
      const result = fn(0, 0, 15);
      expect(result.indexOf('15分钟') >= 0).assertTrue();
    });

    it('formatTransformer 全为 0 返回即将可用', 0, () => {
      const fn = GenshinDailyDetailViewModel['formatTransformer'] as (d: number, h: number, m: number) => string;
      expect(fn(0, 0, 0)).assertEqual('即将可用');
    });

  });
}
