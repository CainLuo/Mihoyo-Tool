/**
 * RdbMigrationV7 — 数据库版本 7 迁移逻辑
 *
 * 版本 6 → 7：
 * - 三张养成计算表（genshin_character_compute / starrail_avatar_compute / zzz_avatar_compute）
 *   新增 target_reached 列（INTEGER DEFAULT 0）。
 *   已达成目标的角色不再删除，而是写入一行 target_reached = 1，用于在"历史记录"中保留并排在最后。
 *
 * 迁移在事务外执行，失败后下次启动会整体重跑；ALTER TABLE ADD COLUMN 不可重复执行，
 * 因此先用 PRAGMA table_info 检查列是否已存在，保证幂等。
 */

import { relationalStore } from '@kit.ArkData';
import { RdbManager } from './RdbManager';
import { TableName, ComputeStateCol } from './TableSchema';

const COMPUTE_TABLES: TableName[] = [
  TableName.GENSHIN_CHARACTER_COMPUTE,
  TableName.STARRAIL_AVATAR_COMPUTE,
  TableName.ZZZ_AVATAR_COMPUTE,
];

export class RdbMigrationV7 {
  /**
   * 执行 V6 → V7 迁移
   */
  public static async run(): Promise<void> {
    for (let i = 0; i < COMPUTE_TABLES.length; i++) {
      const table = COMPUTE_TABLES[i];
      if (await RdbMigrationV7.hasColumn(table, ComputeStateCol.TARGET_REACHED)) {
        continue;
      }
      await RdbManager.executeSql(
        `ALTER TABLE ${table} ADD COLUMN ${ComputeStateCol.TARGET_REACHED} INTEGER DEFAULT 0`, []);
    }
  }

  /** 查询表中是否已有指定列 */
  private static async hasColumn(table: TableName, column: string): Promise<boolean> {
    const store: relationalStore.RdbStore = RdbManager.getRdbStore();
    const rs: relationalStore.ResultSet = await store.querySql(`PRAGMA table_info(${table})`, []);
    try {
      const nameIdx = rs.getColumnIndex('name');
      while (rs.goToNextRow()) {
        if (rs.getValue(nameIdx) === column) {
          return true;
        }
      }
      return false;
    } finally {
      rs.close();
    }
  }
}
