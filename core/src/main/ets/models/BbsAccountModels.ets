/**
 * BbsAccountModels.ets
 *
 * 米游社 BBS 账号详情相关的数据模型。
 * 对应接口：
 *   GET /user/wapi/getUserFullInfo  — 获取 BBS 账号详情（nickname、avatar_url）
 */

// ─── API 响应结构 ─────────────────────────────────────────────────

/** getUserFullInfo 响应中的用户基础信息 */
export interface BbsUserInfo {
  /** 米游社账号 UID */
  uid: string;
  /** 米游社昵称 */
  nickname: string;
  /** 头像 URL */
  avatar_url: string;
}

/** getUserFullInfo 响应中的 data 字段 */
export interface BbsAccountDetailData {
  user_info: BbsUserInfo;
}

/** getUserFullInfo 接口响应 */
export interface BbsAccountDetailResponse {
  retcode: number;
  message: string;
  data: BbsAccountDetailData;
}

// ─── 业务结果 ─────────────────────────────────────────────────────

/** BBS 账号详情业务结果（供 entry 层使用） */
export class BbsAccountDetailResult {
  /** 米游社账号 UID */
  uid: string = '';
  /** 米游社昵称 */
  nickname: string = '';
  /** 头像 URL */
  avatarUrl: string = '';
  /** 原始 API 响应 JSON（用于调试） */
  rawJson: string = '';
}
