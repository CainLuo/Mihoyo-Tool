import { RequestParams, RequestOptions } from '../APIs';

/**
 * MihoyoApiService 抽象基类
 * 所有游戏 API Service 和 Mock Service 的公共接口。
 * 通过 MihoyoApiServiceFactory 创建具体实现。
 */
export abstract class MihoyoApiService {
  /** GET 请求 */
  abstract get(
    path: string,
    params?: RequestParams,
    options?: RequestOptions,
  ): Promise<object>;

  /**
   * POST 请求
   * @param data POST body：JSON 字符串（推荐）或 RequestParams（Map 形式）
   */
  abstract post(
    path: string,
    data?: string | RequestParams,
    options?: RequestOptions,
  ): Promise<object>;
}
