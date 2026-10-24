/**
 * CookieDebug — 登录过期类 retcode 判断工具。
 *
 * 具体码值统一由 RetcodeRegistry 管理；本类只保留旧调用方需要的兼容入口。
 */
import { RetcodeRegistry } from '../errors/RetcodeRegistry';

export class CookieDebug {
  /** 是否为登录过期类返回码（-100 / 10001 / -111） */
  static isAuthExpiredCode(retcode: number | undefined): boolean {
    return RetcodeRegistry.isAuthExpired(retcode);
  }
}
