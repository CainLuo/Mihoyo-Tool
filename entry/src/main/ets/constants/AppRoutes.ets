/**
 * AppRoutes — 全局路由 Path 常量
 *
 * 所有 HMRouter pageUrl 必须从此处引用，禁止在页面文件中直接写 path 字符串。
 * 新增页面时在此处添加对应常量。
 */
export class AppRoutes {
  static readonly MAIN = 'Main'
  static readonly LOGIN = 'Login'
  static readonly SETTING = 'Setting'
  static readonly GENSHIN_DAILY_DETAIL = 'GenshinDailyDetail'
  static readonly GENSHIN_CHARACTER_DETAIL = 'GenshinCharacterDetail'
}
