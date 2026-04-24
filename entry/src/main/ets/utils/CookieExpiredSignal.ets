/**
 * CookieExpiredSignal — Cookie 过期全局信号
 *
 * 任何地方检测到 Cookie 过期（stoken 刷新失败）时，
 * 调用 CookieExpiredSignal.push(info) 将账号信息加入队列。
 * Main.ets 监听 queue 变化，逐一弹 Dialog 提示用户重新登录。
 */
import { AppStorageV2 } from '@kit.ArkUI'
import { FailedAccountInfo } from 'core'

@ObservedV2
export class CookieExpiredSignal {
  @Trace queue: FailedAccountInfo[] = []

  push(info: FailedAccountInfo): void {
    // 同一个账号已在队列中则跳过，避免多个游戏角色同时失效时重复弹 Dialog
    for (let i = 0; i < this.queue.length; i++) {
      if (this.queue[i].username === info.username) {
        return;
      }
    }
    const newQueue: FailedAccountInfo[] = []
    for (let i = 0; i < this.queue.length; i++) {
      newQueue[newQueue.length] = this.queue[i]
    }
    newQueue[newQueue.length] = info
    this.queue = newQueue
  }

  static readonly KEY: string = 'CookieExpiredSignal'

  static instance(): CookieExpiredSignal {
    return AppStorageV2.connect(
      CookieExpiredSignal,
      CookieExpiredSignal.KEY,
      () => new CookieExpiredSignal()
    )!
  }
}
