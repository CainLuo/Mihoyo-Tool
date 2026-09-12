/**
 * ApiErrorHandler — API 错误处理工具类
 *
 * 统一处理米游社 API 响应的 retcode 错误码，抛出对应的业务错误类型。
 * 所有 Repository 层的 sync* 方法在调用 API 后应调用 checkResponse() 进行统一错误检查。
 *
 * 错误码参考：UIGF-org/mihoyo-api-collect
 */
import { AuthExpiredError, GeetestRequiredError, GeetestCreateResult } from '../errors/ApiErrors';
import { ApiErrorCodes } from '../constants/ApiErrorCodes';

export class ApiErrorHandler {
  /**
   * 检查 API 响应的 retcode，根据错误码抛出对应的错误类型
   *
   * @param resp API 响应对象（包含 retcode/message/data 字段）
   * @throws AuthExpiredError 当 retcode 为 -100/10001/-10001 时（Cookie 失效）
   * @throws GeetestRequiredError 当 retcode 为 1034/10035 时（需要 Geetest 验证）
   * @throws Error 当 data 为 null 且 retcode 非 0 时（其他业务错误）
   */
  static checkResponse(resp: object): void {
    const respData = resp as Record<string, object>;
    const retcodeStr = `${respData['retcode'] ?? ''}`;
    const message = `${respData['message'] ?? 'unknown error'}`;

    // Cookie 失效（retcode=-100/10001/-10001）
    if (retcodeStr === '-100' || retcodeStr === '10001' || retcodeStr === '-10001') {
      throw new AuthExpiredError(`retcode=${retcodeStr}: ${message}`);
    }

    // 需要 Geetest 人机验证（retcode=1034/10035）
    if (retcodeStr === '1034' || retcodeStr === '10035') {
      const geetestParams = ApiErrorHandler.extractGeetestParams(respData);
      throw new GeetestRequiredError(`retcode=${retcodeStr}: ${message}`, geetestParams);
    }

    // 其他错误（data 为空且 retcode 非 0）
    if (respData['data'] === null || respData['data'] === undefined) {
      if (retcodeStr !== '0' && retcodeStr !== '') {
        throw new Error(`retcode=${retcodeStr}: ${message}`);
      }
    }
  }

  /**
   * 从 API 响应中提取 Geetest 验证参数
   *
   * 当 retcode=1034/10035 时，响应的 data 字段可能包含 gt/challenge 等参数。
   * 这些参数用于启动 Geetest 验证流程。
   *
   * @param respData API 响应对象
   * @returns GeetestCreateResult 对象，包含 gt/challenge/new_captcha/risk_type 字段
   */
  static extractGeetestParams(respData: Record<string, object>): GeetestCreateResult {
    const result = new GeetestCreateResult();
    const data = respData['data'] as Record<string, object> | null;

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
   * @param retcode retcode 数值或字符串
   * @returns true 表示需要 Geetest 验证
   */
  static isGeetestRequired(retcode: number | string): boolean {
    const retcodeStr = typeof retcode === 'number' ? `${retcode}` : retcode;
    return retcodeStr === '1034' || retcodeStr === '10035';
  }

  /**
   * 检查 retcode 是否为 Cookie 失效错误
   *
   * @param retcode retcode 数值或字符串
   * @returns true 表示 Cookie 已失效
   */
  static isAuthExpired(retcode: number | string): boolean {
    const retcodeStr = typeof retcode === 'number' ? `${retcode}` : retcode;
    return retcodeStr === '-100' || retcodeStr === '10001' || retcodeStr === '-10001';
  }
}
