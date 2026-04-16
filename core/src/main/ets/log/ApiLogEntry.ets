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
  id: number = 0;
  timestamp: number = Date.now();
  level: LogLevel = LogLevel.DEBUG;
  eventType: LogEventType = LogEventType.GENERAL;
  tag: string = '';
  message: string = '';
  extraJson: string = '';
}
