/**
 * DeviceFpCenter — 设备指纹无效 / 账号异常（retcode=5003 / 10041）统一处理
 *
 * PizzaHelperUnited 将 5003 / 10041 归为"设备指纹无效或缺失"，Miao-Yunzai 归为"米游社账号异常"（均不是人机验证），处理方式是让用户重新生成设备指纹。
 * 任何接口返回 5003 / 10041 时，core 的具体 API 通过 ApiConfig.setFingerprintInvalidListener() 显式上报，
 * 这里通过 DeviceFpInvalidSignal 通知 Main.ets 弹出提示（含"重新生成设备指纹"）：
 * - 提示显示中不重复弹；用户取消、或已经重新生成过一次后，本次启动不再提示（避免重新生成后仍无效时反复弹出）
 * - 重新生成成功后通过 SyncRetrySignal 通知首页 / 角色页重新同步
 * 账号详情页的"重新生成设备指纹"也调用 regenerate()。设备指纹全 App 共用，重新生成对所有账号生效。
 */
import { common } from '@kit.AbilityKit'
import { AppStorageV2 } from '@kit.ArkUI'
import { ApiConfig, GameId } from 'core'
import { SyncRetrySignal } from './SyncRetrySignal'
import { gameIdFromApiUrl } from './GameIdUtil'

/** Main.ets 监听 version，弹出设备指纹无效提示 */
@ObservedV2
export class DeviceFpInvalidSignal {
  @Trace version: number = 0
  /** 出错接口所属游戏 */
  gameId: GameId = GameId.GENSHIN
  /** 出错请求的游戏 UID（取不到时为空） */
  roleUid: string = ''
  /** 5003 / 10041 */
  retcode: number = 0

  static readonly KEY: string = 'DeviceFpInvalidSignal'

  static instance(): DeviceFpInvalidSignal {
    return AppStorageV2.connect(DeviceFpInvalidSignal, DeviceFpInvalidSignal.KEY, () => new DeviceFpInvalidSignal())!
  }
}

export class DeviceFpCenter {
  private static initialized: boolean = false
  /** 提示显示中 */
  private static showing: boolean = false
  /** 用户取消过（或重新生成失败）：本次启动不再提示 */
  private static dismissed: boolean = false

  /** 注册 core 的设备指纹无效上报（App 启动时调用一次） */
  static init(): void {
    if (DeviceFpCenter.initialized) {
      return
    }
    DeviceFpCenter.initialized = true
    ApiConfig.setFingerprintInvalidListener((url: string, retcode: number, roleUid: string) => {
      DeviceFpCenter.onInvalid(url, retcode, roleUid)
    })
  }

  private static onInvalid(url: string, retcode: number, roleUid: string): void {
    if (DeviceFpCenter.showing || DeviceFpCenter.dismissed) {
      return
    }
    DeviceFpCenter.showing = true
    const signal = DeviceFpInvalidSignal.instance()
    signal.gameId = gameIdFromApiUrl(url)
    signal.roleUid = roleUid
    signal.retcode = retcode
    signal.version = Date.now()
  }

  /** 提示被取消：本次启动不再提示 */
  static dismiss(): void {
    DeviceFpCenter.showing = false
    DeviceFpCenter.dismissed = true
  }

  /**
   * 重新生成设备指纹（提示 / 账号详情页共用）。成功后通知首页 / 角色页重新同步；失败时抛出。
   * 无论成功与否，本次启动都不再提示：重新生成后仍返回 5003 / 10041 时再提示也无济于事。
   * @throws { Error } 指纹申请或写入失败时
   */
  static async regenerate(context: common.UIAbilityContext): Promise<void> {
    DeviceFpCenter.dismiss()
    await ApiConfig.regenerateDeviceFp(context)
    SyncRetrySignal.instance().notify('')
  }
}
