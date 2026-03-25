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
 *   1. 新增子接口（如 Animation）并在 Theme 中 extends
 *   2. 在 DefaultTheme 中补全默认值（编译器强制提示）
 *   3. DarkTheme / 自定义主题按需覆盖
 * ============================================================
 */

// ---- 颜色 Token ----
// 注意：不能命名为 Color，与 ArkUI 内置枚举冲突
// 颜色值通过 $r('app.color.xxx') 引用，系统自动处理 light/dark 切换
export interface AppColor {
  colorPrimary: Resource        // 主题色
  colorTextPrimary: Resource    // 主文字色
  colorTextSecondary: Resource  // 次要文字色
  colorDivider: Resource        // 分割线色
  colorCardBg: Resource         // 卡片背景色（NavBar/TabBar/Sidebar Chrome 层，dark mode 下与页面背景融合）
  colorSurfaceCard: Resource    // 内容卡片背景色（GameToolCard/CharacterCard 等，比页面背景稍亮）
  colorCardBorder: Resource     // 卡片描边色
  colorPageBg: Resource         // 页面背景色（与卡片形成层次对比）
  colorPlaceholder: Resource    // 占位符/边框色
  colorMask: Resource           // 遮罩色
  colorDanger: Resource         // 危险操作色（删除等）
  colorDangerBg: Resource       // 危险操作背景色
  colorWarning: Resource        // 警告色（树脂接近满时）
  colorSkeletonBg: Resource     // 骨架屏色块背景色（比卡片背景明显亮一档，深色模式下可见）
}

// ---- 字体 Token ----
// 注意：不能命名为 Font，与 ArkUI 内置类型冲突
// 每个字段返回完整 Font 对象，size + weight + family 一起切换
export interface AppFont {
  body10: Font        // 极小辅助文字（武器等级/精炼 Phone）
  body12: Font        // 小辅助文字（角标、占位提示）
  body13: Font        // 辅助说明文字
  body13Bold: Font    // 角色名（Phone）
  body15Bold: Font    // 角色名（非 Phone）
  body16: Font        // 正文
  body16Medium: Font  // 标题栏文字
  title18Bold: Font   // 导航标题
  title20Bold: Font   // 页面标题
  title24Bold: Font   // 大标题
  title26Bold: Font   // 超大标题
}

// ---- 间距 Token ----
// 命名直接用数值，一眼知道是多少 vp
export interface Spacing {
  value2: number   // 2vp  — 极小间距
  value4: number   // 4vp  — 小间距
  value8: number   // 8vp
  value10: number  // 10vp
  value12: number  // 12vp
  value16: number  // 16vp（同时用于 list space、水平边距等）
  value20: number  // 20vp
  value40: number  // 40vp
}

// ---- 圆角 Token ----
export interface Radius {
  radius8: number   // 8vp  — 输入框、小卡片
  radius12: number  // 12vp — 弹窗卡片
  radius16: number  // 16vp — 首页游戏卡片
}

// ---- 阴影 Token ----
export interface Shadow {
  shadowRadius: number   // 阴影模糊半径
  shadowOffsetY: number  // 阴影垂直偏移
  shadowColor: Resource  // 阴影颜色（跟随 light/dark 资源）
}

// ---- 尺寸 Token ----
// 只放属于设计决策的固定值
// TabBar/StatusBar/NavigationBar 高度不在此处，由 ArkUI 布局系统自动处理
export interface Size {
  widthFull: string       // '100%'
  heightFull: string      // '100%'
  widthButton: string     // '90%' — 标准按钮宽度
  widthButtonSM: string   // '80%' — 次要按钮宽度
  heightButton: number    // 50vp  — 标准按钮高度
  heightNavBar: number    // 56vp  — 顶部导航栏高度
  heightTextArea: number  // 150vp — 文本输入区高度
  dialogMinWidth: number  // 280vp — 弹窗最小宽度
  dialogMaxWidth: number  // 400vp — 弹窗最大宽度
  contentMaxWidth: number // 600vp — 详情页内容区最大宽度（宽屏居中限宽）
  iconSizeMD: number      // 22vp  — 导航栏/工具栏图标尺寸
  iconSizeXL: number      // 64vp  — 大图标/emoji 占位尺寸（Placeholder 页）
  avatarSizeMD: number    // 36vp  — 标准头像尺寸
  avatarSizeSM: number    // 28vp  — 小头像尺寸（首页账号行）
  avatarRadius: number    // 50%等效 — 头像圆角（avatarSize / 2）
  gameBarWidth: number    // 4vp   — 游戏色条宽度
  gameBarHeightMD: number // 36vp  — 游戏色条高度（卡片头部）
  gameBarHeightSM: number // 32vp  — 游戏色条高度（设置页角色行）
  gameBarRadius: number   // 2vp   — 游戏色条圆角
  progressSizeMD: number  // 52vp  — 环形进度条尺寸
  progressStroke: number  // 5vp   — 环形进度条描边宽度
  skeletonCardH: number   // 100vp — 骨架屏卡片色块高度
  skeletonTextW: number   // 120vp — 骨架屏文字色块宽度
  skeletonAvatarSize: number // 36vp — 骨架屏头像色块尺寸
  animDurationShimmer: number // 800ms — 骨架屏呼吸动画时长
  shimmerOpacityHigh: number  // 1.0   — 骨架屏呼吸动画高透明度
  shimmerOpacityLow: number   // 0.3   — 骨架屏呼吸动画低透明度
  windowWidthDefault: number  // 360vp — 窗口宽度初始默认值（获取真实值前的 fallback）
  webHeightDefault: number    // 360vp — Web 组件高度初始默认值
  avatarRadiusSM: number  // 14vp  — 小头像圆角（avatarSizeSM / 2）
  iconSizeSM: number      // 32vp  — 小图标尺寸（DailyNoteCard 图标）
  expeditionAvatarSize: number // 40vp — 派遣头像尺寸
  expeditionAvatarRadius: number // 20vp — 派遣头像圆角
  labelWidth: number      // 56vp  — 便签标签固定宽度
  blankHeightSM: number   // 20vp  — 小空白占位高度
  skeletonBlockH: number  // 16vp  — 骨架屏默认文字色块高度
  skeletonBlockR: number  // 8vp   — 骨架屏默认色块圆角
  cardBorderWidth: number // 1vp   — 卡片描边宽度
  sidebarWidth: number    // 200vp — Foldable/PC 侧边导航栏宽度
  qrCodeSize: number      // 200vp — 二维码尺寸
  characterIconHeight: number // 80vp  — 角色卡片头像高度
  weaponOverlaySize: number  // 64vp  — 武器图标容器尺寸
  weaponIconSize: number     // 48vp  — 武器图标尺寸（已废弃，图标现在铺满容器）
  weaponAffixTagH: number    // 16vp  — 精炼标签高度（保留兼容）
  weaponInfoBarH: number     // 18vp  — 武器浮层底部信息栏高度
  elementBadgeSize: number   // 30vp  — 元素角标尺寸
  constellationBadgeSize: number // 22vp — 命座圆形徽章尺寸（列表页）
  charDetailConsBadgeSize: number // 28vp — 命座圆形徽章尺寸（详情页，更大）
  weaponAffixBadgeSize: number   // 18vp — 精炼圆形徽章尺寸
  relicIconSize: number      // 44vp  — 圣遗物小图标尺寸（非 Phone 卡片）
  skillIconSize: number      // 40vp  — 技能图标尺寸（非 Phone 卡片）
  skillBadgeSize: number     // 18vp  — 技能等级徽章尺寸
  borderWidthMedium: number  // 1.5vp — 命座徽章描边宽度
  dividerHeightSM: number    // 10vp  — 信息区竖向分割线高度
  skillLevelRowHeight: number // 56vp — 技能行固定高度（skillIconSize + 16）
  body11FontSize: number     // 11vp  — 底部 Tab 文字大小
  relicIconSizeLG: number    // 40vp  — lg 断点圣遗物图标尺寸
  relicIconSizeSM: number    // 32vp  — sm/md 断点圣遗物图标尺寸
  skillIconSizeLG: number    // 36vp  — lg 断点技能图标尺寸
  skillIconSizeSM: number    // 28vp  — sm/md 断点技能图标尺寸
  skillLevelRowHeightLG: number // 52vp — lg 断点技能行高度（skillIconSizeLG + 16）
  skillLevelRowHeightSM: number // 44vp — sm/md 断点技能行高度（skillIconSizeSM + 16）
  charDetailHeroPanelPortraitH: number // 260vp — 角色详情页 Phone 竖屏立绘区高度
  charDetailHeroPanelLandscapeW: number // 200vp — 角色详情页 Phone 横屏立绘区宽度
  charDetailSkillIconSize: number       // 34vp  — 立绘区 Phone 技能图标尺寸
  charDetailSkillIconRadius: number     // 17vp  — 立绘区 Phone 技能图标圆角
  charDetailNameFontSizePortrait: number // 22vp — Phone 竖屏角色名字体大小
  charDetailNameFontSizeLandscape: number // 15vp — Phone 横屏角色名字体大小
  charDetailWeaponIconSizeLG: number    // 52vp  — 宽屏武器图标尺寸
  charDetailWeaponIconSizeSM: number    // 36vp  — Phone 武器图标尺寸
  charDetailRelicLeftColWidth: number   // 90vp  — 宽屏圣遗物左列宽度
  charDetailConsMarginRight: number     // 12vp  — 命座列距右边缘间距
  charDetailSkillBottomOffset: number   // 24vp  — 技能区距底部偏移量（offset.y 负值）

  // ---- Surface 颜色 Token ----
  surfaceActivePrimary: Resource      // 主色激活态（命座激活背景）
  surfaceDark2xl: Resource            // 极强黑色叠加（命座未激活/技能背景）
  surfaceActiveBorder: Resource       // 主色激活描边
  surfaceInactiveBorder: Resource     // 未激活描边
  surfaceSkillBorderPhone: Resource   // Phone 技能图标描边
  surfaceFetterBg: Resource           // 好感度标签背景
  surfaceFetterBorder: Resource       // 好感度标签描边
  surfaceGlassXs: Resource            // 极弱玻璃感（卡片背景）
  surfaceGlassSm: Resource            // 弱玻璃感（图标背景/分割线）
  surfaceGlassMd: Resource            // 中玻璃感（图标背景/遮罩）
  surfaceOverlaySm: Resource          // 弱白色叠加（分割线）
  surfaceOverlayMd: Resource          // 中白色叠加（分割线）
  surfaceDarkXs: Resource             // 极弱黑色叠加
  surfaceDarkMd: Resource             // 中黑色叠加（圣遗物行背景）
  surfaceDarkLg: Resource             // 较强黑色叠加（属性网格/圣遗物面板）
  surfaceDarkXl: Resource             // 强黑色叠加（属性面板背景）

  // ---- Text 颜色 Token ----
  textOnDarkMedium: Resource          // 中等文字（等级）
  textOnDarkSecondary: Resource       // 次要文字（属性标签）
  textOnDarkTertiary: Resource        // 三级文字（圣遗物副词条标签）
  textOnDarkMuted: Resource           // 弱文字（武器等级/圣遗物主词条标签）
  textOnDarkFaint: Resource           // 极弱文字（圣遗物等级）
  textOnDarkGhost: Resource           // 幽灵文字（Phone 小字）
  textOnDarkHigh: Resource            // 高亮文字（圣遗物副词条值）
  textInactive: Resource              // 未激活状态文字
  textLockIcon: Resource              // 锁图标颜色

  // ---- Accent 颜色 Token ----
  accentRefine: Resource              // 精炼/星级金色
  accentRefineBg: Resource            // 精炼标签背景
  accentPrimaryStrong: Resource       // 圣遗物主词条强调色

  // ---- Overlay 颜色 Token ----
  overlayScrImTop: Resource           // 宽屏遮罩底部不透明色
  overlayGradientEnd: Resource        // 角色卡片底部渐变遮罩终止色
  overlayShadow: Resource             // 文字阴影颜色
  overlayPortraitBase: Resource       // Phone 竖屏遮罩基色
  overlayPortraitStrong: Resource     // Phone 竖屏遮罩强
  overlayPortraitMid: Resource        // Phone 竖屏遮罩中
  overlayPortraitBot: Resource        // Phone 竖屏底部遮罩
  overlayLandOpaque: Resource         // Phone 横屏遮罩不透明
  overlayLandStrong: Resource         // Phone 横屏遮罩强
  overlayLandFade: Resource           // Phone 横屏遮罩淡出

  // ---- Background 渐变色 Token ----
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

  // ---- 渐变透明色 ----
  colorTransparent: Resource

  // ---- 尺寸/间距 Token（角色详情页专用）----
  charDetailConsInactiveOpacity: number   // 命座未激活透明度
  charDetailLockIconRatio: number         // 锁图标相对命座尺寸的比例
  charDetailRightPaddingPortrait: string  // Phone 竖屏右侧留白百分比
  charDetailRightPaddingLandscape: string // Phone 横屏右侧留白百分比
  charDetailBorderWidth: number           // 通用描边宽度（1vp）
  charDetailPaddingTiny: number           // 极小 padding（1vp，用于标签上下）
  charDetailStatsPaddingV: number         // 属性网格行上下 padding（5vp）
  charDetailRelicSubPaddingV: number
  charDetailRelicMainPaddingV: number
  charDetailRelicFontSizeTiny: number
  charDetailRelicCardSpacing: number

  // ---- 启动页 Token ----
  launchLogoSize: number      // 120vp — 启动页 Logo 尺寸
  launchLogoRadius: number    // 28vp  — 启动页 Logo 圆角

  // ---- 登录页 Token ----
  loginNarrowBreakpoint: number  // 480vp — 单栏/双栏切换断点
  loginLogoSizeSM: number        // 52vp  — 单栏 Logo 尺寸
  loginLogoSizeLG: number        // 56vp  — 双栏 Logo 尺寸
  loginWideGap: number           // 48vp  — 双栏间距
  loginWidePaddingH: number      // 40vp  — 双栏水平内边距
  loginTabBarBg: Resource        // Tab 栏背景色
  loginTabBarMarginBottom: number // 18vp — Tab 栏底部间距
  loginInputHeight: number       // 46vp  — 输入框高度
  loginInputBg: Resource         // 输入框背景色
  loginButtonFontSize: number    // 15vp  — 登录按钮字体大小
  loginFeatureDotSize: number    // 5vp   — 特性列表圆点尺寸
  loginCookieAreaHeight: number  // 108vp — Cookie 输入区高度
  value0: number                 // 0vp   — 零间距

  // ---- 渐变角度 Token ----
  gradientAngle135: number   // 135° — 元素背景渐变方向
  gradientAngle150: number   // 150° — Phone 背景渐变方向
  gradientAngle180: number   // 180° — 上下遮罩渐变方向（从上到下）
  gradientAngle90: number    // 90°  — 左右遮罩渐变方向（从左到右）
  gradientAngle0: number     // 0°   — 底部遮罩渐变方向（从下到上）
}
export interface Theme extends AppColor, AppFont, Spacing, Radius, Shadow, Size {}

// ---- 辅助函数 ----
// 用函数构造 Font 对象，规避 ArkTS arkts-no-untyped-obj-literals 限制
export function makeFont(size: number, weight: FontWeight, family: string = ''): Font {
  const f: Font = { size: size, weight: weight, family: family }
  return f
}
