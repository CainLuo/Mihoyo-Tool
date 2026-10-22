/**
 * ApiErrorCodes — 兼容层。
 *
 * @deprecated 使用 `MihoyoRetcode`（原始码）+ `RetcodeRegistry`（语义分类）。
 * 这里仅保留旧 import 的兼容性，所有值都转发到 MihoyoRetcode，避免出现第二份数字来源。
 * 新代码禁止再引用本文件。
 */
import { MihoyoRetcode } from './MihoyoRetcode';

export class ApiErrorCodes {
  /** @deprecated 使用 MihoyoRetcode.SUCCESS */
  static readonly SUCCESS: number = MihoyoRetcode.SUCCESS;

  /** @deprecated 使用 MihoyoRetcode.LOGIN_EXPIRED */
  static readonly AUTH_INVALID: number = MihoyoRetcode.LOGIN_EXPIRED;

  /** @deprecated 使用 MihoyoRetcode.LOGIN_EXPIRED_PLEASE_LOGIN */
  static readonly AUTH_INVALID_ALT1: number = MihoyoRetcode.LOGIN_EXPIRED_PLEASE_LOGIN;

  /** @deprecated 使用 MihoyoRetcode.INVALID_REQUEST */
  static readonly INVALID_REQUEST: number = MihoyoRetcode.INVALID_REQUEST;

  /** @deprecated 使用 MihoyoRetcode.RATE_LIMITED */
  static readonly RATE_LIMITED: number = MihoyoRetcode.RATE_LIMITED;

  /** @deprecated 使用 MihoyoRetcode.INVALID_PARAM */
  static readonly INVALID_PARAM: number = MihoyoRetcode.INVALID_PARAM;

  /** @deprecated 使用 MihoyoRetcode.CAPTCHA_REQUIRED_GAME_RECORD */
  static readonly GEETEST_REQUIRED: number = MihoyoRetcode.CAPTCHA_REQUIRED_GAME_RECORD;

  /** @deprecated 使用 MihoyoRetcode.CAPTCHA_REQUIRED */
  static readonly GEETEST_REQUIRED_GENERAL: number = MihoyoRetcode.CAPTCHA_REQUIRED;

  /** @deprecated 使用 MihoyoRetcode.ACCOUNT_NOT_FOUND */
  static readonly ACCOUNT_NOT_FOUND: number = MihoyoRetcode.ACCOUNT_NOT_FOUND;

  /** @deprecated 使用 MihoyoRetcode.CAPTCHA_INVALID */
  static readonly CAPTCHA_INVALID: number = MihoyoRetcode.CAPTCHA_INVALID;

  /** @deprecated 使用 MihoyoRetcode.QR_EXPIRED */
  static readonly QRCODE_EXPIRED: number = MihoyoRetcode.QR_EXPIRED;

  /** @deprecated 使用 MihoyoRetcode.ROLE_NOT_PUBLIC */
  static readonly ROLE_NOT_PUBLIC: number = MihoyoRetcode.ROLE_NOT_PUBLIC;

  /** @deprecated 使用 MihoyoRetcode.ROLE_NOT_FOUND */
  static readonly ROLE_NOT_FOUND: number = MihoyoRetcode.ROLE_NOT_FOUND;
}
