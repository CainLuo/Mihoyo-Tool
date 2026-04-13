/**
 * QRCodeApiPath — 二维码登录接口路径
 *
 * Domain: MihoyoDomain.HK4E_SDK（https://hk4e-sdk.mihoyo.com）
 * 完整 URL = HK4E_SDK + 游戏路径前缀 + 接口路径
 * 例：https://hk4e-sdk.mihoyo.com/hk4e_cn/combo/panda/qrcode/fetch
 */
export enum QRCodeApiPath {
  /** 获取二维码 URL（含 ticket）— POST */
  FETCH = '/hk4e_cn/combo/panda/qrcode/fetch',
  /** 轮询扫码状态 — POST */
  QUERY = '/hk4e_cn/combo/panda/qrcode/query',
}
