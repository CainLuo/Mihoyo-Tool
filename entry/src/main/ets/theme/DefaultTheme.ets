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
  colorCardBg: Resource = $r('app.color.color_card_bg')
  colorSurfaceCard: Resource = $r('app.color.color_surface_card')
  colorCardBorder: Resource = $r('app.color.color_card_border')
  colorPageBg: Resource = $r('app.color.color_page_bg')
  colorPlaceholder: Resource = $r('app.color.color_placeholder')
  colorMask: Resource = $r('app.color.color_mask')
  colorDanger: Resource = $r('app.color.color_danger')
  colorDangerBg: Resource = $r('app.color.color_danger_bg')
  colorWarning: Resource = $r('app.color.color_warning')
  colorSkeletonBg: Resource = $r('app.color.color_skeleton_bg')
  surfaceActivePrimary: Resource = $r('app.color.surface_active_primary')
  surfaceDark2xl: Resource = $r('app.color.surface_dark_2xl')
  surfaceActiveBorder: Resource = $r('app.color.surface_active_border')
  surfaceInactiveBorder: Resource = $r('app.color.surface_inactive_border')
  surfaceSkillBorderPhone: Resource = $r('app.color.surface_skill_border_phone')
  surfaceFetterBg: Resource = $r('app.color.surface_fetter_bg')
  surfaceFetterBorder: Resource = $r('app.color.surface_fetter_border')
  surfaceGlassXs: Resource = $r('app.color.surface_glass_xs')
  surfaceGlassSm: Resource = $r('app.color.surface_glass_sm')
  surfaceGlassMd: Resource = $r('app.color.surface_glass_md')
  surfaceOverlaySm: Resource = $r('app.color.surface_overlay_sm')
  surfaceOverlayMd: Resource = $r('app.color.surface_overlay_md')
  surfaceDarkXs: Resource = $r('app.color.surface_dark_xs')
  surfaceDarkMd: Resource = $r('app.color.surface_dark_md')
  surfaceDarkLg: Resource = $r('app.color.surface_dark_lg')
  surfaceDarkXl: Resource = $r('app.color.surface_dark_xl')
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

  // ---- AppFont ----
  body10: Font = makeFont(10, FontWeight.Normal)
  body12: Font = makeFont(12, FontWeight.Normal)
  body13: Font = makeFont(13, FontWeight.Normal)
  body13Bold: Font = makeFont(13, FontWeight.Bold)
  body15Bold: Font = makeFont(15, FontWeight.Bold)
  body16: Font = makeFont(16, FontWeight.Normal)
  body16Medium: Font = makeFont(16, FontWeight.Medium)
  title18Bold: Font = makeFont(18, FontWeight.Bold)
  title20Bold: Font = makeFont(20, FontWeight.Bold)
  title24Bold: Font = makeFont(24, FontWeight.Bold)
  title26Bold: Font = makeFont(26, FontWeight.Bold)

  // ---- Spacing ----
  value0: number = 0
  value1: number = 1
  value1p5: number = 1.5
  value2: number = 2
  value4: number = 4
  value5: number = 5
  value8: number = 8
  value9: number = 9
  value10: number = 10
  value11: number = 11
  value12: number = 12
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
  value800: number = 800

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
  charDetailLockIconRatio: number = 0.45

  constructor(fontFamily: string = '') {
    if (fontFamily !== '') {
      this.initFonts(fontFamily)
    }
  }

  protected initFonts(family: string): void {
    this.body10 = makeFont(10, FontWeight.Normal, family)
    this.body12 = makeFont(12, FontWeight.Normal, family)
    this.body13 = makeFont(13, FontWeight.Normal, family)
    this.body13Bold = makeFont(13, FontWeight.Bold, family)
    this.body15Bold = makeFont(15, FontWeight.Bold, family)
    this.body16 = makeFont(16, FontWeight.Normal, family)
    this.body16Medium = makeFont(16, FontWeight.Medium, family)
    this.title18Bold = makeFont(18, FontWeight.Bold, family)
    this.title20Bold = makeFont(20, FontWeight.Bold, family)
    this.title24Bold = makeFont(24, FontWeight.Bold, family)
    this.title26Bold = makeFont(26, FontWeight.Bold, family)
  }
}
