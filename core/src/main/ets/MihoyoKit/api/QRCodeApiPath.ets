/**
 * QRCodeApiPath — 二维码登录接口路径
 *
 * Domain: MihoyoDomain.PASSPORT（https://passport-api.mihoyo.com）
 * 使用新版 passport API，直接返回 stoken，无需 gameToken 转换。
 * header 对齐 TeyvatGuide `passportReq.getQrHeaders`。
 */
import { RequestOptions } from '../../base/network/APIs';
import { ApiConfig } from '../../base/network/ApiConfig';
import { DSUtil } from '../../base/network/DSUtil';
import { HKey, HVal } from '../../base/network/MihoyoHeaderKey';

export enum QRCodeApiPath {
  /** 获取二维码 URL（含 ticket）— POST */
  FETCH = '/account/ma-cn-passport/app/createQRLogin',
  /** 轮询扫码状态 — POST */
  QUERY = '/account/ma-cn-passport/app/queryQRLoginStatus',
}

/** 二维码登录专用配置 */
export class QRCodeConfig {
  /** Passport 二维码登录 app_id */
  static readonly APP_ID: string = ApiConfig.BBS_APP_ID;
  /** client_type: 3 = 二维码登录 */
  static readonly CLIENT_TYPE: string = '3';
  /** User-Agent: TeyvatGuide Capture 变体 */
  static readonly USER_AGENT: string =
    `Mozilla/5.0 miHoYoBBS/${ApiConfig.APP_VERSION} Capture/2.2.0`;

  /**
   * 构建 TeyvatGuide 二维码登录请求头。
   * DS 为 X4，body 参与签名；query 为空。
   */
  static buildOptions(deviceId: string, body: string): RequestOptions {
    const opts = new RequestOptions();
    const h = opts.extraHeaders;
    h.set(HKey.USER_AGENT, QRCodeConfig.USER_AGENT);
    h.set(HKey.ACCEPT, HVal.ACCEPT_ALL);
    h.set(HKey.ACCEPT_LANGUAGE, HVal.ACCEPT_LANG_ZH_CN);
    h.set(HKey.CLIENT_TYPE, QRCodeConfig.CLIENT_TYPE);
    h.set(HKey.APP_VERSION, ApiConfig.APP_VERSION);
    h.set(HKey.SDK_VERSION, ApiConfig.APP_VERSION);
    h.set(HKey.ACCOUNT_VERSION, ApiConfig.APP_VERSION);
    h.set(HKey.APP_ID, QRCodeConfig.APP_ID);
    h.set(HKey.GAME_BIZ, HVal.GAME_BIZ_BBS);
    h.set(HKey.DEVICE_ID, deviceId);
    h.set(HKey.DEVICE_FP, ApiConfig.getDeviceFp());
    h.set(HKey.DEVICE_NAME, ApiConfig.DEVICE_NAME);
    h.set(HKey.DEVICE_MODEL, ApiConfig.DEVICE_MODEL);
    h.set(HKey.DS, DSUtil.generateX4(undefined, body));
    h.set(HKey.CONTENT_TYPE, HVal.JSON);
    return opts;
  }
}
