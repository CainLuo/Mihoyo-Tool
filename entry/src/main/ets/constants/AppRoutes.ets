/**
 * AppRoutes — 全局路由 Path 常量
 *
 * 所有路由 path 必须从此处引用，禁止在页面文件中直接写 path 字符串。
 * 新增页面时在此处添加对应常量。
 */
export class AppRoutes {
  /** 启动页 */
  static readonly LAUNCH = 'Launch'
  /** 主页（底部 Tab 容器） */
  static readonly MAIN = 'Main'
  /** 登录页 */
  static readonly LOGIN = 'Login'
  /** 原神便笺详情页 */
  static readonly GENSHIN_DAILY_DETAIL = 'GenshinDailyDetail'
  /** 原神角色详情页 */
  static readonly GENSHIN_CHARACTER_DETAIL = 'GenshinCharacterDetail'
  /** 星铁角色详情页 */
  static readonly STARRAIL_CHARACTER_DETAIL = 'StarRailCharacterDetail'
  /** 绝区零角色详情页 */
  static readonly ZZZ_CHARACTER_DETAIL = 'ZZZCharacterDetail'
  /** 账号详情页 */
  static readonly ACCOUNT_DETAIL = 'AccountDetail'
  /** 星铁便笺详情页 */
  static readonly STARRAIL_DAILY_DETAIL = 'StarRailDailyDetail'
  /** 绝区零便笺详情页 */
  static readonly ZZZ_DAILY_DETAIL = 'ZZZDailyDetail'
  /** 测试页（仅开发环境使用） */
  static readonly TEST_PAGE = 'TestPage'
  /** WebView 页（用于展示协议/隐私政策等 HTML 内容） */
  static readonly WEB_VIEW = 'WebView'
  /** 通知设置页 */
  static readonly NOTIFICATION_SETTINGS = 'NotificationSettings'
  /** 外观设置页 */
  static readonly APPEARANCE_SETTINGS = 'AppearanceSettings'
}
