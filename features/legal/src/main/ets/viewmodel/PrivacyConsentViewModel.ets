/**
 * PrivacyConsentViewModel — 隐私合规流程状态管理
 *
 * 管理两步阅读流程：
 *   PrivacyConsentStep.TERMS   → 用户协议阅读步骤
 *   PrivacyConsentStep.PRIVACY → 隐私政策阅读步骤
 *
 * 滚动到底部状态一旦变为 true 不可逆（不会因向上滚动而重置）。
 */

import { PrivacyConsentStep } from '../model/PrivacyConsentModels';

export { PrivacyConsentStep } from '../model/PrivacyConsentModels';

@ObservedV2
export class PrivacyConsentViewModel {
  /** 当前步骤：PrivacyConsentStep.TERMS 或 PrivacyConsentStep.PRIVACY */
  @Trace step: string = PrivacyConsentStep.TERMS;

  /** 用户协议是否已滑到底部 */
  @Trace isTermsScrolledToBottom: boolean = false;

  /** 隐私政策是否已滑到底部 */
  @Trace isPrivacyScrolledToBottom: boolean = false;

  /** 步骤一「下一步」按钮是否可点击 */
  get canProceedFromTerms(): boolean {
    return this.isTermsScrolledToBottom;
  }

  /** 步骤二两个按钮是否可点击 */
  get canAgree(): boolean {
    return this.isPrivacyScrolledToBottom;
  }

  /** 切换到步骤二（隐私政策） */
  goToPrivacy(): void {
    this.step = PrivacyConsentStep.PRIVACY;
  }

  /** 标记用户协议已滑到底部（不可逆） */
  markTermsRead(): void {
    this.isTermsScrolledToBottom = true;
  }

  /** 标记隐私政策已滑到底部（不可逆） */
  markPrivacyRead(): void {
    this.isPrivacyScrolledToBottom = true;
  }
}
