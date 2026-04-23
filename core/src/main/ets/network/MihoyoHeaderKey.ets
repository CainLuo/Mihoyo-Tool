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
  /** x-rpc-page：页面标识，部分接口必须携带 */
  PAGE                = 'x-rpc-page',
  /** x-rpc-challenge：Geetest 验证通过后注入 */
  CHALLENGE           = 'x-rpc-challenge',
  /**
   * x-rpc-challenge_path：Geetest 验证通过后注入，告知服务器 challenge 对应的接口完整路径
   * 参考 PizzaHelperUnited URLRequestConfig.writeXRPCChallengeHeaders4DailyNote
   */
  CHALLENGE_PATH      = 'x-rpc-challenge_path',
  /**
   * x-rpc-challenge_game：Geetest 验证通过后注入，告知服务器 challenge 对应的游戏 ID
   * 原神=2，星铁=6，绝区零=8
   */
  CHALLENGE_GAME      = 'x-rpc-challenge_game',
  /** x-rpc-cal_type：原神养成计算接口专用 */
  CAL_TYPE            = 'x-rpc-cal_type',
  /** x-rpc-cultivate_source：绝区零养成计算接口专用 */
  CULTIVATE_SOURCE    = 'x-rpc-cultivate_source',

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
  /** x-rpc-platform: 5（Web/PC） */
  PLATFORM_WEB        = '5',

  /** Referer: https://webstatic.mihoyo.com/（含尾斜杠） */
  REFERER_WEBSTATIC         = 'https://webstatic.mihoyo.com/',
  /**
   * https://webstatic.mihoyo.com（无尾斜杠）
   * 用于 Referer（passport 接口）和 Origin（game_record 接口）
   */
  WEBSTATIC           = 'https://webstatic.mihoyo.com',
  /** Referer: https://app.mihoyo.com，用于 Referer 和 Origin（BBS 接口） */
  APP_MIHOYO          = 'https://app.mihoyo.com',
  /** Referer: https://act.mihoyo.com/，用于 Referer 和 Origin（签到/养成计算接口） */
  REFERER_ACT         = 'https://act.mihoyo.com/',
  /** Origin: https://act.mihoyo.com（无尾斜杠） */
  ORIGIN_ACT          = 'https://act.mihoyo.com',
  /** Referer: https://user.miyoushe.com/ */
  REFERER_USER        = 'https://user.miyoushe.com/',
  /** x-requested-with: com.mihoyo.hyperion */
  REQUESTED_HYPERION  = 'com.mihoyo.hyperion',

  /** x-rpc-sys_version: 16.3.1（与 User-Agent 里的 iOS 版本一致） */
  SYS_VERSION_IOS     = '16.3.1',
}
