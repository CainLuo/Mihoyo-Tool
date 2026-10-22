import { RequestParams, RequestOptions } from '../../base/network/APIs';
import { MihoyoApiService } from '../../base/network/MihoyoApiService';
import { MihoyoDomain } from '../../base/network/MihoyoDomain';
import { SignApiPath, SIGN_GAME_ACT_ID, gameBizToSignHost } from './SignApiPath';
import { HeaderContext, HeaderProfile } from '../../base/network/MihoyoHeaderBuilder';
import { HKey } from '../../base/network/MihoyoHeaderKey';

export class SignApiService extends MihoyoApiService {

  /** 大别野签到 — POST，Domain=BBS_APIHUB，Profile=SIGN */
  async signBBS(cookie: string, challenge?: string): Promise<object> {
    const bodyStr = JSON.stringify({ geetest_challenge: challenge ?? '', geetest_validate: '', geetest_seccode: '' });
    const context = new HeaderContext(HeaderProfile.SIGN, cookie);
    const url = MihoyoDomain.BBS_APIHUB + SignApiPath.SIGN_BBS;
    const response = await this.postWithProfile(url, context, bodyStr);
    this.reportBusinessError(url, response.data, undefined, undefined, bodyStr, cookie, '');
    return response.data;
  }

  /** 游戏每日签到 — POST，Domain=TAKUMI，Profile=SIGN */
  async signGame(
    gameBiz: string,
    roleId: string,
    server: string,
    cookie: string,
    challenge?: string,
  ): Promise<object> {
    const host = gameBizToSignHost(gameBiz);
    const bodyStr = JSON.stringify({
      act_id: SIGN_GAME_ACT_ID,
      region: server,
      uid: roleId,
      geetest_challenge: challenge ?? '',
      geetest_validate: '',
      geetest_seccode: '',
    });
    const context = new HeaderContext(HeaderProfile.SIGN, cookie);
    const opts = new RequestOptions();
    opts.extraHeaders.set(HKey.SIGN_GAME, host);
    const url = MihoyoDomain.TAKUMI + SignApiPath.SIGN_GAME_BASE + `/${host}/sign`;
    const response = await this.postWithProfile(url, context, bodyStr, opts);
    this.reportBusinessError(url, response.data, opts, undefined, bodyStr, cookie, roleId);
    return response.data;
  }

  /** 获取签到状态 — GET，Domain=TAKUMI，Profile=SIGN */
  async getSignInfo(gameBiz: string, roleId: string, server: string, cookie: string): Promise<object> {
    const host = gameBizToSignHost(gameBiz);
    const params = new RequestParams();
    params.set('region', server);
    params.set('uid', roleId);
    const context = new HeaderContext(HeaderProfile.SIGN, cookie);
    const opts = new RequestOptions();
    opts.extraHeaders.set(HKey.SIGN_GAME, host);
    const url = MihoyoDomain.TAKUMI + SignApiPath.SIGN_GAME_BASE + `/${host}/info`;
    const response = await this.getWithProfile(url, context, params, opts);
    this.reportBusinessError(url, response.data, opts, params, undefined, cookie, roleId);
    return response.data;
  }

  /** 获取今日签到奖励 — GET，Domain=TAKUMI，Profile=SIGN */
  async getSignReward(gameBiz: string, cookie: string): Promise<object> {
    const host = gameBizToSignHost(gameBiz);
    const params = new RequestParams();
    const context = new HeaderContext(HeaderProfile.SIGN, cookie);
    const opts = new RequestOptions();
    opts.extraHeaders.set(HKey.SIGN_GAME, host);
    const url = MihoyoDomain.TAKUMI + SignApiPath.SIGN_GAME_BASE + `/${host}/home`;
    const response = await this.getWithProfile(url, context, params, opts);
    this.reportBusinessError(url, response.data, opts, params, undefined, cookie, '');
    return response.data;
  }
}
