/**
 * WidgetLog.ets — Widget 专用日志工具
 *
 * 重要约束：
 * - Widget 运行在独立的「卡片渲染服务进程」或「FormExtension 进程」
 * - 不能导入 HSP 模块（core 是 HSP），会导致运行时崩溃
 * - 使用 hilog 替代 Logger，hilog 在 FormExtensionAbility 中可用
 *
 * 使用方式：
 * ```typescript
 * import { WidgetLog } from './WidgetLog';
 * WidgetLog.info('message');
 * WidgetLog.error('message');
 * ```
 */

import { hilog } from '@kit.PerformanceAnalysisKit';

const DOMAIN: number = 0xFF00;
const TAG: string = 'WIDGET';

/**
 * Widget 专用日志工具类
 */
export class WidgetLog {
  /**
   * 输出信息日志
   */
  static info(message: string): void {
    hilog.info(DOMAIN, TAG, message);
  }

  /**
   * 输出警告日志
   */
  static warn(message: string): void {
    hilog.warn(DOMAIN, TAG, message);
  }

  /**
   * 输出错误日志
   */
  static error(message: string): void {
    hilog.error(DOMAIN, TAG, message);
  }

  /**
   * 输出调试日志
   */
  static debug(message: string): void {
    hilog.debug(DOMAIN, TAG, message);
  }
}
