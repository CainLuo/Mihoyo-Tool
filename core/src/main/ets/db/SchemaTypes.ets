import { TableDef, IndexDef } from './TableSchema';

/** 单个数据库版本迁移：version 为目标版本，run 执行迁移。 */
export interface SchemaMigration {
  version: number;
  run: () => Promise<void>;
}

/** 根 SchemaRegistry 暴露给 RdbManager 的完整 schema 描述。 */
export interface SchemaRegistry {
  dbVersion: number;
  tables: TableDef[];
  indexes: IndexDef[];
  migrations: SchemaMigration[];
}
