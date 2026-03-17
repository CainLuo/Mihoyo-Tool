/**
 * QueryBuilder.test.ets
 *
 * QueryBuilder 单元测试。
 * 测试链式调用是否正确构建 RdbPredicates，以及列选择逻辑。
 *
 * 运行方式：本地单元测试（不需要设备/模拟器）
 *   hvigorw --mode module -p module=core@default -p product=default test
 */

import { describe, it, expect, beforeEach } from '@ohos/hypium';
import { QueryBuilder } from '../main/ets/database/QueryBuilder';

export default function queryBuilderTest() {
  describe('QueryBuilder', () => {

    // ─── build() 基础测试 ────────────────────────────────────────

    it('build_returnsRdbPredicates_whenOnlyTableName', 0, () => {
      // 只传表名，build() 应返回非 null 的 RdbPredicates
      const builder = new QueryBuilder('game_data');
      const predicates = builder.build();
      expect(predicates).assertInstanceOf('Object');
    });

    it('build_withEqualTo_doesNotThrow', 0, () => {
      // equalTo 链式调用后 build() 不应抛出异常
      let threw = false;
      try {
        new QueryBuilder('game_data')
          .equalTo('game_id', 'genshin')
          .equalTo('role_uid', '123456789')
          .build();
      } catch {
        threw = true;
      }
      expect(threw).assertFalse();
    });

    it('build_withMultipleConditions_doesNotThrow', 0, () => {
      // 多条件链式调用不应抛出
      let threw = false;
      try {
        new QueryBuilder('game_data')
          .equalTo('game_id', 'genshin')
          .equalTo('data_type', 'character')
          .greaterThanOrEqualTo('rarity', 5)
          .orderByDesc('level')
          .limit(20)
          .build();
      } catch {
        threw = true;
      }
      expect(threw).assertFalse();
    });

    it('build_withOrCondition_doesNotThrow', 0, () => {
      // OR 条件链式调用不应抛出
      let threw = false;
      try {
        new QueryBuilder('game_data')
          .equalTo('game_id', 'genshin')
          .or()
          .equalTo('game_id', 'starrail')
          .build();
      } catch {
        threw = true;
      }
      expect(threw).assertFalse();
    });

    it('build_withBetween_doesNotThrow', 0, () => {
      let threw = false;
      try {
        new QueryBuilder('game_data')
          .between('rarity', 4, 5)
          .build();
      } catch {
        threw = true;
      }
      expect(threw).assertFalse();
    });

    it('build_withLike_doesNotThrow', 0, () => {
      let threw = false;
      try {
        new QueryBuilder('game_data')
          .like('name', '%菲林%')
          .build();
      } catch {
        threw = true;
      }
      expect(threw).assertFalse();
    });

    it('build_withIn_doesNotThrow', 0, () => {
      let threw = false;
      try {
        new QueryBuilder('game_data')
          .in('rarity', ['4', '5'])
          .build();
      } catch {
        threw = true;
      }
      expect(threw).assertFalse();
    });

    it('build_withOffsetAndLimit_doesNotThrow', 0, () => {
      let threw = false;
      try {
        new QueryBuilder('game_data')
          .equalTo('data_type', 'character')
          .orderByDesc('level')
          .limit(10)
          .offset(20)
          .build();
      } catch {
        threw = true;
      }
      expect(threw).assertFalse();
    });

    // ─── getColumns() 测试 ───────────────────────────────────────

    it('getColumns_returnsUndefined_whenNotSet', 0, () => {
      // 未调用 columns()，getColumns() 应返回 undefined
      const builder = new QueryBuilder('game_data');
      expect(builder.getColumns()).assertUndefined();
    });

    it('getColumns_returnsColumns_whenSet', 0, () => {
      // 调用 columns() 后，getColumns() 应返回指定列数组
      const cols = ['entity_id', 'name', 'rarity', 'level'];
      const builder = new QueryBuilder('game_data').columns(cols);
      const result = builder.getColumns();
      expect(result).assertInstanceOf('Array');
      expect(result!.length).assertEqual(4);
      expect(result![0]).assertEqual('entity_id');
      expect(result![3]).assertEqual('level');
    });

    it('getColumns_returnsUndefined_whenEmptyArray', 0, () => {
      // 传入空数组等同于未设置，应返回 undefined
      const builder = new QueryBuilder('game_data').columns([]);
      expect(builder.getColumns()).assertUndefined();
    });

    // ─── 链式返回自身测试 ────────────────────────────────────────

    it('chainMethods_returnSameBuilderInstance', 0, () => {
      // 所有链式方法应返回同一个 builder 实例
      const builder = new QueryBuilder('game_data');
      const b1 = builder.equalTo('game_id', 'genshin');
      const b2 = b1.orderByDesc('level');
      const b3 = b2.limit(10);
      // 三次调用返回的都是同一个对象
      expect(b1 === builder).assertTrue();
      expect(b2 === builder).assertTrue();
      expect(b3 === builder).assertTrue();
    });

    // ─── 不同表名测试 ────────────────────────────────────────────

    it('build_withGameStatsTable_doesNotThrow', 0, () => {
      let threw = false;
      try {
        new QueryBuilder('game_stats')
          .equalTo('game_id', 'genshin')
          .equalTo('stat_key', 'relic_score')
          .orderByDesc('stat_value')
          .limit(10)
          .build();
      } catch {
        threw = true;
      }
      expect(threw).assertFalse();
    });
  });
}
