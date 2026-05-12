import { AppEnvManager } from '../constants/AppEnvManager';
import { hilog } from '@kit.PerformanceAnalysisKit';

/**
 * 日志等级枚举。
 */
enum LogLevel {
  INFO = 'INFO',
  WARNING = 'WARNING',
  ERROR = 'ERROR',
  DEBUG = 'DEBUG',
  TRACE = 'TRACE'
}

/**
 * 日志上下文：由调用方显式传入，避免运行时堆栈解析带来的 ArkTS 告警。
 */
export interface LogContext {
  file: string;
  method: string;
  line: number;
  column: number;
}

/**
 * 统一日志工具类（core 层，entry 和 core 共用）。
 *
 * 日志输出格式：
 * ℹ️ℹ️ℹ️ [INFO] [2026-02-28 19:42:11.037] [mock] [#12] [EntryAbility.ets:33:7] [EntryAbility.onWindowStageCreate] [EntryAbility] onWindowStageCreate ℹ️ℹ️ℹ️
 *
 * 环境判断职责由 AppEnvManager 负责，Logger 只通过 AppEnvManager.getEnv() 读取环境标签。
 * 
 * HiLog 支持：
 * - 支持按 tag 过滤：hilog -T <tag>
 * - 支持按 domain 过滤：hilog -D 0xFF00
 * - 支持隐私保护：%{public}/%{private}
 * - 支持 isLoggable() 预检查，避免耗时的日志参数构造
 */
export class Logger {
  private static readonly UNKNOWN: string = 'unknown';
  private static sequence: number = 0;
  private static readonly DOMAIN: number = 0xFF00;

  /**
   * 快速构造日志上下文。
   */
  static ctx(file: string, method: string, line: number, column: number = 1): LogContext {
    return { file, method, line, column };
  }

  static info(tag: string, message: string, context?: LogContext): void {
    Logger.print(LogLevel.INFO, tag, message, context);
  }

  static warning(tag: string, message: string, context?: LogContext): void {
    Logger.print(LogLevel.WARNING, tag, message, context);
  }

  static warn(tag: string, message: string, context?: LogContext): void {
    Logger.warning(tag, message, context);
  }

  static error(tag: string, message: string, context?: LogContext): void {
    Logger.print(LogLevel.ERROR, tag, message, context);
  }

  static debug(tag: string, message: string, context?: LogContext): void {
    Logger.print(LogLevel.DEBUG, tag, message, context);
  }

  static trace(tag: string, message: string, context?: LogContext): void {
    Logger.print(LogLevel.TRACE, tag, message, context);
  }

  /**
   * 实际打印入口：统一格式化 + 根据环境决定是否放行。
   */
  private static print(level: LogLevel, tag: string, message: string, context?: LogContext): void {
    if (!Logger.canOutput(level)) {
      return;
    }

    Logger.sequence++;
    const levelMarker: string = Logger.getLevelMarker(level);
    const currentTime: string = Logger.formatTime(new Date());
    const envLabel: string = AppEnvManager.getEnv();
    const location: string = Logger.formatLocation(context);
    const method: string = Logger.formatMethod(context);

    const finalLog: string =
      `${levelMarker}` +
      ` [${level}]` +
      ` [${currentTime}]` +
      ` [${envLabel}]` +
      ` [#${Logger.sequence}]` +
      ` [${location}]` +
      ` [${method}]` +
      ` [${tag}] ${message}` +
      ` ${levelMarker}`;

    // 优先使用 HiLog（支持过滤和隐私保护）
    Logger.printHiLog(level, tag, message, context);
    
    // 同时输出到 console（兼容旧的 Log 窗口查看方式）
    switch (level) {
      case LogLevel.INFO:
        console.info(finalLog);
        return;
      case LogLevel.WARNING:
        console.warn(finalLog);
        return;
      case LogLevel.ERROR:
        console.error(finalLog);
        return;
      case LogLevel.DEBUG:
        console.info(finalLog);
        return;
      case LogLevel.TRACE:
        console.info(finalLog);
        return;
    }
  }

  /**
   * 使用 HiLog 输出日志（支持过滤和隐私保护）
   */
  private static printHiLog(level: LogLevel, tag: string, message: string, context?: LogContext): void {
    // HiLog 的日志级别映射
    let hilogLevel: hilog.LogLevel;
    switch (level) {
      case LogLevel.DEBUG:
        hilogLevel = hilog.LogLevel.DEBUG;
        break;
      case LogLevel.INFO:
        hilogLevel = hilog.LogLevel.INFO;
        break;
      case LogLevel.WARNING:
        hilogLevel = hilog.LogLevel.WARN;
        break;
      case LogLevel.ERROR:
        hilogLevel = hilog.LogLevel.ERROR;
        break;
      case LogLevel.TRACE:
        hilogLevel = hilog.LogLevel.INFO;
        break;
      default:
        hilogLevel = hilog.LogLevel.INFO;
    }

    // 使用 isLoggable() 预检查，避免在不满足日志级别时执行耗时的日志参数构造
    if (!hilog.isLoggable(Logger.DOMAIN, tag, hilogLevel)) {
      return;
    }

    // 格式化 HiLog 消息（简化版，不包含时间戳等冗长信息）
    const location: string = Logger.formatLocation(context);
    const method: string = Logger.formatMethod(context);
    const envLabel: string = AppEnvManager.getEnv();
    
    // 使用格式化字符串，支持隐私保护
    const format = `%{public}s [%{public}s] [%{public}s] [%{public}s] %{public}s`;
    const args = [tag, envLabel, location, method, message];
    
    switch (hilogLevel) {
      case hilog.LogLevel.DEBUG:
        hilog.debug(Logger.DOMAIN, tag, format, ...args);
        break;
      case hilog.LogLevel.INFO:
        hilog.info(Logger.DOMAIN, tag, format, ...args);
        break;
      case hilog.LogLevel.WARN:
        hilog.warn(Logger.DOMAIN, tag, format, ...args);
        break;
      case hilog.LogLevel.ERROR:
        hilog.error(Logger.DOMAIN, tag, format, ...args);
        break;
    }
  }

  private static formatLocation(context?: LogContext): string {
    if (context === undefined) {
      return `${Logger.UNKNOWN}:${Logger.UNKNOWN}:${Logger.UNKNOWN}`;
    }
    return `${context.file}:${context.line}:${context.column}`;
  }

  private static formatMethod(context?: LogContext): string {
    if (context === undefined) {
      return Logger.UNKNOWN;
    }
    return context.method;
  }

  private static getLevelMarker(level: LogLevel): string {
    const emoji: string = Logger.getLevelEmoji(level);
    return `${emoji}${emoji}${emoji}`;
  }

  private static getLevelEmoji(level: LogLevel): string {
    switch (level) {
      case LogLevel.INFO:
        return 'ℹ️';
      case LogLevel.WARNING:
        return '⚠️';
      case LogLevel.ERROR:
        return '❌';
      case LogLevel.DEBUG:
        return '🐞';
      case LogLevel.TRACE:
        return '🔍';
    }
    return '🧾';
  }

  private static formatTime(time: Date): string {
    const year: string = `${time.getFullYear()}`;
    const month: string = Logger.leftPad(time.getMonth() + 1, 2);
    const day: string = Logger.leftPad(time.getDate(), 2);
    const hour: string = Logger.leftPad(time.getHours(), 2);
    const minute: string = Logger.leftPad(time.getMinutes(), 2);
    const second: string = Logger.leftPad(time.getSeconds(), 2);
    const millisecond: string = Logger.leftPad(time.getMilliseconds(), 3);
    return `${year}-${month}-${day} ${hour}:${minute}:${second}.${millisecond}`;
  }

  private static leftPad(value: number, size: number): string {
    let text: string = `${value}`;
    while (text.length < size) {
      text = `0${text}`;
    }
    return text;
  }

  /**
   * Release 环境：仅放行 info / warning。
   */
  private static canOutput(level: LogLevel): boolean {
    if (!AppEnvManager.isRelease()) {
      return true;
    }
    return level === LogLevel.INFO || level === LogLevel.WARNING;
  }
}
