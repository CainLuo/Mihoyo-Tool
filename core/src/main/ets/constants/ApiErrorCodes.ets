/**
 * ApiErrorCodes — 米游社 / HoYoLAB API 错误码常量
 *
 * 所有 retcode 判断必须从此处引用，禁止在业务代码中直接写数字字面量。
 * 来源：UIGF-org/mihoyo-api-collect
 */
export class ApiErrorCodes {
  // ── 通用 ────────────────────────────────────────────────────

  /** 成功 */
  static readonly SUCCESS: number = 0;

  /** 登录已过期 / Cookie 无效 */
  static readonly AUTH_INVALID: number = -100;

  /** 请求频率过高，触发限流 */
  static readonly RATE_LIMITED: number = -110;

  /** 参数错误 */
  static readonly INVALID_PARAM: number = -1;

  // ── 人机验证（Geetest）────────────────────────────────────

  /**
   * 需要 Geetest 人机验证
   * 触发场景：实时便笺、角色详情等接口在短时间内频繁请求时
   */
  static readonly GEETEST_REQUIRED: number = 10035;

  // ── 账号 / 登录 ──────────────────────────────────────────

  /** 账号不存在 */
  static readonly ACCOUNT_NOT_FOUND: number = -1002;

  /** 验证码错误或已过期 */
  static readonly CAPTCHA_INVALID: number = -3208;

  /** 二维码已过期 */
  static readonly QRCODE_EXPIRED: number = -106;

  // ── 游戏角色 ─────────────────────────────────────────────

  /** 角色未公开展示战绩 */
  static readonly ROLE_NOT_PUBLIC: number = 10102;

  /** 角色不存在或 UID 错误 */
  static readonly ROLE_NOT_FOUND: number = 10103;
}
