/**
 * AppRoutes — 全局路由 Path 常量
 *
 * 所有路由 path 必须从此处引用，禁止在页面文件中直接写 path 字符串。
 * 新增页面时在此处添加对应常量。
 */
export class AppRoutes {
  static readonly LAUNCH = 'Launch'
  static readonly MAIN = 'Main'
  static readonly LOGIN = 'Login'
  static readonly GENSHIN_DAILY_DETAIL = 'GenshinDailyDetail'
  static readonly GENSHIN_CHARACTER_DETAIL = 'GenshinCharacterDetail'
  static readonly STARRAIL_CHARACTER_DETAIL = 'StarRailCharacterDetail'
  static readonly ZZZ_CHARACTER_DETAIL = 'ZZZCharacterDetail'
  static readonly ACCOUNT_DETAIL = 'AccountDetail'
  static readonly STARRAIL_DAILY_DETAIL = 'StarRailDailyDetail'
  static readonly ZZZ_DAILY_DETAIL = 'ZZZDailyDetail'
  static readonly TEST_PAGE = 'TestPage'
  static readonly WEB_VIEW = 'WebView'
  static readonly NOTIFICATION_SETTINGS = 'NotificationSettings'
}
