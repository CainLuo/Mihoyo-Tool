/**
 * AccountSignal — 账号数据变更全局信号
 *
 * 登录成功后调用 AccountSignal.notify()，
 * Home / Characters / My 通过 @Local + @Monitor 监听 version 字段自动重新加载。
 *
 * 使用 AppStorageV2 保证跨组件共享同一实例。
 */
import { AppStorageV2 } from '@kit.ArkUI'

@ObservedV2
export class AccountSignal {
  @Trace version: number = 0

  notify(): void {
    this.version = Date.now()
  }

  static readonly KEY: string = 'AccountSignal'

  static instance(): AccountSignal {
    return AppStorageV2.connect(AccountSignal, AccountSignal.KEY, () => new AccountSignal())!
  }
}
