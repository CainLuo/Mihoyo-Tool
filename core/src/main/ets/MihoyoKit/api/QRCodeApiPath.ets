/**
 * QRCodeApiPath — 二维码登录接口路径
 *
 * Domain: MihoyoDomain.PASSPORT_API（https://passport-api.mihoyo.com）
 * 使用新版 passport API，直接返回 stoken，无需 gameToken 转换。
 * 参考：TeyvatGuide、PizzaHelper 的实现
 */
export enum QRCodeApiPath {
  /** 获取二维码 URL（含 ticket）— POST */
  FETCH = '/account/ma-cn-passport/app/createQRLogin',
  /** 轮询扫码状态 — POST */
  QUERY = '/account/ma-cn-passport/app/queryQRLoginStatus',
}

/** 二维码登录专用配置 */
export class QRCodeConfig {
  /** 新版 passport API 的 app_id */
  static readonly APP_ID: string = 'ddxf5dufpuyo';
  /** client_type: 3 = HYPContainer */
  static readonly CLIENT_TYPE: string = '3';
  /** User-Agent: HYPContainer 版本号 */
  static readonly USER_AGENT: string = 'HYPContainer/1.3.3.182';
}
