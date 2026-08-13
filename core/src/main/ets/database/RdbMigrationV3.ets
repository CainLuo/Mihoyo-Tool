/**
 * RdbMigrationV3 — 数据库版本 3 迁移逻辑
 *
 * 版本 2 → 3：
 * 1. 为 Compute 表添加 raw_json 列
 * 2. 创建 material_bag 分表（三张独立表，按游戏分离）
 * 3. 创建 material_target_config 表（三张独立表，存储养成目标配置）
 */

import { RdbManager } from './RdbManager';

export class RdbMigrationV3 {
  /**
   * 执行 V2 → V3 迁移
   */
  public static async run(): Promise<void> {
    // 1. 为三张 Compute 表添加 raw_json 列
    await RdbManager.executeSql(
      'ALTER TABLE genshin_character_compute ADD COLUMN raw_json TEXT DEFAULT \'\'',
      []
    );
    await RdbManager.executeSql(
      'ALTER TABLE starrail_avatar_compute ADD COLUMN raw_json TEXT DEFAULT \'\'',
      []
    );
    await RdbManager.executeSql(
      'ALTER TABLE zzz_avatar_compute ADD COLUMN raw_json TEXT DEFAULT \'\'',
      []
    );

    // 2. 创建 material_bag 分表（三张独立表）
    // 原神材料背包表
    await RdbManager.executeSql(
      `CREATE TABLE IF NOT EXISTS genshin_material_bag (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        account_id TEXT NOT NULL,
        role_uid TEXT NOT NULL,
        material_id TEXT NOT NULL,
        material_name TEXT NOT NULL,
        material_icon TEXT DEFAULT '',
        rarity TEXT DEFAULT '',
        count INTEGER DEFAULT 0,
        source TEXT DEFAULT 'api',
        update_time INTEGER,
        FOREIGN KEY (account_id) REFERENCES account_table(uid) ON DELETE CASCADE
      )`,
      []
    );
    // 星穹铁道材料背包表
    await RdbManager.executeSql(
      `CREATE TABLE IF NOT EXISTS starrail_material_bag (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        account_id TEXT NOT NULL,
        role_uid TEXT NOT NULL,
        material_id TEXT NOT NULL,
        material_name TEXT NOT NULL,
        material_icon TEXT DEFAULT '',
        rarity TEXT DEFAULT '',
        count INTEGER DEFAULT 0,
        source TEXT DEFAULT 'api',
        update_time INTEGER,
        FOREIGN KEY (account_id) REFERENCES account_table(uid) ON DELETE CASCADE
      )`,
      []
    );
    // 绝区零材料背包表
    await RdbManager.executeSql(
      `CREATE TABLE IF NOT EXISTS zzz_material_bag (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        account_id TEXT NOT NULL,
        role_uid TEXT NOT NULL,
        material_id TEXT NOT NULL,
        material_name TEXT NOT NULL,
        material_icon TEXT DEFAULT '',
        rarity TEXT DEFAULT '',
        count INTEGER DEFAULT 0,
        source TEXT DEFAULT 'api',
        update_time INTEGER,
        FOREIGN KEY (account_id) REFERENCES account_table(uid) ON DELETE CASCADE
      )`,
      []
    );
    // 创建三张材料背包表的唯一索引
    await RdbManager.executeSql(
      'CREATE UNIQUE INDEX IF NOT EXISTS idx_genshin_material_bag_unique ON genshin_material_bag(account_id, role_uid, material_id)',
      []
    );
    await RdbManager.executeSql(
      'CREATE UNIQUE INDEX IF NOT EXISTS idx_starrail_material_bag_unique ON starrail_material_bag(account_id, role_uid, material_id)',
      []
    );
    await RdbManager.executeSql(
      'CREATE UNIQUE INDEX IF NOT EXISTS idx_zzz_material_bag_unique ON zzz_material_bag(account_id, role_uid, material_id)',
      []
    );

    // 3. 创建 material_target_config 表（三张独立表）
    // 原神养成目标配置表
    await RdbManager.executeSql(
      `CREATE TABLE IF NOT EXISTS genshin_material_target_config (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        account_id TEXT NOT NULL,
        role_uid TEXT NOT NULL,
        config_json TEXT DEFAULT '',
        update_time INTEGER,
        FOREIGN KEY (account_id) REFERENCES account_table(uid) ON DELETE CASCADE
      )`,
      []
    );
    // 星穹铁道养成目标配置表
    await RdbManager.executeSql(
      `CREATE TABLE IF NOT EXISTS starrail_material_target_config (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        account_id TEXT NOT NULL,
        role_uid TEXT NOT NULL,
        config_json TEXT DEFAULT '',
        update_time INTEGER,
        FOREIGN KEY (account_id) REFERENCES account_table(uid) ON DELETE CASCADE
      )`,
      []
    );
    // 绝区零养成目标配置表
    await RdbManager.executeSql(
      `CREATE TABLE IF NOT EXISTS zzz_material_target_config (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        account_id TEXT NOT NULL,
        role_uid TEXT NOT NULL,
        config_json TEXT DEFAULT '',
        update_time INTEGER,
        FOREIGN KEY (account_id) REFERENCES account_table(uid) ON DELETE CASCADE
      )`,
      []
    );
    // 创建三张配置表的唯一索引
    await RdbManager.executeSql(
      'CREATE UNIQUE INDEX IF NOT EXISTS idx_genshin_material_target_config_unique ON genshin_material_target_config(account_id, role_uid)',
      []
    );
    await RdbManager.executeSql(
      'CREATE UNIQUE INDEX IF NOT EXISTS idx_starrail_material_target_config_unique ON starrail_material_target_config(account_id, role_uid)',
      []
    );
    await RdbManager.executeSql(
      'CREATE UNIQUE INDEX IF NOT EXISTS idx_zzz_material_target_config_unique ON zzz_material_target_config(account_id, role_uid)',
      []
    );

    // 4. 删除旧的 material_bag 表（如果存在）
    // 旧表数据不迁移，用户重新同步即可
    await RdbManager.executeSql('DROP TABLE IF EXISTS material_bag', []);
  }
}
