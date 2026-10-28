/**
 * SignalStorageKey — 全局信号在 AppStorageV2 中的 key
 *
 * 只用于 AppStorageV2.connect()。值会被持久引用，不要修改。
 * @Monitor 路径直接写字面量（如 @Monitor('geetestSignal.trigger')），不放在这里；
 * 改 @Local 字段名或 ViewModel 字段名时，要同步修改对应的 @Monitor 字面量。
 */
export enum SignalStorageKey {
  /** GeetestSignal 在 AppStorage 中的 key */
  GEETEST_SIGNAL_KEY = 'GeetestSignal',

  /** CookieExpiredSignal 在 AppStorage 中的 key */
  COOKIE_EXPIRED_SIGNAL_KEY = 'CookieExpiredSignal',
}
