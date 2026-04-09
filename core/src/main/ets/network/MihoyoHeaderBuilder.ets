import { RequestParams } from './APIs';
import { ApiConfig } from './ApiConfig';
import { DSUtil } from './DSUtil';

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
   *
   * DS 签名规则：GET 请求 query=params 序列化，body=""；POST 请求 query=""，body=JSON.stringify(data)
   */
  static build(
    profile: HeaderProfile,
    cookie: string,
    params?: RequestParams,
    body?: string,
  ): Map<string, string> {
    const h = new Map<string, string>();

    // ── 所有接口共有 ──────────────────────────────────────────────
    h.set('x-rpc-app_version', ApiConfig.APP_VERSION);
    h.set('x-rpc-device_id', ApiConfig.getDeviceIdSync());
    h.set('x-rpc-device_fp', ApiConfig.getDeviceFp());
    h.set('x-rpc-sys_version', '15.7.1');
    h.set('Cookie', cookie);
    h.set('User-Agent', ApiConfig.USER_AGENT);
    h.set('Accept', 'application/json, text/plain, */*');

    // ── 按 Profile 差异化注入 ─────────────────────────────────────
    if (profile === HeaderProfile.GAME_RECORD) {
      h.set('x-rpc-client_type', '5');
      // 注意：米游社服务端的拼写错误，必须用 "x-rpc-tool_verison" 而非 "version"
      // 默认使用原神版本号；StarRailApiService 调用后会覆盖为星铁版本号
      h.set('x-rpc-tool_verison', ApiConfig.TOOL_VERSION_GENSHIN);
      h.set('Referer', 'https://webstatic.mihoyo.com/');
      h.set('Origin', 'https://webstatic.mihoyo.com');
      h.set('DS', DSUtil.generateV1(params, body));
    } else if (profile === HeaderProfile.ZZZ_GAME_RECORD) {
      h.set('x-rpc-language', 'zh-cn');
      h.set('x-rpc-platform', '1');
      h.set('Referer', 'https://act.mihoyo.com/');
      h.set('Origin', 'https://act.mihoyo.com');
      // 绝区零游戏记录接口不携带 DS
    } else if (profile === HeaderProfile.CALCULATE) {
      h.set('Referer', 'https://act.mihoyo.com/');
      h.set('Origin', 'https://act.mihoyo.com');
      // 养成计算不携带 DS
    } else if (profile === HeaderProfile.BBS) {
      h.set('x-rpc-client_type', '1');
      h.set('Referer', 'https://app.mihoyo.com');
      h.set('Origin', 'https://app.mihoyo.com');
      h.set('DS', DSUtil.generateV2(params, body));
    } else if (profile === HeaderProfile.SIGN) {
      h.set('x-rpc-client_type', '2');
      h.set('Referer', 'https://act.mihoyo.com/');
      h.set('Origin', 'https://act.mihoyo.com');
      // SIGN 使用 X6 salt
      h.set('DS', DSUtil.generateX6(params, body));
      // 游戏签到需要额外的 x-rpc-signgame 头，由 SignApiService 在调用后手动注入
    }

    return h;
  }
}
