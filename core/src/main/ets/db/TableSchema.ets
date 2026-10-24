import { TableName } from './TableName';

/**
 * 公共列名枚举 — 跨多张表复用的列名。
 * 所有 DAO 的 equalTo/getColumnIndex 调用必须使用此 enum，禁止直接写字符串。
 */
export enum CommonCol {
  /** 自增主键 */
  ID          = 'id',
  /** 关联的米游社账号 UID（外键 → account_table.uid，ON DELETE CASCADE） */
  ACCOUNT_ID  = 'account_id',
  /** 游戏角色 UID（与 game_role_table.role_id 对应） */
  ROLE_UID    = 'role_uid',
  /** 角色/代理人 ID（米游社 API 返回的 avatar_id 字段） */
  AVATAR_ID   = 'avatar_id',
  /** 原始 API 响应 JSON，完整保存以便 Parser 重新解析 */
  RAW_JSON    = 'raw_json',
  /** 数据写入时间戳（Unix 秒） */
  UPDATE_TIME = 'update_time',
  /** sync_meta 表专用：标识数据类型，值与 TableName enum 对齐 */
  DATA_TYPE   = 'data_type',
}

/**
 * 三张养成计算表（genshin_character_compute / starrail_avatar_compute / zzz_avatar_compute）共用的本地状态列（v7 新增）。
 * 不来自 API：计算时判定该角色已达到养成目标、没有请求接口，用于在历史记录中保留并标记该角色。
 */
export enum ComputeStateCol {
  /** 1 = 已达成目标（各 consume / raw_json 为空），0 = 正常计算结果 */
  TARGET_REACHED = 'target_reached',
}

/**
 * 单列定义，描述一张表中某一列的名称、SQLite 类型和约束。
 * 由 TableDef 持有，通过 buildCreateSql() 拼入 DDL。
 */
export class ColumnDef {
  /** 列名（与对应 XxxCol enum 的值保持一致） */
  name: string;
  /** SQLite 数据类型（'INTEGER' / 'TEXT' / 'REAL' / 'BLOB'） */
  type: string;
  /** 列级约束，如 'PRIMARY KEY AUTOINCREMENT'、'NOT NULL'、"DEFAULT ''"（可为空字符串） */
  constraints: string;

  /**
   * @param name        列名
   * @param type        SQLite 数据类型
   * @param constraints 列级约束（可选，默认为空字符串）
   */
  constructor(name: string, type: string, constraints: string = '') {
    this.name = name;
    this.type = type;
    this.constraints = constraints;
  }
}

/**
 * 表定义，描述一张表的名称、所有列和可选的外键约束。
 * 通过 buildCreateSql() 生成 CREATE TABLE IF NOT EXISTS DDL，
 * 通过 columnNames() 返回列名数组供 DAO 的 upsertRow/queryFirst/queryAll 使用。
 */
export class TableDef {
  /** 表名（来自 TableName enum） */
  tableName: TableName;
  /** 所有列定义，顺序与 DAO upsertRow 传入的 values 数组严格对应 */
  columns: ColumnDef[];
  /**
   * 表级外键约束字符串（可选）。
   * 示例：'FOREIGN KEY (account_id) REFERENCES account_table(uid) ON DELETE CASCADE'
   * 为空字符串时不追加外键约束。
   */
  foreignKey: string;

  /**
   * @param tableName  表名
   * @param columns    列定义数组（顺序决定 upsertRow 的 values 顺序）
   * @param foreignKey 表级外键约束（可选，默认为空字符串）
   */
  constructor(tableName: TableName, columns: ColumnDef[], foreignKey: string = '') {
    this.tableName = tableName;
    this.columns = columns;
    this.foreignKey = foreignKey;
  }

  /**
   * 生成 CREATE TABLE IF NOT EXISTS DDL 字符串。
   * 由 RdbManager.createTables() 调用，幂等（IF NOT EXISTS 保证）。
   */
  buildCreateSql(): string {
    const colDefs: string[] = [];
    for (let i = 0; i < this.columns.length; i++) {
      const col = this.columns[i];
      const def = col.constraints.length > 0
        ? `${col.name} ${col.type} ${col.constraints}`
        : `${col.name} ${col.type}`;
      colDefs.push(def);
    }
    if (this.foreignKey.length > 0) {
      colDefs.push(this.foreignKey);
    }
    return `CREATE TABLE IF NOT EXISTS ${this.tableName} (\n  ${colDefs.join(',\n  ')}\n)`;
  }

  /**
   * 返回所有列名的字符串数组。
   * DAO 的 upsertRow/queryFirst/queryAll 调用此方法获取列名列表，
   * 确保列名顺序与 upsertRow 传入的 values 数组严格一致。
   */
  columnNames(): string[] {
    const names: string[] = [];
    for (let i = 0; i < this.columns.length; i++) {
      names.push(this.columns[i].name);
    }
    return names;
  }
}

// ── 公共外键约束模板 ──────────────────────────────────────────
export const FK_ACCOUNT = 'FOREIGN KEY (account_id) REFERENCES account_table(uid) ON DELETE CASCADE';

// ── 索引定义 ─────────────────────────────────────────────────

/**
 * 单个索引定义，描述一个数据库索引的名称、所在表、列和是否唯一。
 * 通过 buildCreateSql() 生成 CREATE [UNIQUE] INDEX IF NOT EXISTS DDL。
 */
export class IndexDef {
  /** 索引名称（全局唯一，命名规范：idx_{表名缩写}_{用途}） */
  indexName: string;
  /** 索引所在的表（来自 TableName enum） */
  tableName: TableName;
  /** 参与索引的列名数组（复合索引时顺序影响查询效率） */
  columns: string[];
  /**
   * 是否为唯一索引。
   * true = UNIQUE INDEX，用于实现业务唯一键约束（如 account_id+role_uid+avatar_id）；
   * false = 普通索引，用于加速查询（如按 element/rarity 过滤）。
   */
  unique: boolean;

  /**
   * @param indexName 索引名称
   * @param tableName 所在表
   * @param columns   参与索引的列名数组
   * @param unique    是否唯一索引（默认 false）
   */
  constructor(indexName: string, tableName: TableName, columns: string[], unique: boolean = false) {
    this.indexName = indexName;
    this.tableName = tableName;
    this.columns = columns;
    this.unique = unique;
  }

  /**
   * 生成 CREATE [UNIQUE] INDEX IF NOT EXISTS DDL 字符串。
   * 由 RdbManager.createTables() 调用，幂等（IF NOT EXISTS 保证）。
   */
  buildCreateSql(): string {
    const uniqueStr = this.unique ? 'UNIQUE ' : '';
    return `CREATE ${uniqueStr}INDEX IF NOT EXISTS ${this.indexName} ON ${this.tableName}(${this.columns.join(', ')})`;
  }
}
