import axios, { AxiosInstance, AxiosResponse } from '@ohos/axios';
import { RequestParams, RequestOptions, RequestValue } from './APIs';
import { HttpError, HttpResponse } from './HttpTypes';
import { ApiLogSystem } from '../log/ApiLogSystem';
import { LogEventType } from '../log/ApiLogEntry';
import { AppEnvManager } from '../../common/constants/AppEnvManager';
import certFramework from '@ohos.security.cert';

interface X509TrustManager {
  checkClientTrusted(data: certFramework.X509Cert): void;
  checkServerTrusted(data: certFramework.X509Cert): void;
}

/**
 * BaseApiService — 构建链路内唯一的 axios 封装层。
 *
 * 只负责：
 *   - axios 单例、超时、debug 证书信任
 *   - get / post
 *   - HTTP 非 200 拦截
 *   - HTTP 层日志（脱敏 URL、状态码、耗时、错误类型；不打印 header / body）
 *
 * 不负责：
 *   - response.data 拆包
 *   - 业务 retcode 判断
 *   - Geetest / 指纹上报
 *   - 米游社 URL / header / DS / Cookie
 */
export class BaseApiService {
  private static instance: AxiosInstance | null = null;

  /** 供 DeviceFpService / GeetestService / ZZZRecordRequest 等非继承调用方使用 */
  static readonly shared: BaseApiService = new BaseApiService();

  private static readonly SENSITIVE_QUERY_KEYS: string[] = [
    'stoken',
    'ltoken',
    'cookie_token',
    'ticket',
    'token',
    'device_fp',
    'device_id',
    'mid',
    'stuid',
    'ltuid',
    'authkey',
  ];

  private static getAxiosInstance(): AxiosInstance {
    if (BaseApiService.instance === null) {
      if (AppEnvManager.isDebug()) {
        class TrustAllManager implements X509TrustManager {
          checkClientTrusted(_data: certFramework.X509Cert): void {}
          checkServerTrusted(_data: certFramework.X509Cert): void {}
        }
        BaseApiService.instance = axios.create({
          timeout: 30000,
          sslCertificateManager: new TrustAllManager(),
          validateStatus: (_status: number) => true,
        });
      } else {
        BaseApiService.instance = axios.create({
          timeout: 30000,
          validateStatus: (_status: number) => true,
        });
      }
    }
    return BaseApiService.instance;
  }

  private static headersToRecord(headers?: Map<string, string>): Record<string, string> {
    const result: Record<string, string> = {};
    if (headers !== undefined) {
      headers.forEach((value: string, key: string) => {
        result[key] = value;
      });
    }
    return result;
  }

  private static paramsToRecord(params?: RequestParams): Record<string, RequestValue> | undefined {
    if (params === undefined || params.size === 0) {
      return undefined;
    }
    const result: Record<string, RequestValue> = {};
    params.forEach((value: RequestValue, key: string) => {
      result[key] = value;
    });
    return result;
  }

  private static bodyToRecord(data?: string | RequestParams): string | Record<string, RequestValue> | undefined {
    if (typeof data === 'string') {
      return data;
    }
    return BaseApiService.paramsToRecord(data);
  }

  /** 脱敏 URL query，至少覆盖 token / stoken / ltoken / ticket / device_fp / device_id */
  private static redactUrl(url: string): string {
    const queryIndex = url.indexOf('?');
    if (queryIndex < 0) {
      return url;
    }
    const base = url.substring(0, queryIndex);
    const query = url.substring(queryIndex + 1);
    if (query.length === 0) {
      return url;
    }

    const parts = query.split('&');
    const safeParts: string[] = [];
    for (let i = 0; i < parts.length; i++) {
      const part = parts[i];
      const eqIndex = part.indexOf('=');
      const key = eqIndex >= 0 ? part.substring(0, eqIndex) : part;
      if (BaseApiService.SENSITIVE_QUERY_KEYS.indexOf(key.toLowerCase()) >= 0) {
        safeParts[safeParts.length] = key + '=***';
      } else {
        safeParts[safeParts.length] = part;
      }
    }
    return base + '?' + safeParts.join('&');
  }

  private static logHttpRequest(method: string, url: string): void {
    try {
      ApiLogSystem.getInstance().debug(
        'BaseApiService',
        method + ' ' + BaseApiService.redactUrl(url),
        LogEventType.API_REQUEST,
      );
    } catch (_) {}
  }

  private static logHttpResponse(method: string, url: string, status: number, durationMs: number): void {
    try {
      ApiLogSystem.getInstance().debug(
        'BaseApiService',
        method + ' ' + BaseApiService.redactUrl(url) + ' → ' + status + ' (' + durationMs + 'ms)',
        LogEventType.API_RESPONSE,
        JSON.stringify({ status: status, durationMs: durationMs }),
      );
    } catch (_) {}
  }

  private static logHttpError(method: string, url: string, status: number, durationMs: number,
    errorType: string): void {
    try {
      ApiLogSystem.getInstance().error(
        'BaseApiService',
        method + ' ' + BaseApiService.redactUrl(url) + ' → ' + errorType,
        LogEventType.API_ERROR,
        JSON.stringify({ status: status, durationMs: durationMs, errorType: errorType }),
      );
    } catch (_) {}
  }

  private static responseBody(response: AxiosResponse): object {
    if (response.data === null || response.data === undefined) {
      return new Object();
    }
    return response.data as object;
  }

  private static handleResponse(response: AxiosResponse, method: string, url: string,
    startedAt: number): HttpResponse {
    const status = response.status;
    const durationMs = Date.now() - startedAt;
    if (status !== 200) {
      BaseApiService.logHttpError(method, url, status, durationMs, 'HTTP ' + status);
      throw new HttpError(status, 'HTTP ' + status, BaseApiService.responseBody(response));
    }

    BaseApiService.logHttpResponse(method, url, status, durationMs);
    return new HttpResponse(status, BaseApiService.responseBody(response));
  }

  private static toHttpError(error: Error | object, method: string, url: string,
    startedAt: number): HttpError {
    if (error instanceof HttpError) {
      return error;
    }
    const durationMs = Date.now() - startedAt;
    const errorType = error instanceof Error ? error.name : 'Error';
    BaseApiService.logHttpError(method, url, 0, durationMs, errorType);
    const message = error instanceof Error && error.message.length > 0
      ? error.message
      : 'Network request failed';
    return new HttpError(0, message);
  }

  async get(url: string, params?: RequestParams, options?: RequestOptions): Promise<HttpResponse> {
    const startedAt = Date.now();
    BaseApiService.logHttpRequest('GET', url);
    try {
      const response: AxiosResponse = await BaseApiService.getAxiosInstance().get(url, {
        params: BaseApiService.paramsToRecord(params),
        headers: BaseApiService.headersToRecord(options?.extraHeaders),
      });
      return BaseApiService.handleResponse(response, 'GET', url, startedAt);
    } catch (error) {
      throw BaseApiService.toHttpError(error as Error, 'GET', url, startedAt);
    }
  }

  async post(url: string, data?: string | RequestParams, options?: RequestOptions): Promise<HttpResponse> {
    const startedAt = Date.now();
    BaseApiService.logHttpRequest('POST', url);
    try {
      const response: AxiosResponse = await BaseApiService.getAxiosInstance().post(
        url,
        BaseApiService.bodyToRecord(data),
        {
          headers: BaseApiService.headersToRecord(options?.extraHeaders),
        },
      );
      return BaseApiService.handleResponse(response, 'POST', url, startedAt);
    } catch (error) {
      throw BaseApiService.toHttpError(error as Error, 'POST', url, startedAt);
    }
  }
}
