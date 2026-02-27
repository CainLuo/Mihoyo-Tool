
import axios, { AxiosInstance, AxiosRequestConfig, AxiosResponse, InternalAxiosRequestConfig } from '@ohos/axios';
import { BaseApiService } from './APIs';
import { ApiConfig } from './ApiConfig';
import { getCookie } from './CookieManager';
import { generateDS } from './DSUtil';

/**
 * HTTP 服务类
 * 实现 BaseApiService 抽象类，封装 Axios 实例
 */
export class HttpService extends BaseApiService {
  private static instance: AxiosInstance;

  /**
   * 获取 Axios 实例
   * @returns AxiosInstance
   */
  private static getInstance(): AxiosInstance {
    if (!HttpService.instance) {
      HttpService.instance = HttpService.createInstance();
    }
    return HttpService.instance;
  }

  /**
   * 创建 Axios 实例
   * @returns AxiosInstance
   */
  private static createInstance(): AxiosInstance {
    const instance = axios.create({
      timeout: 30000,
      headers: {
        'Content-Type': 'application/json',
        'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36'
      }
    });
    // 请求拦截器
    instance.interceptors.request.use(
      async (config: InternalAxiosRequestConfig) => {
        // 生成 DS 签名
        const ds = generateDS(config);
        if (ds) {
          const headers = config.headers as Record<string, string>;
          headers['x-rpc-ds'] = ds;
        }

        // 注入 Cookie
        const cookie = await getCookie();
        if (cookie) {
          const headers = config.headers as Record<string, string>;
          headers['Cookie'] = cookie;
        }
        return config;
      },
      (error: Error) => {
        return Promise.reject(error);
      }
    );
    // 响应拦截器
    instance.interceptors.response.use(
      (response: AxiosResponse): AxiosResponse => {
        return response;
      },
      (error: Error) => {
        return Promise.reject(error);
      }
    );

    return instance;
  }

  /**
   * 构建完整的请求 URL
   * @param url 请求 URL
   * @param baseUrlType BaseURL 类型
   * @returns 完整的请求 URL
   */
  private buildUrl(url: string, baseUrlType?: string): string {
    const baseUrl = ApiConfig.getBaseUrl(baseUrlType || 'PUBLIC_DATA');
    return `${baseUrl}${url.startsWith('/') ? '' : '/'}${url}`;
  }

  /**
   * GET 请求
   * @param url 请求 URL
   * @param params 请求参数
   * @param baseUrlType BaseURL 类型
   * @returns Promise<T>
   */
  public async get(
    url: string,
    params?: Record<string, string | number | boolean>,
    baseUrlType?: string
  ): Promise<Object> {
    const fullUrl = this.buildUrl(url, baseUrlType);
    const response: AxiosResponse = await HttpService.getInstance().get(fullUrl, { params });
    return response.data;
  }

  /**
   * POST 请求
   * @param url 请求 URL
   * @param data 请求数据
   * @param baseUrlType BaseURL 类型
   * @returns Promise<T>
   */
  public async post(
    url: string,
    data?: Record<string, string | number | boolean | Object>,
    baseUrlType?: string
  ): Promise<Object> {
    const fullUrl = this.buildUrl(url, baseUrlType);
    const response: AxiosResponse = await HttpService.getInstance().post(fullUrl, data);
    return response.data;
  }

  /**
   * PUT 请求
   * @param url 请求 URL
   * @param data 请求数据
   * @param baseUrlType BaseURL 类型
   * @returns Promise<T>
   */
  public async put(
    url: string,
    data?: Record<string, string | number | boolean | Object>,
    baseUrlType?: string
  ): Promise<Object> {
    const fullUrl = this.buildUrl(url, baseUrlType);
    const response: AxiosResponse = await HttpService.getInstance().put(fullUrl, data);
    return response.data;
  }

  /**
   * DELETE 请求
   * @param url 请求 URL
   * @param params 请求参数
   * @param baseUrlType BaseURL 类型
   * @returns Promise<T>
   */
  public async delete(
    url: string,
    params?: Record<string, string | number | boolean | Object>,
    baseUrlType?: string
  ): Promise<Object> {
    const fullUrl = this.buildUrl(url, baseUrlType);
    const response: AxiosResponse = await HttpService.getInstance().delete(fullUrl, { params });
    return response.data;
  }
}
