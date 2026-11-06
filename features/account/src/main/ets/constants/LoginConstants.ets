/**
 * LoginTabEnum.ets — 登录页相关枚举
 *
 * 规范：禁止用字符串字面量做状态/类型判断，必须使用 enum（见 harmonyos-rules.md 第十八节）。
 */

/** 登录方式 Tab */
export enum LoginTab {
  PHONE = 'phone',
  QRCODE = 'qrcode',
  COOKIE = 'cookie',
}

/** 手机号登录步骤 */
export enum PhoneStep {
  INPUT_PHONE = 'input_phone',
  INPUT_CODE = 'input_code',
}

/** 二维码状态 */
export enum QRCodeStat {
  LOADING = 'loading',
  READY = 'ready',
  SCANNED = 'scanned',
  CONFIRMED = 'confirmed',
  EXPIRED = 'expired',
  ERROR = 'error',
}

/** 短信验证码冷却秒数 */
export const SMS_COOLDOWN_SECONDS: number = 60;

/** 二维码轮询间隔（毫秒） */
export const QR_POLL_INTERVAL_MS: number = 2000;

/** 短信冷却倒计时步长（毫秒） */
export const COOLDOWN_TICK_MS: number = 1000;
