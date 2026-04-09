import { describe, it, expect } from '@ohos/hypium';
import { MyViewModel } from '../main/ets/viewmodel/MyViewModel';
import { ViewState } from '../main/ets/constants/ViewStates';

/**
 * MyViewModel 单元测试
 *
 * 只测试初始状态和 KEYS 常量，不依赖设备。
 */
export default function myViewModelTest() {
  describe('MyViewModel', () => {

    it('初始 viewState 为 LOADING', 0, () => {
      const vm = new MyViewModel();
      expect(vm.viewState).assertEqual(ViewState.LOADING);
    });

    it('初始 accounts 为空数组', 0, () => {
      const vm = new MyViewModel();
      expect(vm.accounts.length).assertEqual(0);
    });

    it('KEYS.viewState 路径正确', 0, () => {
      expect(MyViewModel.KEYS.viewState).assertEqual('vm.viewState');
    });

    it('KEYS.accounts 路径正确', 0, () => {
      expect(MyViewModel.KEYS.accounts).assertEqual('vm.accounts');
    });

  });
}
