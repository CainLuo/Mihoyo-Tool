/**
 * WidgetLogger — Widget 模块专用日志工具
 *
 * 用途：在 FormExtension 进程中使用的日志工具，不依赖 core 模块。
 *
 * 环境判断：
 * - 通过 BuildProfile.APP_ENV 读取环境（编译时常量）
 * - Release 环境下禁用 debug/trace 级别日志
 * - Mock/Debug 环境下输出所有日志
 *
 * 使用方式：
 * ```ts
 * WidgetLogger.info('TAG', 'message');
 * WidgetLogger.warn('TAG', 'message');
 * WidgetLogger.error('TAG', 'message');
 * WidgetLogger.debug('TAG', 'message');  // release 环境下不输出
 * ```
 */

import { hilog } from '@kit.PerformanceAnalysisKit';
import BuildProfile from 'BuildProfile';

/** 日志级别 */
enum LogLevel {
  DEBUG = 3,
  INFO = 4,
  WARN = 5,
  ERROR = 6,
}

/** 日志域 */
const DOMAIN = 0xFF00;

/** 是否为 release 环境（编译时常量） */
const IS_RELEASE: boolean = BuildProfile.APP_ENV.toLowerCase() === 'release';

/** 最低日志级别（release 环境只输出 info 及以上） */
const MIN_LEVEL: LogLevel = IS_RELEASE ? LogLevel.INFO : LogLevel.DEBUG;

export class WidgetLogger {
  /**
   * 输出 debug 级别日志（release 环境下不输出）
   */
  static debug(tag: string, message: string): void {
    if (MIN_LEVEL > LogLevel.DEBUG) {
      return;
    }
    hilog.debug(DOMAIN, tag, '%{public}s', message);
  }

  /**
   * 输出 info 级别日志
   */
  static info(tag: string, message: string): void {
    if (MIN_LEVEL > LogLevel.INFO) {
      return;
    }
    hilog.info(DOMAIN, tag, '%{public}s', message);
  }

  /**
   * 输出 warn 级别日志
   */
  static warn(tag: string, message: string): void {
    if (MIN_LEVEL > LogLevel.WARN) {
      return;
    }
    hilog.warn(DOMAIN, tag, '%{public}s', message);
  }

  /**
   * 输出 error 级别日志
   */
  static error(tag: string, message: string): void {
    if (MIN_LEVEL > LogLevel.ERROR) {
      return;
    }
    hilog.error(DOMAIN, tag, '%{public}s', message);
  }
}
