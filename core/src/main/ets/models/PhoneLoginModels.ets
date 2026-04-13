/**
 * PhoneLoginModels.ets
 *
 * 手机号登录流程相关的数据模型。
 * 对应接口：
 *   POST /account/ma-cn-verifier/verifier/createLoginCaptcha  — 发送短信验证码
 *   POST /account/ma-cn-passport/app/loginByMobileCaptcha     — 提交验证码登录
 */

// ─── Geetest 人机验证 ─────────────────────────────────────────────

/** create_mmt 接口返回的人机验证任务数据 */
export interface MmtData {
  /** 验证任务 key，无论是否需要 Geetest 都会返回 */
  mmt_key: string;
  /** Geetest 应用 ID（需要 v3 验证时才有） */
  gt?: string;
  /** v3 challenge（需要 v3 验证时才有） */
  challenge?: string;
  /** v4 风险类型（需要 v4 验证时才有，如 'slide'） */
  risk_type?: string;
  /** 是否新验证码（v3 专用） */
  new_captcha?: number;
  /** 是否成功（0=需要验证，1=无需验证） */
  success?: number;
  /** 是否使用 v4 验证 */
  use_v4?: boolean;
}

/** create_mmt 接口响应 */
export interface MmtResponse {
  code: number;
  data: MmtResponseData;
}

interface MmtResponseData {
  mmt_data: MmtData;
  /** 0=无需验证，1=需要验证 */
  mmt_type: number;
  msg: string;
  scene_type: number;
  status: number;
}

/** Geetest v4 验证结果（用于发送短信时携带） */
export interface GeetestV4Data {
  /** 批次号 */
  lot_number: string;
  /** 验证输出 */
  captcha_output: string;
  /** 通过 token */
  pass_token: string;
  /** 生成时间 */
  gen_time: string;
  /** 验证码 ID */
  captcha_id: string;
  /** 签名 token */
  sign_token: string;
}

// ─── 手机号登录响应 ───────────────────────────────────────────────

/** 手机号登录成功后的账号信息（API 响应内嵌结构） */
export interface PhoneLoginAccountInfo {
  /** 米游社账号 ID */
  account_id: number;
  /** 区号（如 '+86'） */
  area_code: string;
  /** 手机号（脱敏） */
  mobile: string;
  /** Login Ticket（即 weblogin_token，用于换取 LToken） */
  weblogin_token: string;
}

/** loginByMobileCaptcha 接口响应 */
export interface PhoneLoginResponse {
  code: number;
  data: PhoneLoginResponseData;
}

interface PhoneLoginResponseData {
  account_info: PhoneLoginAccountInfo;
  msg: string;
  status: number;
}

// ─── 业务结果 ─────────────────────────────────────────────────────

/** 手机号登录成功后的 Token 信息（业务结果，供 LoginViewModel 使用） */
export class LoginMobileResult {
  /** SToken（长期有效，用于换取其他 Token） */
  stoken: string = '';
  /** 账号 ID（aid） */
  aid: string = '';
  /** 设备 mid */
  mid: string = '';
}
