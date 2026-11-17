/**
 * LaunchViewModel.ets — 启动页 ViewModel
 *
 * 启动页只做三件事：判断隐私协议是否已同意、等待 Core（含 DB）就绪、初始化失败后重试。
 * 页面负责动画与路由，Model 层访问收敛到这里。
 */
import { CoreInitializer } from 'core';
import { common } from '@kit.AbilityKit';
import { APP_ENV } from 'basic';
import { LegalPreferences } from 'legal';

export class LaunchViewModel {
  /** 用户是否已同意隐私协议 */
  hasAgreed(ctx: common.UIAbilityContext): boolean {
    return LegalPreferences.hasAgreed(ctx);
  }

  /** 等待 Core（含 DB）初始化完成；初始化失败时 reject */
  waitForReady(): Promise<void> {
    return CoreInitializer.waitForReady();
  }

  /**
   * 重新初始化 Core。
   *
   * 上次初始化已失败时重新执行一遍；若初始化仍在进行中，CoreInitializer 会复用同一个任务，
   * 不会重复初始化数据库。
   */
  retryInit(ctx: common.UIAbilityContext): Promise<void> {
    return CoreInitializer.initCore({ env: APP_ENV, context: ctx });
  }
}
