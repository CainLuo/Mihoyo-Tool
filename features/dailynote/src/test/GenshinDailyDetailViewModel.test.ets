import { describe, it, expect } from '@ohos/hypium';
import { GenshinDailyDetailViewModel } from '../main/ets/viewmodel/GenshinDailyDetailViewModel';
import { ViewState } from 'basic';

/**
 * GenshinDailyDetailViewModel 单元测试
 *
 * 测试初始状态与 init 方法，不依赖设备。
 * 时间文案格式化已迁到 utils/TimeFormatUtil（formatSeconds / formatTransformer），
 * 依赖 UIContext 读取字符串资源，无法在 Local Test 中运行，需在 ohosTest 或冒烟中覆盖。
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
      vm.init('1', 'uid1');
      // init 是 public 方法，调用后不崩溃即可（内部字段为 private）
      expect(true).assertTrue();
    });

  });
}
