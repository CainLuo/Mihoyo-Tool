/**
 * ApiErrors.ets — 业务错误类型
 * 所有网络层抛出的业务错误均继承自 Error，便于 catch 后 instanceof 判断。
 */

/** Geetest 验证申请结果（createVerification 接口返回） */
export class GeetestCreateResult {
  gt: string = '';
  challenge: string = '';
  new_captcha: number = 0;
}

/** Geetest 验证提交参数（用户完成验证后传入） */
export class GeetestVerifyInput {
  geetest_challenge: string = '';
  geetest_validate: string = '';
  geetest_seccode: string = '';
}

/** Cookie 失效（retcode=-100） */
export class AuthExpiredError extends Error {
  constructor(message: string) {
    super(message);
  }
}

/** 需要 Geetest 验证（retcode=10035） */
export class GeetestRequiredError extends Error {
  geetestParams: GeetestCreateResult;

  constructor(message: string, geetestParams: GeetestCreateResult) {
    super(message);
    this.geetestParams = geetestParams;
  }
}

/** 签到需要 Geetest 验证（retcode=1034） */
export class GeetestSignRequiredError extends Error {
  geetestParams: GeetestCreateResult;

  constructor(message: string, geetestParams: GeetestCreateResult) {
    super(message);
    this.geetestParams = geetestParams;
  }
}

/** 角色战绩未公开（retcode=10102） */
export class RoleNotPublicError extends Error {
  constructor(message: string) {
    super(message);
  }
}
