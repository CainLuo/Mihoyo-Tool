/**
 * LaunchViewModel.ets — 启动页 ViewModel
 *
 * 启动页只做两件事：判断隐私协议是否已同意、等待 Core（含 DB）就绪。
 * 页面负责动画与路由，Model 层访问收敛到这里。
 */
import { CoreInitializer } from 'core';
import { common } from '@kit.AbilityKit';
import { LegalPreferences } from 'legal';

export class LaunchViewModel {
  /** 用户是否已同意隐私协议 */
  hasAgreed(ctx: common.UIAbilityContext): boolean {
    return LegalPreferences.hasAgreed(ctx);
  }

  /** 等待 Core（含 DB）初始化完成 */
  waitForReady(): Promise<void> {
    return CoreInitializer.waitForReady();
  }
}
