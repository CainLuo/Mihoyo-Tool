/**
 * API 服务抽象基类
 * 定义基础的 HTTP 方法签名
 */
export abstract class BaseApiService {
  /**
   * GET 请求
   * @param url 请求 URL
   * @param params 请求参数
   * @param baseUrlType BaseURL 类型
   * @returns Promise<Object>
   */
  public abstract get(
    url: string,
    params?: Record<string, Object>,
    baseUrlType?: string
  ): Promise<Object>;
  /**
   * POST 请求
   * @param url 请求 URL
   * @param data 请求数据
   * @param baseUrlType BaseURL 类型
   * @returns Promise<Object>
   */
  public abstract post(
    url: string,
    data?: Record<string, Object>,
    baseUrlType?: string
  ): Promise<Object>;
  /**
   * PUT 请求
   * @param url 请求 URL
   * @param data 请求数据
   * @param baseUrlType BaseURL 类型
   * @returns Promise<Object>
   */
  public abstract put(
    url: string,
    data?: Record<string, Object>,
    baseUrlType?: string
  ): Promise<Object>;
  /**
   * DELETE 请求
   * @param url 请求 URL
   * @param params 请求参数
   * @param baseUrlType BaseURL 类型
   * @returns Promise<Object>
   */
  public abstract delete(
    url: string,
    params?: Record<string, Object>,
    baseUrlType?: string
  ): Promise<Object>;
}
