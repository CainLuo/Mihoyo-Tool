import { AppEnvManager } from '../../common/constants/AppEnvManager';

/**
 * 米游社 API 域名。
 *
 * UAT / Release 使用官方域名；Mock 统一指向本机 local-service。
 * Mock 下保留 BBS_APIHUB 的 /apihub 前缀，其他域名只保留原 path。
 * 直接 REST 路由由 local-service 后续实现，当前只切换域名。
 */

const MOCK_BASE: string = 'http://127.0.0.1:8787';

function resolveDomain(official: string, mockPath: string): string {
  return AppEnvManager.isMock() ? MOCK_BASE + mockPath : official;
}

export class MihoyoDomain {
  /** 米游社游戏记录 API（原神/星铁/绝区零 游戏数据） */
  static get TAKUMI_RECORD(): string {
    return resolveDomain('https://api-takumi-record.mihoyo.com', '');
  }

  /** 米游社主 API（养成计算、账号绑定、游戏签到等） */
  static get TAKUMI(): string {
    return resolveDomain('https://api-takumi.mihoyo.com', '');
  }

  /** 米游社 BBS API（账号详情、Geetest 验证） */
  static get BBS(): string {
    return resolveDomain('https://bbs-api.miyoushe.com', '');
  }

  /**
   * 米游社 BBS ApiHub（大别野签到）
   * 大别野签到完整 URL = BBS_APIHUB + SignApiPath.SIGN_BBS
   */
  static get BBS_APIHUB(): string {
    return resolveDomain('https://bbs-api.miyoushe.com/apihub', '/apihub');
  }

  /** 绝区零养成计算专用 */
  static get ACT_TAKUMI(): string {
    return resolveDomain('https://act-api-takumi.mihoyo.com', '');
  }

  /** Passport API（Cookie 刷新：cookie_token / ltoken） */
  static get PASSPORT(): string {
    return resolveDomain('https://passport-api.mihoyo.com', '');
  }

  /** Passport V4 API（ltoken 验证） */
  static get PASSPORT_V4(): string {
    return resolveDomain('https://passport-api-v4.mihoyo.com', '');
  }

  /** 原神 SDK（二维码登录） */
  static get HK4E_SDK(): string {
    return resolveDomain('https://hk4e-sdk.mihoyo.com', '');
  }

  /** 设备指纹 API（获取真实 device_fp） */
  static get PUBLIC_DATA_API(): string {
    return resolveDomain('https://public-data-api.mihoyo.com', '');
  }
}
