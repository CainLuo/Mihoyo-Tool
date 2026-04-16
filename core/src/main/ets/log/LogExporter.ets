/**
 * LogExporter — 日志导出器
 *
 * 将所有日志文件打包为 ZIP，通过 DocumentViewPicker.save() 让用户选择保存位置。
 * 导出文件名格式：mihoyo_tool_log_<version>_<timestamp>.zip
 * 无需任何权限，DocumentViewPicker 由用户主动触发授权。
 */

import { common } from '@kit.AbilityKit';
import { zlib } from '@kit.BasicServicesKit';
import { fileIo, picker } from '@kit.CoreFileKit';
import { ApiLogSystem } from './ApiLogSystem';
import { Logger } from '../utils/Logger';

export class LogExporter {
  /**
   * 导出所有日志文件为 ZIP，通过系统文件管理器让用户选择保存位置。
   * @param context UIAbilityContext
   * @param appVersion 应用版本号（由调用方传入，避免 core 依赖 entry BuildProfile）
   * @returns true 表示导出成功，false 表示用户取消，抛出异常表示失败
   */
  static async export(context: common.UIAbilityContext, appVersion: string = '1.0.0'): Promise<boolean> {
    let tempZipPath = '';
    try {
      const fileManager = ApiLogSystem.getInstance().getFileManager();
      const logFiles = await fileManager.listLogFiles();

      if (logFiles.length === 0) {
        Logger.info('LogExporter', 'No log files to export');
        return false;
      }

      // 生成导出文件名
      const timestamp = Date.now();
      const zipName = 'mihoyo_tool_log_' + appVersion + '_' + timestamp + '.zip';
      tempZipPath = context.cacheDir + '/' + zipName;

      // 打包为 ZIP（将日志目录整体压缩）
      const logDir = fileManager.getLogDir();
      const options: zlib.Options = {
        level: zlib.CompressLevel.COMPRESS_LEVEL_DEFAULT_COMPRESSION,
      };
      await zlib.compressFile(logDir, tempZipPath, options);

      // 通过 DocumentViewPicker 让用户选择保存位置
      const documentPicker = new picker.DocumentViewPicker(context);
      const saveOptions = new picker.DocumentSaveOptions();
      saveOptions.newFileNames = [zipName];
      saveOptions.fileSuffixChoices = ['.zip'];

      const saveResult = await documentPicker.save(saveOptions);
      if (saveResult === null || saveResult.length === 0) {
        // 用户取消，静默处理
        Logger.info('LogExporter', 'User cancelled export');
        return false;
      }

      // 将临时 ZIP 写入用户选择的位置
      const destUri = saveResult[0];
      const destFile = fileIo.openSync(destUri, fileIo.OpenMode.WRITE_ONLY | fileIo.OpenMode.CREATE);
      const srcFile = fileIo.openSync(tempZipPath, fileIo.OpenMode.READ_ONLY);
      try {
        fileIo.copyFileSync(srcFile.fd, destFile.fd);
      } finally {
        fileIo.closeSync(srcFile);
        fileIo.closeSync(destFile);
      }

      Logger.info('LogExporter', 'Export completed: ' + destUri);
      return true;
    } catch (e) {
      const msg = e instanceof Error ? e.message : String(e);
      Logger.error('LogExporter', 'Export failed: ' + msg);
      throw new Error('Export failed: ' + msg);
    } finally {
      // 清理临时 ZIP
      if (tempZipPath !== '') {
        try {
          fileIo.unlinkSync(tempZipPath);
        } catch (_) {}
      }
    }
  }
}
