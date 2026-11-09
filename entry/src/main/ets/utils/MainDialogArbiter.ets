/**
 * MainDialogArbiter — MainPage 全局弹窗仲裁
 *
 * 承接 Cookie 过期 / 人机验证 / 设备指纹无效三类全局弹窗的排队与互斥：
 * - 人机验证队列优先，设备指纹提示等人机验证队列清空后再弹；
 * - Cookie 过期弹框独立处理，不参与人机验证 / 指纹提示的仲裁。
 *
 * 本类只保存非响应式的调度状态（isGeetestShowing 等不参与 build()），
 * MainPage 侧的 @Monitor 仍保留在组件内，回调时委托到这里。
 */
import { promptAction } from '@kit.ArkUI'
import { common } from '@kit.AbilityKit'
import { AppRoutes, CookieExpiredSignal, DialogDedup, FeedbackType, showFeedback } from 'basic'
import { DeviceFpCenter, DeviceFpInvalidSignal, GeetestQueueItem, GeetestSignal, showGeetestDialog } from 'verification'
import { FailedAccountInfo, GeetestVerifyInput, Logger } from 'core'
import { getGameAccountLabel } from './MainDialogLabels'

export class MainDialogArbiter {
  private uiCtx: UIContext | null = null
  private stack: NavPathStack | null = null
  private geetestSignal: GeetestSignal | null = null
  private deviceFpInvalidSignal: DeviceFpInvalidSignal | null = null

  /** 用户是否请求取消全部验证队列（当前无入口置 true，保留原有语义） */
  private isGeetestCancelAllRequested: boolean = false
  private isGeetestShowing: boolean = false
  private isGeetestPending: boolean = false
  private isFpPromptShowing: boolean = false
  private isFpPromptPending: boolean = false

  /** 组件挂载时注入 UI 上下文、共享路由栈与两个全局信号 */
  attach(uiCtx: UIContext | null, stack: NavPathStack,
         geetestSignal: GeetestSignal, deviceFpInvalidSignal: DeviceFpInvalidSignal): void {
    this.uiCtx = uiCtx
    this.stack = stack
    this.geetestSignal = geetestSignal
    this.deviceFpInvalidSignal = deviceFpInvalidSignal
  }

  /** Cookie 过期队列变化：逐个弹框提示重新登录 */
  onCookieExpiredQueueChanged(signal: CookieExpiredSignal): void {
    if (signal.queue.length === 0) {
      return
    }
    const info: FailedAccountInfo = signal.queue[0]
    // 从队列移除
    signal.queue = signal.queue.slice(1)

    const ctx = this.uiCtx
    if (ctx === null) {
      return
    }
    // 同一账号的登录过期弹框正在显示时，忽略重复触发
    const dedupKey = `cookie_expired:${info.username}`
    if (!DialogDedup.tryAcquire(dedupKey)) {
      return
    }
    ctx.getPromptAction().showDialog({
      title: $r('app.string.cookie_expired_dialog_title'),
      message: $r('app.string.cookie_expired_dialog_msg', info.nickname),
      buttons: [
        { text: $r('app.string.dialog_cancel'), color: '#999999' },
        { text: $r('app.string.cookie_expired_go_login'), color: '#E8534A' },
      ],
    }).then((result: promptAction.ShowDialogSuccessResponse) => {
      DialogDedup.release(dedupKey)
      if (result.index === 1) {
        this.stack?.pushPathByName(AppRoutes.LOGIN, null)
      }
      // 若队列还有，继续弹下一个（同引用赋值不会触发 @Monitor，保留原行为）
      if (signal.queue.length > 0) {
        signal.queue = signal.queue
      }
    }).catch((_: Error | object) => {
      DialogDedup.release(dedupKey)
    })
  }

  /** 设备指纹无效（5003 / 10041）：人机验证优先，队列清空后再提示 */
  onDeviceFpInvalid(signal: DeviceFpInvalidSignal, geetestQueueLength: number): void {
    // 人机验证框显示中或还有排队项：等验证队列处理完再提示
    if (this.isGeetestShowing || geetestQueueLength > 0) {
      this.isFpPromptPending = true
      return
    }
    this.showDeviceFpPrompt(signal)
  }

  /** 人机验证触发：设备指纹提示显示中则挂起，关闭后再弹 */
  async onGeetestTriggered(trigger: number, signal: GeetestSignal): Promise<void> {
    if (trigger === 0) {
      return
    }
    // "设备指纹无效"提示显示中：等它关闭后再弹验证框
    if (this.isFpPromptShowing) {
      this.isGeetestPending = true
      return
    }
    await this.showCurrentGeetest(signal)
  }

  private showDeviceFpPrompt(signal: DeviceFpInvalidSignal): void {
    const ctx = this.uiCtx
    if (ctx === null) {
      DeviceFpCenter.dismiss()
      return
    }
    let fallback = ''
    try {
      fallback = ctx.getHostContext()?.resourceManager.getStringSync($r('app.string.device_fp_unknown_account').id) ?? ''
    } catch (_) {
    }
    const label = getGameAccountLabel(this.uiCtx, signal.gameId, signal.roleUid, fallback)
    this.isFpPromptShowing = true
    ctx.getPromptAction().showDialog({
      title: $r('app.string.device_fp_invalid_title'),
      message: $r('app.string.device_fp_invalid_msg', label, signal.retcode),
      buttons: [
        { text: $r('app.string.dialog_cancel'), color: '#999999' },
        // 弹框按钮宽度有限，用短文案（完整文案"重新生成设备指纹"会被截断）
        { text: $r('app.string.device_fp_regenerate_short'), color: '#E8534A' },
      ],
    }).then((result: promptAction.ShowDialogSuccessResponse) => {
      this.onDeviceFpPromptClosed()
      if (result.index !== 1) {
        DeviceFpCenter.dismiss()
        return
      }
      DeviceFpCenter.regenerate(ctx.getHostContext() as common.UIAbilityContext).then(() => {
        showFeedback(ctx, FeedbackType.SUCCESS, $r('app.string.device_fp_regenerate_success'))
      }).catch((e: Error | object) => {
        Logger.error('Main', `regenerate device fp failed: ${e instanceof Error ? e.message : String(e)}`)
        showFeedback(ctx, FeedbackType.ERROR, $r('app.string.device_fp_regenerate_failed'))
      })
    }).catch((_: Error | object) => {
      this.onDeviceFpPromptClosed()
      DeviceFpCenter.dismiss()
    })
  }

  /** "设备指纹无效"提示关闭：弹出挂起的人机验证框 */
  private onDeviceFpPromptClosed(): void {
    this.isFpPromptShowing = false
    if (this.isGeetestPending) {
      this.isGeetestPending = false
      const signal = this.geetestSignal
      if (signal !== null) {
        this.showCurrentGeetest(signal)
      }
    }
  }

  private async showCurrentGeetest(signal: GeetestSignal): Promise<void> {
    const item: GeetestQueueItem | null = signal.getCurrentItem()
    if (item === null) {
      return
    }

    const progress = signal.getProgress()
    const ctx = this.uiCtx
    if (ctx === null) {
      return
    }

    // 重置"取消全部"标记
    this.isGeetestCancelAllRequested = false

    // 弹出 Geetest 验证对话框
    this.isGeetestShowing = true
    let result: GeetestVerifyInput | null = null
    try {
      result = await showGeetestDialog(
        ctx,
        item.trigger.createResult,
        progress,
        this.getGeetestLabel(item)
      )
    } catch (e) {
      Logger.error('MainPage', 'showGeetestDialog failed: ' + (e as Error).message)
    } finally {
      this.isGeetestShowing = false
    }

    // 处理结果
    if (result !== null) {
      // 验证成功，回调原调用方：gt 来自 createResult，challenge / validate 来自验证结果
      const trigger = item.trigger
      signal.resolveSuccess(
        trigger.createResult.gt,
        result.geetest_challenge,
        result.geetest_validate
      )
    } else if (this.isGeetestCancelAllRequested) {
      // 用户请求取消全部队列
      signal.resolveCancelAll()
    } else {
      // 用户只取消当前项
      signal.resolveCancelCurrent()
    }
    // 人机验证队列全部处理完：弹出挂起的"设备指纹无效"提示
    if (signal.queueLength === 0 && this.isFpPromptPending) {
      this.isFpPromptPending = false
      const fpSignal = this.deviceFpInvalidSignal
      if (fpSignal !== null) {
        this.showDeviceFpPrompt(fpSignal)
      }
    }
  }

  /** 验证框标题栏：多账号排队时提示是哪个游戏账号（游戏名 · UID）；取不到游戏 UID 时显示米游社昵称 */
  private getGeetestLabel(item: GeetestQueueItem): string {
    return getGameAccountLabel(this.uiCtx, item.trigger.gameId, item.trigger.roleId, item.accountName)
  }
}
