/**
 * MihoyoApiService 抽象基类
 * 所有游戏 API Service 的公共接口。
 * 通过 ApiServiceFactory 创建具体实现。
 */
import { BaseApiService } from './BaseApiService';
import { RequestParams, RequestOptions, RequestValue } from './APIs';
import { HeaderContext, MihoyoHeaderBuilder } from './MihoyoHeaderBuilder';
import { HttpResponse } from './HttpTypes';
import { ApiLogSystem } from '../log/ApiLogSystem';
import { LogEventType } from '../log/ApiLogEntry';
import { GeetestReporter } from './GeetestReporter';
import { FingerprintReporter } from './FingerprintReporter';
import { RetcodeRegistry } from '../errors/RetcodeRegistry';

export abstract class MihoyoApiService extends BaseApiService {

  /**
   * 合并请求头：公共 Profile header 先写入，请求特定的 extraHeaders 后写入（同名覆盖），
   * 最后按 removeHeaders 删除。不会修改调用方传入的 options。
   */
  protected prepareOptions(
    context: HeaderContext,
    params?: RequestParams,
    body?: string,
    options?: RequestOptions,
  ): RequestOptions {
    const merged = new RequestOptions();
    if (options !== undefined) {
      merged.suppressGeetestReport = options.suppressGeetestReport;
    }

    const common = MihoyoHeaderBuilder.buildFor(context, params, body);
    common.forEach((value: string, key: string) => {
      merged.extraHeaders.set(key, value);
    });

    if (options !== undefined) {
      options.extraHeaders.forEach((value: string, key: string) => {
        merged.extraHeaders.set(key, value);
      });
      for (let i = 0; i < options.removeHeaders.length; i++) {
        merged.extraHeaders.delete(options.removeHeaders[i]);
      }
    }
    return merged;
  }

  /** 使用公共 header Profile 发起 GET；需要完全自定义 header 的接口继续使用 get()。 */
  protected async getWithProfile(
    url: string,
    context: HeaderContext,
    params?: RequestParams,
    options?: RequestOptions,
  ): Promise<HttpResponse> {
    return super.get(url, params, this.prepareOptions(context, params, undefined, options));
  }

  /** 使用公共 header Profile 发起 POST；body 为 JSON 字符串。 */
  protected async postWithProfile(
    url: string,
    context: HeaderContext,
    body?: string,
    options?: RequestOptions,
  ): Promise<HttpResponse> {
    return super.post(url, body, this.prepareOptions(context, undefined, body, options));
  }

  /**
   * 具体 API 在自己的请求返回后显式调用。
   * BaseApiService / MihoyoApiService 的 get / post 不自动上报，避免所有接口都被默认上报。
   *
   * @param url         请求 URL（Reporter 会自行去掉 query）
   * @param data        HTTP 响应体
   * @param options     请求选项；suppressGeetestReport 当前同时抑制 Geetest + 指纹上报，但不抑制业务错误日志
   * @param params      GET query，仅在没有显式 roleUid 时用于提取
   * @param requestBody POST body，仅在没有显式 roleUid 时用于提取
   * @param cookie      该请求实际使用的 Cookie；不传时从 extraHeaders 读取
   * @param roleUid     游戏角色 UID；BBS 账号 UID 不能传到这里
   */
  protected reportBusinessError(
    url: string,
    data: object,
    options?: RequestOptions,
    params?: RequestParams,
    requestBody?: string | Record<string, RequestValue>,
    cookie?: string,
    roleUid?: string,
  ): void {
    if (data === null || data === undefined) {
      return;
    }

    const body = data as Record<string, Object>;
    const retcode = body['retcode'] as number | undefined;
    if (retcode === undefined) {
      return;
    }

    // 业务错误日志与上报开关无关，保持旧 transport 的日志行为
    if (!RetcodeRegistry.isSuccess(retcode)) {
      try {
        const message = body['message'] as string ?? '';
        ApiLogSystem.getInstance().warning(
          'MihoyoApiService',
          'retcode=' + retcode + ': ' + message,
          LogEventType.API_ERROR,
          JSON.stringify({ retcode: retcode, message: message }),
        );
      } catch (_) {}
    }

    if (options?.suppressGeetestReport === true) {
      return;
    }

    const actualCookie = cookie !== undefined ? cookie : this.cookieOf(options);
    const actualRoleUid = roleUid !== undefined
      ? roleUid
      : GeetestReporter.roleUidOf(url, params, requestBody);
    if (RetcodeRegistry.isVerificationRequired(retcode)) {
      GeetestReporter.report(url, actualCookie, actualRoleUid, retcode);
    } else if (RetcodeRegistry.isFingerprintInvalid(retcode)) {
      FingerprintReporter.report(url, retcode, actualRoleUid);
    }
  }

  private cookieOf(options?: RequestOptions): string {
    const headers = options?.extraHeaders;
    if (headers === undefined) {
      return '';
    }
    const cookie = headers.get('Cookie');
    if (cookie !== undefined) {
      return cookie;
    }
    const lowerCookie = headers.get('cookie');
    return lowerCookie !== undefined ? lowerCookie : '';
  }
}
