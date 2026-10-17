/**
 * ButtonModifier.ets — 按钮样式修改器
 *
 * 使用 AttributeModifier 封装按钮样式，支持跨文件导出。
 * 所有颜色和尺寸从 ThemeManager 读取，禁止硬编码。
 *
 * 注意：不设置 width，由使用方根据场景自行决定按钮宽度。
 */

import { themeManager, ThemeManager } from '../theme/ThemeManager';

/**
 * PrimaryButtonModifier — 主要按钮样式
 *
 * 用于页面主要操作按钮，如"登录"、"去同步"等。
 * 不包含宽度设置，使用方需自行设置 width 或 padding。
 */
export class PrimaryButtonModifier implements AttributeModifier<ButtonAttribute> {
  private tm: ThemeManager = themeManager;
  /** 按钮是否可用 */
  public enabled: boolean = true;

  constructor(enabled?: boolean) {
    this.enabled = enabled ?? true;
  }

  applyNormalAttribute(instance: ButtonAttribute): void {
    instance
      .height(this.tm.current.value50)
      .borderRadius(this.tm.current.radius12)
      .backgroundColor(this.enabled ? this.tm.current.colorPrimary : this.tm.current.colorTextMuted)
      .fontSize(this.tm.current.fontMedium17)
      .fontWeight(FontWeight.Medium)
      .fontColor(this.tm.current.textOnDarkHigh);
  }
}
