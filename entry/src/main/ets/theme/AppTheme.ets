/**
 * ============================================================
 * AppTheme — UI Token 接口定义
 * ============================================================
 *
 * 规则：
 *   - 所有 UI 组件的样式值必须从 ThemeManager.current 读取
 *   - 禁止在任何 .ets 文件中直接写死颜色、字体、间距、圆角、尺寸
 *
 * 扩展方式：
 *   1. 新增子接口并在 Theme 中 extends
 *   2. 在 DefaultTheme 中补全默认值（编译器强制提示）
 *   3. DarkTheme / 自定义主题按需覆盖
 * ============================================================
 */

// ---- 颜色 Token ----
export interface AppColor {
  colorPrimary: Resource
  colorTextPrimary: Resource
  colorTextSecondary: Resource
  colorDivider: Resource
  colorSurfaceCard: Resource
  colorPageBg: Resource
  colorPlaceholder: Resource
  colorMask: Resource
  colorDanger: Resource
  colorDangerBg: Resource
  colorWarning: Resource
  colorSurfaceSubtle: Resource

  // ---- Surface ----
  surfaceActivePrimary: Resource
  surfaceDarkLg: Resource
  surfaceActiveBorder: Resource
  surfaceInactiveBorder: Resource
  surfaceSkillBorderPhone: Resource
  surfaceFetterBg: Resource
  surfaceFetterBorder: Resource
  surfaceGlass: Resource
  surfaceDarkSm: Resource
  surfaceDarkMd: Resource

  // ---- Text ----
  textOnDarkMedium: Resource
  textOnDarkSecondary: Resource
  textOnDarkTertiary: Resource
  textOnDarkMuted: Resource
  textOnDarkFaint: Resource
  textOnDarkGhost: Resource
  textOnDarkHigh: Resource
  textInactive: Resource
  textLockIcon: Resource

  // ---- Accent ----
  accentRefine: Resource
  accentRefineBg: Resource
  accentPrimaryStrong: Resource

  // ---- Overlay ----
  overlayScrImTop: Resource
  overlayGradientEnd: Resource
  overlayShadow: Resource
  overlayPortraitBase: Resource
  overlayPortraitStrong: Resource
  overlayPortraitMid: Resource
  overlayPortraitBot: Resource
  overlayLandOpaque: Resource
  overlayLandStrong: Resource
  overlayLandFade: Resource

  // ---- Background ----
  bgElementHydro1: Resource
  bgElementHydro2: Resource
  bgElementHydro3: Resource
  bgElementPyro1: Resource
  bgElementPyro2: Resource
  bgElementPyro3: Resource
  bgElementElectro1: Resource
  bgElementElectro2: Resource
  bgElementElectro3: Resource
  bgElementAnemo1: Resource
  bgElementAnemo2: Resource
  bgElementAnemo3: Resource
  bgElementGeo1: Resource
  bgElementGeo2: Resource
  bgElementGeo3: Resource
  bgElementCryo1: Resource
  bgElementCryo2: Resource
  bgElementCryo3: Resource
  bgElementDendro1: Resource
  bgElementDendro2: Resource
  bgElementDendro3: Resource
  bgPortrait1: Resource
  bgPortrait2: Resource
  bgPageDeep: Resource
  colorTransparent: Resource

  // ---- 登录页颜色 ----
  loginTabBarBg: Resource
  loginInputBg: Resource

  // ---- 二维码颜色 ----
  qrCodeFg: Color
  qrCodeBg: Color

  // ---- 角色卡片叠加色 ----
  roleCardServerBg: Resource
  roleCardStatBg: Resource

  // ---- Widget 卡片背景色 ----
  /** Widget 卡片固定背景色（#2E3033），遵循鸿蒙卡片官方规范 */
  widgetCardBg: Resource
}

// ---- 字体 Token ----
export interface AppFont {
  body10: Font
  body12: Font
  body13: Font
  body13Bold: Font
  body15Bold: Font
  body16: Font
  body16Medium: Font
  title18Bold: Font
  title20Bold: Font
  title24Bold: Font
  title26Bold: Font
}

// ---- 间距/尺寸 Token（纯数值，命名即数值）----
export interface Spacing {
  value0: number    // 0vp
  value1: number    // 1vp
  value1p5: number  // 1.5vp
  value2: number    // 2vp
  value3: number    // 3vp
  value4: number    // 4vp
  value5: number    // 5vp
  value8: number    // 8vp
  value9: number    // 9vp
  value10: number   // 10vp
  value11: number   // 11vp
  value12: number   // 12vp
  value13: number   // 13vp
  value14: number   // 14vp
  value15: number   // 15vp
  value16: number   // 16vp
  value17: number   // 17vp
  value18: number   // 18vp
  value20: number   // 20vp
  value22: number   // 22vp
  value24: number   // 24vp
  value28: number   // 28vp
  value30: number   // 30vp
  value32: number   // 32vp
  value34: number   // 34vp
  value36: number   // 36vp
  value40: number   // 40vp
  value44: number   // 44vp
  value46: number   // 46vp
  value48: number   // 48vp
  value50: number   // 50vp
  value52: number   // 52vp
  value56: number   // 56vp
  value64: number   // 64vp
  value80: number   // 80vp
  value90: number   // 90vp
  value100: number  // 100vp
  value108: number  // 108vp
  value120: number  // 120vp
  value150: number  // 150vp
  value200: number  // 200vp
  value260: number  // 260vp
  value280: number  // 280vp
  value360: number  // 360vp
  value400: number  // 400vp
  value480: number  // 480vp
  value600: number  // 600vp
}

// ---- 动画时长 Token（单位 ms）----
export interface Duration {
  /** 骨架屏闪烁动画时长 */
  duration800: number  // 800ms
}

// ---- 百分比字符串 Token ----
export interface Percent {
  full: string       // '100%'
  pct90: string      // '90%'
  pct80: string      // '80%'
  pct40: string      // '40%'
  pct45: string      // '45%'
  pct35: string      // '35%'
}

// ---- 圆角 Token ----
export interface Radius {
  radius8: number   // 8vp
  radius12: number  // 12vp
  radius16: number  // 16vp
}

// ---- 阴影 Token ----
export interface Shadow {
  shadowRadius: number
  shadowOffsetY: number
  shadowColor: Resource
}

// ---- 渐变角度 Token ----
export interface Angle {
  a0: number    // 0°
  a90: number   // 90°
  a135: number  // 135°
  a150: number  // 150°
  a180: number  // 180°
}

// ---- 透明度 Token ----
export interface Opacity {
  shimmerOpacityHigh: number   // 1.0
  shimmerOpacityLow: number    // 0.3
  charDetailConsInactiveOpacity: number  // 0.3
  charDetailLockIconRatio: number        // 0.6
}

export interface Theme extends AppColor, AppFont, Spacing, Percent, Radius, Shadow, Angle, Opacity, Duration {}

// ---- 辅助函数 ----
export function makeFont(size: number, weight: FontWeight, family: string = ''): Font {
  const f: Font = { size: size, weight: weight, family: family }
  return f
}
