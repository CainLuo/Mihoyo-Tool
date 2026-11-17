import { describe, it, expect } from '@ohos/hypium';
import { CoalescingRunner } from '../main/ets/model/service/CoalescingRunner';

export default function coalescingRunnerTest() {
  describe('CoalescingRunner', () => {

    it('顺序调用各自执行一次', 0, async (done: Function) => {
      let runs = 0;
      const runner = new CoalescingRunner(async () => {
        runs++;
        await Promise.resolve();
      });

      await runner.run();
      await runner.run();

      expect(runs).assertEqual(2);
      expect(runner.isRunning()).assertFalse();
      done();
    });

    it('并发调用合并为一轮，并补跑一次', 0, async (done: Function) => {
      let runs = 0;
      const runner = new CoalescingRunner(async () => {
        runs++;
        await Promise.resolve();
      });

      const first = runner.run();
      const second = runner.run();
      const third = runner.run();

      // 任务已同步开始执行，后两次触发只登记尾随重跑
      expect(runs).assertEqual(1);
      expect(runner.isRunning()).assertTrue();

      await first;
      await second;
      await third;

      // 三次触发 → 一轮 + 一次尾随重跑
      expect(runs).assertEqual(2);
      expect(runner.isRunning()).assertFalse();
      done();
    });

    it('任务抛错后复位，下次仍可运行', 0, async (done: Function) => {
      let runs = 0;
      const runner = new CoalescingRunner(async () => {
        runs++;
        if (runs === 1) {
          throw new Error('boom');
        }
        await Promise.resolve();
      });

      let failed = false;
      try {
        await runner.run();
      } catch (_e) {
        failed = true;
      }
      expect(failed).assertTrue();
      expect(runner.isRunning()).assertFalse();

      await runner.run();
      expect(runs).assertEqual(2);
      done();
    });

  });
}
