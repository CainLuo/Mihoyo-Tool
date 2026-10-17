/**
 * RdbMigrationV2 — 数据库版本 2 迁移逻辑
 *
 * 版本 1 → 2：
 * - 为 zzz_daily_note 表添加 widget_raw_json 列
 */

import { RdbManager } from './RdbManager';

export class RdbMigrationV2 {
  /**
   * 执行 V1 → V2 迁移
   */
  public static async run(): Promise<void> {
    // 为 zzz_daily_note 添加 widget_raw_json 列
    await RdbManager.executeSql(
      'ALTER TABLE zzz_daily_note ADD COLUMN widget_raw_json TEXT DEFAULT \'\'',
      []
    );
  }
}
