import { NetworkFactory } from './NetworkFactory';
import { RequestOptions, RequestParams } from './APIs';
import { GeetestCreateResult, GeetestVerifyInput } from '../errors/ApiErrors';
import { DSUtil } from './DSUtil';
import { HttpClient } from './HttpClient';
import { MihoyoDomain } from './MihoyoDomain';
import { MihoyoAccountApiPath } from './MihoyoAccountApiPath';
import { HKey, HVal } from './MihoyoHeaderKey';
import { ApiConfig } from './ApiConfig';

/**
 * ============================================================
 * Geetest 验证服务（core 层）
 * ============================================================
 *
 * 职责：
 *   1. createVerification  — 向米游社申请一次 Geetest 验证任务，获取 gt + challenge
 *   2. verifyVerification  — 把用户完成验证后的结果提交给米游社，换取可用于 API 请求的新 challenge
 *
 * 不负责：
 *   - 展示验证码 UI（由 entry 层的 GeetestDialog 组件负责）
 *   - 把验证结果注入到业务请求（由调用方通过 RequestOptions.extraHeaders 注入）
 *
 * 完整流程（参考 TeyvatGuide miscReq.ts）：
 *   1. core.GeetestService.createVerification(cookie)
 *      → 返回 GeetestCreateResult { gt, challenge?, risk_type? }
 *   2. entry.GeetestDialog.show(createResult)
 *      → 用户完成验证，返回 GeetestVerifyInput { geetest_challenge, geetest_validate, geetest_seccode }
 *   3. core.GeetestService.verifyVerification(verifyInput, cookie)
 *      → 返回新的 challenge 字符串
 *   4. 调用方用新 challenge 构造 extraHeaders，重新发起业务请求：
 *      apiService.get(url, params, {
 *        extraHeaders: {
 *          'x-rpc-challenge': newChallenge,
 *          'x-rpc-validate':  verifyInput.geetest_validate,
 *          'x-rpc-seccode':   verifyInput.geetest_seccode,
 *        }
 *      })
 *
 * 米游社接口地址（来源：TeyvatGuide miscReq.ts）：
 *   createVerification: GET  https://bbs-api.miyoushe.com/misc/api/createVerification
 *   verifyVerification: POST https://bbs-api.miyoushe.com/misc/api/verifyVerification
 * ============================================================
 */

// ---- 类型定义 ----

/**
 * verifyVerification 接口成功后返回的新 challenge
 * 这个 challenge 才是最终注入到业务请求头里的值
 */
export interface GeetestVerifyResult {
  /** 可直接用于 x-rpc-challenge 请求头的新 challenge */
  challenge: string;
}

// ---- 米游社 API 响应包装类型 ----

interface MysBaseResponse {
  retcode: number;
  message: string;
}

interface CreateVerificationResponse extends MysBaseResponse {
  data: GeetestCreateResult;
}

interface VerifyVerificationResponse extends MysBaseResponse {
  data: GeetestVerifyResult;
}

// ---- 服务实现 ----

/**
 * Geetest 验证服务
 *
 * 使用方式（entry 层）：
 *   import { GeetestService } from 'core';
 *
 *   const createResult = await GeetestService.createVerification(cookie);
 *   // 展示验证码弹窗，拿到用户验证结果
 *   const verifyInput = await GeetestDialog.show(createResult);
 *   if (!verifyInput) return; // 用户取消
 *   const newChallenge = await GeetestService.verifyVerification(verifyInput, cookie);
 *   // 用新 challenge 重试业务请求
 */
export class GeetestService {
  /**
   * 米游社 misc API 基础路径
   * 来源：TeyvatGuide miscReq.ts bamBu 常量
   */
  private static readonly BASE_URL = 'https://bbs-api.miyoushe.com/misc/api';

  /**
   * 向米游社申请一次 Geetest 验证任务
   *
   * @param cookie 当前用户的 Cookie 字符串（需包含 login_ticket 或 stoken）
   * @param useK2  是否使用 K2 salt 生成 DS 签名。
   *               米游社部分接口要求 K2，部分要求 X4，默认 true（与 TeyvatGuide 保持一致）。
   *               TODO: 当 DSUtil 支持多 salt 后，此参数传给 DS 生成逻辑。
   * @returns GeetestCreateResult，包含 gt 和 challenge（v3）或 risk_type（v4）
   * @throws Error 当接口返回 retcode !== 0 时
   */
  public static async createVerification(
    cookie: string,
  ): Promise<GeetestCreateResult> {
    const createParams = new RequestParams();
    createParams.set('is_high', 'true');
    // K2 + isSign=true：salt_v1，不含 b/q，字母数字 random（与 TeyvatGuide miscReq.ts 一致）
    const opts = new RequestOptions();
    opts.extraHeaders.set(HKey.COOKIE, cookie);
    opts.extraHeaders.set(HKey.APP_VERSION, ApiConfig.APP_VERSION);
    opts.extraHeaders.set(HKey.CLIENT_TYPE, HVal.CLIENT_ANDROID);
    opts.extraHeaders.set(HKey.DEVICE_FP, ApiConfig.getDeviceFp());
    opts.extraHeaders.set(HKey.DEVICE_ID, ApiConfig.getDeviceIdSync());
    opts.extraHeaders.set(HKey.USER_AGENT, ApiConfig.USER_AGENT);
    opts.extraHeaders.set(HKey.DS, DSUtil.generateK2Sign());
    const resp = await HttpClient.get(
      MihoyoDomain.BBS + MihoyoAccountApiPath.CREATE_VERIFICATION,
      createParams,
      opts
    ) as CreateVerificationResponse;

    if (resp.retcode !== 0) {
      throw new Error(`createVerification failed: [${resp.retcode}] ${resp.message}`);
    }
    return resp.data;
  }

  /**
   * 提交用户验证结果，换取可用于业务请求的新 challenge
   *
   * @param verifyInput 用户完成 Geetest 验证后 SDK 返回的结果
   * @param cookie      当前用户的 Cookie 字符串
   * @param useK2       是否使用 K2 salt，默认 true
   * @returns 新的 challenge 字符串，直接用于 x-rpc-challenge 请求头
   * @throws Error 当接口返回 retcode !== 0 时
   */
  public static async verifyVerification(
    verifyInput: GeetestVerifyInput,
    cookie: string,
  ): Promise<string> {
    const bodyStr = JSON.stringify({
      geetest_challenge: verifyInput.geetest_challenge,
      geetest_validate: verifyInput.geetest_validate,
      geetest_seccode: verifyInput.geetest_seccode,
    });
    // K2 + isSign=false：salt_v1，含 body，字母数字 random（与 TeyvatGuide miscReq.ts 一致）
    const opts = new RequestOptions();
    opts.extraHeaders.set(HKey.COOKIE, cookie);
    opts.extraHeaders.set(HKey.APP_VERSION, ApiConfig.APP_VERSION);
    opts.extraHeaders.set(HKey.CLIENT_TYPE, HVal.CLIENT_ANDROID);
    opts.extraHeaders.set(HKey.DEVICE_FP, ApiConfig.getDeviceFp());
    opts.extraHeaders.set(HKey.DEVICE_ID, ApiConfig.getDeviceIdSync());
    opts.extraHeaders.set(HKey.USER_AGENT, ApiConfig.USER_AGENT);
    opts.extraHeaders.set(HKey.DS, DSUtil.generateK2(undefined, bodyStr));
    const resp = await HttpClient.post(
      MihoyoDomain.BBS + MihoyoAccountApiPath.VERIFY_VERIFICATION,
      bodyStr,
      opts
    ) as VerifyVerificationResponse;

    if (resp.retcode !== 0) {
      throw new Error(`verifyVerification failed: [${resp.retcode}] ${resp.message}`);
    }
    return resp.data.challenge;
  }

  /**
   * 便捷方法：根据 createVerification 的结果判断 Geetest 版本
   * @returns 'v3' | 'v4'
   */
  public static getGeetestVersion(createResult: GeetestCreateResult): 'v3' | 'v4' {
    // ArkTS 不支持 in 操作符（arkts-no-in），改为直接检查字段是否 undefined
    return createResult.challenge !== undefined ? 'v3' : 'v4';
  }
}
