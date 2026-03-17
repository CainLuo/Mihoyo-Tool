/**
 * QueryBuilder.ets
 *
 * 链式 Query Builder，将业务语义的链式调用翻译为 RdbPredicates。
 * 业务代码完全不接触 SQL 字符串，所有查询逻辑集中在此文件。
 *
 * 使用示例：
 *   const rows = await new QueryBuilder('game_data')
 *     .equalTo('game_id', 'genshin')
 *     .equalTo('role_uid', '123456789')
 *     .equalTo('data_type', 'character')
 *     .greaterThanOrEqualTo('rarity', 5)
 *     .orderByDesc('level')
 *     .limit(20)
 *     .build();
 */

import { relationalStore } from '@kit.ArkData';

/**
 * 排序方向
 */
export type OrderDirection = 'ASC' | 'DESC';

/**
 * 链式 Query Builder
 * 封装 RdbPredicates，提供类型安全的链式 API
 */
export class QueryBuilder {
  /** 内部持有的 RdbPredicates 实例 */
  private readonly predicates: relationalStore.RdbPredicates;
  /** 查询列列表，空数组表示查询所有列 */
  private selectedColumns: string[] = [];

  /**
   * @param tableName 目标表名
   */
  constructor(tableName: string) {
    this.predicates = new relationalStore.RdbPredicates(tableName);
  }

  // ─── 条件方法 ────────────────────────────────────────────────

  /**
   * 等于条件
   * @param field 列名
   * @param value 目标值
   */
  equalTo(field: string, value: string | number): QueryBuilder {
    this.predicates.equalTo(field, value);
    return this;
  }

  /**
   * 不等于条件
   */
  notEqualTo(field: string, value: string | number): QueryBuilder {
    this.predicates.notEqualTo(field, value);
    return this;
  }

  /**
   * 大于条件
   */
  greaterThan(field: string, value: number): QueryBuilder {
    this.predicates.greaterThan(field, value);
    return this;
  }

  /**
   * 大于等于条件
   */
  greaterThanOrEqualTo(field: string, value: number): QueryBuilder {
    this.predicates.greaterThanOrEqualTo(field, value);
    return this;
  }

  /**
   * 小于条件
   */
  lessThan(field: string, value: number): QueryBuilder {
    this.predicates.lessThan(field, value);
    return this;
  }

  /**
   * 小于等于条件
   */
  lessThanOrEqualTo(field: string, value: number): QueryBuilder {
    this.predicates.lessThanOrEqualTo(field, value);
    return this;
  }

  /**
   * LIKE 模糊匹配，% 为通配符
   * 例：.like('name', '%菲林%')
   */
  like(field: string, pattern: string): QueryBuilder {
    this.predicates.like(field, pattern);
    return this;
  }

  /**
   * IN 条件，匹配列表中的任意值
   * 例：.in('rarity', ['4', '5'])
   */
  in(field: string, values: string[]): QueryBuilder {
    this.predicates.in(field, values);
    return this;
  }

  /**
   * BETWEEN 范围条件（含两端）
   */
  between(field: string, low: number, high: number): QueryBuilder {
    this.predicates.between(field, low, high);
    return this;
  }

  /**
   * IS NULL 条件
   */
  isNull(field: string): QueryBuilder {
    this.predicates.isNull(field);
    return this;
  }

  /**
   * IS NOT NULL 条件
   */
  isNotNull(field: string): QueryBuilder {
    this.predicates.isNotNull(field);
    return this;
  }

  /**
   * AND 连接（默认行为，多个条件自动 AND）
   * 显式调用可提高可读性
   */
  and(): QueryBuilder {
    this.predicates.and();
    return this;
  }

  /**
   * OR 连接，将下一个条件与前一个条件用 OR 连接
   * 例：.equalTo('game_id', 'genshin').or().equalTo('game_id', 'starrail')
   */
  or(): QueryBuilder {
    this.predicates.or();
    return this;
  }

  // ─── 排序与分页 ──────────────────────────────────────────────

  /**
   * 升序排序
   * @param field 排序列名
   */
  orderByAsc(field: string): QueryBuilder {
    this.predicates.orderByAsc(field);
    return this;
  }

  /**
   * 降序排序
   * @param field 排序列名
   */
  orderByDesc(field: string): QueryBuilder {
    this.predicates.orderByDesc(field);
    return this;
  }

  /**
   * 限制返回行数（分页用）
   * @param count 最多返回的行数
   */
  limit(count: number): QueryBuilder {
    this.predicates.limitAs(count);
    return this;
  }

  /**
   * 跳过前 N 行（分页偏移）
   * @param offset 跳过的行数
   */
  offset(offset: number): QueryBuilder {
    this.predicates.offsetAs(offset);
    return this;
  }

  // ─── 列选择 ──────────────────────────────────────────────────

  /**
   * 指定查询列，不调用则查询所有列
   * 列表页建议只查通用列，不查 raw_json，可显著提升性能
   *
   * @param columns 列名数组
   */
  columns(columns: string[]): QueryBuilder {
    this.selectedColumns = columns;
    return this;
  }

  // ─── 构建 ────────────────────────────────────────────────────

  /**
   * 构建并返回 RdbPredicates 实例
   * 供 RdbManager.query() 使用
   */
  build(): relationalStore.RdbPredicates {
    return this.predicates;
  }

  /**
   * 获取已选择的列列表
   * 供 DAO 层传入 RdbManager.query() 的 columns 参数
   */
  getColumns(): string[] | undefined {
    return this.selectedColumns.length > 0 ? this.selectedColumns : undefined;
  }
}
