/**
 * MainPageViewModel.ets — 主页 ViewModel
 *
 * 主页是唯一的人机验证 / 设备指纹弹框宿主。两个中心服务在此初始化，
 * 保持「主页出现时注册」的既有语义，页面不再直接调用 verification 的 service。
 */
import { GeetestCenter, DeviceFpCenter } from 'verification';
import { common } from '@kit.AbilityKit';

export class MainPageViewModel {
  /** 注册人机验证（1034 / 10035）与设备指纹无效（5003 / 10041）的全局监听 */
  initVerificationCenters(): void {
    GeetestCenter.init();
    DeviceFpCenter.init();
  }

  /** 关闭「设备指纹无效」提示（本次启动不再提示） */
  dismissDeviceFp(): void {
    DeviceFpCenter.dismiss();
  }

  /** 重新生成设备指纹 */
  regenerateDeviceFp(ctx: common.UIAbilityContext): Promise<void> {
    return DeviceFpCenter.regenerate(ctx);
  }
}
