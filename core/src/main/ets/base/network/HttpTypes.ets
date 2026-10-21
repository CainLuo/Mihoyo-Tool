/**
 * HttpTypes — HTTP 层项目自有类型
 *
 * 该文件不 import axios，避免 axios 类型泄漏到具体 API Service。
 * 具体 API 自己从 HttpResponse.data 中读取业务响应，再判断 retcode / 拆业务 data。
 */

export class HttpResponse {
  /** HTTP 状态码 */
  status: number = 0;

  /** 原始 HTTP 响应体（不是米游社业务里的 data 字段） */
  data: object = new Object();

  constructor(status: number = 0, data: object = new Object()) {
    this.status = status;
    this.data = data;
  }
}

export class HttpError extends Error {
  /** HTTP 状态码；网络错误 / 无响应时为 0 */
  statusCode: number = 0;

  /** HTTP 响应体；无响应时为空对象 */
  body: object = new Object();

  constructor(statusCode: number, message: string, body: object = new Object()) {
    super(message);
    this.statusCode = statusCode;
    this.body = body;
  }
}
