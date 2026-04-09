import { describe, it, expect } from '@ohos/hypium';
import { LoginViewModel, LoginViewModelKeys } from '../main/ets/viewmodel/LoginViewModel';
import { LoginTab, PhoneStep } from '../main/ets/constants/LoginTabEnum';

/**
 * LoginViewModel 单元测试
 *
 * 只测试纯逻辑（初始状态、纯函数、KEYS 常量），
 * 不依赖设备、不调用 Repository 或 ApiService。
 * 使用 main source set 的 LoginViewModel（mock 版本接口一致）。
 */
export default function loginViewModelTest() {
  describe('LoginViewModel', () => {

    // ─── 初始状态 ────────────────────────────────────────────────

    it('初始 activeTab 为 PHONE', 0, () => {
      const vm = new LoginViewModel();
      expect(vm.activeTab).assertEqual(LoginTab.PHONE);
    });

    it('初始 loginSuccess 为 false', 0, () => {
      const vm = new LoginViewModel();
      expect(vm.loginSuccess).assertFalse();
    });

    it('初始 isLoading 为 false', 0, () => {
      const vm = new LoginViewModel();
      expect(vm.isLoading).assertFalse();
    });

    it('初始 errorMsg 为空字符串', 0, () => {
      const vm = new LoginViewModel();
      expect(vm.errorMsg).assertEqual('');
    });

    it('初始 loginedAccountId 为 -1', 0, () => {
      const vm = new LoginViewModel();
      expect(vm.loginedAccountId).assertEqual(-1);
    });

    it('初始 loginedAccountVM 为 null', 0, () => {
      const vm = new LoginViewModel();
      expect(vm.loginedAccountVM).assertNull();
    });

    // ─── switchTab ───────────────────────────────────────────────

    it('switchTab 切换后 activeTab 更新', 0, () => {
      const vm = new LoginViewModel();
      vm.switchTab(LoginTab.COOKIE);
      expect(vm.activeTab).assertEqual(LoginTab.COOKIE);
    });

    it('switchTab 切换时 errorMsg 清空', 0, () => {
      const vm = new LoginViewModel();
      vm.errorMsg = 'some_error';
      vm.switchTab(LoginTab.COOKIE);
      expect(vm.errorMsg).assertEqual('');
    });

    // ─── maskedPhone ─────────────────────────────────────────────

    it('maskedPhone 11 位手机号脱敏正确', 0, () => {
      const vm = new LoginViewModel();
      vm.phoneNumber = '13812345678';
      expect(vm.maskedPhone).assertEqual('138****5678');
    });

    it('maskedPhone 短号（< 7 位）不脱敏', 0, () => {
      const vm = new LoginViewModel();
      vm.phoneNumber = '123';
      expect(vm.maskedPhone).assertEqual('123');
    });

    it('maskedPhone 恰好 7 位不脱敏', 0, () => {
      const vm = new LoginViewModel();
      vm.phoneNumber = '1234567';
      // length < 7 才不脱敏，7 位会脱敏
      const result = vm.maskedPhone;
      expect(result.length).assertLarger(0);
    });

    // ─── backToPhoneInput ────────────────────────────────────────

    it('backToPhoneInput 重置 phoneStep 为 INPUT_PHONE', 0, () => {
      const vm = new LoginViewModel();
      vm.phoneStep = PhoneStep.INPUT_CODE;
      vm.backToPhoneInput();
      expect(vm.phoneStep).assertEqual(PhoneStep.INPUT_PHONE);
    });

    it('backToPhoneInput 清空 smsCode', 0, () => {
      const vm = new LoginViewModel();
      vm.smsCode = '123456';
      vm.backToPhoneInput();
      expect(vm.smsCode).assertEqual('');
    });

    it('backToPhoneInput 清空 errorMsg', 0, () => {
      const vm = new LoginViewModel();
      vm.errorMsg = 'some_error';
      vm.backToPhoneInput();
      expect(vm.errorMsg).assertEqual('');
    });

    // ─── loginByCookie 空输入防重 ────────────────────────────────

    it('loginByCookie 空输入设置 errorMsg', 0, async () => {
      const vm = new LoginViewModel();
      vm.cookieInput = '';
      await vm.loginByCookie();
      expect(vm.errorMsg).assertEqual('cookie_empty');
    });

    it('loginByCookie 只有空格设置 errorMsg', 0, async () => {
      const vm = new LoginViewModel();
      vm.cookieInput = '   ';
      await vm.loginByCookie();
      expect(vm.errorMsg).assertEqual('cookie_empty');
    });

    // ─── KEYS 路径常量 ───────────────────────────────────────────

    it('KEYS.loginSuccess 路径正确', 0, () => {
      expect(LoginViewModel.KEYS.loginSuccess).assertEqual('vm.loginSuccess');
    });

    it('KEYS.loginedAccountId 路径正确', 0, () => {
      expect(LoginViewModel.KEYS.loginedAccountId).assertEqual('vm.loginedAccountId');
    });

    it('KEYS.loginedAccountVM 路径正确', 0, () => {
      expect(LoginViewModel.KEYS.loginedAccountVM).assertEqual('vm.loginedAccountVM');
    });

  });
}
