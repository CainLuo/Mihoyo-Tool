/**
 * SyncRetrySignal — 重新同步全局信号
 *
 * 人机验证通过（GeetestCenter）或重新生成设备指纹（DeviceFpCenter）后调用 notify()，
 * HomePage / CharactersPage 通过 @Local + @Monitor 监听 version 字段重新同步。
 *
 * 使用 AppStorageV2 保证跨组件共享同一实例。
 */
import { AppStorageV2 } from '@kit.ArkUI'

@ObservedV2
export class SyncRetrySignal {
  @Trace version: number = 0

  /** 通知所有监听方重新同步（监听方只看 version，重新同步全部账号） */
  notify(): void {
    this.version = Date.now()
  }

  static readonly KEY: string = 'SyncRetrySignal'

  static getInstance(): SyncRetrySignal {
    return AppStorageV2.connect(SyncRetrySignal, SyncRetrySignal.KEY, () => new SyncRetrySignal())!
  }
}
