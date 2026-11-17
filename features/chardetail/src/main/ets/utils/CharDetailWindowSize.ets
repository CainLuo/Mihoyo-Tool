/**
 * CharDetailWindowSize.ets
 *
 * 角色详情页共用的窗口尺寸逻辑：
 *   - 初始尺寸取默认 Display（px → vp）
 *   - 订阅 / 取消订阅 windowSizeChange
 *   - 统一断点计算（xs < 600 ≤ sm < 840 ≤ md < 1200 ≤ lg）
 */

import { display, UIContext, window } from '@kit.ArkUI';

export class CharDetailWindowSize {
  private uiCtx: UIContext;
  private onSize: (widthVp: number, heightVp: number) => void;

  private sizeCallback: (size: window.Size) => void = (size: window.Size) => {
    this.onSize(this.uiCtx.px2vp(size.width), this.uiCtx.px2vp(size.height));
  };

  constructor(uiCtx: UIContext, onSize: (widthVp: number, heightVp: number) => void) {
    this.uiCtx = uiCtx;
    this.onSize = onSize;
  }

  /** 读取初始尺寸并订阅窗口尺寸变化 */
  attach(): void {
    try {
      const d = display.getDefaultDisplaySync();
      this.onSize(this.uiCtx.px2vp(d.width), this.uiCtx.px2vp(d.height));
    } catch (_e) {}
    try {
      window.getLastWindow(this.uiCtx.getHostContext(), (err, win) => {
        if (err.code !== 0 || win === undefined) { return; }
        try { win.on('windowSizeChange', this.sizeCallback); } catch (_e) {}
      });
    } catch (_e) {}
  }

  /** 取消订阅窗口尺寸变化 */
  detach(): void {
    try {
      window.getLastWindow(this.uiCtx.getHostContext(), (err, win) => {
        if (err.code !== 0 || win === undefined) { return; }
        try { win.off('windowSizeChange', this.sizeCallback); } catch (_e) {}
      });
    } catch (_e) {}
  }
}

/** 按宽度（vp）返回断点标识 */
export function resolveCharDetailBreakpoint(widthVp: number): string {
  if (widthVp < 600) { return 'xs'; }
  if (widthVp < 840) { return 'sm'; }
  if (widthVp < 1200) { return 'md'; }
  return 'lg';
}
