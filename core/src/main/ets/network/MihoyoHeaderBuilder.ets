import { RequestParams } from './APIs';
import { ApiConfig } from './ApiConfig';
import { DSUtil } from './DSUtil';
import { HKey, HVal } from './MihoyoHeaderKey';
import { GameFpBiz } from './DeviceFpService';

/** 请求头 Profile 枚举 */
export enum HeaderProfile {
  /** 原神/星铁 游戏记录接口（有 DS，Referer=webstatic，client_type=5） */
  GAME_RECORD = 'GAME_RECORD',
  /** 绝区零 游戏记录接口（无 DS，Referer=act，带 language/platform） */
  ZZZ_GAME_RECORD = 'ZZZ_GAME_RECORD',
  /** 养成计算接口（原神/星铁，有 DS，Referer=act） */
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

/** PizzaHelperUnited 国服 x-rpc-app_version 与 User-Agent */
const PZ_APP_VERSION: string = '2.40.1';
const PZ_USER_AGENT: string =
  `Mozilla/5.0 (iPhone; CPU iPhone OS 17_6 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) miHoYoBBS/${PZ_APP_VERSION}`;

export class MihoyoHeaderBuilder {
  /**
   * 整套对齐 PizzaHelperUnited（generateRecordAPIRequest + URLRequestConfig.defaultHeaders）：
   * 便笺 / Widget / 星铁角色接口使用。账号完整 Cookie、DS(X4)、该游戏单独申请的 device_fp、大写 device_id。
   * @param biz        游戏（决定使用哪个游戏的指纹）
   * @param userAgent  覆盖 User-Agent（星铁 / 绝区零 Widget 用 WidgetExtension），不传则用 PizzaHelperUnited 默认 UA
   */
  static buildPizza(cookie: string, biz: GameFpBiz, params?: RequestParams, userAgent?: string): Map<string, string> {
    const h = new Map<string, string>();
    h.set(HKey.USER_AGENT, userAgent !== undefined ? userAgent : PZ_USER_AGENT);
    h.set(HKey.REFERER, HVal.WEBSTATIC);
    h.set(HKey.ORIGIN, HVal.WEBSTATIC);
    h.set(HKey.ACCEPT_LANGUAGE, 'zh-CN,zh-Hans;q=0.9');
    h.set(HKey.ACCEPT, HVal.ACCEPT_JSON);
    h.set(HKey.REQUESTED_WITH, HVal.REQUESTED_HYPERION);
    h.set(HKey.APP_VERSION, PZ_APP_VERSION);
    h.set(HKey.CLIENT_TYPE, HVal.CLIENT_WEB);
    h.set(HKey.PAGE, '3.1.3_#/rpg');
    h.set(HKey.DEVICE_ID, ApiConfig.getDeviceIdSync().toUpperCase());
    h.set(HKey.LANGUAGE, HVal.LANG_ZH_CN);
    h.set('Sec-Fetch-Dest', 'empty');
    h.set('Sec-Fetch-Site', 'same-site');
    h.set('Sec-Fetch-Mode', 'cors');
    h.set(HKey.DEVICE_FP, ApiConfig.getGameFp(biz));
    h.set(HKey.COOKIE, MihoyoHeaderBuilder.pizzaCookie(cookie));
    h.set(HKey.DS, DSUtil.generateX4(params));
    return h;
  }

  /**
   * PizzaHelperUnited 扫码登录后保存的 Cookie（GetCookieQRCodeView.parseGameToken）：
   * stuid / stoken / ltuid / ltoken / mid / cookie_token / account_id，其中 ltoken 直接等于 stoken。
   * 已有账号的 Cookie 可能带 DEVICEFP / _MHYUUID / *_v2 等字段、ltoken 为换来的真 ltoken，
   * 这里在请求时统一按 PizzaHelperUnited 的格式重建（不改数据库里保存的 Cookie）。
   */
  static pizzaCookie(cookie: string): string {
    const keep = ['stuid', 'stoken', 'ltuid', 'mid', 'cookie_token', 'account_id'];
    const values = new Map<string, string>();
    const parts = cookie.split(';');
    for (let i = 0; i < parts.length; i++) {
      const p = parts[i].trim();
      const eq = p.indexOf('=');
      if (eq > 0) {
        const k = p.substring(0, eq);
        if (keep.indexOf(k) !== -1 && !values.has(k)) {
          values.set(k, p.substring(eq + 1));
        }
      }
    }
    if (values.size === 0) {
      return cookie;
    }
    const stoken = values.get('stoken');
    let result = '';
    const order = ['stuid', 'stoken', 'ltuid', 'ltoken', 'mid', 'cookie_token', 'account_id'];
    for (let i = 0; i < order.length; i++) {
      const v = order[i] === 'ltoken' ? stoken : values.get(order[i]);
      if (v !== undefined && v.length > 0) {
        result += `${order[i]}=${v}; `;
      }
    }
    return result;
  }

  /**
   * 实时便笺接口：补齐真实抓包（mihoyo_apis.md 原神 / 星铁 / 绝区零实时便笺）中有、而通用 Profile 缺少的请求头：
   * - x-rpc-device_name：URL 编码的设备名
   * - Accept-Language：zh-CN,zh-Hans;q=0.9
   * - User-Agent：版本号与 x-rpc-app_version 一致（原 USER_AGENT 为 2.104.0，而 app_version 为 2.115.0）
   * 性能监控类请求头（x-rum-*、baggage、traceparent）不参与校验，不补。
   */
  static addNoteCaptureHeaders(headers: Map<string, string>): void {
    headers.set(HKey.DEVICE_NAME, encodeURIComponent(ApiConfig.DEVICE_NAME));
    headers.set(HKey.ACCEPT_LANGUAGE, 'zh-CN,zh-Hans;q=0.9');
    headers.set(HKey.USER_AGENT, ApiConfig.USER_AGENT_MATCH_APP_VERSION);
  }

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
    // ── CALCULATE Profile 特殊处理：独立构建，不走共有逻辑 ───────────
    if (profile === HeaderProfile.CALCULATE) {
      // 养成计算接口（原神/星铁）
      // 参考 TeyvatGuide takumiReq.ts batchCompute 实现：
      // - 使用 DS header（X4 salt）
      // - x-rpc-cal_type: "0"（在线计算，"1" 是离线计算）
      // - client_type: "5"（来自 getRequestHeader 默认值）
      // - 使用完整 Cookie（account_id, cookie_token, ltoken, ltuid）
      const c = new Map<string, string>();
      c.set(HKey.APP_VERSION, ApiConfig.APP_VERSION);
      c.set(HKey.CLIENT_TYPE, HVal.CLIENT_WEB);  // 5
      c.set(HKey.DEVICE_ID, ApiConfig.getDeviceIdSync());
      c.set(HKey.DEVICE_FP, ApiConfig.getDeviceFp());
      c.set(HKey.REQUESTED_WITH, HVal.REQUESTED_HYPERION);
      c.set(HKey.REFERER, HVal.REFERER_WEBSTATIC);
      c.set(HKey.ACCEPT, HVal.ACCEPT_JSON);
      c.set(HKey.CONTENT_TYPE, HVal.JSON_UTF8);
      c.set(HKey.USER_AGENT, ApiConfig.USER_AGENT);
      c.set(HKey.COOKIE, cookie);
      // x-rpc-cal_type: "0" 在线计算（与 TeyvatGuide 一致）
      c.set(HKey.CAL_TYPE, '0');
      // DS 使用 X4 salt（与 TeyvatGuide 一致）
      c.set(HKey.DS, DSUtil.generateX4(undefined, body));
      return c;
    }

    // ── 其他 Profile：共有 header + 差异化注入 ───────────────────────
    const h = new Map<string, string>();
    h.set(HKey.APP_VERSION, ApiConfig.APP_VERSION);
    h.set(HKey.DEVICE_ID, ApiConfig.getDeviceIdSync());
    h.set(HKey.DEVICE_FP, ApiConfig.getDeviceFp());
    h.set(HKey.SYS_VERSION, HVal.SYS_VERSION_IOS);
    h.set(HKey.LANGUAGE, HVal.LANG_ZH_CN);
    h.set(HKey.COOKIE, cookie);
    h.set(HKey.USER_AGENT, ApiConfig.USER_AGENT);
    h.set(HKey.ACCEPT, HVal.ACCEPT_JSON);
    // 米游社大多数 API 需要验证此字段（来源：UIGF-org/mihoyo-api-collect/other/authentication.md）
    h.set(HKey.REQUESTED_WITH, HVal.REQUESTED_HYPERION);

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
