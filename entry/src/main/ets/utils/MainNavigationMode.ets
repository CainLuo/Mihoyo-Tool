/**
 * MainNavigationMode — MainPage 的响应式导航模式计算
 *
 * 官方 FAQ 推荐方案：横屏时分栏（分屏 / 悬浮窗除外），竖屏时按断点决定。
 */
import { display, window } from '@kit.ArkUI';

/** 是否横屏（含反向横屏） */
export function isLandscapeOrientation(orientation: display.Orientation): boolean {
  return orientation === display.Orientation.LANDSCAPE ||
    orientation === display.Orientation.LANDSCAPE_INVERTED;
}

/**
 * 综合屏幕方向 + 窗口状态计算 Navigation 显示模式。
 * @param isLandscape 是否横屏
 * @param windowWidthVp 当前窗口宽度（vp）
 * @param windowStatusType 窗口状态；分屏（SPLIT_SCREEN）与悬浮窗（FLOATING）空间受限，用堆叠
 */
export function resolveNavigationMode(isLandscape: boolean, windowWidthVp: number,
                                      windowStatusType: window.WindowStatusType | undefined): NavigationMode {
  if (isLandscape) {
    const isNarrowWindow = windowStatusType === window.WindowStatusType.FLOATING ||
      windowStatusType === window.WindowStatusType.SPLIT_SCREEN;
    return isNarrowWindow ? NavigationMode.Stack : NavigationMode.Split;
  }
  return windowWidthVp < 520 ? NavigationMode.Stack : NavigationMode.Split;
}
