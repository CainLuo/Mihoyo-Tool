/**
 * MihoyoHeaderKey — 米游社请求头 Key 和固定 Value 常量
 *
 * 所有 header key 字符串必须从此处引用，禁止在 Service/Builder 中直接写字符串字面量。
 */

// ─── Header Key 枚举 ─────────────────────────────────────────────

export enum HKey {
  CONTENT_TYPE        = 'content-type',
  COOKIE              = 'Cookie',
  USER_AGENT          = 'User-Agent',
  ACCEPT              = 'Accept',
  REFERER             = 'Referer',
  ORIGIN              = 'Origin',
  DS                  = 'DS',

  // x-rpc-* 系列
  APP_VERSION         = 'x-rpc-app_version',
  APP_ID              = 'x-rpc-app_id',
  CLIENT_TYPE         = 'x-rpc-client_type',
  DEVICE_ID           = 'x-rpc-device_id',
  DEVICE_FP           = 'x-rpc-device_fp',
  DEVICE_MODEL        = 'x-rpc-device_model',
  DEVICE_NAME         = 'x-rpc-device_name',
  SYS_VERSION         = 'x-rpc-sys_version',
  /** 注意：米游社服务端拼写错误，必须用 "verison" 而非 "version" */
  TOOL_VERSION        = 'x-rpc-tool_verison',
  GAME_BIZ            = 'x-rpc-game_biz',
  LANGUAGE            = 'x-rpc-language',
  PLATFORM            = 'x-rpc-platform',
  AIGIS               = 'x-rpc-aigis',
  SIGN_GAME           = 'x-rpc-signgame',

  // 其他
  REQUESTED_WITH      = 'x-requested-with',
}

// ─── 固定 Value 常量 ─────────────────────────────────────────────

export enum HVal {
  /** content-type: application/json */
  JSON                = 'application/json',
  /** content-type: text/plain;charset=UTF-8 */
  TEXT_PLAIN          = 'text/plain;charset=UTF-8',
  /** Accept: application/json, text/plain, *\/* */
  ACCEPT_JSON         = 'application/json, text/plain, */*',

  /** x-rpc-client_type: 1 = iOS */
  CLIENT_IOS          = '1',
  /** x-rpc-client_type: 2 = 安卓 */
  CLIENT_ANDROID      = '2',
  /** x-rpc-client_type: 5 = Web/PC */
  CLIENT_WEB          = '5',

  /** x-rpc-game_biz: hk4e_cn（原神国服） */
  GAME_BIZ_GENSHIN    = 'hk4e_cn',

  /** x-rpc-language: zh-cn */
  LANG_ZH_CN          = 'zh-cn',
  /** x-rpc-platform: 1（安卓） */
  PLATFORM_ANDROID    = '1',

  /** Referer: https://webstatic.mihoyo.com/ */
  REFERER_WEBSTATIC   = 'https://webstatic.mihoyo.com/',
  /** Referer: https://webstatic.mihoyo.com（无尾斜杠，部分接口用） */
  REFERER_WEBSTATIC2  = 'https://webstatic.mihoyo.com',
  /** Referer: https://app.mihoyo.com */
  REFERER_APP         = 'https://app.mihoyo.com',
  /** Referer: https://act.mihoyo.com/ */
  REFERER_ACT         = 'https://act.mihoyo.com/',
  /** Referer: https://user.miyoushe.com/ */
  REFERER_USER        = 'https://user.miyoushe.com/',

  /** Origin: https://webstatic.mihoyo.com */
  ORIGIN_WEBSTATIC    = 'https://webstatic.mihoyo.com',
  /** Origin: https://app.mihoyo.com */
  ORIGIN_APP          = 'https://app.mihoyo.com',
  /** Origin: https://act.mihoyo.com */
  ORIGIN_ACT          = 'https://act.mihoyo.com',

  /** x-requested-with: com.mihoyo.hyperion */
  REQUESTED_HYPERION  = 'com.mihoyo.hyperion',

  /** x-rpc-sys_version: 15.7.1（iOS 模拟版本） */
  SYS_VERSION_IOS     = '15.7.1',
}
