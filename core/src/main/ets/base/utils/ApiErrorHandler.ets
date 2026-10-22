/**
 * ApiErrorHandler — API 错误处理工具类
 *
 * 统一处理米游社 API 响应的 retcode 错误码，抛出对应的业务错误类型。
 * 所有 Repository 层的 sync* 方法在调用 API 后应调用 checkResponse() 进行统一错误检查。
 *
 * 码值不在这里硬编码：分类查 RetcodeRegistry，原始码见 MihoyoRetcode。
 * 错误码来源：UIGF-org/mihoyo-api-collect + PizzaHelperUnited 交叉验证。
 */
import { AuthExpiredError, GeetestRequiredError, GeetestCreateResult } from '../errors/ApiErrors';
import { RetcodeKind, RetcodeRegistry } from '../errors/RetcodeRegistry';

/**
 * API 响应基础结构
 */
interface ApiResponse {
  retcode: number;
  message: string;
  data: object | null;
}

export class ApiErrorHandler {
  /**
   * 检查 API 响应的 retcode，根据错误码抛出对应的错误类型
   *
   * @param resp API 响应对象（包含 retcode/message/data 字段）
   * @throws AuthExpiredError 当 retcode 属于 AUTH_EXPIRED（-100 / 10001 / -111）
   * @throws GeetestRequiredError 当 retcode 属于 VERIFICATION_REQUIRED（1034 / 10035）
   * @throws Error 当 data 为 null 且 retcode 非 0 时（其他业务错误）
   */
  static checkResponse(resp: object): void {
    const respData = resp as ApiResponse;
    const retcode: number = respData.retcode ?? 0;
    const message: string = respData.message ?? 'unknown error';

    // 统一从 RetcodeRegistry 取语义，避免在这里重复写 -100 / 10001 / 1034 / 10035
    const kind = RetcodeRegistry.kindOf(retcode);

    // Cookie 失效（-100 / 10001 / -111）；-10001 是请求无效，不属于登录失效
    if (kind === RetcodeKind.AUTH_EXPIRED) {
      throw new AuthExpiredError(`retcode=${retcode}: ${message}`);
    }

    // 需要 Geetest 人机验证（1034 / 10035）
    if (kind === RetcodeKind.VERIFICATION_REQUIRED) {
      const geetestParams = ApiErrorHandler.extractGeetestParams(respData);
      throw new GeetestRequiredError(`retcode=${retcode}: ${message}`, geetestParams);
    }

    // 其他错误（data 为空且 retcode 非 0）
    if (respData.data === null || respData.data === undefined) {
      if (!RetcodeRegistry.isSuccess(retcode)) {
        throw new Error(`retcode=${retcode}: ${message}`);
      }
    }
  }

  /**
   * 从 API 响应中提取 Geetest 验证参数
   *
   * 当 retcode 属于 VERIFICATION_REQUIRED（1034 / 10035）时，响应的 data 字段可能包含 gt/challenge 等参数。
   * 这些参数用于启动 Geetest 验证流程。
   *
   * @param respData API 响应对象
   * @returns GeetestCreateResult 对象，包含 gt/challenge/new_captcha/risk_type 字段
   */
  static extractGeetestParams(respData: ApiResponse): GeetestCreateResult {
    const result = new GeetestCreateResult();
    const data = respData.data as Record<string, object> | null;

    if (data !== null && data !== undefined) {
      result.gt = `${data['gt'] ?? ''}`;
      result.challenge = `${data['challenge'] ?? ''}`;
      result.new_captcha = Number(data['new_captcha'] ?? 0);
      result.risk_type = `${data['risk_type'] ?? ''}`;
    }

    return result;
  }

  /**
   * 检查 retcode 是否为 Geetest 验证错误
   *
   * @param retcode retcode 数值
   * @returns true 表示需要 Geetest 验证
   */
  static isGeetestRequired(retcode: number): boolean {
    return RetcodeRegistry.isVerificationRequired(retcode);
  }


  /**
   * 检查 retcode 是否为 Cookie 失效错误
   *
   * @param retcode retcode 数值
   * @returns true 表示 Cookie 已失效
   */
  static isAuthExpired(retcode: number): boolean {
    return RetcodeRegistry.isAuthExpired(retcode);
  }
}
