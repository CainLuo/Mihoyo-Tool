/**
 * PrivacyConsentModels.ets — 隐私合规流程模型
 *
 * 步骤值对外仍是 string，与既有测试断言和路由参数契约保持一致。
 */

/** 隐私合规步骤常量 */
export class PrivacyConsentStep {
  static readonly TERMS: string = 'terms';
  static readonly PRIVACY: string = 'privacy';
}
