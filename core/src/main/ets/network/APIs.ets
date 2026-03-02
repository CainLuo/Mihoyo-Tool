/**
 * API 服务抽象基类
 * 定义基础的 HTTP 方法签名
 */
export type RequestValue = string | number | boolean | null | object;
export type RequestParams = Record<string, RequestValue>;

export abstract class BaseApiService {
  /**
   * GET 请求
   * @param url 请求 URL
   * @param params 请求参数
   * @param baseUrlType BaseURL 类型
   * @returns Promise<object>
   */
  public abstract get(
    url: string,
    params?: RequestParams,
    baseUrlType?: string
  ): Promise<object>;
  /**
   * POST 请求
   * @param url 请求 URL
   * @param data 请求数据
   * @param baseUrlType BaseURL 类型
   * @returns Promise<object>
   */
  public abstract post(
    url: string,
    data?: RequestParams,
    baseUrlType?: string
  ): Promise<object>;
  /**
   * PUT 请求
   * @param url 请求 URL
   * @param data 请求数据
   * @param baseUrlType BaseURL 类型
   * @returns Promise<object>
   */
  public abstract put(
    url: string,
    data?: RequestParams,
    baseUrlType?: string
  ): Promise<object>;
  /**
   * DELETE 请求
   * @param url 请求 URL
   * @param params 请求参数
   * @param baseUrlType BaseURL 类型
   * @returns Promise<object>
   */
  public abstract delete(
    url: string,
    params?: RequestParams,
    baseUrlType?: string
  ): Promise<object>;
}
