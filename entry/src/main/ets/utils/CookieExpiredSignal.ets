/**
 * CookieExpiredSignal — Cookie 过期全局信号
 *
 * 任何地方检测到 Cookie 过期（stoken 刷新失败）时，
 * 调用 CookieExpiredSignal.push(info) 将账号信息加入队列。
 * Main.ets 监听 queue 变化，逐一弹 Dialog 提示用户重新登录。
 *
 * expiredUsernames：本次运行期间判定为过期的账号（弹框出队后仍保留）。
 * 账号详情页据此显示"重新登录 / 刷新 Cookie"；刷新 Cookie 或重新登录成功后调用 clearExpired 移除。
 * 不持久化：App 冷启动会自动用 stoken 刷新所有账号，失败的会重新 push。
 */
import { AppStorageV2 } from '@kit.ArkUI'
import { FailedAccountInfo } from 'core'
import { Logger } from 'core'
import { SignalMonitorKey } from '../constants/SignalMonitorKey'

@ObservedV2
export class CookieExpiredSignal {
  @Trace queue: FailedAccountInfo[] = []
  /** 已过期账号的 username 列表 */
  @Trace expiredUsernames: string[] = []

  /**
   * @param source 触发来源（用于日志排查，例如 'Home.syncDailyNote genshin/123'）
   */
  push(info: FailedAccountInfo, source: string = ''): void {
    this.markExpired(info.username)
    // 同一个账号已在队列中则跳过，避免多个游戏角色同时失效时重复弹 Dialog
    for (let i = 0; i < this.queue.length; i++) {
      if (this.queue[i].username === info.username) {
        return
      }
    }
    const newQueue: FailedAccountInfo[] = []
    for (let i = 0; i < this.queue.length; i++) {
      newQueue[newQueue.length] = this.queue[i]
    }
    newQueue[newQueue.length] = info
    this.queue = newQueue
  }

  /** 标记账号已过期 */
  markExpired(username: string): void {
    if (username.length === 0 || this.expiredUsernames.includes(username)) {
      return
    }
    this.expiredUsernames = this.expiredUsernames.concat([username])
  }

  /** 刷新 Cookie / 重新登录成功后移除过期标记（同时移除尚未弹出的过期弹框） */
  clearExpired(username: string): void {
    this.expiredUsernames = this.expiredUsernames.filter((u: string) => u !== username)
    if (this.queue.some((q: FailedAccountInfo) => q.username === username)) {
      this.queue = this.queue.filter((q: FailedAccountInfo) => q.username !== username)
    }
  }

  isExpired(username: string): boolean {
    return this.expiredUsernames.includes(username)
  }

  static instance(): CookieExpiredSignal {
    return AppStorageV2.connect(
      CookieExpiredSignal,
      SignalMonitorKey.COOKIE_EXPIRED_SIGNAL_KEY,
      () => new CookieExpiredSignal()
    )!
  }
}
