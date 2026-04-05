/**
 * SyncDataType — sync_meta 表的 data_type 字段枚举
 *
 * 值与 TableName 完全对齐（sync_meta.data_type 存储的就是对应的表名字符串）。
 * 通过重新导出 TableName 消除重复字符串定义，同时保留 SyncDataType 语义。
 */
export { TableName as SyncDataType } from '../database/v2/TableSchema';
