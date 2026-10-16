export enum MihoyoDomain {
  /** 米游社游戏记录 API（原神/星铁/绝区零 游戏数据） */
  TAKUMI_RECORD = 'https://api-takumi-record.mihoyo.com',
  /** 米游社主 API（养成计算、账号绑定、游戏签到等） */
  TAKUMI = 'https://api-takumi.mihoyo.com',
  /** 米游社 BBS API（账号详情、Geetest 验证） */
  BBS = 'https://bbs-api.miyoushe.com',
  /**
   * 米游社 BBS ApiHub（大别野签到）
   * 大别野签到完整 URL = BBS_APIHUB + SignApiPath.SIGN_BBS
   */
  BBS_APIHUB = 'https://bbs-api.miyoushe.com/apihub',
  /** 绝区零养成计算专用 */
  ACT_TAKUMI = 'https://act-api-takumi.mihoyo.com',
  /** Passport API（Cookie 刷新：cookie_token / ltoken） */
  PASSPORT = 'https://passport-api.mihoyo.com',
  /** Passport V4 API（ltoken 验证） */
  PASSPORT_V4 = 'https://passport-api-v4.mihoyo.com',
  /** 原神 SDK（二维码登录） */
  HK4E_SDK = 'https://hk4e-sdk.mihoyo.com',
  /** 设备指纹 API（获取真实 device_fp） */
  PUBLIC_DATA_API = 'https://public-data-api.mihoyo.com',
}
