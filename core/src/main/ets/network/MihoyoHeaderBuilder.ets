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
  /**
   * Widget 便笺接口（原神/星铁/绝区零）
   * 使用 WidgetExtension User-Agent，client_type=1，Referer=app.mihoyo.com
   * Cookie 格式：stuid=xxx;stoken=v2_xxx;mid=xxx（由调用方传入已构造好的 Widget Cookie）
   */
  WIDGET = 'WIDGET',
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
    h.set(HKey.LANGUAGE, HVal.LANG_ZH_CN);
    h.set(HKey.COOKIE, cookie);
    h.set(HKey.USER_AGENT, ApiConfig.USER_AGENT);
    h.set(HKey.ACCEPT, HVal.ACCEPT_JSON);

    // ── 按 Profile 差异化注入 ─────────────────────────────────────
    if (profile === HeaderProfile.GAME_RECORD) {
      h.set(HKey.CLIENT_TYPE, HVal.CLIENT_WEB);
      h.set(HKey.TOOL_VERSION, ApiConfig.TOOL_VERSION_GENSHIN);
      h.set(HKey.REFERER, HVal.REFERER_WEBSTATIC);
      h.set(HKey.ORIGIN, HVal.WEBSTATIC);
      // GAME_RECORD 接口使用 salt_x4（经抓包验证，米游社 App 2.104.0 使用此 salt）
      h.set(HKey.DS, DSUtil.generateX4(params, body));
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
    } else if (profile === HeaderProfile.WIDGET) {
      // Widget 便笺接口：使用 WidgetExtension User-Agent，client_type=1（iOS App），Referer=app.mihoyo.com
      // client_type=1 对应 iOS App，DS 使用 V2 salt（与 BBS profile 一致）
      // 参考 mihoyo_apis.md Widget 请求头：DS 字段存在，client_type=1
      h.set(HKey.USER_AGENT, ApiConfig.WIDGET_USER_AGENT);
      h.set(HKey.CLIENT_TYPE, HVal.CLIENT_IOS);
      h.set(HKey.REFERER, HVal.APP_MIHOYO);
      h.set(HKey.ORIGIN, HVal.APP_MIHOYO);
      h.set(HKey.DS, DSUtil.generateV2(params, body));
    }

    return h;
  }
}
