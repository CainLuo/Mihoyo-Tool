/**
 * PhoneLoginModels.ets（仅 internal，手机号登录数据模型）
 */

export interface MmtData {
  mmt_key: string;
  gt?: string;
  challenge?: string;
  risk_type?: string;
  new_captcha?: number;
  success?: number;
  use_v4?: boolean;
}

export interface MmtResponse {
  code: number;
  data: MmtResponseData;
}

interface MmtResponseData {
  mmt_data: MmtData;
  mmt_type: number;
  msg: string;
  scene_type: number;
  status: number;
}

export interface GeetestV4Data {
  lot_number: string;
  captcha_output: string;
  pass_token: string;
  gen_time: string;
  captcha_id: string;
  sign_token: string;
}

export interface PhoneLoginAccountInfo {
  account_id: number;
  area_code: string;
  mobile: string;
  weblogin_token: string;
}

export interface PhoneLoginResponse {
  code: number;
  data: PhoneLoginResponseData;
}

interface PhoneLoginResponseData {
  account_info: PhoneLoginAccountInfo;
  msg: string;
  status: number;
}

export class LoginMobileResult {
  stoken: string = '';
  aid: string = '';
  mid: string = '';
}
