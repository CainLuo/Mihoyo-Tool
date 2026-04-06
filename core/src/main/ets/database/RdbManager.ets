import { relationalStore } from '@kit.ArkData';
import { common } from '@kit.AbilityKit';
import { ALL_TABLES, ALL_INDEXES, TableName } from './TableSchema';

/**
 * 数据库管理器 V2
 * 全新 V1.0 架构，15 张专用表，SecurityLevel.S2 加密
 */
export class RdbManager {
  private static rdbStore: relationalStore.RdbStore | null = null;
  private static readonly DB_NAME: string = 'mihoyo_tool_v2.db';
  private static readonly DB_VERSION: number = 1;

  /**
   * 初始化数据库，使用 SecurityLevel.S2 加密
   * 初始化后执行 PRAGMA foreign_keys = ON 并运行迁移
   */
  public static async init(context: common.UIAbilityContext): Promise<void> {
    if (RdbManager.rdbStore !== null) {
      return;
    }
    const storeConfig: relationalStore.StoreConfig = {
      name: RdbManager.DB_NAME,
      securityLevel: relationalStore.SecurityLevel.S2
    };
    try {
      RdbManager.rdbStore = await relationalStore.getRdbStore(context, storeConfig);
      await RdbManager.executeSqlInternal('PRAGMA foreign_keys = ON', []);
      await RdbManager.runMigrations();
    } catch (error) {
      throw new Error(`RdbManager init failed: ${RdbManager.toErrorMessage(error)}`);
    }
  }

  /**
   * 获取 RdbStore 实例（内部使用）
   */
  public static getRdbStore(): relationalStore.RdbStore {
    if (RdbManager.rdbStore === null) {
      throw new Error('RdbManager: RdbStore not initialized');
    }
    return RdbManager.rdbStore;
  }

  /**
   * 在事务中执行操作，失败时自动回滚
   * beginTransaction / commit / rollBack 均为同步 API，不可 await
   */
  public static async runInTransaction(fn: () => Promise<void>): Promise<void> {
    const store: relationalStore.RdbStore = RdbManager.getRdbStore();
    try {
      store.beginTransaction();
    } catch (error) {
      throw new Error(`beginTransaction failed: ${RdbManager.toErrorMessage(error)}`);
    }

    try {
      await fn();
      store.commit();
    } catch (error) {
      const actionError: string = RdbManager.toErrorMessage(error);
      try {
        store.rollBack();
      } catch (rollbackError) {
        throw new Error(
          `Transaction failed: ${actionError}; rollBack also failed: ${RdbManager.toErrorMessage(rollbackError)}`
        );
      }
      throw new Error(`Transaction failed: ${actionError}`);
    }
  }

  /**
   * 检查 user_version，首次安装时建全部 15 张表并设 user_version=1
   */
  private static async runMigrations(): Promise<void> {
    const store: relationalStore.RdbStore = RdbManager.getRdbStore();

    // 查询当前 user_version
    let currentVersion: number = 0;
    try {
      const rs: relationalStore.ResultSet = await store.querySql('PRAGMA user_version', []);
      try {
        if (rs.goToFirstRow()) {
          const val: relationalStore.ValueType = rs.getValue(0);
          if (typeof val === 'number') {
            currentVersion = val;
          }
        }
      } catch (readError) {
        // getValue 失败时保持 currentVersion=0，触发首次建表
      } finally {
        rs.close();
      }
    } catch (error) {
      throw new Error(`runMigrations: query user_version failed: ${RdbManager.toErrorMessage(error)}`);
    }

    if (currentVersion === 0) {
      // 首次安装：建全部 15 张表
      await RdbManager.createTables();
      await RdbManager.executeSqlInternal(`PRAGMA user_version = ${RdbManager.DB_VERSION}`, []);
    } else if (currentVersion < RdbManager.DB_VERSION) {
      // 按版本顺序执行迁移（当前版本 1 无需迁移逻辑）
      // 未来版本在此处添加 if (currentVersion < 2) { ... } 等
    }
    // currentVersion === DB_VERSION 时跳过
  }

  /**
   * 创建全部 15 张表（含索引）
   * 表结构定义在 TableSchema.ets 中，通过 buildCreateSql() 生成 DDL
   */
  private static async createTables(): Promise<void> {
    for (let i = 0; i < ALL_TABLES.length; i++) {
      await RdbManager.executeSqlInternal(ALL_TABLES[i].buildCreateSql(), []);
    }
    for (let i = 0; i < ALL_INDEXES.length; i++) {
      await RdbManager.executeSqlInternal(ALL_INDEXES[i].buildCreateSql(), []);
    }
  }

  /**
   * 执行 SQL 语句（内部使用）
   */
  private static async executeSqlInternal(
    sql: string,
    bindArgs: Array<relationalStore.ValueType>
  ): Promise<void> {
    const store: relationalStore.RdbStore = RdbManager.getRdbStore();
    await store.executeSql(sql, bindArgs);
  }

  /**
   * 执行 SQL 语句（公开接口，供 DAO 使用）
   */
  public static async executeSql(
    sql: string,
    bindArgs?: Array<relationalStore.ValueType>
  ): Promise<void> {
    try {
      await RdbManager.executeSqlInternal(sql, bindArgs ?? []);
    } catch (error) {
      throw new Error(`executeSql failed: ${RdbManager.toErrorMessage(error)}`);
    }
  }

  /**
   * 执行 INSERT OR REPLACE 写入单行数据
   * 根据表名和列名数组自动生成 SQL，避免手写字符串出错
   *
   * @param table   表名
   * @param columns 列名数组（顺序与 values 一一对应）
   * @param values  值数组（顺序与 columns 一一对应）
   */
  public static async upsertRow(
    table: TableName,
    columns: string[],
    values: Array<relationalStore.ValueType>
  ): Promise<void> {
    const placeholders: string[] = [];
    for (let i = 0; i < columns.length; i++) {
      placeholders.push('?');
    }
    const sql = `INSERT OR REPLACE INTO ${table} (${columns.join(', ')}) VALUES (${placeholders.join(', ')})`;
    try {
      await RdbManager.executeSqlInternal(sql, values);
    } catch (error) {
      throw new Error(`upsertRow(${table}) failed: ${RdbManager.toErrorMessage(error)}`);
    }
  }

  /**
   * 执行 DELETE 删除匹配条件的行
   */
  public static async deleteRows(predicates: relationalStore.RdbPredicates): Promise<void> {
    const store = RdbManager.getRdbStore();
    try {
      await store.delete(predicates);
    } catch (error) {
      throw new Error(`deleteRows failed: ${RdbManager.toErrorMessage(error)}`);
    }
  }

  /**
   * 执行 UPDATE 更新匹配条件的行
   * @param table      表名
   * @param setClauses 要更新的列名数组
   * @param setValues  对应的新值数组
   * @param whereCols  WHERE 条件列名数组（用 AND 连接）
   * @param whereVals  WHERE 条件值数组
   */
  public static async updateRows(
    table: TableName,
    setClauses: string[],
    setValues: Array<relationalStore.ValueType>,
    whereCols: string[],
    whereVals: Array<relationalStore.ValueType>
  ): Promise<void> {
    const setStr: string[] = [];
    for (let i = 0; i < setClauses.length; i++) {
      setStr.push(`${setClauses[i]} = ?`);
    }
    const whereStr: string[] = [];
    for (let i = 0; i < whereCols.length; i++) {
      whereStr.push(`${whereCols[i]} = ?`);
    }
    const sql = `UPDATE ${table} SET ${setStr.join(', ')} WHERE ${whereStr.join(' AND ')}`;
    const params: Array<relationalStore.ValueType> = [];
    for (let i = 0; i < setValues.length; i++) {
      params.push(setValues[i]);
    }
    for (let i = 0; i < whereVals.length; i++) {
      params.push(whereVals[i]);
    }
    try {
      await RdbManager.executeSqlInternal(sql, params);
    } catch (error) {
      throw new Error(`updateRows(${table}) failed: ${RdbManager.toErrorMessage(error)}`);
    }
  }

  /**
   * 查询并返回第一条记录，不存在时返回 null
   * 封装 query → goToFirstRow → mapRow → close，消除 DAO 中的 ResultSet 直接操作
   */
  public static async queryFirst<T>(
    predicates: relationalStore.RdbPredicates,
    columns: string[],
    mapRow: (rs: relationalStore.ResultSet) => T
  ): Promise<T | null> {
    const store = RdbManager.getRdbStore();
    let rs: relationalStore.ResultSet | null = null;
    try {
      rs = await store.query(predicates, columns);
      try {
        if (rs.goToFirstRow()) {
          return mapRow(rs);
        }
        return null;
      } catch (readError) {
        throw new Error(`queryFirst: read failed: ${RdbManager.toErrorMessage(readError)}`);
      }
    } catch (error) {
      throw new Error(`queryFirst failed: ${RdbManager.toErrorMessage(error)}`);
    } finally {
      if (rs !== null) {
        try { rs.close(); } catch (_) {}
      }
    }
  }

  /**
   * 查询并返回所有记录
   * 封装 query → goToNextRow 循环 → mapRow → close，消除 DAO 中的 ResultSet 直接操作
   */
  public static async queryAll<T>(
    predicates: relationalStore.RdbPredicates,
    columns: string[],
    mapRow: (rs: relationalStore.ResultSet) => T
  ): Promise<T[]> {
    const store = RdbManager.getRdbStore();
    let rs: relationalStore.ResultSet | null = null;
    try {
      rs = await store.query(predicates, columns);
      const result: T[] = [];
      try {
        while (rs.goToNextRow()) {
          result.push(mapRow(rs));
        }
      } catch (readError) {
        throw new Error(`queryAll: read failed: ${RdbManager.toErrorMessage(readError)}`);
      }
      return result;
    } catch (error) {
      throw new Error(`queryAll failed: ${RdbManager.toErrorMessage(error)}`);
    } finally {
      if (rs !== null) {
        try { rs.close(); } catch (_) {}
      }
    }
  }

  private static toErrorMessage(error: Error | object): string {
    if (error instanceof Error) {
      return error.message;
    }
    return `${error}`;
  }
}
