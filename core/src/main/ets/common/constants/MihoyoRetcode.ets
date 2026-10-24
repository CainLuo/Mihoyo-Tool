/**
 * MihoyoRetcode — 米游社 / HoYoLAB API 业务返回码（retcode）唯一数字来源。
 *
 * 维护规则：
 * 1. 新增 retcode 只在这里加枚举值；语义、触发场景、处理方式在
 *    `base/errors/RetcodeRegistry.ets` 中登记。
 * 2. 业务代码禁止直接写数字；特殊码判断统一走 RetcodeRegistry。
 * 3. 来源优先级：mihoyo-api-collect/other/error_code.md → PizzaHelperUnited
 *    → TeyvatGuide / 项目实测。
 *
 * 注意：`retcode === 0` 只代表业务成功，不代表 HTTP 一定成功；HTTP 状态码由
 * BaseApiService 单独处理。
 */
export enum MihoyoRetcode {
  /** 成功 */
  SUCCESS = 0,

  // ── 登录 / 鉴权 ─────────────────────────────────────────────

  /** 登录失效 / Cookie 无效（api-takumi.mihoyo.com / api-takumi.miyoushe.com） */
  LOGIN_EXPIRED = -100,

  /** 需要登录 / Cookie 缺失或无效（api-takumi-record.mihoyo.com） */
  LOGIN_EXPIRED_PLEASE_LOGIN = 10001,

  /** 登录失效（旧 passport / takumi 接口） */
  LOGIN_EXPIRED_LEGACY = -111,

  // ── 请求 / 参数 ─────────────────────────────────────────────

  /**
   * 请求无效（invalid request）。
   * 通常表示 DS 签名、公共 Header、参数或设备信息不匹配，不是 Cookie 失效。
   */
  INVALID_REQUEST = -10001,

  /** 参数错误 */
  INVALID_PARAM = -1,

  /** 参数错误（api-takumi.mihoyo.com） */
  INVALID_PARAM_ALT = -101,

  /** 参数错误（api-takumi.mihoyo.com 旧接口） */
  INVALID_PARAM_LEGACY = 1000,

  /** 用户信息不匹配，例如 role_id / UID 与 Cookie 不匹配 */
  USER_INFO_MISMATCH = 1008,

  /** 账号未绑定当前 Cookie，或账号不存在 */
  ACCOUNT_NOT_FOUND = -1002,

  // ── 限流 / 服务端 ───────────────────────────────────────────

  /** 请求频率过高，触发限流 */
  RATE_LIMITED = -110,

  /** 服务端异常 / 参数错误，message 通常提示稍后重试 */
  SERVER_ERROR = -502,

  /** 系统异常（api-takumi.miyoushe.com） */
  SERVER_ERROR_ALT = 1002,

  /** 服务器维护 / 升级 */
  MAINTENANCE = 10307,

  // ── 人机验证（Geetest）─────────────────────────────────────

  /** 需要人机验证（通用接口，例如登录、签到、BBS） */
  CAPTCHA_REQUIRED = 1034,

  /** 需要人机验证（game_record 接口，例如便笺、角色详情） */
  CAPTCHA_REQUIRED_GAME_RECORD = 10035,

  // ── 设备指纹 ───────────────────────────────────────────────

  /** 设备指纹无效 / 账号异常 */
  FINGERPRINT_INVALID = 5003,

  /** 设备指纹无效 / 账号异常（备用码） */
  FINGERPRINT_INVALID_ALT = 10041,

  // ── 游戏角色 ───────────────────────────────────────────────

  /** 角色未公开展示战绩 */
  ROLE_NOT_PUBLIC = 10102,

  /** 角色不存在或 UID 错误 */
  ROLE_NOT_FOUND = 10103,

  // ── 登录辅助流程 ───────────────────────────────────────────

  /** 短信 / 登录验证码错误或已过期 */
  CAPTCHA_INVALID = -3208,

  /** 二维码已过期；这是登录流程状态，不是普通错误 */
  QR_EXPIRED = -106,

  // ── HTTP 状态（不是业务 retcode）────────────────────────────

  /** HTTP 403：地区限制；仅用于统一语义分类，不会出现在 retcode 字段中 */
  HTTP_REGION_RESTRICTED = 403,

  // 说明：api-launcher.mihoyo.com 的 -205（invalid key）/ -204（no record）
  // 属于启动器专用协议，当前 App 不调用，暂不纳入本枚举。
}
