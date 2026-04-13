/**
 * AccountRow.ets
 *
 * 米游社账号数据库行模型，对应 account_table 表。
 */
export class AccountRow {
  /** 本地数据库自增 ID */
  id: number = 0;
  /** 米游社用户名（唯一键，用于 upsert 判断） */
  username: string = '';
  /** 完整 Cookie 字符串（account_id + cookie_token + ltoken + ltuid） */
  cookie: string = '';
  /** SToken（长期有效，用于刷新 cookie_token / ltoken） */
  stoken: string = '';
  /** SToken 对应的 stuid（账号 ID） */
  stuid: string = '';
  /** 设备 mid（与 stoken 配套使用） */
  mid: string = '';
  /** 是否为当前激活账号（0=否，1=是） */
  isActive: number = 0;
  /** 账号创建时间（Unix 秒） */
  createTime: number = 0;
  /** 账号最后更新时间（Unix 秒） */
  updateTime: number = 0;
  /** 米游社账号 UID */
  uid: string = '';
  /** 米游社昵称 */
  nickname: string = '';
  /** 头像 URL */
  avatarUrl: string = '';
  /** 个人简介 */
  introduce: string = '';
  /** 原始 API 响应 JSON（来自 getUserFullInfo） */
  rawJson: string = '';
}
