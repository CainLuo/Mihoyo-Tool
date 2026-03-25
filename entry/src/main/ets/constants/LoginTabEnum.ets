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
