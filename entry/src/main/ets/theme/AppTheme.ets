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
  colorCardBg: Resource         // 卡片背景色
  colorCardBorder: Resource     // 卡片描边色
  colorPageBg: Resource         // 页面背景色（与卡片形成层次对比）
  colorPlaceholder: Resource    // 占位符/边框色
  colorMask: Resource           // 遮罩色
  colorDanger: Resource         // 危险操作色（删除等）
  colorDangerBg: Resource       // 危险操作背景色
  colorWarning: Resource        // 警告色（树脂接近满时）
}

// ---- 字体 Token ----
// 注意：不能命名为 Font，与 ArkUI 内置类型冲突
// 每个字段返回完整 Font 对象，size + weight + family 一起切换
export interface AppFont {
  body13: Font        // 辅助说明文字
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
  qrCodeSize: number      // 200vp — 二维码尺寸
}

// ---- 顶层 Protocol ----
export interface Theme extends AppColor, AppFont, Spacing, Radius, Shadow, Size {}

// ---- 辅助函数 ----
// 用函数构造 Font 对象，规避 ArkTS arkts-no-untyped-obj-literals 限制
export function makeFont(size: number, weight: FontWeight, family: string = ''): Font {
  const f: Font = { size: size, weight: weight, family: family }
  return f
}
