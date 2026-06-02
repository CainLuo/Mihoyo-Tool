/**
 * ColorUtil — 颜色工具函数
 *
 * 用于动态生成带透明度的颜色值。
 * 透明色在应用启动时预先计算并缓存，组件直接使用缓存值。
 */

import { common } from '@kit.AbilityKit';

/**
 * 预定义的透明度常量
 */
export class Alpha {
  /** 10% */
  static readonly P10: number = 0.1;
  /** 15% */
  static readonly P15: number = 0.15;
  /** 20% */
  static readonly P20: number = 0.2;
  /** 35% */
  static readonly P35: number = 0.35;
  /** 40% */
  static readonly P40: number = 0.4;
  /** 50% */
  static readonly P50: number = 0.5;
  /** 60% */
  static readonly P60: number = 0.6;
  /** 80% */
  static readonly P80: number = 0.8;
}

/**
 * 将颜色整数值转换为十六进制字符串
 * @param colorInt 颜色整数值（如 0xFF000000）
 * @returns 十六进制颜色字符串（如 '#000000'）
 */
function colorIntToHex(colorInt: number): string {
  // 去掉 Alpha 通道，只取 RGB
  const r = (colorInt >> 16) & 0xFF;
  const g = (colorInt >> 8) & 0xFF;
  const b = colorInt & 0xFF;
  return `#${r.toString(16).padStart(2, '0').toUpperCase()}${g.toString(16).padStart(2, '0').toUpperCase()}${b.toString(16).padStart(2, '0').toUpperCase()}`;
}

/**
 * 将十六进制颜色与透明度组合，返回带 Alpha 的颜色字符串
 * @param hex 十六进制颜色（如 '#000000' 或 '000000'）
 * @param alpha 透明度（0-1）
 * @returns 带 Alpha 的十六进制颜色（如 '#80000000'）
 */
export function colorWithAlpha(hex: string, alpha: number): string {
  const cleanHex = hex.startsWith('#') ? hex.slice(1) : hex;
  const alphaHex = Math.round(alpha * 255).toString(16).padStart(2, '0').toUpperCase();
  return `#${alphaHex}${cleanHex}`;
}

/**
 * 透明色缓存
 * 在应用启动时调用 init() 初始化
 */
export class TransparentColorCache {
  // Black with alpha
  static blackWith80: string = '#CC000000';
  static blackWith60: string = '#99000000';
  static blackWith40: string = '#66000000';

  // White with alpha
  static whiteWith10: string = '#1AFFFFFF';
  static whiteWith20: string = '#33FFFFFF';
  static whiteWith35: string = '#59FFFFFF';
  static whiteWith60: string = '#99FFFFFF';

  // Blue_500 with alpha
  static blue500With15: string = '#263A6FD8';
  static blue500With60: string = '#993A6FD8';

  /**
   * 初始化透明色缓存（从 color.json 读取基础颜色并计算）
   * 在 CoreInitializer.initCore() 中调用
   */
  static init(context: common.UIAbilityContext): void {
    const resMgr = context.resourceManager;

    // 获取基础颜色值（使用 getColorSync 返回数字，再转换为十六进制）
    const blackColor = resMgr.getColorSync($r('app.color.black'));
    const whiteColor = resMgr.getColorSync($r('app.color.white'));
    const blue500Color = resMgr.getColorSync($r('app.color.color_primary'));

    // 将数字颜色值转换为十六进制字符串
    const black = colorIntToHex(blackColor);
    const white = colorIntToHex(whiteColor);
    const blue500 = colorIntToHex(blue500Color);

    // 计算透明色
    TransparentColorCache.blackWith80 = colorWithAlpha(black, Alpha.P80);
    TransparentColorCache.blackWith60 = colorWithAlpha(black, Alpha.P60);
    TransparentColorCache.blackWith40 = colorWithAlpha(black, Alpha.P40);
    TransparentColorCache.whiteWith10 = colorWithAlpha(white, Alpha.P10);
    TransparentColorCache.whiteWith20 = colorWithAlpha(white, Alpha.P20);
    TransparentColorCache.whiteWith35 = colorWithAlpha(white, Alpha.P35);
    TransparentColorCache.whiteWith60 = colorWithAlpha(white, Alpha.P60);
    TransparentColorCache.blue500With15 = colorWithAlpha(blue500, Alpha.P15);
    TransparentColorCache.blue500With60 = colorWithAlpha(blue500, Alpha.P60);
  }
}
