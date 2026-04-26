/**
 * PrivacyConsentViewModel — 隐私合规流程状态管理
 *
 * 管理两步阅读流程：
 *   step 'terms'   → 用户协议阅读步骤
 *   step 'privacy' → 隐私政策阅读步骤
 *
 * 滚动到底部状态一旦变为 true 不可逆（不会因向上滚动而重置）。
 */

export class PrivacyConsentViewModelKeys {
  step: string = 'vm.step';
  termsScrolledToBottom: string = 'vm.termsScrolledToBottom';
  privacyScrolledToBottom: string = 'vm.privacyScrolledToBottom';
}

@ObservedV2
export class PrivacyConsentViewModel {
  static readonly KEYS: PrivacyConsentViewModelKeys = new PrivacyConsentViewModelKeys();

  /** 当前步骤：'terms' 或 'privacy' */
  @Trace step: string = 'terms';

  /** 用户协议是否已滑到底部 */
  @Trace termsScrolledToBottom: boolean = false;

  /** 隐私政策是否已滑到底部 */
  @Trace privacyScrolledToBottom: boolean = false;

  /** 步骤一「下一步」按钮是否可点击 */
  get canProceedFromTerms(): boolean {
    return this.termsScrolledToBottom;
  }

  /** 步骤二两个按钮是否可点击 */
  get canAgree(): boolean {
    return this.privacyScrolledToBottom;
  }

  /** 切换到步骤二（隐私政策） */
  goToPrivacy(): void {
    this.step = 'privacy';
  }

  /** 标记用户协议已滑到底部（不可逆） */
  markTermsRead(): void {
    this.termsScrolledToBottom = true;
  }

  /** 标记隐私政策已滑到底部（不可逆） */
  markPrivacyRead(): void {
    this.privacyScrolledToBottom = true;
  }
}
