/**
 * ApiLogEntry — API 日志条目数据模型
 *
 * 日志完整记录所有信息，不做任何脱敏处理。
 * 每条日志序列化为一行 JSON（NDJSON 格式）写入文件。
 */

export enum LogLevel {
  DEBUG = 'DEBUG',
  INFO = 'INFO',
  WARNING = 'WARNING',
  ERROR = 'ERROR',
}

export enum LogEventType {
  API_REQUEST = 'API_REQUEST',
  API_RESPONSE = 'API_RESPONSE',
  API_ERROR = 'API_ERROR',
  LIFECYCLE = 'LIFECYCLE',
  GENERAL = 'GENERAL',
}

export class ApiLogEntry {
  /** 同文件内自增 ID */
  id: number = 0;
  /** 日志时间戳（Unix 毫秒） */
  timestamp: number = Date.now();
  /** 日志级别 */
  level: LogLevel = LogLevel.DEBUG;
  /** 事件类型 */
  eventType: LogEventType = LogEventType.GENERAL;
  /** 日志标签（模块名） */
  tag: string = '';
  /** 日志消息 */
  message: string = '';
  /** 附加 JSON 数据（可选，如请求/响应体） */
  extraJson: string = '';
}
