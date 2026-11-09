/**
 * MainPageBuilders — MainPage 的模块级 @Builder
 *
 * 规范要求 @Builder 不得内联在 Component / Page 文件中，统一外置到
 * {组件名}Builders.ets，由主文件按需 import。
 */
import { AccountSwitchDialog, AccountSwitchDialogParams } from 'basic'

@Builder
export function accountSwitchDialogBuilder(params: AccountSwitchDialogParams) {
  AccountSwitchDialog({ params: params })
}
