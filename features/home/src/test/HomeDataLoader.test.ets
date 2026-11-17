import { describe, it, expect } from '@ohos/hypium';
import { HomeDataLoader } from '../main/ets/viewmodel/HomeDataLoader';
import { GameId } from 'core';

/**
 * HomeDataLoader 的大部分方法依赖 Repository / DB。
 * 这里只覆盖不触达 DB 的兜底分支；查询与解析由设备端/冒烟覆盖。
 */
export default function homeDataLoaderTest() {
  describe('HomeDataLoader', () => {

    it('不支持的游戏 shouldSyncDailyNote 返回 true', 0, async (done: Function) => {
      const result = await HomeDataLoader.shouldSyncDailyNote('', '', GameId.HONKAI3);
      expect(result).assertTrue();
      done();
    });

    it('不支持的游戏 getDailyNoteLastSyncTime 返回 0', 0, async (done: Function) => {
      const result = await HomeDataLoader.getDailyNoteLastSyncTime('', '', GameId.HONKAI3);
      expect(result).assertEqual(0);
      done();
    });

  });
}
