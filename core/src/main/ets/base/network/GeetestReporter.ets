/**
 * GeetestReporter — 人机验证（retcode=1034 / 10035）统一上报
 *
 * 具体 API 收到 1034 / 10035 时显式调用 report()，由 entry 通过 GeetestService.setRequiredListener() 注册的监听统一弹框。
 * BaseApiService 不自动上报；便笺 / Widget 请求的 suppressGeetestReport 只由具体 API 判断，由 Repository 在两者都失败后自行上报。
 */
import { RequestParams, RequestValue } from './APIs';
import { RetcodeRegistry } from '../errors/RetcodeRegistry';

/** url 已去掉 query；roleUid 为该请求的游戏 UID（取不到时为空字符串）；retcode 为 1034 / 10035（决定验证接口） */
export type GeetestRequiredListener = (url: string, cookie: string, roleUid: string, retcode: number) => void;

export class GeetestReporter {
  private static listener: GeetestRequiredListener | null = null;

  static setListener(listener: GeetestRequiredListener | null): void {
    GeetestReporter.listener = listener;
  }

  /**
   * @param url    触发验证的接口地址（会去掉 query，作为 x-rpc-challenge_path）
   * @param cookie 该请求使用的 Cookie
   * @param roleUid 该请求的游戏 UID（用于弹框时提示是哪个游戏账号）
   * @param retcode 1034 / 10035（Axiu-Plugin：10035 走 createGeetest，1034 走 createVerification）
   */
  static report(url: string, cookie: string, roleUid: string, retcode: number): void {
    const listener = GeetestReporter.listener;
    if (listener === null) {
      return;
    }
    const q = url.indexOf('?');
    try {
      listener(q >= 0 ? url.substring(0, q) : url, cookie, roleUid, retcode);
    } catch (_) {}
  }

  /** 从请求中取游戏 UID：query 参数 / URL / 请求体里的 role_id，养成计算接口为请求体里的 uid */
  static roleUidOf(url: string, params?: RequestParams, body?: string | Record<string, RequestValue>): string {
    const p = params?.get('role_id');
    if (p !== undefined && p !== null) {
      return `${p}`;
    }
    const q = url.match(/[?&]role_id=([^&]+)/);
    if (q !== null) {
      return q[1];
    }
    if (typeof body === 'string') {
      const b = body.match(/"(?:role_id|uid)"\s*:\s*"?(\d+)/);
      return b !== null ? b[1] : '';
    }
    if (body !== undefined) {
      const v = body['role_id'] ?? body['uid'];
      return v !== undefined && v !== null ? `${v}` : '';
    }
    return '';
  }

  /**
   * 1034 / 10035：需要人机验证（Miao-Yunzai mysInfo.js checkCode、Axiu-Plugin、GT-Manual 均只对这两个码过验证码）。
   * 10041 与 5003 同类（"米游社账号异常" / 设备指纹无效），见 FingerprintReporter。
   */
  static isGeetestRetcode(retcode: number | undefined): boolean {
    return RetcodeRegistry.isVerificationRequired(retcode);
  }
}
