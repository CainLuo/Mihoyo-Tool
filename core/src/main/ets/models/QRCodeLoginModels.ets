/**
 * QRCodeLoginModels.ets
 *
 * 二维码登录流程相关的数据模型。
 * 对应接口：
 *   POST /account/ma-cn-passport/app/createQRLogin  — 获取二维码 URL
 *   POST /account/ma-cn-passport/app/queryQRLoginStatus  — 轮询扫码状态
 *
 * 新版 passport API 直接返回 stoken，无需 gameToken 转换链。
 */

// ─── 获取二维码 ───────────────────────────────────────────────────

/** createQRLogin 接口响应 */
export interface QRCodeFetchResponse {
  retcode: number;
  message: string;
  data: QRCodeFetchData;
}

interface QRCodeFetchData {
  /** 二维码 ticket，用于后续轮询 */
  ticket: string;
  /** 二维码指向的 URL，传给 ArkUI QRCode 组件展示 */
  url: string;
}

/** createQRLogin 业务结果 */
export class QRCodeFetchResult {
  /** 二维码完整 URL */
  url: string = '';
  /** ticket，用于后续轮询 */
  ticket: string = '';
}

// ─── 轮询扫码状态 ─────────────────────────────────────────────────

/** queryQRLoginStatus 接口响应 */
export interface QRCodeQueryResponse {
  retcode: number;
  message: string;
  data: QRCodeQueryData | null;
}

interface QRCodeQueryData {
  /** 扫码状态：Created / Scanned / Confirmed */
  status: string;
  /** 登录凭证，仅 Confirmed 时存在 */
  tokens?: QRCodeToken[];
  /** 用户信息，仅 Confirmed 时存在 */
  user_info?: QRCodeUserInfo;
}

/** Token 信息 */
interface QRCodeToken {
  /** token 值 */
  token: string;
  /** token 类型：1=stoken, 2=ltoken, 4=cookie_token */
  token_type: number;
}

/** 用户信息 */
interface QRCodeUserInfo {
  /** 账号 ID */
  aid: string;
  /** mid */
  mid: string;
  /** 账号名称 */
  account_name: string;
}

/** 二维码扫描确认后的数据（新版 passport API 直接返回 token） */
export class QRCodeConfirmedData {
  /** 米游社账号 UID（aid） */
  uid: string = '';
  /** stoken */
  stoken: string = '';
  /** ltoken */
  ltoken: string = '';
  /** mid */
  mid: string = '';
}

/** queryQRLoginStatus 业务结果 */
export class QRCodeQueryResult {
  /** 扫码状态（小写）：created / scanned / confirmed / expired */
  stat: string = '';
  /** 扫码确认后的数据，仅 stat=confirmed 时非 null */
  confirmed: QRCodeConfirmedData | null = null;
}
