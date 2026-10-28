/**
 * AccountSignal — 账号数据变更全局信号
 *
 * 登录成功、账号变更后调用 AccountSignal.notify()；三个养成目标配置 ViewModel 在保存配置且计算成功后也会调用
 * （ToolsPage 依赖它刷新已配置目标的数量）。
 * HomePage / CharactersPage / MyPage / ToolsPage 通过 @Local + @Monitor 监听 version 字段自动重新加载。
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

  static getInstance(): AccountSignal {
    return AppStorageV2.connect(AccountSignal, AccountSignal.KEY, () => new AccountSignal())!
  }
}
