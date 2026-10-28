/**
 * FeedbackUtil — 操作反馈工具函数
 *
 * 调用方传入当前 UIContext、反馈类型和文案，即可在屏幕底部显示 Snackbar。
 * 每次调用独立创建 ComponentContent，用完即销毁。
 * 同一错误码 / 同一文案的 Snackbar 正在显示时，再次调用会被忽略（见 DialogDedup）。
 */
import { ComponentContent } from '@kit.ArkUI'
import { FeedbackType } from '../constants/FeedbackType'
import { SnackbarParams } from '../model/SnackbarParamsModel'
import { SnackbarContent } from '../shares/SnackbarContent'
import { DialogDedup } from './DialogDedupUtil'

/** 供 ComponentContent + wrapBuilder 使用的模块级 @Builder 函数 */
@Builder
function snackbarBuilder(params: SnackbarParams) {
  SnackbarContent({ params: params })
}

/**
 * 在屏幕底部显示一个轻量 Snackbar 反馈。
 *
 * @param ctx   当前页面的 UIContext（从 this.getUIContext() 获取）
 * @param type  反馈类型（SUCCESS / ERROR / INFO）
 * @param text  反馈文案，支持多语言资源引用
 */
export function showFeedback(
  ctx: UIContext,
  type: FeedbackType,
  text: ResourceStr,
): void {
  // 同一错误码 / 文案正在显示时忽略
  const key = `snackbar:${type}:${DialogDedup.getDedupKey(text)}`
  if (!DialogDedup.tryAcquire(key)) {
    return
  }

  const params = new SnackbarParams()
  params.type = type
  params.text = text

  const content = new ComponentContent(ctx, wrapBuilder(snackbarBuilder), params)
  let disposed = false
  // 弹框消失（定时关闭 / 点外部 / 系统关闭）或打开失败后释放节点；放到下一轮事件循环，避免在弹框回调中释放
  const disposeContent = () => {
    setTimeout(() => {
      if (!disposed) {
        disposed = true
        content.dispose()
      }
    }, 0)
  }
  params.onDismiss = () => {
    DialogDedup.release(key)
    if (!disposed) {
      ctx.getPromptAction().closeCustomDialog(content)
    }
  }

  ctx.getPromptAction().openCustomDialog(content, {
    alignment: DialogAlignment.Bottom,
    offset: { dx: 0, dy: -80 },
    maskColor: Color.Transparent,
    isModal: false,
    autoCancel: true,
    // 被系统 / 点击外部关闭时也要释放 key
    onDidDisappear: () => {
      DialogDedup.release(key)
      disposeContent()
    },
  }).catch((_: Error | object) => {
    DialogDedup.release(key)
    disposeContent()
  })
}
