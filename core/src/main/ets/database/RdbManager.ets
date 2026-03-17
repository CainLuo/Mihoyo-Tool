import { relationalStore } from '@kit.ArkData';
import { common } from '@kit.AbilityKit';

/**
 * 游戏资产接口
 */
interface GameAsset {
  type: string;
  entityId: string;
  level: number;
  element: string;
  rawJson: string;
}

/**
 * 数据库管理器
 * 负责数据库的初始化、建表和基本操作
 */
export class RdbManager {
  private static rdbStore: relationalStore.RdbStore | null = null;
  private static readonly DB_NAME: string = 'mihoyo_tool.db';

  /**
   * 初始化数据库
   * @param context 能力上下文
   */
  public static async init(context: common.UIAbilityContext): Promise<void> {
    if (RdbManager.rdbStore !== null) {
      return;
    }
    const storeConfig: relationalStore.StoreConfig = {
      name: RdbManager.DB_NAME,
      securityLevel: relationalStore.SecurityLevel.S1
    };
    try {
      RdbManager.rdbStore = await relationalStore.getRdbStore(context, storeConfig);
      await RdbManager.createTables();
    } catch (error) {
      throw new Error(`Rdb init failed: ${RdbManager.toErrorMessage(error)}`);
    }
  }

  /**
   * 创建数据表
   * 表结构详见 .kiro/steering/database-architecture.md
   */
  private static async createTables(): Promise<void> {
    const store: relationalStore.RdbStore = RdbManager.getRdbStore();

    // ── 账号表 ──────────────────────────────────────────────────
    const createAccountTableSql: string = `
      CREATE TABLE IF NOT EXISTS account_table (
        id          INTEGER PRIMARY KEY AUTOINCREMENT,
        username    TEXT UNIQUE,
        cookie      TEXT,
        is_active   INTEGER DEFAULT 0,
        create_time INTEGER,
        update_time INTEGER
      );
    `;

    // ── 游戏角色表（各游戏 UID）──────────────────────────────────
    const createGameRoleTableSql: string = `
      CREATE TABLE IF NOT EXISTS game_role_table (
        id         INTEGER PRIMARY KEY AUTOINCREMENT,
        account_id INTEGER,
        game_id    TEXT,
        role_id    TEXT,
        nickname   TEXT,
        level      INTEGER,
        server     TEXT,
        FOREIGN KEY (account_id) REFERENCES account_table(id)
      );
    `;

    // ── 核心数据表：所有游戏所有数据类型 ────────────────────────
    // data_type 枚举：character / weapon / relic / activity /
    //                 gacha_record / gacha_summary / daily_note / abyss
    // extra_int1/extra_int2/extra_text1 语义由 data_type 决定，详见架构文档
    const createGameDataTableSql: string = `
      CREATE TABLE IF NOT EXISTS game_data (
        id          INTEGER PRIMARY KEY AUTOINCREMENT,
        game_id     TEXT    NOT NULL,
        role_uid    TEXT    NOT NULL,
        data_type   TEXT    NOT NULL,
        entity_id   TEXT    NOT NULL,
        name        TEXT,
        rarity      INTEGER,
        level       INTEGER,
        extra_int1  INTEGER,
        extra_int2  INTEGER,
        extra_text1 TEXT,
        raw_json    TEXT    NOT NULL,
        update_time INTEGER
      );
    `;
    // 唯一索引：防止重复写入
    const createGameDataUniqueIdxSql: string = `
      CREATE UNIQUE INDEX IF NOT EXISTS idx_game_data_unique
        ON game_data(game_id, role_uid, data_type, entity_id);
    `;
    // 查询索引：按游戏+用户+类型批量查
    const createGameDataQueryIdxSql: string = `
      CREATE INDEX IF NOT EXISTS idx_game_data_query
        ON game_data(game_id, role_uid, data_type);
    `;
    // 活动索引：按结束时间过滤未结束活动
    const createGameDataActivityIdxSql: string = `
      CREATE INDEX IF NOT EXISTS idx_game_data_activity
        ON game_data(game_id, data_type, extra_int2);
    `;

    // ── 统计结果表：预计算，供统计页直接查询 ────────────────────
    // stat_key 枚举：relic_score / is_graduated / crit_rate /
    //                crit_dmg / pity_count / up_pity_count
    const createGameStatsTableSql: string = `
      CREATE TABLE IF NOT EXISTS game_stats (
        id          INTEGER PRIMARY KEY AUTOINCREMENT,
        game_id     TEXT NOT NULL,
        role_uid    TEXT NOT NULL,
        entity_id   TEXT NOT NULL,
        stat_key    TEXT NOT NULL,
        stat_value  REAL,
        update_time INTEGER
      );
    `;
    const createGameStatsUniqueIdxSql: string = `
      CREATE UNIQUE INDEX IF NOT EXISTS idx_game_stats_unique
        ON game_stats(game_id, role_uid, entity_id, stat_key);
    `;

    // ── 同步状态表：追踪每种数据的最后同步时间和状态 ────────────
    const createSyncMetaTableSql: string = `
      CREATE TABLE IF NOT EXISTS sync_meta (
        id             INTEGER PRIMARY KEY AUTOINCREMENT,
        game_id        TEXT NOT NULL,
        role_uid       TEXT NOT NULL,
        data_type      TEXT NOT NULL,
        last_sync_time INTEGER,
        sync_status    TEXT,
        error_msg      TEXT
      );
    `;
    const createSyncMetaUniqueIdxSql: string = `
      CREATE UNIQUE INDEX IF NOT EXISTS idx_sync_meta_unique
        ON sync_meta(game_id, role_uid, data_type);
    `;

    try {
      await store.executeSql(createAccountTableSql, []);
      await store.executeSql(createGameRoleTableSql, []);
      await store.executeSql(createGameDataTableSql, []);
      await store.executeSql(createGameDataUniqueIdxSql, []);
      await store.executeSql(createGameDataQueryIdxSql, []);
      await store.executeSql(createGameDataActivityIdxSql, []);
      await store.executeSql(createGameStatsTableSql, []);
      await store.executeSql(createGameStatsUniqueIdxSql, []);
      await store.executeSql(createSyncMetaTableSql, []);
      await store.executeSql(createSyncMetaUniqueIdxSql, []);
    } catch (error) {
      throw new Error(`Create tables failed: ${RdbManager.toErrorMessage(error)}`);
    }
  }

  /**
   * 获取 RdbStore 实例
   */
  public static getRdbStore(): relationalStore.RdbStore {
    if (RdbManager.rdbStore === null) {
      throw new Error('RdbStore not initialized');
    }
    return RdbManager.rdbStore;
  }

  /**
   * 通用查询方法
   */
  public static async query(
    predicates: relationalStore.RdbPredicates,
    columns?: string[]
  ): Promise<relationalStore.ResultSet> {
    const store: relationalStore.RdbStore = RdbManager.getRdbStore();
    try {
      return await store.query(predicates, columns);
    } catch (error) {
      throw new Error(`Query failed: ${RdbManager.toErrorMessage(error)}`);
    }
  }

  /**
   * 插入数据，返回插入的行 ID
   */
  public static async insert(
    tableName: string,
    values: relationalStore.ValuesBucket
  ): Promise<number> {
    const store: relationalStore.RdbStore = RdbManager.getRdbStore();
    try {
      return await store.insert(tableName, values);
    } catch (error) {
      throw new Error(`Insert failed: ${RdbManager.toErrorMessage(error)}`);
    }
  }

  /**
   * 批量插入数据
   */
  public static async batchInsert(
    tableName: string,
    valuesList: relationalStore.ValuesBucket[]
  ): Promise<void> {
    const store: relationalStore.RdbStore = RdbManager.getRdbStore();
    await RdbManager.runInTransaction(store, 'Batch insert', async () => {
      for (const values of valuesList) {
        await store.insert(tableName, values);
      }
    });
  }

  /**
   * 更新数据，返回更新的行数
   * @param predicates 更新条件（表名已在 RdbPredicates 构造时绑定）
   */
  public static async update(
    values: relationalStore.ValuesBucket,
    predicates: relationalStore.RdbPredicates
  ): Promise<number> {
    const store: relationalStore.RdbStore = RdbManager.getRdbStore();
    try {
      return await store.update(values, predicates);
    } catch (error) {
      throw new Error(`Update failed: ${RdbManager.toErrorMessage(error)}`);
    }
  }

  /**
   * 删除数据，返回删除的行数
   * @param predicates 删除条件（表名已在 RdbPredicates 构造时绑定）
   */
  public static async delete(
    predicates: relationalStore.RdbPredicates
  ): Promise<number> {
    const store: relationalStore.RdbStore = RdbManager.getRdbStore();
    try {
      return await store.delete(predicates);
    } catch (error) {
      throw new Error(`Delete failed: ${RdbManager.toErrorMessage(error)}`);
    }
  }

  /**
   * 执行 SQL 语句
   */
  public static async executeSql(
    sql: string,
    bindArgs?: Array<string | number | boolean | null>
  ): Promise<void> {
    const store: relationalStore.RdbStore = RdbManager.getRdbStore();
    try {
      await store.executeSql(sql, bindArgs ?? []);
    } catch (error) {
      throw new Error(`Execute SQL failed: ${RdbManager.toErrorMessage(error)}`);
    }
  }

  /**
   * 全量替换游戏资产数据（先删后插，在事务中执行）
   */
  public static async replaceGameAssets(
    roleId: string,
    gameId: string,
    assets: Array<GameAsset>
  ): Promise<void> {
    const store: relationalStore.RdbStore = RdbManager.getRdbStore();
    await RdbManager.runInTransaction(store, 'Replace game assets', async () => {
      const deletePredicates: relationalStore.RdbPredicates =
        new relationalStore.RdbPredicates('game_asset_table')
          .equalTo('role_id', roleId)
          .equalTo('game_id', gameId);
      await store.delete(deletePredicates);

      for (const asset of assets) {
        const values: relationalStore.ValuesBucket = {
          'role_id': roleId,
          'game_id': gameId,
          'type': asset.type,
          'entity_id': asset.entityId,
          'level': asset.level,
          'element': asset.element,
          'raw_json': asset.rawJson
        };
        await store.insert('game_asset_table', values);
      }
    });
  }

  /**
   * 在事务中执行操作。
   * beginTransaction / commit / rollBack 均为同步 API，不可 await。
   */
  private static async runInTransaction(
    store: relationalStore.RdbStore,
    actionName: string,
    action: () => Promise<void>
  ): Promise<void> {
    try {
      store.beginTransaction();
    } catch (error) {
      throw new Error(`${actionName} beginTransaction failed: ${RdbManager.toErrorMessage(error)}`);
    }

    try {
      await action();
      store.commit();
    } catch (error) {
      const actionError: string = RdbManager.toErrorMessage(error);
      try {
        store.rollBack();
      } catch (rollbackError) {
        throw new Error(
          `${actionName} failed: ${actionError}; rollBack failed: ${RdbManager.toErrorMessage(rollbackError)}`
        );
      }
      throw new Error(`${actionName} failed: ${actionError}`);
    }
  }

  private static toErrorMessage(error: Error | object): string {
    if (error instanceof Error) {
      return error.message;
    }
    return `${error}`;
  }
}
