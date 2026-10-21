/**
 * ApiErrors.ets — 业务错误类型
 * 
 * 设计说明：
 * - ArkTS 严格模式只允许抛出 Error 类型
 * - SyncError 是 Error 的子类，通过 kind 字段区分错误类型
 * - 所有错误通过 SyncErrorFactory 创建
 * - 使用 kind 字段匹配错误类型，替代 instanceof 判断
 */

import { ApiErrorCodes } from '../../common/constants/ApiErrorCodes';

// ═══════════════════════════════════════════════════════════════
// 错误类型常量（kind 字段值）
// ═══════════════════════════════════════════════════════════════

/** 错误类型枚举 */
export enum SyncErrorKind {
  /** 普通业务错误 */
  NORMAL = 'normal',
  /** Geetest 人机验证错误 */
  GEETEST = 'geetest',
  /** 用户取消 Geetest 验证 */
  GEETEST_CANCELLED = 'geetestCancelled',
  /** Cookie 失效错误 */
  AUTH_EXPIRED = 'authExpired'
}

// ═══════════════════════════════════════════════════════════════
// SyncError — 统一错误类
// ═══════════════════════════════════════════════════════════════

/**
 * SyncError — 同步错误统一类
 * 
 * 使用 kind 字段区分错误类型，替代 instanceof 判断：
 * 
 * ```typescript
 * try {
 *   await repo.sync();
 * } catch (e) {
 *   const error = e as SyncError;
 *   switch (error.kind) {
 *     case SyncErrorKind.AUTH_EXPIRED:
 *       // Cookie 失效
 *       break;
 *     case SyncErrorKind.GEETEST:
 *       // Geetest 验证
 *       break;
 *     case SyncErrorKind.NORMAL:
 *       // 普通错误
 *       break;
 *   }
 * }
 * ```
 */
export class SyncError extends Error {
  /** 错误类型 */
  readonly kind: SyncErrorKind;

  /** 错误码（仅 NormalError 有效） */
  readonly code: number;

  // Geetest 专用字段
  readonly gt: string;
  readonly challenge: string;
  readonly newCaptcha: number;
  readonly riskType: string;

  private constructor(
    kind: SyncErrorKind,
    message: string,
    code: number = 0,
    gt: string = '',
    challenge: string = '',
    newCaptcha: number = 0,
    riskType: string = ''
  ) {
    super(message);
    this.kind = kind;
    this.code = code;
    this.gt = gt;
    this.challenge = challenge;
    this.newCaptcha = newCaptcha;
    this.riskType = riskType;
  }

  /**
   * 创建普通业务错误
   */
  static normal(code: number, message: string): SyncError {
    return new SyncError(SyncErrorKind.NORMAL, message, code);
  }

  /**
   * 创建 Geetest 验证错误
   */
  static geetest(gt: string, challenge: string, newCaptcha: number, riskType: string): SyncError {
    const message = 'Geetest verification required';
    return new SyncError(SyncErrorKind.GEETEST, message, 0, gt, challenge, newCaptcha, riskType);
  }

  /**
   * 创建 Geetest 取消错误（用户主动取消验证）
   */
  static geetestCancelled(): SyncError {
    const message = 'User cancelled Geetest verification';
    return new SyncError(SyncErrorKind.GEETEST_CANCELLED, message);
  }

  /**
   * 创建 Cookie 失效错误
   */
  static authExpired(message: string): SyncError {
    return new SyncError(SyncErrorKind.AUTH_EXPIRED, message);
  }
}

// ═══════════════════════════════════════════════════════════════
// SyncErrorFactory — 错误工厂类（便捷方法）
// ═══════════════════════════════════════════════════════════════

/**
 * SyncErrorFactory — 创建 SyncError 实例的工厂类
 * 
 * 所有 Repository 和 ViewModel 层的错误创建都应该通过此类进行。
 */
export class SyncErrorFactory {
  /**
   * 创建普通业务错误
   */
  static normal(code: number, message: string): SyncError {
    return SyncError.normal(code, message);
  }

  /**
   * 创建 Geetest 验证错误
   */
  static geetest(gt: string, challenge: string, newCaptcha: number, riskType: string): SyncError {
    return SyncError.geetest(gt, challenge, newCaptcha, riskType);
  }

  /**
   * 创建 Geetest 取消错误
   */
  static geetestCancelled(): SyncError {
    return SyncError.geetestCancelled();
  }

  /**
   * 创建 Cookie 失效错误
   */
  static authExpired(message: string): SyncError {
    return SyncError.authExpired(message);
  }

  /**
   * 从 API 响应解析错误类型
   * 
   * @param resp API 响应对象（包含 retcode 和 message 字段）
   * @returns SyncError 或 null（retcode=0 时返回 null）
   */
  static fromResponse(resp: Record<string, Object>): SyncError | null {
    const retcode = resp['retcode'] as number;
    const message = (resp['message'] as string) ?? 'Unknown error';

    // 成功
    if (retcode === ApiErrorCodes.SUCCESS) {
      return null;
    }

    // Cookie 失效（-100, 10001）；-10001 是请求无效，不属于登录失效
    if (retcode === ApiErrorCodes.AUTH_INVALID ||
        retcode === ApiErrorCodes.AUTH_INVALID_ALT1) {
      return SyncErrorFactory.authExpired(message);
    }

    // Geetest 验证（1034, 10035）
    if (retcode === ApiErrorCodes.GEETEST_REQUIRED_GENERAL ||
        retcode === ApiErrorCodes.GEETEST_REQUIRED) {
      const data = resp['data'] as Record<string, Object> | undefined;
      if (data !== undefined && data !== null) {
        return SyncErrorFactory.geetest(
          (data['gt'] as string) ?? '',
          (data['challenge'] as string) ?? '',
          (data['new_captcha'] as number) ?? 0,
          (data['risk_type'] as string) ?? ''
        );
      }
      // 无 data 字段时返回默认 Geetest 错误
      return SyncErrorFactory.geetest('', '', 0, '');
    }

    // 其他错误
    return SyncErrorFactory.normal(retcode, message);
  }

  /**
   * 从 Error 创建 SyncError
   * 
   * 用于 catch 块中统一错误类型
   */
  static fromError(error: Error): SyncError {
    return SyncErrorFactory.normal(0, error.message);
  }
}

// ═══════════════════════════════════════════════════════════════
// 旧的错误类（保留，标记 @deprecated）
// ═══════════════════════════════════════════════════════════════

/** Geetest 验证申请结果（createVerification 接口返回） */
export class GeetestCreateResult {
  /** Geetest 应用 ID，v3/v4 均有 */
  gt: string = '';
  /** v3 专用：动态 challenge token */
  challenge: string = '';
  /** 是否新验证码（v3 字段） */
  new_captcha: number = 0;
  /** v4 专用：风险类型 */
  risk_type: string = '';
}

/** Geetest 验证提交参数（用户完成验证后传入） */
export class GeetestVerifyInput {
  geetest_challenge: string = '';
  geetest_validate: string = '';
  geetest_seccode: string = '';
}

/**
 * Cookie 失效错误
 * @deprecated 使用 SyncError.authExpired() 或 SyncErrorFactory.authExpired()
 */
export class AuthExpiredErrorClass extends Error {
  constructor(message: string) {
    super(message);
  }
}

/**
 * 需要 Geetest 人机验证错误
 * @deprecated 使用 SyncError.geetest() 或 SyncErrorFactory.geetest()
 */
export class GeetestRequiredErrorClass extends Error {
  geetestParams: GeetestCreateResult;

  constructor(message: string, geetestParams: GeetestCreateResult) {
    super(message);
    this.geetestParams = geetestParams;
  }
}

/**
 * 角色战绩未公开错误
 * @deprecated 使用 SyncError.normal() 或 SyncErrorFactory.normal()
 */
export class RoleNotPublicErrorClass extends Error {
  constructor(message: string) {
    super(message);
  }
}

// ── 兼容性别名类（内部使用）─────────────────────────────────────

/**
 * AuthExpiredErrorClass 的别名类
 * @deprecated 仅为兼容旧代码，实际应使用 AuthExpiredErrorClass
 */
export class AuthExpiredError extends Error {
  constructor(message: string) {
    super(message);
  }
}

/**
 * GeetestRequiredErrorClass 的别名类
 * @deprecated 仅为兼容旧代码，实际应使用 GeetestRequiredErrorClass
 */
export class GeetestRequiredError extends Error {
  geetestParams: GeetestCreateResult;

  constructor(message: string, geetestParams: GeetestCreateResult) {
    super(message);
    this.geetestParams = geetestParams;
  }
}

/**
 * RoleNotPublicErrorClass 的别名类
 * @deprecated 仅为兼容旧代码，实际应使用 RoleNotPublicErrorClass
 */
export class RoleNotPublicError extends Error {
  constructor(message: string) {
    super(message);
  }
}
