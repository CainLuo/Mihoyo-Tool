import { describe, it, expect } from '@ohos/hypium';
import { PrivacyConsentViewModel } from '../main/ets/viewmodel/PrivacyConsentViewModel';

export default function privacyConsentViewModelTest() {
  describe('PrivacyConsentViewModel', () => {

    it('初始 step 为 terms', 0, () => {
      const vm = new PrivacyConsentViewModel();
      expect(vm.step).assertEqual('terms');
    });

    it('初始 termsScrolledToBottom 为 false', 0, () => {
      const vm = new PrivacyConsentViewModel();
      expect(vm.isTermsScrolledToBottom).assertFalse();
    });

    it('初始 privacyScrolledToBottom 为 false', 0, () => {
      const vm = new PrivacyConsentViewModel();
      expect(vm.isPrivacyScrolledToBottom).assertFalse();
    });

    it('初始 canProceedFromTerms 为 false', 0, () => {
      const vm = new PrivacyConsentViewModel();
      expect(vm.canProceedFromTerms).assertFalse();
    });

    it('初始 canAgree 为 false', 0, () => {
      const vm = new PrivacyConsentViewModel();
      expect(vm.canAgree).assertFalse();
    });

    it('markTermsRead 后 canProceedFromTerms 为 true', 0, () => {
      const vm = new PrivacyConsentViewModel();
      vm.markTermsRead();
      expect(vm.canProceedFromTerms).assertTrue();
    });

    it('markPrivacyRead 后 canAgree 为 true', 0, () => {
      const vm = new PrivacyConsentViewModel();
      vm.markPrivacyRead();
      expect(vm.canAgree).assertTrue();
    });

    it('goToPrivacy 切换 step 为 privacy', 0, () => {
      const vm = new PrivacyConsentViewModel();
      vm.goToPrivacy();
      expect(vm.step).assertEqual('privacy');
    });

    it('markTermsRead 不影响 privacyScrolledToBottom', 0, () => {
      const vm = new PrivacyConsentViewModel();
      vm.markTermsRead();
      expect(vm.isPrivacyScrolledToBottom).assertFalse();
    });

    it('markPrivacyRead 不影响 termsScrolledToBottom', 0, () => {
      const vm = new PrivacyConsentViewModel();
      vm.markPrivacyRead();
      expect(vm.isTermsScrolledToBottom).assertFalse();
    });

  });
}
