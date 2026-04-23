/**
 * FeedbackUtil — 操作反馈工具函数
 *
 * 调用方传入当前 UIContext、反馈类型和文案，即可在屏幕底部显示 Snackbar。
 * 每次调用独立创建 ComponentContent，用完即销毁，无全局状态。
 */
import { ComponentContent } from '@kit.ArkUI'
import { FeedbackType } from '../constants/FeedbackType'
import { SnackbarParams } from '../models/SnackbarParams'
import { SnackbarContent } from '../components/SnackbarContent'

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
  const params = new SnackbarParams()
  params.type = type
  params.text = text

  const content = new ComponentContent(ctx, wrapBuilder(snackbarBuilder), params)
  params.onDismiss = () => {
    ctx.getPromptAction().closeCustomDialog(content)
  }

  ctx.getPromptAction().openCustomDialog(content, {
    alignment: DialogAlignment.Bottom,
    offset: { dx: 0, dy: -80 },
    maskColor: Color.Transparent,
    isModal: false,
    autoCancel: true,
  }).catch((_: Error | object) => {})
}
