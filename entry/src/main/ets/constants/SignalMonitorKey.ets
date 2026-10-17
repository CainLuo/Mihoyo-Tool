/**
 * SignalMonitorKey — @Monitor 路径字符串枚举
 *
 * 所有 @Monitor 装饰器的路径字符串必须使用此枚举，禁止硬编码。
 * 格式：<Signal/ViewModel 名称>.<字段名>
 *
 * 分类：
 * - AppStorage keys：用于 AppStorageV2.connect()
 * - @Monitor 路径：用于 @Monitor 装饰器
 */
export enum SignalMonitorKey {
  // ─────────────────────────────────────────────────────────────
  // AppStorage keys（用于 AppStorageV2.connect）
  // ─────────────────────────────────────────────────────────────
  
  /** GeetestSignal 在 AppStorage 中的 key */
  GEETEST_SIGNAL_KEY = 'GeetestSignal',
  
  /** CookieExpiredSignal 在 AppStorage 中的 key */
  COOKIE_EXPIRED_SIGNAL_KEY = 'CookieExpiredSignal',
  
  // ─────────────────────────────────────────────────────────────
  // @Monitor 路径（用于 @Monitor 装饰器）
  // ─────────────────────────────────────────────────────────────
  
  // Signal 路径
  /** GeetestSignal.trigger 字段监听路径 */
  GEETEST_TRIGGER = 'geetestSignal.trigger',
  
  /** CookieExpiredSignal.queue 字段监听路径 */
  COOKIE_EXPIRED_QUEUE = 'cookieExpiredSignal.queue',
  
  // HomeViewModel 路径
  /** HomeViewModel.viewState 字段监听路径 */
  HOME_VIEW_STATE = 'vm.viewState',
  
  /** HomeViewModel.isRefreshing 字段监听路径 */
  HOME_IS_REFRESHING = 'vm.isRefreshing',
  
  /** HomeViewModel.networkErrorMsg 字段监听路径 */
  HOME_NETWORK_ERROR = 'vm.networkErrorMsg',
  
  /** HomeViewModel.geetestTrigger 字段监听路径 */
  HOME_GEETEST_TRIGGER = 'vm.geetestTrigger',
  
  /** HomeViewModel.refreshCoolingDown 字段监听路径 */
  HOME_REFRESH_COOLING = 'vm.refreshCoolingDown',
  
  /** HomeViewModel.refreshResult 字段监听路径 */
  HOME_REFRESH_RESULT = 'vm.refreshResult',
}
