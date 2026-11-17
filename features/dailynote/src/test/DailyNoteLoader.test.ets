import { describe, it, expect } from '@ohos/hypium';
import { loadDailyNote } from '../main/ets/utils/DailyNoteLoader';
import { ViewState } from 'basic';

/**
 * DailyNoteLoader 是三个便笺详情页共用的加载骨架。
 * 通过注入 readRawJson / parse 覆盖 LOADING → EMPTY / DATA / ERROR 三条路径。
 */
export default function dailyNoteLoaderTest() {
  describe('DailyNoteLoader', () => {

    it('读取到 null 时返回 EMPTY 且 note 为 null', 0, async (done: Function) => {
      const result = await loadDailyNote<string>(
        'Test',
        async (): Promise<string | null> => null,
        (rawJson: string): string => rawJson,
      );
      expect(result.viewState).assertEqual(ViewState.EMPTY);
      expect(result.note === null).assertTrue();
      done();
    });

    it('读取到 rawJson 时返回 DATA 并调用 parse', 0, async (done: Function) => {
      const result = await loadDailyNote<string>(
        'Test',
        async (): Promise<string | null> => '{"current": 1}',
        (rawJson: string): string => `parsed:${rawJson}`,
      );
      expect(result.viewState).assertEqual(ViewState.DATA);
      expect(result.note === null).assertFalse();
      expect(result.note).assertEqual('parsed:{"current": 1}');
      done();
    });

    it('readRawJson 抛错时返回 ERROR 且 note 为 null', 0, async (done: Function) => {
      const result = await loadDailyNote<string>(
        'Test',
        async (): Promise<string | null> => {
          throw new Error('db failed');
        },
        (rawJson: string): string => rawJson,
      );
      expect(result.viewState).assertEqual(ViewState.ERROR);
      expect(result.note === null).assertTrue();
      done();
    });

    it('parse 抛错时返回 ERROR 且 note 为 null', 0, async (done: Function) => {
      const result = await loadDailyNote<string>(
        'Test',
        async (): Promise<string | null> => 'bad json',
        (rawJson: string): string => {
          throw new Error('parse failed');
        },
      );
      expect(result.viewState).assertEqual(ViewState.ERROR);
      expect(result.note === null).assertTrue();
      done();
    });

    it('每次调用返回独立的 result 对象', 0, async (done: Function) => {
      const first = await loadDailyNote<string>(
        'Test',
        async (): Promise<string | null> => null,
        (rawJson: string): string => rawJson,
      );
      const second = await loadDailyNote<string>(
        'Test',
        async (): Promise<string | null> => null,
        (rawJson: string): string => rawJson,
      );
      expect(first === second).assertFalse();
      done();
    });

  });
}
