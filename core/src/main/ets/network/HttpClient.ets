import axios, { AxiosInstance, AxiosResponse } from '@ohos/axios';
import { RequestParams, RequestOptions, RequestValue } from './APIs';
import { ApiLogSystem } from '../log/ApiLogSystem';
import { LogEventType } from '../log/ApiLogEntry';
import { AppEnvManager } from '../constants/AppEnvManager';
import certFramework from '@ohos.security.cert';

interface X509TrustManager {
  checkClientTrusted(data: certFramework.X509Cert): void;
  checkServerTrusted(data: certFramework.X509Cert): void;
}

/**
 * HttpClient — HTTP 客户端
 * 接受完整 URL（含 Domain），通过 extraHeaders 注入请求头（含 Cookie、DS 等）。
 * 与旧版 HttpService 的区别：不依赖 ApiConfig，不自动注入 DS，由调用方通过 extraHeaders 控制。
 */
export class HttpClient {
  private static instance: AxiosInstance | null = null;

  private static getInstance(): AxiosInstance {
    if (HttpClient.instance === null) {
      if (AppEnvManager.isDebug()) {
        class TrustAllManager implements X509TrustManager {
          checkClientTrusted(_data: certFramework.X509Cert): void {}
          checkServerTrusted(_data: certFramework.X509Cert): void {}
        }
        HttpClient.instance = axios.create({
          timeout: 30000,
          sslCertificateManager: new TrustAllManager(),
          headers: { 'Content-Type': 'application/json' },
        });
      } else {
        HttpClient.instance = axios.create({
          timeout: 30000,
          headers: { 'Content-Type': 'application/json' },
        });
      }
    }
    return HttpClient.instance;
  }

  /** 将 Map<string, string> 转为 Record<string, string> */
  private static headersToRecord(headers: Map<string, string>): Record<string, string> {
    const result: Record<string, string> = {};
    headers.forEach((v: string, k: string) => {
      result[k] = v;
    });
    return result;
  }

  /** 将 RequestParams 转为 Record<string, RequestValue> */
  private static paramsToRecord(params?: RequestParams): Record<string, RequestValue> | undefined {
    if (params === undefined || params.size === 0) {
      return undefined;
    }
    const result: Record<string, RequestValue> = {};
    params.forEach((v: RequestValue, k: string) => {
      result[k] = v;
    });
    return result;
  }

  /**
   * GET 请求
   * @param url     完整 URL（含 Domain + Path）
   * @param params  查询参数
   * @param options 请求选项（extraHeaders 包含 Cookie、DS 等）
   */
  static async get(url: string, params?: RequestParams, options?: RequestOptions): Promise<object> {
    const headers = options?.extraHeaders !== undefined
      ? HttpClient.headersToRecord(options.extraHeaders)
      : new Object() as Record<string, string>;

    const startTime = Date.now();
    // 记录请求日志
    try {
      ApiLogSystem.getInstance().debug(
        'HttpClient',
        'GET ' + url,
        LogEventType.API_REQUEST,
        JSON.stringify({ method: 'GET', headers }),
      );
    } catch (_) {}

    let response: AxiosResponse;
    try {
      response = await HttpClient.getInstance().get(url, {
        params: HttpClient.paramsToRecord(params),
        headers,
      });
    } catch (e) {
      // 记录网络异常日志
      try {
        const err = e as Error;
        ApiLogSystem.getInstance().error(
          'HttpClient',
          'GET ' + url + ' → ' + (err?.name ?? 'Error') + ': ' + (err?.message ?? String(e)),
          LogEventType.API_ERROR,
          JSON.stringify({ errorType: err?.name ?? 'Error', errorMessage: err?.message ?? String(e) }),
        );
      } catch (_) {}
      throw new Error(e instanceof Error ? e.message : String(e));
    }

    const durationMs = Date.now() - startTime;
    const data = response.data as Record<string, Object>;
    const retcode = data['retcode'] as number | undefined;

    if (retcode !== undefined && retcode !== 0) {
      // 记录业务错误日志
      try {
        const message = data['message'] as string ?? '';
        ApiLogSystem.getInstance().warning(
          'HttpClient',
          'GET ' + url + ' → retcode=' + retcode + ': ' + message,
          LogEventType.API_ERROR,
          JSON.stringify({ retcode, message }),
        );
      } catch (_) {}
    } else {
      // 记录成功响应日志
      try {
        const bodyPreview = JSON.stringify(data).substring(0, 500);
        ApiLogSystem.getInstance().debug(
          'HttpClient',
          'GET ' + url + ' → 200 (' + durationMs + 'ms)',
          LogEventType.API_RESPONSE,
          JSON.stringify({ statusCode: 200, durationMs, bodyPreview }),
        );
      } catch (_) {}
    }

    return response.data as object;
  }

  /**
   * POST 请求
   * @param url  完整 URL
   * @param data POST body（JSON 字符串或 RequestParams）
   * @param options 请求选项
   */
  static async post(
    url: string,
    data?: string | RequestParams,
    options?: RequestOptions,
  ): Promise<object> {
    const headers = options?.extraHeaders !== undefined
      ? HttpClient.headersToRecord(options.extraHeaders)
      : new Object() as Record<string, string>;
    let body: string | Record<string, RequestValue> | undefined;
    if (typeof data === 'string') {
      body = data;
    } else if (data instanceof RequestParams) {
      body = HttpClient.paramsToRecord(data);
    } else {
      body = undefined;
    }

    const startTime = Date.now();
    const bodySize = typeof body === 'string' ? body.length : 0;
    // 记录请求日志
    try {
      ApiLogSystem.getInstance().debug(
        'HttpClient',
        'POST ' + url,
        LogEventType.API_REQUEST,
        JSON.stringify({ method: 'POST', headers, bodySize }),
      );
    } catch (_) {}

    let response: AxiosResponse;
    try {
      response = await HttpClient.getInstance().post(url, body, { headers });
    } catch (e) {
      // 记录网络异常日志
      try {
        const err = e as Error;
        ApiLogSystem.getInstance().error(
          'HttpClient',
          'POST ' + url + ' → ' + (err?.name ?? 'Error') + ': ' + (err?.message ?? String(e)),
          LogEventType.API_ERROR,
          JSON.stringify({ errorType: err?.name ?? 'Error', errorMessage: err?.message ?? String(e) }),
        );
      } catch (_) {}
      throw new Error(e instanceof Error ? e.message : String(e));
    }

    const durationMs = Date.now() - startTime;
    const respData = response.data as Record<string, Object>;
    const retcode = respData['retcode'] as number | undefined;

    if (retcode !== undefined && retcode !== 0) {
      // 记录业务错误日志
      try {
        const message = respData['message'] as string ?? '';
        ApiLogSystem.getInstance().warning(
          'HttpClient',
          'POST ' + url + ' → retcode=' + retcode + ': ' + message,
          LogEventType.API_ERROR,
          JSON.stringify({ retcode, message }),
        );
      } catch (_) {}
    } else {
      // 记录成功响应日志
      try {
        const bodyPreview = JSON.stringify(respData).substring(0, 500);
        ApiLogSystem.getInstance().debug(
          'HttpClient',
          'POST ' + url + ' → 200 (' + durationMs + 'ms)',
          LogEventType.API_RESPONSE,
          JSON.stringify({ statusCode: 200, durationMs, bodyPreview }),
        );
      } catch (_) {}
    }

    return response.data as object;
  }
}
