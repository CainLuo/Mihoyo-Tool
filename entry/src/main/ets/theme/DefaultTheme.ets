/**
 * ============================================================
 * DefaultTheme — 默认主题
 * ============================================================
 */

import { Theme, makeFont } from './AppTheme'

export class DefaultTheme implements Theme {
  // ---- AppColor ----
  colorPrimary: Resource = $r('app.color.color_primary')
  colorTextPrimary: Resource = $r('app.color.color_text_primary')
  colorTextSecondary: Resource = $r('app.color.color_text_secondary')
  colorDivider: Resource = $r('app.color.color_divider')
  colorPageBg: Resource = $r('app.color.color_page_bg')
  colorSurfaceCard: Resource = $r('app.color.color_surface_card')
  colorPlaceholder: Resource = $r('app.color.color_placeholder')
  colorMask: Resource = $r('app.color.color_mask')
  colorDanger: Resource = $r('app.color.color_danger')
  colorDangerBg: Resource = $r('app.color.color_danger_bg')
  colorWarning: Resource = $r('app.color.color_warning')
  colorSurfaceSubtle: Resource = $r('app.color.color_surface_subtle')

  // ---- 成功状态 ----
  colorSuccess: Resource = $r('app.color.color_success')
  colorSuccessBg: Resource = $r('app.color.color_success_bg')

  // ---- 文本 ----
  colorTextMuted: Resource = $r('app.color.text_on_dark_muted')

  surfaceActivePrimary: Resource = $r('app.color.surface_active_primary')
  surfaceDarkLg: Resource = $r('app.color.surface_dark_lg')
  surfaceActiveBorder: Resource = $r('app.color.surface_active_border')
  surfaceInactiveBorder: Resource = $r('app.color.surface_inactive_border')
  surfaceSkillBorderPhone: Resource = $r('app.color.surface_skill_border_phone')
  surfaceFetterBg: Resource = $r('app.color.surface_fetter_bg')
  surfaceFetterBorder: Resource = $r('app.color.surface_fetter_border')
  surfaceGlass: Resource = $r('app.color.surface_glass')
  surfaceDarkSm: Resource = $r('app.color.surface_dark_sm')
  surfaceDarkMd: Resource = $r('app.color.surface_dark_md')
  textOnDarkHigh: Resource = $r('app.color.text_on_dark_high')
  textOnDarkMedium: Resource = $r('app.color.text_on_dark_medium')
  textOnDarkSecondary: Resource = $r('app.color.text_on_dark_secondary')
  textOnDarkTertiary: Resource = $r('app.color.text_on_dark_tertiary')
  textOnDarkMuted: Resource = $r('app.color.text_on_dark_muted')
  textOnDarkFaint: Resource = $r('app.color.text_on_dark_faint')
  textOnDarkGhost: Resource = $r('app.color.text_on_dark_ghost')
  textInactive: Resource = $r('app.color.text_inactive')
  textLockIcon: Resource = $r('app.color.text_lock_icon')
  accentRefine: Resource = $r('app.color.accent_refine')
  accentRefineBg: Resource = $r('app.color.accent_refine_bg')
  accentPrimaryStrong: Resource = $r('app.color.accent_primary_strong')
  overlayScrImTop: Resource = $r('app.color.overlay_scrim_top')
  overlayGradientEnd: Resource = $r('app.color.overlay_gradient_end')
  overlayShadow: Resource = $r('app.color.overlay_shadow')
  overlayPortraitBase: Resource = $r('app.color.overlay_portrait_base')
  overlayPortraitStrong: Resource = $r('app.color.overlay_portrait_strong')
  overlayPortraitMid: Resource = $r('app.color.overlay_portrait_mid')
  overlayPortraitBot: Resource = $r('app.color.overlay_portrait_bot')
  overlayLandOpaque: Resource = $r('app.color.overlay_land_opaque')
  overlayLandStrong: Resource = $r('app.color.overlay_land_strong')
  overlayLandFade: Resource = $r('app.color.overlay_land_fade')
  bgElementHydro1: Resource = $r('app.color.bg_element_hydro_1')
  bgElementHydro2: Resource = $r('app.color.bg_element_hydro_2')
  bgElementHydro3: Resource = $r('app.color.bg_element_hydro_3')
  bgElementPyro1: Resource = $r('app.color.bg_element_pyro_1')
  bgElementPyro2: Resource = $r('app.color.bg_element_pyro_2')
  bgElementPyro3: Resource = $r('app.color.bg_element_pyro_3')
  bgElementElectro1: Resource = $r('app.color.bg_element_electro_1')
  bgElementElectro2: Resource = $r('app.color.bg_element_electro_2')
  bgElementElectro3: Resource = $r('app.color.bg_element_electro_3')
  bgElementAnemo1: Resource = $r('app.color.bg_element_anemo_1')
  bgElementAnemo2: Resource = $r('app.color.bg_element_anemo_2')
  bgElementAnemo3: Resource = $r('app.color.bg_element_anemo_3')
  bgElementGeo1: Resource = $r('app.color.bg_element_geo_1')
  bgElementGeo2: Resource = $r('app.color.bg_element_geo_2')
  bgElementGeo3: Resource = $r('app.color.bg_element_geo_3')
  bgElementCryo1: Resource = $r('app.color.bg_element_cryo_1')
  bgElementCryo2: Resource = $r('app.color.bg_element_cryo_2')
  bgElementCryo3: Resource = $r('app.color.bg_element_cryo_3')
  bgElementDendro1: Resource = $r('app.color.bg_element_dendro_1')
  bgElementDendro2: Resource = $r('app.color.bg_element_dendro_2')
  bgElementDendro3: Resource = $r('app.color.bg_element_dendro_3')
  bgPortrait1: Resource = $r('app.color.bg_portrait_1')
  bgPortrait2: Resource = $r('app.color.bg_portrait_2')
  bgPageDeep: Resource = $r('app.color.bg_page_deep')
  colorTransparent: Resource = $r('app.color.color_transparent')
  loginTabBarBg: Resource = $r('app.color.login_tab_bar_bg')
  loginInputBg: Resource = $r('app.color.login_input_bg')
  qrCodeFg: Color = Color.Black
  qrCodeBg: Color = Color.White
  roleCardServerBg: Resource = $r('app.color.role_card_server_bg')
  roleCardStatBg: Resource = $r('app.color.role_card_stat_bg')
  widgetCardBg: Resource = $r('app.color.widget_card_bg')

  // ---- FontSize ----
  font9: number = 9
  font10: number = 10
  font11: number = 11
  font12: number = 12
  font13: number = 13
  font14: number = 14
  fontBold14: number = 14
  font16: number = 16
  fontBold16: number = 16
  font17: number = 17
  fontMedium17: number = 17
  font18: number = 18
  fontBold18: number = 18
  font20: number = 20
  fontBold20: number = 20
  font24: number = 24
  fontBold24: number = 24
  font26: number = 26
  fontBold26: number = 26

  // ---- Spacing ----
  value0: number = 0
  value1: number = 1
  value1p5: number = 1.5
  value2: number = 2
  value3: number = 3
  value4: number = 4
  value5: number = 5
  value6: number = 6
  value8: number = 8
  value9: number = 9
  value10: number = 10
  value11: number = 11
  value12: number = 12
  value13: number = 13
  value14: number = 14
  value15: number = 15
  value16: number = 16
  value17: number = 17
  value18: number = 18
  value20: number = 20
  value22: number = 22
  value24: number = 24
  value28: number = 28
  value30: number = 30
  value32: number = 32
  value34: number = 34
  value36: number = 36
  value40: number = 40
  value44: number = 44
  value46: number = 46
  value48: number = 48
  value50: number = 50
  value52: number = 52
  value56: number = 56
  value64: number = 64
  value80: number = 80
  value90: number = 90
  value100: number = 100
  value108: number = 108
  value120: number = 120
  value150: number = 150
  value200: number = 200
  value260: number = 260
  value280: number = 280
  value360: number = 360
  value400: number = 400
  value480: number = 480
  value600: number = 600

  // ---- Duration ----
  duration800: number = 800

  // ---- Percent ----
  full: string = '100%'
  pct90: string = '90%'
  pct80: string = '80%'
  pct40: string = '40%'
  pct45: string = '45%'
  pct35: string = '35%'

  // ---- Radius ----
  radius8: number = 8
  radius12: number = 12
  radius16: number = 16

  // ---- Shadow ----
  shadowRadius: number = 8
  shadowOffsetY: number = 2
  shadowColor: Resource = $r('app.color.color_shadow')

  // ---- Angle ----
  a0: number = 0
  a90: number = 90
  a135: number = 135
  a150: number = 150
  a180: number = 180

  // ---- Opacity ----
  shimmerOpacityHigh: number = 1.0
  shimmerOpacityLow: number = 0.3
  charDetailConsInactiveOpacity: number = 0.3
  charDetailLockIconRatio: number = 0.6
  opacity03: number = 0.3
  opacity06: number = 0.6

  constructor() {
    // 无需初始化，所有字段已在声明时赋值
  }
}
