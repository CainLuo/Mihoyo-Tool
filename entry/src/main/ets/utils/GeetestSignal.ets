/**
 * GeetestSignal — Geetest 人机验证全局信号
 *
 * 当 API 返回需要 Geetest 验证时，调用 GeetestSignal.push() 加入队列。
 * Main.ets 监听 trigger 变化，弹出 GeetestDialog，验证完成后回调原调用方。
 *
 * 支持队列场景：多个账号同时需要验证时，按顺序逐一弹出 Dialog。
 * 用户可选择"取消当前"继续下一项，或"取消全部"清空队列。
 */
import { AppStorageV2 } from '@kit.ArkUI'
import { GeetestTrigger } from '../models/GeetestTrigger'
import { SignalMonitorKey } from '../constants/SignalMonitorKey'
import { GeetestProgress } from '../components/GeetestDialogHelper'

/**
 * Geetest 回调接口
 * 验证成功时调用 onSuccess，用户取消时调用 onCancel。
 */
export interface GeetestCallback {
  /** 验证成功，传递验证结果 */
  onSuccess: (gt: string, challenge: string, validate: string) => void
  /** 用户取消验证 */
  onCancel: () => void
}

/**
 * 队列项：包含触发器、回调和账号名
 */
export interface GeetestQueueItem {
  /** 触发验证所需的完整上下文 */
  trigger: GeetestTrigger
  /** 验证完成后的回调 */
  callback: GeetestCallback
  /** 账号名（用于 UI 显示当前验证的账号） */
  accountName: string
}

@ObservedV2
export class GeetestSignal {
  /** 触发 UI 监听的计数器（每次 +1 触发 @Monitor） */
  @Trace trigger: number = 0

  /** 队列长度（用于 UI 显示进度） */
  @Trace queueLength: number = 0

  /** 验证队列 */
  private queue: GeetestQueueItem[] = []

  /** 当前处理的队列项索引 */
  private currentIndex: number = 0

  /**
   * 获取全局单例
   * 通过 AppStorageV2 管理，保证跨组件共享同一实例。
   */
  static instance(): GeetestSignal {
    return AppStorageV2.connect(
      GeetestSignal,
      SignalMonitorKey.GEETEST_SIGNAL_KEY,
      () => new GeetestSignal()
    )!
  }

  /**
   * 推送验证请求到队列
   * @param trigger 触发验证所需的完整上下文
   * @param callback 验证完成后的回调
   * @param accountName 账号名（用于 UI 显示）
   */
  push(trigger: GeetestTrigger, callback: GeetestCallback, accountName: string = ''): void {
    const item: GeetestQueueItem = {
      trigger: trigger,
      callback: callback,
      accountName: accountName
    }
    this.queue[this.queue.length] = item
    this.queueLength = this.queue.length

    // 如果队列只有 1 项，立即触发 UI
    if (this.queue.length === 1) {
      this.trigger++
    }
  }

  /**
   * 获取当前验证项
   * @returns 当前队列项，如果队列为空则返回 null
   */
  getCurrentItem(): GeetestQueueItem | null {
    if (this.queue.length === 0 || this.currentIndex >= this.queue.length) {
      return null
    }
    return this.queue[this.currentIndex]
  }

  /**
   * 获取队列进度
   * @returns { current: 当前项序号(1-based), total: 总数 }
   */
  getProgress(): GeetestProgress {
    const progress = new GeetestProgress()
    progress.current = this.currentIndex + 1
    progress.total = this.queue.length
    return progress
  }

  /**
   * 验证成功，回调结果并处理下一项
   */
  resolveSuccess(gt: string, challenge: string, validate: string): void {
    const item = this.getCurrentItem()
    if (item !== null) {
      item.callback.onSuccess(gt, challenge, validate)
    }
    this.processNext()
  }

  /**
   * 用户取消当前项
   */
  resolveCancelCurrent(): void {
    const item = this.getCurrentItem()
    if (item !== null) {
      item.callback.onCancel()
    }
    this.processNext()
  }

  /**
   * 用户取消全部队列
   * 对当前及之后的所有项调用 onCancel，然后清空队列。
   */
  resolveCancelAll(): void {
    // 对当前及之后的所有项调用 onCancel
    for (let i = this.currentIndex; i < this.queue.length; i++) {
      this.queue[i].callback.onCancel()
    }
    this.resetQueue()
  }

  /**
   * 处理下一项
   * 如果还有下一项，触发 UI 显示新的验证；否则清空队列。
   */
  private processNext(): void {
    this.currentIndex++
    if (this.currentIndex < this.queue.length) {
      // 还有下一项，触发 UI 显示新的验证
      this.trigger++
    } else {
      // 队列已清空
      this.resetQueue()
    }
  }

  /**
   * 重置队列
   */
  private resetQueue(): void {
    this.queue = []
    this.currentIndex = 0
    this.queueLength = 0
  }
}

/** 全局单例（通过 AppStorageV2 管理） */
export const geetestSignal = GeetestSignal.instance()
