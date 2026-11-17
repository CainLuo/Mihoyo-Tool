/**
 * CoalescingRunner — 串行化重复触发（in-flight 合并 + 尾随重跑）
 *
 * 同一时刻只允许一个任务实例在跑：
 *   - 运行期间再次触发，调用方共享当前轮的 Promise，不会各起一轮；
 *   - 同时登记一次「尾随重跑」，当前轮结束后立刻再跑一轮，
 *     保证后到的触发不会被丢弃（例如冷启动那轮还在跑时，同步完成后的第二轮带着新数据到达）。
 *
 * 不依赖设备 API，可在本地单元测试中直接测试。
 */
export class CoalescingRunner {
  private readonly task: () => Promise<void>;
  private inFlight: Promise<void> | null = null;
  private rerunRequested: boolean = false;

  /** @param task 实际执行的异步任务；实现内部不要再调用 run() */
  constructor(task: () => Promise<void>) {
    this.task = task;
  }

  /** 当前是否有一轮正在执行 */
  isRunning(): boolean {
    return this.inFlight !== null;
  }

  /** 触发一次运行；并发调用共享同一轮（含尾随重跑）的 Promise */
  run(): Promise<void> {
    const running = this.inFlight;
    if (running !== null) {
      this.rerunRequested = true;
      return running;
    }
    const loop = this.runLoop();
    this.inFlight = loop;
    return loop;
  }

  private async runLoop(): Promise<void> {
    try {
      do {
        this.rerunRequested = false;
        await this.task();
      } while (this.rerunRequested);
    } finally {
      this.inFlight = null;
    }
  }
}
