import { NetworkFactory } from './NetworkFactory';
import { RequestOptions, RequestParams } from './APIs';
import { GeetestCreateResult, GeetestVerifyInput } from '../errors/ApiErrors';
import { DSUtil } from './DSUtil';
import { HttpClient } from './HttpClient';
import { MihoyoDomain } from './MihoyoDomain';
import { MihoyoAccountApiPath } from './MihoyoAccountApiPath';
import { HKey, HVal } from './MihoyoHeaderKey';
import { ApiConfig } from './ApiConfig';
import { GameId } from '../constants/GameId';
import { GenshinApiPath } from './GenshinApiPath';
import { StarRailApiPath } from './StarRailApiPath';
import { ZZZApiPath } from './ZZZApiPath';

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
 * 完整流程（参考 PizzaHelperUnited CreateVerificationAPI.swift）：
 *   1. core.GeetestService.createVerification(cookie, gameId)
 *      → 返回 GeetestCreateResult { gt, challenge?, risk_type? }
 *   2. entry.GeetestDialog.show(createResult)
 *      → 用户完成验证，返回 GeetestVerifyInput { geetest_challenge, geetest_validate, geetest_seccode }
 *   3. core.GeetestService.verifyVerification(verifyInput, cookie, gameId)
 *      → 返回新的 challenge 字符串
 *   4. 调用方用新 challenge 重新发起业务请求（x-rpc-challenge 已在 ApiService 层注入）
 *
 * 接口地址（参考 PizzaHelperUnited，使用 card/wapi 端点，与 daily note 同域名）：
 *   createVerification: GET  https://api-takumi-record.mihoyo.com/game_record/app/card/wapi/createVerification
 *   verifyVerification: POST https://api-takumi-record.mihoyo.com/game_record/app/card/wapi/verifyVerification
 * ============================================================
 */

// ---- 类型定义 ----

/**
 * verifyVerification 接口成功后返回的新 challenge
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

export class GeetestService {

  /**
   * 根据 gameId 返回对应的 x-rpc-challenge_path 值
   * 参考 PizzaHelperUnited URLRequestConfig.writeXRPCChallengeHeaders4DailyNote
   */
  static getChallengePath(gameId: GameId): string {
    if (gameId === GameId.GENSHIN) {
      return MihoyoDomain.TAKUMI_RECORD + GenshinApiPath.DAILY_NOTE;
    }
    if (gameId === GameId.STARRAIL) {
      return MihoyoDomain.TAKUMI_RECORD + StarRailApiPath.DAILY_NOTE;
    }
    if (gameId === GameId.ZZZ) {
      return MihoyoDomain.TAKUMI_RECORD + ZZZApiPath.DAILY_NOTE;
    }
    return '';
  }

  /**
   * 根据 gameId 返回对应的 x-rpc-challenge_game 值
   * 原神=2，星铁=6，绝区零=8
   * 参考 PizzaHelperUnited URLRequestConfig.writeXRPCChallengeHeaders4DailyNote
   */
  static getChallengeGame(gameId: GameId): string {
    if (gameId === GameId.GENSHIN) { return '2'; }
    if (gameId === GameId.STARRAIL) { return '6'; }
    if (gameId === GameId.ZZZ) { return '8'; }
    return '';
  }

  /**
   * 向米游社申请一次 Geetest 验证任务
   *
   * @param cookie  当前用户的 Cookie 字符串
   * @param gameId  触发验证的游戏 ID，用于注入 x-rpc-challenge_path 和 x-rpc-challenge_game
   * @returns GeetestCreateResult，包含 gt 和 challenge（v3）或 risk_type（v4）
   * @throws Error 当接口返回 retcode !== 0 时
   */
  public static async createVerification(
    cookie: string,
    gameId: GameId,
  ): Promise<GeetestCreateResult> {
    const createParams = new RequestParams();
    createParams.set('is_high', 'true');

    const opts = new RequestOptions();
    opts.extraHeaders.set(HKey.COOKIE, cookie);
    opts.extraHeaders.set(HKey.APP_VERSION, ApiConfig.APP_VERSION);
    opts.extraHeaders.set(HKey.CLIENT_TYPE, HVal.CLIENT_WEB);
    opts.extraHeaders.set(HKey.DEVICE_FP, ApiConfig.getDeviceFp());
    opts.extraHeaders.set(HKey.DEVICE_ID, ApiConfig.getDeviceIdSync());
    opts.extraHeaders.set(HKey.USER_AGENT, ApiConfig.USER_AGENT);
    // 告知服务器此次验证针对哪个接口，参考 PizzaHelperUnited writeXRPCChallengeHeaders4DailyNote
    const challengePath = GeetestService.getChallengePath(gameId);
    const challengeGame = GeetestService.getChallengeGame(gameId);
    if (challengePath.length > 0) {
      opts.extraHeaders.set(HKey.CHALLENGE_PATH, challengePath);
    }
    if (challengeGame.length > 0) {
      opts.extraHeaders.set(HKey.CHALLENGE_GAME, challengeGame);
    }
    // 使用 X4 salt（与 PizzaHelperUnited defaultHeaders 一致，card/wapi 端点使用 X4）
    opts.extraHeaders.set(HKey.DS, DSUtil.generateX4(createParams));

    const resp = await HttpClient.get(
      MihoyoDomain.TAKUMI_RECORD + MihoyoAccountApiPath.CREATE_VERIFICATION,
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
   * @param gameId      触发验证的游戏 ID，用于注入 x-rpc-challenge_path 和 x-rpc-challenge_game
   * @returns 新的 challenge 字符串，直接用于 x-rpc-challenge 请求头
   * @throws Error 当接口返回 retcode !== 0 时
   */
  public static async verifyVerification(
    verifyInput: GeetestVerifyInput,
    cookie: string,
    gameId: GameId,
  ): Promise<string> {
    // geetest_seccode 格式：validate + "|jordan"
    // 参考 PizzaHelperUnited VerifyVerificationBody：geetestSeccode = "\(validate)|jordan"
    const bodyStr = JSON.stringify({
      geetest_challenge: verifyInput.geetest_challenge,
      geetest_validate: verifyInput.geetest_validate,
      geetest_seccode: verifyInput.geetest_validate + '|jordan',
    });

    const opts = new RequestOptions();
    opts.extraHeaders.set(HKey.COOKIE, cookie);
    opts.extraHeaders.set(HKey.APP_VERSION, ApiConfig.APP_VERSION);
    opts.extraHeaders.set(HKey.CLIENT_TYPE, HVal.CLIENT_WEB);
    opts.extraHeaders.set(HKey.DEVICE_FP, ApiConfig.getDeviceFp());
    opts.extraHeaders.set(HKey.DEVICE_ID, ApiConfig.getDeviceIdSync());
    opts.extraHeaders.set(HKey.USER_AGENT, ApiConfig.USER_AGENT);
    // 告知服务器此次验证针对哪个接口
    const challengePath = GeetestService.getChallengePath(gameId);
    const challengeGame = GeetestService.getChallengeGame(gameId);
    if (challengePath.length > 0) {
      opts.extraHeaders.set(HKey.CHALLENGE_PATH, challengePath);
    }
    if (challengeGame.length > 0) {
      opts.extraHeaders.set(HKey.CHALLENGE_GAME, challengeGame);
    }
    // 使用 X4 salt（与 PizzaHelperUnited 一致）
    opts.extraHeaders.set(HKey.DS, DSUtil.generateX4(undefined, bodyStr));

    const resp = await HttpClient.post(
      MihoyoDomain.TAKUMI_RECORD + MihoyoAccountApiPath.VERIFY_VERIFICATION,
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
