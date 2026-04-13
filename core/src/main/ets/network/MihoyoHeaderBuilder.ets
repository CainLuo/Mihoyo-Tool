import { RequestParams } from './APIs';
import { ApiConfig } from './ApiConfig';
import { DSUtil } from './DSUtil';
import { HKey, HVal } from './MihoyoHeaderKey';

/** 请求头 Profile 枚举 */
export enum HeaderProfile {
  /** 原神/星铁 游戏记录接口（有 DS，Referer=webstatic，client_type=5） */
  GAME_RECORD = 'GAME_RECORD',
  /** 绝区零 游戏记录接口（无 DS，Referer=act，带 language/platform） */
  ZZZ_GAME_RECORD = 'ZZZ_GAME_RECORD',
  /** 养成计算接口（原神/星铁，无 DS，Referer=act） */
  CALCULATE = 'CALCULATE',
  /** BBS 账号 + 游戏角色绑定 + 战绩卡片 + Geetest（有 DS，Referer=app，client_type=1） */
  BBS = 'BBS',
  /**
   * 签到接口（大别野 + 各游戏）
   * 使用 X6 salt，client_type=2，Referer=act
   * 游戏签到额外需要 x-rpc-signgame 头（由调用方在 build() 后手动 set）
   */
  SIGN = 'SIGN',
}

export class MihoyoHeaderBuilder {
  /**
   * 构建请求头 Map
   * @param profile  请求头 Profile
   * @param cookie   登录 Cookie
   * @param params   GET 请求参数（用于 DS 签名的 query 部分，POST 请求传 undefined）
   * @param body     POST 请求 body 字符串（用于 DS 签名的 body 部分，GET 请求传 undefined）
   */
  static build(
    profile: HeaderProfile,
    cookie: string,
    params?: RequestParams,
    body?: string,
  ): Map<string, string> {
    const h = new Map<string, string>();

    // ── 所有接口共有 ──────────────────────────────────────────────
    h.set(HKey.APP_VERSION, ApiConfig.APP_VERSION);
    h.set(HKey.DEVICE_ID, ApiConfig.getDeviceIdSync());
    h.set(HKey.DEVICE_FP, ApiConfig.getDeviceFp());
    h.set(HKey.SYS_VERSION, HVal.SYS_VERSION_IOS);
    h.set(HKey.COOKIE, cookie);
    h.set(HKey.USER_AGENT, ApiConfig.USER_AGENT);
    h.set(HKey.ACCEPT, HVal.ACCEPT_JSON);

    // ── 按 Profile 差异化注入 ─────────────────────────────────────
    if (profile === HeaderProfile.GAME_RECORD) {
      h.set(HKey.CLIENT_TYPE, HVal.CLIENT_WEB);
      h.set(HKey.TOOL_VERSION, ApiConfig.TOOL_VERSION_GENSHIN);
      h.set(HKey.REFERER, HVal.REFERER_WEBSTATIC);
      h.set(HKey.ORIGIN, HVal.WEBSTATIC);
      h.set(HKey.DS, DSUtil.generateV1(params, body));
    } else if (profile === HeaderProfile.ZZZ_GAME_RECORD) {
      h.set(HKey.LANGUAGE, HVal.LANG_ZH_CN);
      h.set(HKey.PLATFORM, HVal.PLATFORM_ANDROID);
      h.set(HKey.REFERER, HVal.REFERER_ACT);
      h.set(HKey.ORIGIN, HVal.ORIGIN_ACT);
    } else if (profile === HeaderProfile.CALCULATE) {
      h.set(HKey.REFERER, HVal.REFERER_ACT);
      h.set(HKey.ORIGIN, HVal.ORIGIN_ACT);
    } else if (profile === HeaderProfile.BBS) {
      h.set(HKey.CLIENT_TYPE, HVal.CLIENT_IOS);
      h.set(HKey.REFERER, HVal.APP_MIHOYO);
      h.set(HKey.ORIGIN, HVal.APP_MIHOYO);
      h.set(HKey.DS, DSUtil.generateV2(params, body));
    } else if (profile === HeaderProfile.SIGN) {
      h.set(HKey.CLIENT_TYPE, HVal.CLIENT_ANDROID);
      h.set(HKey.REFERER, HVal.REFERER_ACT);
      h.set(HKey.ORIGIN, HVal.ORIGIN_ACT);
      h.set(HKey.DS, DSUtil.generateX6(params, body));
    }

    return h;
  }
}
