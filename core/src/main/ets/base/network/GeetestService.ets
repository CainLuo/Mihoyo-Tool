import { RequestOptions, RequestParams } from './APIs';
import { GeetestCreateResult, GeetestVerifyInput } from '../errors/ApiErrors';
import { DSUtil } from './DSUtil';
import { BaseApiService } from './BaseApiService';
import { MihoyoDomain } from './MihoyoDomain';
import { MihoyoAccountApiPath } from '../../network/MihoyoAccountApiPath';
import { HKey, HVal } from './MihoyoHeaderKey';
import { ApiConfig } from './ApiConfig';
import { GameId } from '../../common/constants/GameId';
import { GenshinApiPath } from '../../network/GenshinApiPath';
import { StarRailApiPath } from '../../network/StarRailApiPath';
import { ZZZApiPath } from '../../network/ZZZApiPath';
import { GeetestReporter, GeetestRequiredListener } from './GeetestReporter';
import { ZZZRecordRequest } from '../../network/ZZZRecordRequest';

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
   * 注册人机验证统一处理：任何接口返回 1034 / 10035 时回调（url 已去掉 query，cookie 为该请求的 Cookie，roleUid 为游戏 UID，retcode 决定验证接口）
   */
  public static setRequiredListener(listener: GeetestRequiredListener | null): void {
    GeetestReporter.setListener(listener);
  }

  /** 是否为需要人机验证的返回码（1034 / 10035） */
  public static isGeetestRetcode(retcode: number): boolean {
    return GeetestReporter.isGeetestRetcode(retcode);
  }

  /** Repository 主动上报（便笺与 Widget 都失败时） */
  public static reportRequired(url: string, cookie: string, roleUid: string, retcode: number): void {
    GeetestReporter.report(url, cookie, roleUid, retcode);
  }

  /**
   * 向米游社申请一次 Geetest 验证任务
   *
   * @param cookie  当前用户的 Cookie 字符串
   * @param gameId  触发验证的游戏 ID，用于注入 x-rpc-challenge_path 和 x-rpc-challenge_game
   * @param challengePathOverride 失败接口的完整地址；不传则为该游戏的便笺接口（参考 PizzaHelperUnited challengePathOverride）
   * @param retcode 触发验证的返回码（绝区零战绩接口据此选择验证接口）
   * @returns GeetestCreateResult，包含 gt 和 challenge（v3）或 risk_type（v4）
   * @throws Error 当接口返回 retcode !== 0 时
   */
  public static async createVerification(
    cookie: string,
    gameId: GameId,
    challengePathOverride?: string,
    retcode: number = 1034,
  ): Promise<GeetestCreateResult> {
    // 绝区零战绩接口：照 Axiu-Plugin（10035 → createGeetest，1034 → card/wapi/createVerification），用该账号的设备指纹
    if (challengePathOverride !== undefined && ZZZRecordRequest.isZZZRecordUrl(challengePathOverride)) {
      return ZZZRecordRequest.createGeetest(cookie, retcode);
    }
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
    const challengePath = challengePathOverride !== undefined && challengePathOverride.length > 0
      ? challengePathOverride : GeetestService.getChallengePath(gameId);
    const challengeGame = GeetestService.getChallengeGame(gameId);
    if (challengePath.length > 0) {
      opts.extraHeaders.set(HKey.CHALLENGE_PATH, challengePath);
    }
    if (challengeGame.length > 0) {
      opts.extraHeaders.set(HKey.CHALLENGE_GAME, challengeGame);
    }
    // 使用 X4 salt（与 PizzaHelperUnited defaultHeaders 一致，card/wapi 端点使用 X4）
    opts.extraHeaders.set(HKey.DS, DSUtil.generateX4(createParams));

    const response = await BaseApiService.shared.get(
      MihoyoDomain.TAKUMI_RECORD + MihoyoAccountApiPath.CREATE_VERIFICATION,
      createParams,
      opts
    );
    const resp = response.data as CreateVerificationResponse;

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
   * @param challengePathOverride 失败接口的完整地址，须与 createVerification 时一致；不传则为该游戏的便笺接口
   * @returns 新的 challenge 字符串，直接用于 x-rpc-challenge 请求头
   * @throws Error 当接口返回 retcode !== 0 时
   */
  public static async verifyVerification(
    verifyInput: GeetestVerifyInput,
    cookie: string,
    gameId: GameId,
    challengePathOverride?: string,
    retcode: number = 1034,
  ): Promise<string> {
    // 绝区零战绩接口：照 Axiu-Plugin（10035 → verifyGeetest，1034 → card/wapi/verifyVerification），返回的 challenge 用于重放原请求
    if (challengePathOverride !== undefined && ZZZRecordRequest.isZZZRecordUrl(challengePathOverride)) {
      return ZZZRecordRequest.verifyGeetest(cookie, verifyInput, challengePathOverride, retcode);
    }
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
    const challengePath = challengePathOverride !== undefined && challengePathOverride.length > 0
      ? challengePathOverride : GeetestService.getChallengePath(gameId);
    const challengeGame = GeetestService.getChallengeGame(gameId);
    if (challengePath.length > 0) {
      opts.extraHeaders.set(HKey.CHALLENGE_PATH, challengePath);
    }
    if (challengeGame.length > 0) {
      opts.extraHeaders.set(HKey.CHALLENGE_GAME, challengeGame);
    }
    // 使用 X4 salt（与 PizzaHelperUnited 一致）
    opts.extraHeaders.set(HKey.DS, DSUtil.generateX4(undefined, bodyStr));

    const response = await BaseApiService.shared.post(
      MihoyoDomain.TAKUMI_RECORD + MihoyoAccountApiPath.VERIFY_VERIFICATION,
      bodyStr,
      opts
    );
    const resp = response.data as VerifyVerificationResponse;

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
