/**
 * ApiConstants.ets
 *
 * 米游社 API 协议层常量：请求体字段名、响应字段名、状态值、特殊 retcode。
 * 禁止在 Repository / Service 中直接写这些字符串字面量。
 */

// ─── 手机号登录 ───────────────────────────────────────────────────

/** loginByMobileCaptcha 请求体 action_type 字段值 */
export const LOGIN_ACTION_TYPE_MOBILE = 'login_by_mobile_captcha';

/** loginByMobileCaptcha / getTokenByGameToken 响应体字段名 */
export const RESP_FIELD_TOKEN = 'token';
export const RESP_FIELD_USER_INFO = 'user_info';
export const RESP_FIELD_AID = 'aid';
export const RESP_FIELD_MID = 'mid';

// ─── 二维码登录 ───────────────────────────────────────────────────

/** queryQRCode retcode：二维码已过期 */
export const RETCODE_QR_EXPIRED = -106;

/** queryQRCode 响应 stat 字段值 */
export const QR_STAT_INIT = 'init';
export const QR_STAT_SCANNED = 'scanned';
export const QR_STAT_CONFIRMED = 'confirmed';
export const QR_STAT_EXPIRED = 'expired';

/** queryQRCode payload.proto 字段值：账号类型（Confirmed 后才有） */
export const QR_PROTO_ACCOUNT = 'Account';

// ─── Cookie 字段名 ────────────────────────────────────────────────

/** Cookie 字符串中的字段名 */
export const COOKIE_FIELD_ACCOUNT_ID = 'account_id';
export const COOKIE_FIELD_COOKIE_TOKEN = 'cookie_token';
export const COOKIE_FIELD_LTOKEN = 'ltoken';
export const COOKIE_FIELD_LTUID = 'ltuid';

// ─── 同步状态 ─────────────────────────────────────────────────────

/** sync_meta.sync_status 字段值 */
export const SYNC_STATUS_PENDING = 'pending';
export const SYNC_STATUS_SYNCING = 'syncing';
export const SYNC_STATUS_SUCCESS = 'success';
export const SYNC_STATUS_FAILED = 'failed';
