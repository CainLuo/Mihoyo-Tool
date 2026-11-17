import { describe, it, expect } from '@ohos/hypium';
import { CharacterDataSource } from '../main/ets/viewmodel/CharacterDataSource';
import { GameDataSummary } from 'core';

/**
 * DataChangeListener 测试桩：只统计 onDataReloaded 次数。
 * 其余方法必须实现以满足 ArkUI 接口。
 */
class TestDataChangeListener implements DataChangeListener {
  reloadCount: number = 0;

  onDataReloaded(): void {
    this.reloadCount++;
  }

  onDataAdded(index: number): void {
  }

  onDataAdd(index: number): void {
  }

  onDataMoved(from: number, to: number): void {
  }

  onDataMove(from: number, to: number): void {
  }

  onDataDeleted(index: number): void {
  }

  onDataDelete(index: number): void {
  }

  onDataChanged(index: number): void {
  }

  onDataChange(index: number): void {
  }

  onDatasetChange(dataOperations: DataOperation[]): void {
  }
}

function makeSummary(entityId: string, name: string): GameDataSummary {
  const summary = new GameDataSummary();
  summary.entityId = entityId;
  summary.name = name;
  return summary;
}

export default function characterDataSourceTest() {
  describe('CharacterDataSource', () => {

    it('初始 totalCount 为 0', 0, () => {
      const source = new CharacterDataSource();
      expect(source.totalCount()).assertEqual(0);
    });

    it('setData 后 totalCount 与 getData 正确', 0, () => {
      const source = new CharacterDataSource();
      source.setData([makeSummary('1001', '旅行者'), makeSummary('1002', '派蒙')]);
      expect(source.totalCount()).assertEqual(2);
      expect(source.getData(0).entityId).assertEqual('1001');
      expect(source.getData(1).name).assertEqual('派蒙');
    });

    it('setData 替换旧数据而不是追加', 0, () => {
      const source = new CharacterDataSource();
      source.setData([makeSummary('1001', '旅行者')]);
      source.setData([makeSummary('1002', '派蒙')]);
      expect(source.totalCount()).assertEqual(1);
      expect(source.getData(0).entityId).assertEqual('1002');
    });

    it('setData 会通知已注册的 listener', 0, () => {
      const source = new CharacterDataSource();
      const listener = new TestDataChangeListener();
      source.registerDataChangeListener(listener);
      source.setData([makeSummary('1001', '旅行者')]);
      expect(listener.reloadCount).assertEqual(1);
    });

    it('重复注册同一个 listener 只通知一次', 0, () => {
      const source = new CharacterDataSource();
      const listener = new TestDataChangeListener();
      source.registerDataChangeListener(listener);
      source.registerDataChangeListener(listener);
      source.setData([makeSummary('1001', '旅行者')]);
      expect(listener.reloadCount).assertEqual(1);
    });

    it('unregister 后不再通知', 0, () => {
      const source = new CharacterDataSource();
      const listener = new TestDataChangeListener();
      source.registerDataChangeListener(listener);
      source.unregisterDataChangeListener(listener);
      source.setData([makeSummary('1001', '旅行者')]);
      expect(listener.reloadCount).assertEqual(0);
    });

    it('unregister 未注册的 listener 不崩溃', 0, () => {
      const source = new CharacterDataSource();
      const listener = new TestDataChangeListener();
      let threw = false;
      try {
        source.unregisterDataChangeListener(listener);
      } catch (_) {
        threw = true;
      }
      expect(threw).assertFalse();
    });

  });
}
