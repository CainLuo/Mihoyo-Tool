import relationalStore from '@ohos.data.relationalStore';
import common from '@ohos.app.ability.common';

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
   */
  private static async createTables(): Promise<void> {
    const store: relationalStore.RdbStore = RdbManager.getRdbStore();

    const createAccountTableSql: string = `
      CREATE TABLE IF NOT EXISTS account_table (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        username TEXT UNIQUE,
        cookie TEXT,
        is_active INTEGER DEFAULT 0,
        create_time INTEGER,
        update_time INTEGER
      );
    `;

    const createGameRoleTableSql: string = `
      CREATE TABLE IF NOT EXISTS game_role_table (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        account_id INTEGER,
        game_id TEXT,
        role_id TEXT,
        nickname TEXT,
        level INTEGER,
        server TEXT,
        FOREIGN KEY (account_id) REFERENCES account_table(id)
      );
    `;

    const createGameAssetTableSql: string = `
      CREATE TABLE IF NOT EXISTS game_asset_table (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        role_id TEXT,
        game_id TEXT,
        type TEXT,
        entity_id TEXT,
        level INTEGER,
        element TEXT,
        raw_json TEXT
      );
    `;

    try {
      await store.executeSql(createAccountTableSql, []);
      await store.executeSql(createGameRoleTableSql, []);
      await store.executeSql(createGameAssetTableSql, []);
    } catch (error) {
      throw new Error(`Create tables failed: ${RdbManager.toErrorMessage(error)}`);
    }
  }

  /**
   * 获取 RdbStore 实例
   * @returns RdbStore 实例
   */
  public static getRdbStore(): relationalStore.RdbStore {
    if (RdbManager.rdbStore === null) {
      throw new Error('RdbStore not initialized');
    }
    return RdbManager.rdbStore;
  }

  /**
   * 通用查询方法
   * @param predicates 查询条件
   * @param columns 查询列
   * @returns 查询结果
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
   * 插入数据
   * @param tableName 表名
   * @param values 数据值
   * @returns 插入的行ID
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
   * @param tableName 表名
   * @param valuesList 数据值列表
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
   * 更新数据
   * @param tableName 表名
   * @param values 数据值
   * @param predicates 更新条件
   * @returns 更新的行数
   */
  public static async update(
    _tableName: string,
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
   * 删除数据
   * @param tableName 表名
   * @param predicates 删除条件
   * @returns 删除的行数
   */
  public static async delete(
    _tableName: string,
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
   * @param sql SQL 语句
   * @param bindArgs 绑定参数
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
   * 全量替换游戏资产数据
   * @param roleId 角色ID
   * @param gameId 游戏ID
   * @param assets 资产数据列表
   */
  public static async replaceGameAssets(
    roleId: string,
    gameId: string,
    assets: Array<GameAsset>
  ): Promise<void> {
    const store: relationalStore.RdbStore = RdbManager.getRdbStore();
    await RdbManager.runInTransaction(store, 'Replace game assets', async () => {
      const deletePredicates: relationalStore.RdbPredicates = new relationalStore.RdbPredicates('game_asset_table')
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

  private static async runInTransaction(
    store: relationalStore.RdbStore,
    actionName: string,
    action: () => Promise<void>
  ): Promise<void> {
    try {
      await store.beginTransaction();
    } catch (error) {
      throw new Error(`${actionName} beginTransaction failed: ${RdbManager.toErrorMessage(error)}`);
    }

    try {
      await action();
      await store.commit();
    } catch (error) {
      const actionError: string = RdbManager.toErrorMessage(error);
      try {
        await store.rollback(0);
      } catch (rollbackError) {
        throw new Error(
          `${actionName} failed: ${actionError}; rollback failed: ${RdbManager.toErrorMessage(rollbackError)}`
        );
      }
      throw new Error(`${actionName} failed: ${actionError}`);
    }
  }

  private static toErrorMessage(error: object): string {
    if (error instanceof Error) {
      return error.message;
    }
    return `${error}`;
  }
}
