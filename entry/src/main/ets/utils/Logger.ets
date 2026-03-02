import { APP_RUNTIME_ENV, APP_RUNTIME_SOURCE } from '../config/RuntimeConfig';

/**
 * 应用运行环境枚举。
 */
export enum RuntimeEnv {
  MOCK = 'Mock',
  RELEASE = 'Release',
  OTHER = 'Other'
}

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
 * 统一日志工具类。
 *
 * 日志输出格式：
 * ℹ️ℹ️ℹ️ [INFO] [2026-02-28 19:42:11.037] [Mock] [#12] [EntryAbility.ets:33:7] [EntryAbility.onWindowStageCreate] [EntryAbility] onWindowStageCreate ℹ️ℹ️ℹ️
 */
export class Logger {
  private static readonly UNKNOWN: string = 'unknown';
  private static sequence: number = 0;

  /**
   * 快速构造日志上下文。
   */
  static ctx(file: string, method: string, line: number, column: number = 1): LogContext {
    return { file, method, line, column };
  }

  /**
   * 获取当前运行环境（Mock / Release / Other）。
   */
  static getRuntimeEnv(): RuntimeEnv {
    return Logger.parseRuntimeEnv(APP_RUNTIME_ENV);
  }

  /**
   * 输出环境细节字符串，便于排查当前到底命中了哪个环境。
   */
  static getRuntimeEnvDetail(): string {
    return `runtimeEnv=${Logger.getRuntimeEnv()}, envFlag=${APP_RUNTIME_ENV}, source=${APP_RUNTIME_SOURCE}`;
  }

  /**
   * 判断是否为 Mock 环境。
   */
  static isMockEnv(): boolean {
    return Logger.getRuntimeEnv() === RuntimeEnv.MOCK;
  }

  /**
   * 判断是否为 Release 环境。
   */
  static isReleaseEnv(): boolean {
    return Logger.getRuntimeEnv() === RuntimeEnv.RELEASE;
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
    const runtimeEnv: string = `${Logger.getRuntimeEnv()}`;
    const location: string = Logger.formatLocation(context);
    const method: string = Logger.formatMethod(context);

    const finalLog: string =
      `${levelMarker}` +
      ` [${level}]` +
      ` [${currentTime}]` +
      ` [${runtimeEnv}]` +
      ` [#${Logger.sequence}]` +
      ` [${location}]` +
      ` [${method}]` +
      ` [${tag}] ${message}` +
      ` ${levelMarker}`;

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
   * 生成 [file:line:column]。
   */
  private static formatLocation(context?: LogContext): string {
    if (context === undefined) {
      return `${Logger.UNKNOWN}:${Logger.UNKNOWN}:${Logger.UNKNOWN}`;
    }
    return `${context.file}:${context.line}:${context.column}`;
  }

  /**
   * 生成 [method]。
   */
  private static formatMethod(context?: LogContext): string {
    if (context === undefined) {
      return Logger.UNKNOWN;
    }
    return context.method;
  }

  /**
   * 每个日志等级对应 marker：前后各 3 个 emoji。
   */
  private static getLevelMarker(level: LogLevel): string {
    const emoji: string = Logger.getLevelEmoji(level);
    return `${emoji}${emoji}${emoji}`;
  }

  /**
   * 每个日志等级对应 emoji。
   */
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

  /**
   * 时间格式：yyyy-MM-dd HH:mm:ss.SSS
   */
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
    if (!Logger.isReleaseEnv()) {
      return true;
    }
    return level === LogLevel.INFO || level === LogLevel.WARNING;
  }

  private static parseRuntimeEnv(runtimeFlag: string): RuntimeEnv {
    const normalized: string = runtimeFlag.toLowerCase();
    if (normalized === 'mock') {
      return RuntimeEnv.MOCK;
    }
    if (normalized === 'release') {
      return RuntimeEnv.RELEASE;
    }
    return RuntimeEnv.OTHER;
  }
}
