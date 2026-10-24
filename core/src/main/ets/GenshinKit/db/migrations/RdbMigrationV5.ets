/**
 * RdbMigrationV5 — 数据库版本 5 迁移逻辑
 *
 * 版本 4 → 5：
 * - 新建 genshin_compute_summary（batch_compute 顶层整批合计，字段与 API 一致），
 *   用于材料汇总视图展示精确的总缺口（data.overall_consume）。
 *
 * 迁移在事务外执行，失败后下次启动会整体重跑，每一步必须幂等（IF NOT EXISTS）。
 */

import { RdbManager } from '../../../db/RdbManager';
import { TableName } from '../../../db/TableName';
import { GENSHIN_COMPUTE_SUMMARY_TABLE, GENSHIN_INDEXES } from '../schema';

export class RdbMigrationV5 {
  /**
   * 执行 V4 → V5 迁移
   */
  public static async run(): Promise<void> {
    await RdbManager.executeSql(GENSHIN_COMPUTE_SUMMARY_TABLE.buildCreateSql(), []);
    for (let i = 0; i < GENSHIN_INDEXES.length; i++) {
      if (GENSHIN_INDEXES[i].tableName === TableName.GENSHIN_COMPUTE_SUMMARY) {
        await RdbManager.executeSql(GENSHIN_INDEXES[i].buildCreateSql(), []);
      }
    }
  }
}
