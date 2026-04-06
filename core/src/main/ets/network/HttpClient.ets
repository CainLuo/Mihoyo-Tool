import axios, { AxiosInstance, AxiosResponse } from '@ohos/axios';
import { RequestParams, RequestOptions, RequestValue } from './APIs';

/**
 * HttpClientV2 — 新版 HTTP 客户端
 * 接受完整 URL（含 Domain），通过 extraHeaders 注入请求头（含 Cookie、DS 等）。
 * 与旧版 HttpService 的区别：不依赖 ApiConfig，不自动注入 DS，由调用方通过 extraHeaders 控制。
 */
export class HttpClient {
  private static instance: AxiosInstance | null = null;

  private static getInstance(): AxiosInstance {
    if (HttpClient.instance === null) {
      HttpClient.instance = axios.create({
        timeout: 30000,
        headers: {
          'Content-Type': 'application/json',
        },
      });
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
    const response: AxiosResponse = await HttpClient.getInstance().get(url, {
      params: HttpClient.paramsToRecord(params),
      headers,
    });
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
    const response: AxiosResponse = await HttpClient.getInstance().post(url, body, { headers });
    return response.data as object;
  }
}
