/**
 * ============================================================
 * DefaultTheme — 默认主题
 * ============================================================
 *
 * 颜色全部通过 $r('app.color.xxx') 引用资源系统，
 * light/dark 切换由系统根据 base/dark 目录自动处理，
 * 无需手动维护 DarkTheme。
 *
 * 切换字体：
 *   子类传入 fontFamily，initFonts() 自动用它初始化所有字体 token。
 * ============================================================
 */

import { Theme, makeFont } from './AppTheme'

export class DefaultTheme implements Theme {
  // ---- AppColor（通过资源系统，自动适配 light/dark）----
  colorPrimary: Resource = $r('app.color.color_primary')
  colorTextPrimary: Resource = $r('app.color.color_text_primary')
  colorTextSecondary: Resource = $r('app.color.color_text_secondary')
  colorDivider: Resource = $r('app.color.color_divider')
  colorCardBg: Resource = $r('app.color.color_card_bg')
  colorCardBorder: Resource = $r('app.color.color_card_border')
  colorPageBg: Resource = $r('app.color.color_page_bg')
  colorPlaceholder: Resource = $r('app.color.color_placeholder')
  colorMask: Resource = $r('app.color.color_mask')
  colorDanger: Resource = $r('app.color.color_danger')
  colorDangerBg: Resource = $r('app.color.color_danger_bg')
  colorWarning: Resource = $r('app.color.color_warning')

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
  value2: number = 2
  value4: number = 4
  value8: number = 8
  value10: number = 10
  value12: number = 12
  value16: number = 16
  value20: number = 20
  value40: number = 40

  // ---- Radius ----
  radius8: number = 8
  radius12: number = 12
  radius16: number = 16

  // ---- Shadow ----
  shadowRadius: number = 8
  shadowOffsetY: number = 2
  shadowColor: Resource = $r('app.color.color_shadow')

  // ---- Size ----
  widthFull: string = '100%'
  heightFull: string = '100%'
  widthButton: string = '90%'
  widthButtonSM: string = '80%'
  heightButton: number = 50
  heightNavBar: number = 56
  heightTextArea: number = 150
  dialogMinWidth: number = 280
  dialogMaxWidth: number = 400
  contentMaxWidth: number = 600
  iconSizeMD: number = 22
  iconSizeXL: number = 64
  avatarSizeMD: number = 36
  avatarSizeSM: number = 28
  avatarRadius: number = 18
  gameBarWidth: number = 4
  gameBarHeightMD: number = 36
  gameBarHeightSM: number = 32
  gameBarRadius: number = 2
  progressSizeMD: number = 52
  progressStroke: number = 5
  skeletonCardH: number = 100
  skeletonTextW: number = 120
  skeletonAvatarSize: number = 36
  animDurationShimmer: number = 800
  shimmerOpacityHigh: number = 1.0
  shimmerOpacityLow: number = 0.3
  windowWidthDefault: number = 360
  webHeightDefault: number = 360
  avatarRadiusSM: number = 14
  iconSizeSM: number = 32
  expeditionAvatarSize: number = 40
  expeditionAvatarRadius: number = 20
  labelWidth: number = 56
  blankHeightSM: number = 20
  skeletonBlockH: number = 16
  skeletonBlockR: number = 8
  cardBorderWidth: number = 1
  sidebarWidth: number = 200
  qrCodeSize: number = 200
  characterIconHeight: number = 80
  weaponOverlaySize: number = 64
  weaponIconSize: number = 48
  weaponAffixTagH: number = 16
  elementBadgeSize: number = 30
  constellationBadgeSize: number = 22
  weaponAffixBadgeSize: number = 18
  relicIconSize: number = 44
  skillIconSize: number = 40
  skillBadgeSize: number = 18
  borderWidthMedium: number = 1.5
  dividerHeightSM: number = 10
  skillLevelRowHeight: number = 56
  body11FontSize: number = 11
  relicIconSizeLG: number = 40
  relicIconSizeSM: number = 32
  skillIconSizeLG: number = 36
  skillIconSizeSM: number = 28
  skillLevelRowHeightLG: number = 52
  skillLevelRowHeightSM: number = 44
  charDetailConsBadgeSize: number = 32
  charDetailHeroPanelPortraitH: number = 260
  charDetailHeroPanelLandscapeW: number = 200
  charDetailSkillIconSize: number = 34
  charDetailSkillIconRadius: number = 17
  charDetailNameFontSizePortrait: number = 22
  charDetailNameFontSizeLandscape: number = 15
  charDetailWeaponIconSizeLG: number = 52
  charDetailWeaponIconSizeSM: number = 36
  charDetailRelicLeftColWidth: number = 90
  charDetailConsMarginRight: number = 12
  charDetailSkillBottomOffset: number = 24

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
