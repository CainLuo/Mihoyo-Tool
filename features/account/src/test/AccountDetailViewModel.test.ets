import { describe, it, expect } from '@ohos/hypium';
import { AccountDetailViewModel } from '../main/ets/viewmodel/AccountDetailViewModel';

/**
 * AccountDetailViewModel 单元测试
 *
 * 只测试初始状态，不依赖设备。
 */
export default function accountDetailViewModelTest() {
  describe('AccountDetailViewModel', () => {

    it('初始 deleted 为 false', 0, () => {
      const vm = new AccountDetailViewModel();
      expect(vm.isDeleted).assertFalse();
    });

    it('初始 errorMsg 为空字符串', 0, () => {
      const vm = new AccountDetailViewModel();
      expect(vm.errorMsg).assertEqual('');
    });



  });
}
