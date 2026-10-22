/**
 * RetcodeRegistry — 米游社 retcode 语义注册表。
 *
 * 职责：
 * 1. 把 MihoyoRetcode 的数字映射为稳定的语义分类（RetcodeKind）。
 * 2. 为每个码记录中文含义、触发场景、建议处理方式和来源，避免业务层重复解释。
 * 3. 提供统一的判断方法；Service / Repository / ViewModel 不再直接写 retcode 数字。
 *
 * 这里只做“分类和解释”，不负责发请求、不负责弹框、不负责创建具体错误类型。
 * 具体错误类型仍由 ApiErrorHandler / SyncErrorFactory 根据 RetcodeKind 创建。
 */
import { MihoyoRetcode } from '../../common/constants/MihoyoRetcode';

/**
 * retcode 语义分类。
 *
 * 新增分类时优先复用已有分类；只有 UI / 错误处理确实需要不同动作时才新增。
 */
export enum RetcodeKind {
  /** 成功 */
  SUCCESS = 'success',
  /** 登录失效 / Cookie 无效，可尝试刷新 Cookie 或重新登录 */
  AUTH_EXPIRED = 'authExpired',
  /** 需要 Geetest 人机验证 */
  VERIFICATION_REQUIRED = 'verificationRequired',
  /** 设备指纹无效 / 账号异常，需要重新生成设备指纹 */
  FINGERPRINT_INVALID = 'fingerprintInvalid',
  /** 角色战绩未公开 */
  ROLE_NOT_PUBLIC = 'roleNotPublic',
  /** 角色不存在 / UID 错误 */
  ROLE_NOT_FOUND = 'roleNotFound',
  /** 账号未绑定 / 账号不存在 */
  ACCOUNT_NOT_FOUND = 'accountNotFound',
  /** 请求无效：DS / Header / 参数错误，不是登录失效 */
  INVALID_REQUEST = 'invalidRequest',
  /** 参数错误 */
  INVALID_PARAM = 'invalidParam',
  /** 请求频率过高 */
  RATE_LIMITED = 'rateLimited',
  /** 服务端异常，可重试 */
  SERVER_ERROR = 'serverError',
  /** 服务器维护 / 升级 */
  MAINTENANCE = 'maintenance',
  /** 二维码已过期（登录流程状态） */
  QR_EXPIRED = 'qrExpired',
  /** 短信 / 登录验证码错误或过期 */
  CAPTCHA_INVALID = 'captchaInvalid',
  /** 地区限制（HTTP 403） */
  REGION_RESTRICTED = 'regionRestricted',
  /** 未收录的 retcode */
  UNKNOWN = 'unknown',
}

/**
 * 单个 retcode 的元数据。
 *
 * `description` / `trigger` / `handling` 是给开发和排障看的，不是 UI 文案；
 * UI 仍然优先展示服务端返回的 message，避免擅自改写服务端错误。
 */
export class RetcodeInfo {
  /** 原始 retcode */
  readonly code: number;
  /** 语义分类 */
  readonly kind: RetcodeKind;
  /** 中文含义 */
  readonly description: string;
  /** 触发场景 */
  readonly trigger: string;
  /** 建议处理方式 */
  readonly handling: string;
  /** 来源 */
  readonly source: string;

  constructor(
    code: number,
    kind: RetcodeKind,
    description: string,
    trigger: string,
    handling: string,
    source: string,
  ) {
    this.code = code;
    this.kind = kind;
    this.description = description;
    this.trigger = trigger;
    this.handling = handling;
    this.source = source;
  }
}

export class RetcodeRegistry {
  private static readonly SRC_COLLECT: string = 'mihoyo-api-collect/other/error_code.md';
  private static readonly SRC_PIZZA: string = 'PizzaHelperUnited/Packages/PZKit/Sources/PZAccountKit/HoYoAPIs/Common/HoYo_Models/APIError.swift';
  private static readonly SRC_PROJECT: string = '项目既有 ApiErrorCodes / 实测';
  private static readonly SRC_TEYVAT: string = 'TeyvatGuide';

  /** 唯一注册表；所有查询都从这里取，避免各处重复判断 */
  private static readonly TABLE: Map<number, RetcodeInfo> = RetcodeRegistry.buildTable();

  /** 从 Error message 中提取 `retcode=xxx`；没有则返回 null */
  private static readonly RETCODE_PATTERN: RegExp = /retcode=(-?\d+)/;

  /**
   * 查询 retcode 元数据；未收录的码返回 UNKNOWN，但保留原始 code。
   */
  static infoOf(code: number): RetcodeInfo {
    const info = RetcodeRegistry.TABLE.get(code);
    if (info !== undefined) {
      return info;
    }
    return new RetcodeInfo(
      code,
      RetcodeKind.UNKNOWN,
      '未知错误',
      '未收录的 retcode',
      '保留原始 retcode 与服务端 message，按普通错误记录并展示',
      '未收录',
    );
  }

  /** 只取语义分类 */
  static kindOf(code: number): RetcodeKind {
    return RetcodeRegistry.infoOf(code).kind;
  }

  /** 是否成功（只认 0） */
  static isSuccess(code: number | undefined): boolean {
    return code === MihoyoRetcode.SUCCESS;
  }

  /** 是否登录失效（-100 / 10001 / -111） */
  static isAuthExpired(code: number | undefined): boolean {
    if (code === undefined) {
      return false;
    }
    return RetcodeRegistry.kindOf(code) === RetcodeKind.AUTH_EXPIRED;
  }

  /** 是否需要 Geetest（1034 / 10035） */
  static isVerificationRequired(code: number | undefined): boolean {
    if (code === undefined) {
      return false;
    }
    return RetcodeRegistry.kindOf(code) === RetcodeKind.VERIFICATION_REQUIRED;
  }

  /** 是否设备指纹无效 / 账号异常（5003 / 10041） */
  static isFingerprintInvalid(code: number | undefined): boolean {
    if (code === undefined) {
      return false;
    }
    return RetcodeRegistry.kindOf(code) === RetcodeKind.FINGERPRINT_INVALID;
  }

  /** 是否二维码过期 */
  static isQrExpired(code: number | undefined): boolean {
    if (code === undefined) {
      return false;
    }
    return RetcodeRegistry.kindOf(code) === RetcodeKind.QR_EXPIRED;
  }

  /** 是否角色战绩未公开 */
  static isRoleNotPublic(code: number | undefined): boolean {
    if (code === undefined) {
      return false;
    }
    return RetcodeRegistry.kindOf(code) === RetcodeKind.ROLE_NOT_PUBLIC;
  }

  /** 是否角色不存在 */
  static isRoleNotFound(code: number | undefined): boolean {
    if (code === undefined) {
      return false;
    }
    return RetcodeRegistry.kindOf(code) === RetcodeKind.ROLE_NOT_FOUND;
  }

  /** 是否请求无效（DS / Header / 参数），注意这不是登录失效 */
  static isInvalidRequest(code: number | undefined): boolean {
    if (code === undefined) {
      return false;
    }
    return RetcodeRegistry.kindOf(code) === RetcodeKind.INVALID_REQUEST;
  }

  /** 是否限流 */
  static isRateLimited(code: number | undefined): boolean {
    if (code === undefined) {
      return false;
    }
    return RetcodeRegistry.kindOf(code) === RetcodeKind.RATE_LIMITED;
  }

  /** 是否服务端异常 */
  static isServerError(code: number | undefined): boolean {
    if (code === undefined) {
      return false;
    }
    return RetcodeRegistry.kindOf(code) === RetcodeKind.SERVER_ERROR;
  }

  /** 是否维护中 */
  static isMaintenance(code: number | undefined): boolean {
    if (code === undefined) {
      return false;
    }
    return RetcodeRegistry.kindOf(code) === RetcodeKind.MAINTENANCE;
  }

  /** 是否可重试（限流或服务端异常） */
  static isRetryable(code: number): boolean {
    const kind = RetcodeRegistry.kindOf(code);
    return kind === RetcodeKind.RATE_LIMITED || kind === RetcodeKind.SERVER_ERROR;
  }

  /**
   * 从错误消息中解析 retcode。
   * 使用精确数字匹配，避免 `retcode=-100` 误匹配 `retcode=-10001`。
   */
  static retcodeFromMessage(message: string): number | null {
    const match = message.match(RetcodeRegistry.RETCODE_PATTERN);
    if (match === null) {
      return null;
    }
    return Number(match[1]);
  }

  /** 错误消息中的 retcode 是否属于指定分类 */
  static messageHasKind(message: string, kind: RetcodeKind): boolean {
    const code = RetcodeRegistry.retcodeFromMessage(message);
    if (code === null) {
      return false;
    }
    return RetcodeRegistry.kindOf(code) === kind;
  }

  /**
   * HTTP 403 + 地区限制 message 的统一判断。
   * 403 不是业务 retcode，单独用此方法，避免把普通 403 都当成地区限制。
   */
  static isRegionRestricted(httpStatus: number, message: string): boolean {
    return httpStatus === MihoyoRetcode.HTTP_REGION_RESTRICTED &&
      message.indexOf('not available in your country or region') >= 0;
  }

  private static buildTable(): Map<number, RetcodeInfo> {
    const table: Map<number, RetcodeInfo> = new Map<number, RetcodeInfo>();

    table.set(MihoyoRetcode.SUCCESS, new RetcodeInfo(
      MihoyoRetcode.SUCCESS,
      RetcodeKind.SUCCESS,
      '成功',
      '接口正常返回',
      '继续解析 data',
      '通用约定',
    ));

    // ── 登录 / 鉴权 ─────────────────────────────────────────────

    table.set(MihoyoRetcode.LOGIN_EXPIRED, new RetcodeInfo(
      MihoyoRetcode.LOGIN_EXPIRED,
      RetcodeKind.AUTH_EXPIRED,
      '登录失效 / Cookie 无效',
      'Cookie 过期、被下线、ltoken 无效；常见于 api-takumi.mihoyo.com',
      '优先用 stoken 刷新 Cookie；刷新失败或重试仍失败时提示重新登录',
      RetcodeRegistry.SRC_COLLECT,
    ));

    table.set(MihoyoRetcode.LOGIN_EXPIRED_PLEASE_LOGIN, new RetcodeInfo(
      MihoyoRetcode.LOGIN_EXPIRED_PLEASE_LOGIN,
      RetcodeKind.AUTH_EXPIRED,
      '需要登录（Please login）',
      'Cookie 缺失、未登录或 Cookie 不完整；常见于 api-takumi-record.mihoyo.com',
      '优先用 stoken 刷新 Cookie；刷新失败或重试仍失败时提示重新登录',
      RetcodeRegistry.SRC_COLLECT,
    ));

    table.set(MihoyoRetcode.LOGIN_EXPIRED_LEGACY, new RetcodeInfo(
      MihoyoRetcode.LOGIN_EXPIRED_LEGACY,
      RetcodeKind.AUTH_EXPIRED,
      '登录失效（旧接口）',
      'api-takumi.mihoyo.com 旧接口 Cookie 失效',
      '按登录失效处理：刷新 Cookie，失败后提示重新登录',
      RetcodeRegistry.SRC_COLLECT,
    ));

    // ── 请求 / 参数 ─────────────────────────────────────────────

    table.set(MihoyoRetcode.INVALID_REQUEST, new RetcodeInfo(
      MihoyoRetcode.INVALID_REQUEST,
      RetcodeKind.INVALID_REQUEST,
      '请求无效（invalid request）',
      'DS 签名、公共 Header、参数或设备信息不匹配；不是 Cookie 过期',
      '不要刷新 Cookie；记录 URL/retcode，检查 DS、Header、参数和请求体',
      RetcodeRegistry.SRC_COLLECT,
    ));

    table.set(MihoyoRetcode.INVALID_PARAM, new RetcodeInfo(
      MihoyoRetcode.INVALID_PARAM,
      RetcodeKind.INVALID_PARAM,
      '参数错误',
      '参数缺失、类型错误或值不合法',
      '展示服务端 message；不要按登录失效处理',
      RetcodeRegistry.SRC_COLLECT,
    ));

    table.set(MihoyoRetcode.INVALID_PARAM_ALT, new RetcodeInfo(
      MihoyoRetcode.INVALID_PARAM_ALT,
      RetcodeKind.INVALID_PARAM,
      '参数错误',
      '请求参数缺失或错误（api-takumi.mihoyo.com）',
      '展示服务端 message；不要按登录失效处理',
      RetcodeRegistry.SRC_COLLECT,
    ));

    table.set(MihoyoRetcode.INVALID_PARAM_LEGACY, new RetcodeInfo(
      MihoyoRetcode.INVALID_PARAM_LEGACY,
      RetcodeKind.INVALID_PARAM,
      '参数错误',
      '请求参数缺失或错误（api-takumi.mihoyo.com 旧接口）',
      '展示服务端 message；不要按登录失效处理',
      RetcodeRegistry.SRC_COLLECT,
    ));

    table.set(MihoyoRetcode.USER_INFO_MISMATCH, new RetcodeInfo(
      MihoyoRetcode.USER_INFO_MISMATCH,
      RetcodeKind.INVALID_PARAM,
      '用户信息不匹配',
      'role_id / UID 与 Cookie 不匹配，或 UID 无效',
      '提示检查角色 / UID；不要刷新 Cookie',
      RetcodeRegistry.SRC_COLLECT,
    ));

    table.set(MihoyoRetcode.ACCOUNT_NOT_FOUND, new RetcodeInfo(
      MihoyoRetcode.ACCOUNT_NOT_FOUND,
      RetcodeKind.ACCOUNT_NOT_FOUND,
      '账号未绑定或不存在',
      'getTokenByGameToken 等接口找不到对应账号',
      '提示重新登录或重新绑定账号；不要当作普通参数错误',
      RetcodeRegistry.SRC_COLLECT,
    ));

    // ── 限流 / 服务端 ───────────────────────────────────────────

    table.set(MihoyoRetcode.RATE_LIMITED, new RetcodeInfo(
      MihoyoRetcode.RATE_LIMITED,
      RetcodeKind.RATE_LIMITED,
      '请求频率过高',
      '短时间请求过多触发限流',
      '退避后重试；不要刷新 Cookie',
      RetcodeRegistry.SRC_PROJECT,
    ));

    table.set(MihoyoRetcode.SERVER_ERROR, new RetcodeInfo(
      MihoyoRetcode.SERVER_ERROR,
      RetcodeKind.SERVER_ERROR,
      '服务端异常 / 参数错误',
      'message 通常为 Something went wrong...please retry later',
      '可重试；持续失败时展示服务端 message',
      RetcodeRegistry.SRC_COLLECT,
    ));

    table.set(MihoyoRetcode.SERVER_ERROR_ALT, new RetcodeInfo(
      MihoyoRetcode.SERVER_ERROR_ALT,
      RetcodeKind.SERVER_ERROR,
      '系统异常',
      '米游社系统异常，或请求参数错误',
      '可重试；持续失败时展示服务端 message',
      RetcodeRegistry.SRC_COLLECT,
    ));

    table.set(MihoyoRetcode.MAINTENANCE, new RetcodeInfo(
      MihoyoRetcode.MAINTENANCE,
      RetcodeKind.MAINTENANCE,
      '服务器维护 / 升级',
      '服务端维护或版本升级',
      '提示维护中，稍后重试；不要刷新 Cookie',
      RetcodeRegistry.SRC_PIZZA,
    ));

    // ── 人机验证 ───────────────────────────────────────────────

    table.set(MihoyoRetcode.CAPTCHA_REQUIRED, new RetcodeInfo(
      MihoyoRetcode.CAPTCHA_REQUIRED,
      RetcodeKind.VERIFICATION_REQUIRED,
      '需要人机验证（通用）',
      '登录、签到、BBS 等接口短时间频繁请求',
      '交给 GeetestReporter / GeetestCenter 弹框；不要刷新 Cookie',
      RetcodeRegistry.SRC_COLLECT,
    ));

    table.set(MihoyoRetcode.CAPTCHA_REQUIRED_GAME_RECORD, new RetcodeInfo(
      MihoyoRetcode.CAPTCHA_REQUIRED_GAME_RECORD,
      RetcodeKind.VERIFICATION_REQUIRED,
      '需要人机验证（游戏记录）',
      '便笺、角色详情等 game_record 接口频繁请求',
      'GeetestReporter 弹框；绝区零战绩接口需走 createGeetest / verifyGeetest',
      RetcodeRegistry.SRC_PROJECT,
    ));

    // ── 设备指纹 ───────────────────────────────────────────────

    table.set(MihoyoRetcode.FINGERPRINT_INVALID, new RetcodeInfo(
      MihoyoRetcode.FINGERPRINT_INVALID,
      RetcodeKind.FINGERPRINT_INVALID,
      '设备指纹无效 / 账号异常',
      'device_fp 缺失、失效或账号风控',
      '提示重新生成设备指纹；不要走 Geetest',
      RetcodeRegistry.SRC_PIZZA,
    ));

    table.set(MihoyoRetcode.FINGERPRINT_INVALID_ALT, new RetcodeInfo(
      MihoyoRetcode.FINGERPRINT_INVALID_ALT,
      RetcodeKind.FINGERPRINT_INVALID,
      '设备指纹无效 / 账号异常',
      'device_fp 缺失、失效或账号风控（备用码）',
      '提示重新生成设备指纹；不要走 Geetest',
      RetcodeRegistry.SRC_PIZZA,
    ));

    // ── 游戏角色 ───────────────────────────────────────────────

    table.set(MihoyoRetcode.ROLE_NOT_PUBLIC, new RetcodeInfo(
      MihoyoRetcode.ROLE_NOT_PUBLIC,
      RetcodeKind.ROLE_NOT_PUBLIC,
      '角色战绩未公开',
      '角色未开启战绩展示',
      '提示用户在游戏内开启战绩展示；不要刷新 Cookie',
      RetcodeRegistry.SRC_PIZZA,
    ));

    table.set(MihoyoRetcode.ROLE_NOT_FOUND, new RetcodeInfo(
      MihoyoRetcode.ROLE_NOT_FOUND,
      RetcodeKind.ROLE_NOT_FOUND,
      '角色不存在或 UID 错误',
      'role_id 无效、角色已删除或区服不匹配',
      '提示重新选择角色 / 检查 UID；不要刷新 Cookie',
      RetcodeRegistry.SRC_PROJECT,
    ));

    // ── 登录辅助流程 ───────────────────────────────────────────

    table.set(MihoyoRetcode.CAPTCHA_INVALID, new RetcodeInfo(
      MihoyoRetcode.CAPTCHA_INVALID,
      RetcodeKind.CAPTCHA_INVALID,
      '验证码错误或已过期',
      '短信 / 登录验证码输入错误或超时',
      '要求重新获取验证码',
      RetcodeRegistry.SRC_PROJECT,
    ));

    table.set(MihoyoRetcode.QR_EXPIRED, new RetcodeInfo(
      MihoyoRetcode.QR_EXPIRED,
      RetcodeKind.QR_EXPIRED,
      '二维码已过期',
      '扫码登录二维码超过有效期',
      '刷新二维码，不按普通错误提示',
      RetcodeRegistry.SRC_TEYVAT,
    ));

    // ── HTTP 状态（不是业务 retcode）────────────────────────────

    table.set(MihoyoRetcode.HTTP_REGION_RESTRICTED, new RetcodeInfo(
      MihoyoRetcode.HTTP_REGION_RESTRICTED,
      RetcodeKind.REGION_RESTRICTED,
      '地区限制（HTTP 403）',
      '服务端返回 HTTP 403，且 message 包含 Our services are not available in your country or region',
      '提示地区限制；不要重试或刷新 Cookie',
      RetcodeRegistry.SRC_PIZZA,
    ));

    return table;
  }
}
