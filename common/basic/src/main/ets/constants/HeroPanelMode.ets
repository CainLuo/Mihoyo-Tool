/**
 * HeroPanelMode — 角色立绘区布局模式枚举
 *
 * 禁止在 CharDetailHeroPanel 及其调用方中直接写 'wide'、'portrait'、'landscape' 字符串。
 * 所有布局模式判断必须使用此 enum。
 */
export enum HeroPanelMode {
  /** 宽屏三栏布局（Tablet / PC / Foldable 展开） */
  WIDE = 'wide',
  /** Phone 竖屏布局 */
  PORTRAIT = 'portrait',
  /** Phone 横屏布局 */
  LANDSCAPE = 'landscape',
}
