import axios, { AxiosInstance, AxiosResponse, InternalAxiosRequestConfig } from '@ohos/axios';
import { BaseApiService, RequestOptions, RequestParams, RequestValue } from './APIs';
import { getCookie } from './CookieManager';

/**
 * HTTP 服务类
 * 实现 BaseApiService，封装 Axios 实例，处理 DS 签名、Cookie 注入、额外请求头合并。
 *
 * 关于 extraHeaders（RequestOptions.extraHeaders）：
 *   Geetest 验证通过后，调用方需要在 options.extraHeaders 里传入：
 *     { 'x-rpc-challenge': challenge, 'x-rpc-validate': validate, 'x-rpc-seccode': seccode }
 *   这些字段会在 buildHeaders() 里与默认头合并，优先级高于默认头。
 */
export class HttpService extends BaseApiService {
  private static axiosInstance: AxiosInstance;

  private static getAxiosInstance(): AxiosInstance {
    if (!HttpService.axiosInstance) {
      HttpService.axiosInstance = HttpService.createAxiosInstance();
    }
    return HttpService.axiosInstance;
  }

  private static createAxiosInstance(): AxiosInstance {
    const instance = axios.create({
      timeout: 30000,
      headers: {
        'Content-Type': 'application/json',
        'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36'
      }
    });

    // 请求拦截器：注入 Cookie
    instance.interceptors.request.use(
      async (config: InternalAxiosRequestConfig) => {
        const cookie = await getCookie();
        if (cookie) {
          const headers = config.headers as Record<string, string>;
          headers['Cookie'] = cookie;
        }
        return config;
      },
      (error: Error) => Promise.reject(error)
    );

    instance.interceptors.response.use(
      (response: AxiosResponse): AxiosResponse => response,
      (error: Error) => Promise.reject(error)
    );

    return instance;
  }

  /**
   * 构建完整 URL（直接返回传入的 URL，调用方负责传入完整路径）
   */
  private buildUrl(url: string, _baseUrlType?: string): string {
    return url;
  }

  /**
   * 将 Map<string,string> 转为 axios 需要的 Record<string,string>
   * ArkTS 不支持 spread，用 forEach 逐条写入
   */
  private mapToRecord(map?: Map<string, RequestValue>): Record<string, RequestValue> | undefined {
    if (!map || map.size === 0) {
      return undefined;
    }
    const result: Record<string, RequestValue> = {};
    map.forEach((value: RequestValue, key: string) => {
      result[key] = value;
    });
    return result;
  }

  /**
   * 合并请求头：将 Map<string,string> 转为 axios 需要的 Record<string,string>
   * extraHeaders 优先级高于默认头，用于注入 Geetest 验证结果等动态字段。
   */
  private buildHeaders(extraHeaders?: Map<string, string>): Record<string, string> {
    if (!extraHeaders || extraHeaders.size === 0) {
      return {};
    }
    const result: Record<string, string> = {};
    extraHeaders.forEach((value: string, key: string) => {
      result[key] = value;
    });
    return result;
  }

  public async get(url: string, params?: RequestParams, options?: RequestOptions): Promise<object> {
    const fullUrl = this.buildUrl(url, options?.baseUrlType);
    const headers = this.buildHeaders(options?.extraHeaders);
    const response: AxiosResponse = await HttpService.getAxiosInstance().get(fullUrl, {
      params: this.mapToRecord(params),
      headers
    });
    return response.data;
  }

  public async post(url: string, data?: RequestParams, options?: RequestOptions): Promise<object> {
    const fullUrl = this.buildUrl(url, options?.baseUrlType);
    const headers = this.buildHeaders(options?.extraHeaders);
    const response: AxiosResponse = await HttpService.getAxiosInstance().post(fullUrl, this.mapToRecord(data), {
      headers
    });
    return response.data;
  }

  public async put(url: string, data?: RequestParams, options?: RequestOptions): Promise<object> {
    const fullUrl = this.buildUrl(url, options?.baseUrlType);
    const headers = this.buildHeaders(options?.extraHeaders);
    const response: AxiosResponse = await HttpService.getAxiosInstance().put(fullUrl, this.mapToRecord(data), {
      headers
    });
    return response.data;
  }

  public async delete(url: string, params?: RequestParams, options?: RequestOptions): Promise<object> {
    const fullUrl = this.buildUrl(url, options?.baseUrlType);
    const headers = this.buildHeaders(options?.extraHeaders);
    const response: AxiosResponse = await HttpService.getAxiosInstance().delete(fullUrl, {
      params: this.mapToRecord(params),
      headers
    });
    return response.data;
  }
}
