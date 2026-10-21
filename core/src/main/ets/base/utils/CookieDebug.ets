/**
 * CookieDebug — 返回码判断工具
 */
export class CookieDebug {
  /** 是否为登录过期类返回码（-100 / 10001） */
  static isAuthExpiredCode(retcode: number | undefined): boolean {
    return retcode === -100 || retcode === 10001;
  }
}
