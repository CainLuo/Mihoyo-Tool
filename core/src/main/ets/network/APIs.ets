/**
 * API 服务抽象基类
 * 定义基础的 HTTP 方法签名和公共类型
 *
 * 设计决策（方案 B）：
 *   所有请求方法统一接收 RequestOptions 对象作为最后一个可选参数。
 *
 * ArkTS 限制说明：
 *   - arkts-no-untyped-obj-literals：对象字面量只能对应 class，不能对应 interface 或 Record。
 *   - class 的索引签名（[key: string]: V）在 ArkTS 中支持不稳定，改用 Map 更可靠。
 *   - RequestParams 和 RequestOptions 均使用 Map，调用方用 new + set() 赋值。
 */

/**
 * 请求参数：Map<string, RequestValue>
 * 调用方：
 *   const p = new RequestParams();
 *   p.set('key', 'value');
 */
export type RequestValue = string | number | boolean | null | object;
export class RequestParams extends Map<string, RequestValue> {}

/**
 * 请求选项 class。
 * extraHeaders 使用 Map<string, string>，避免 Record 字面量问题。
 */
export class RequestOptions {
  /** BaseURL 类型，对应 ApiConfig 中的枚举值，不传时默认 PUBLIC_DATA */
  baseUrlType: string = '';

  /**
   * 额外请求头（Map 形式），会与默认请求头合并（同名字段以此处为准）。
   * 主要用途：Geetest 验证通过后注入：
   *   x-rpc-challenge / x-rpc-validate / x-rpc-seccode
   * 以及覆盖 Cookie：
   *   Cookie: <指定账号的 cookie>
   */
  extraHeaders: Map<string, string> = new Map();
}

export abstract class BaseApiService {
  public abstract get(
    url: string,
    params?: RequestParams,
    options?: RequestOptions
  ): Promise<object>;

  public abstract post(
    url: string,
    data?: RequestParams,
    options?: RequestOptions
  ): Promise<object>;

  public abstract put(
    url: string,
    data?: RequestParams,
    options?: RequestOptions
  ): Promise<object>;

  public abstract delete(
    url: string,
    params?: RequestParams,
    options?: RequestOptions
  ): Promise<object>;
}
