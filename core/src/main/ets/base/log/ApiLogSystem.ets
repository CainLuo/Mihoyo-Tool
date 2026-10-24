/**
 * ApiLogSystem — API 日志收集系统单例入口
 *
 * 初始化前的日志缓存到 pendingQueue，初始化完成后批量写入。
 * 所有写入操作均有 try-catch 保护，不影响主业务流程。
 */

import { common } from '@kit.AbilityKit';
import { ApiLogEntry, LogLevel, LogEventType } from './ApiLogEntry';
import { LogFileManager } from './LogFileManager';
import { Logger } from '../utils/Logger';

export class ApiLogSystem {
  private static instance: ApiLogSystem | null = null;
  private initialized: boolean = false;
  private pendingQueue: ApiLogEntry[] = [];
  private fileManager: LogFileManager = new LogFileManager();

  private constructor() {}

  static getInstance(): ApiLogSystem {
    if (ApiLogSystem.instance === null) {
      ApiLogSystem.instance = new ApiLogSystem();
    }
    return ApiLogSystem.instance;
  }

  async init(context: common.UIAbilityContext): Promise<void> {
    if (this.initialized) {
      return;
    }
    try {
      await this.fileManager.init(context);
      this.initialized = true;
      // 批量写入 pendingQueue
      const pending = this.pendingQueue;
      this.pendingQueue = [];
      for (let i = 0; i < pending.length; i++) {
        await this.fileManager.append(pending[i]);
      }
      // 写入初始化完成标记
      const entry = new ApiLogEntry();
      entry.level = LogLevel.INFO;
      entry.eventType = LogEventType.LIFECYCLE;
      entry.tag = 'ApiLogSystem';
      entry.message = 'ApiLogSystem initialized, pending flushed: ' + pending.length;
      await this.fileManager.append(entry);
    } catch (e) {
      Logger.error('ApiLogSystem', 'init failed: ' + String(e));
    }
  }

  log(entry: ApiLogEntry): void {
    try {
      if (!this.initialized) {
        this.pendingQueue[this.pendingQueue.length] = entry;
        return;
      }
      // 异步写入，不阻塞调用方
      this.fileManager.append(entry).catch((e: Error | object) => {
        Logger.error('ApiLogSystem', 'async append failed: ' + String(e));
      });
    } catch (e) {
      Logger.error('ApiLogSystem', 'log failed: ' + String(e));
    }
  }

  debug(tag: string, message: string, eventType?: LogEventType, extraJson?: string): void {
    const entry = new ApiLogEntry();
    entry.level = LogLevel.DEBUG;
    entry.eventType = eventType ?? LogEventType.GENERAL;
    entry.tag = tag;
    entry.message = message;
    entry.extraJson = extraJson ?? '';
    this.log(entry);
  }

  info(tag: string, message: string, eventType?: LogEventType, extraJson?: string): void {
    const entry = new ApiLogEntry();
    entry.level = LogLevel.INFO;
    entry.eventType = eventType ?? LogEventType.GENERAL;
    entry.tag = tag;
    entry.message = message;
    entry.extraJson = extraJson ?? '';
    this.log(entry);
  }

  warning(tag: string, message: string, eventType?: LogEventType, extraJson?: string): void {
    const entry = new ApiLogEntry();
    entry.level = LogLevel.WARNING;
    entry.eventType = eventType ?? LogEventType.GENERAL;
    entry.tag = tag;
    entry.message = message;
    entry.extraJson = extraJson ?? '';
    this.log(entry);
  }

  error(tag: string, message: string, eventType?: LogEventType, extraJson?: string): void {
    const entry = new ApiLogEntry();
    entry.level = LogLevel.ERROR;
    entry.eventType = eventType ?? LogEventType.GENERAL;
    entry.tag = tag;
    entry.message = message;
    entry.extraJson = extraJson ?? '';
    this.log(entry);
  }

  getFileManager(): LogFileManager {
    return this.fileManager;
  }
}
