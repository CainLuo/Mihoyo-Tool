/**
 * QRCodeLoginModels.ets
 *
 * 二维码登录流程相关的数据模型。
 * 对应接口：
 *   POST /hk4e_cn/combo/panda/qrcode/fetch  — 获取二维码 URL
 *   POST /hk4e_cn/combo/panda/qrcode/query  — 轮询扫码状态
 */

// ─── 获取二维码 ───────────────────────────────────────────────────

/** fetchQRCode 接口响应 */
export interface QRCodeFetchResponse {
  retcode: number;
  message: string;
  data: QRCodeFetchData;
}

interface QRCodeFetchData {
  /** 二维码指向的 URL，传给 ArkUI QRCode 组件展示 */
  url: string;
}

/** fetchQRCode 业务结果 */
export class QRCodeFetchResult {
  /** 二维码完整 URL */
  url: string = '';
  /** 从 URL 中提取的 ticket，用于后续轮询 */
  ticket: string = '';
}

// ─── 轮询扫码状态 ─────────────────────────────────────────────────

/** queryQRCode 接口响应 */
export interface QRCodeQueryResponse {
  retcode: number;
  message: string;
  data: QRCodeQueryData | null;
}

interface QRCodeQueryData {
  /** 扫码状态：Init / Scanned / Confirmed */
  stat: string;
  payload: QRCodePayload;
}

interface QRCodePayload {
  /** 数据协议类型：Raw / Account */
  proto: string;
  /** Confirmed 后为 JSON 字符串：{"uid":"xxx","token":"xxx"} */
  raw: string;
  /** 扩展字段（通常为空） */
  ext: string;
}

/** 二维码扫描确认后从 payload.raw 解析出的数据 */
export interface QRCodeConfirmedData {
  /** 米游社账号 UID */
  uid: string;
  /** game_token，用于换取 SToken */
  token: string;
}

/** queryQRCode 业务结果 */
export class QRCodeQueryResult {
  /** 扫码状态（小写）：init / scanned / confirmed / expired */
  stat: string = '';
  /** 扫码确认后的数据，仅 stat=confirmed 时非 null */
  confirmed: QRCodeConfirmedData | null = null;
}
