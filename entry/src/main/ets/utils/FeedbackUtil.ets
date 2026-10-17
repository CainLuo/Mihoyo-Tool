/**
 * FeedbackUtil — 操作反馈工具函数
 *
 * 调用方传入当前 UIContext、反馈类型和文案，即可在屏幕底部显示 Snackbar。
 * 每次调用独立创建 ComponentContent，用完即销毁。
 * 同一错误码 / 同一文案的 Snackbar 正在显示时，再次调用会被忽略（见 DialogDedup）。
 */
import { ComponentContent } from '@kit.ArkUI'
import { FeedbackType } from '../constants/FeedbackType'
import { SnackbarParams } from '../models/SnackbarParams'
import { SnackbarContent } from '../components/SnackbarContent'
import { DialogDedup } from './DialogDedup'

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
  const key = `snackbar:${type}:${DialogDedup.keyOf(text)}`
  if (!DialogDedup.tryAcquire(key)) {
    return
  }

  const params = new SnackbarParams()
  params.type = type
  params.text = text

  const content = new ComponentContent(ctx, wrapBuilder(snackbarBuilder), params)
  params.onDismiss = () => {
    DialogDedup.release(key)
    ctx.getPromptAction().closeCustomDialog(content)
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
    },
  }).catch((_: Error | object) => {
    DialogDedup.release(key)
  })
}
