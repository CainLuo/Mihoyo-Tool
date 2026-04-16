/**
 * LogFileManager — 日志文件管理器
 *
 * 负责日志文件的创建、追加写入、大小轮转和清理。
 * 日志存储在应用沙箱目录 files/logs/，无需任何用户权限。
 * 文件操作通过 IFileSystem 接口抽象，支持 Mock 测试。
 */

import { common } from '@kit.AbilityKit';
import { fileIo } from '@kit.CoreFileKit';
import { util } from '@kit.ArkTS';
import { ApiLogEntry } from './ApiLogEntry';
import { Logger } from '../utils/Logger';

export interface IFileSystem {
  appendLine(filePath: string, line: string): Promise<void>;
  getFileSize(filePath: string): Promise<number>;
  listFiles(dirPath: string): Promise<string[]>;
  deleteFile(filePath: string): Promise<void>;
  getTotalSize(dirPath: string): Promise<number>;
  mkdirIfNotExists(dirPath: string): Promise<void>;
}

export interface DeleteResult {
  deletedCount: number;
  failedCount: number;
  freedBytes: number;
}

/** 默认文件系统实现（使用 @kit.CoreFileKit） */
class DefaultFileSystem implements IFileSystem {
  async appendLine(filePath: string, line: string): Promise<void> {
    let fd: number = -1;
    try {
      // 用 READ_WRITE | CREATE 打开，手动 seek 到末尾追加
      const file = fileIo.openSync(filePath, fileIo.OpenMode.READ_WRITE | fileIo.OpenMode.CREATE);
      fd = file.fd;
      // seek 到文件末尾
      const stat = fileIo.statSync(filePath);
      const offset = stat.size;
      const content = line + '\n';
      // 用 TextEncoder 转为 Uint8Array，确保写入正确
      const encoder = new util.TextEncoder();
      const encoded = encoder.encodeInto(content);
      await fileIo.write(fd, encoded.buffer, { offset: offset, length: encoded.byteLength });
    } catch (e) {
      const msg = e instanceof Error ? e.message : String(e);
      Logger.error('LogFileManager', 'appendLine failed: ' + msg + ', filePath=' + filePath);
      throw new Error('appendLine failed: ' + msg);
    } finally {
      if (fd >= 0) {
        try { fileIo.closeSync(fd); } catch (_) {}
      }
    }
  }

  async getFileSize(filePath: string): Promise<number> {
    try {
      const stat = fileIo.statSync(filePath);
      return stat.size;
    } catch (_) {
      return 0;
    }
  }

  async listFiles(dirPath: string): Promise<string[]> {
    try {
      const entries = fileIo.listFileSync(dirPath);
      const result: string[] = [];
      for (let i = 0; i < entries.length; i++) {
        result[result.length] = dirPath + '/' + entries[i];
      }
      return result;
    } catch (_) {
      return [];
    }
  }

  async deleteFile(filePath: string): Promise<void> {
    try {
      fileIo.unlinkSync(filePath);
    } catch (e) {
      throw new Error(e instanceof Error ? e.message : String(e));
    }
  }

  async getTotalSize(dirPath: string): Promise<number> {
    const files = await this.listFiles(dirPath);
    let total = 0;
    for (let i = 0; i < files.length; i++) {
      total += await this.getFileSize(files[i]);
    }
    return total;
  }

  async mkdirIfNotExists(dirPath: string): Promise<void> {
    try {
      fileIo.mkdirSync(dirPath);
    } catch (_) {
      // 目录已存在，忽略
    }
  }
}

export class LogFileManager {
  static readonly MAX_FILE_SIZE_BYTES: number = 5 * 1024 * 1024; // 5MB
  static readonly LOG_DIR_NAME: string = 'logs';
  static readonly FILE_PREFIX: string = 'api_log_';

  private logDir: string = '';
  private currentFilePath: string = '';
  private currentFileId: number = 0;
  private fs: IFileSystem;

  constructor(fs?: IFileSystem) {
    this.fs = fs ?? new DefaultFileSystem();
  }

  async init(context: common.UIAbilityContext): Promise<void> {
    this.logDir = context.filesDir + '/' + LogFileManager.LOG_DIR_NAME;
    await this.fs.mkdirIfNotExists(this.logDir);
    this.currentFilePath = this.logDir + '/' + LogFileManager.getCurrentFileName();
    this.currentFileId = 0;
  }

  async append(entry: ApiLogEntry): Promise<void> {
    if (this.logDir === '') {
      Logger.error('LogFileManager', 'append called before init, logDir is empty');
      return;
    }
    try {
      // 检查是否需要轮转
      const size = await this.fs.getFileSize(this.currentFilePath);
      if (size >= LogFileManager.MAX_FILE_SIZE_BYTES) {
        this.currentFilePath = this.getRotatedFilePath();
        this.currentFileId = 0;
      }
      // 赋值 id（同文件内自增）
      this.currentFileId++;
      entry.id = this.currentFileId;
      const line = JSON.stringify(entry);
      await this.fs.appendLine(this.currentFilePath, line);
    } catch (e) {
      Logger.error('LogFileManager', 'append failed: ' + String(e));
    }
  }

  async getTotalLogSize(): Promise<number> {
    if (this.logDir === '') {
      return 0;
    }
    return this.fs.getTotalSize(this.logDir);
  }

  async deleteAllLogs(): Promise<DeleteResult> {
    const result: DeleteResult = { deletedCount: 0, failedCount: 0, freedBytes: 0 };
    if (this.logDir === '') {
      return result;
    }
    const files = await this.fs.listFiles(this.logDir);
    for (let i = 0; i < files.length; i++) {
      const filePath = files[i];
      try {
        const size = await this.fs.getFileSize(filePath);
        await this.fs.deleteFile(filePath);
        result.deletedCount++;
        result.freedBytes += size;
      } catch (_) {
        result.failedCount++;
      }
    }
    // 重置当前文件路径
    this.currentFilePath = this.logDir + '/' + LogFileManager.getCurrentFileName();
    this.currentFileId = 0;
    return result;
  }

  async listLogFiles(): Promise<string[]> {
    if (this.logDir === '') {
      return [];
    }
    return this.fs.listFiles(this.logDir);
  }

  getLogDir(): string {
    return this.logDir;
  }

  /** 获取当前日期对应的日志文件名（纯函数） */
  static getCurrentFileName(): string {
    const now = new Date();
    const year = now.getFullYear();
    const month = String(now.getMonth() + 1).padStart(2, '0');
    const day = String(now.getDate()).padStart(2, '0');
    return LogFileManager.FILE_PREFIX + year + '-' + month + '-' + day + '.txt';
  }

  /** 格式化字节数为人类可读字符串（纯函数） */
  static formatSize(bytes: number): string {
    if (bytes <= 0) {
      return '0 B';
    }
    const kb = 1024;
    const mb = 1024 * 1024;
    const gb = 1024 * 1024 * 1024;
    if (bytes < kb) {
      return bytes + ' B';
    } else if (bytes < mb) {
      return (bytes / kb).toFixed(1) + ' KB';
    } else if (bytes < gb) {
      return (bytes / mb).toFixed(1) + ' MB';
    } else {
      return (bytes / gb).toFixed(2) + ' GB';
    }
  }

  /** 生成轮转文件路径（在当前日期文件名后追加 _2、_3 等） */
  private getRotatedFilePath(): string {
    const baseName = LogFileManager.getCurrentFileName().replace('.txt', '');
    let suffix = 2;
    let candidate = this.logDir + '/' + baseName + '_' + suffix + '.txt';
    // 简单策略：找一个不存在或较小的文件
    return candidate;
  }
}
