/**
 * GeetestBridge — 注入到 Web 页面的 JS Bridge 对象
 *
 * HTML 内通过 window.geetestBridge.onSuccess(...) / window.geetestBridge.onCancel() 调用。
 *
 * 注意：registerJavaScriptProxy 要求方法列表在注册时显式声明，
 * 且方法参数只支持基础类型（string / number / boolean）。
 */
import { GeetestVerifyInput } from 'core';

export class GeetestBridge {
  /** resolve/reject 由外部在创建 Promise 时注入 */
  private resolveCallback: ((result: GeetestVerifyInput | null) => void) | null = null;

  setCallback(resolve: (result: GeetestVerifyInput | null) => void): void {
    this.resolveCallback = resolve;
  }

  /**
   * Geetest 验证成功回调（由 HTML 内 JS 调用）
   * @param challenge geetest_challenge
   * @param validate  geetest_validate
   * @param seccode   geetest_seccode
   */
  onSuccess(challenge: string, validate: string, seccode: string): void {
    if (this.resolveCallback) {
      const result: GeetestVerifyInput = {
        geetest_challenge: challenge,
        geetest_validate: validate,
        geetest_seccode: seccode,
      };
      this.resolveCallback(result);
      this.resolveCallback = null;
    }
  }

  /** 用户取消验证回调（由 HTML 内 JS 调用） */
  onCancel(): void {
    if (this.resolveCallback) {
      this.resolveCallback(null);
      this.resolveCallback = null;
    }
  }
}
