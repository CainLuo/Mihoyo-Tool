/**
 * MihoyoApiService 抽象基类
 * 所有游戏 API Service 的公共接口。
 * 通过 MihoyoApiServiceFactory 创建具体实现。
 */
import { BaseApiService } from './BaseApiService';
import { RequestParams, RequestOptions, RequestValue } from './APIs';
import { ApiLogSystem } from '../log/ApiLogSystem';
import { LogEventType } from '../log/ApiLogEntry';
import { GeetestReporter } from './GeetestReporter';
import { FingerprintReporter } from './FingerprintReporter';

export abstract class MihoyoApiService extends BaseApiService {

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
    if (retcode !== 0) {
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
    if (GeetestReporter.isGeetestRetcode(retcode)) {
      GeetestReporter.report(url, actualCookie, actualRoleUid, retcode);
    } else if (FingerprintReporter.isFingerprintRetcode(retcode)) {
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
