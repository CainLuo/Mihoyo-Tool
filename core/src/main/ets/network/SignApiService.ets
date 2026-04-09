import { RequestParams, RequestOptions } from './APIs';
import { MihoyoApiService } from './MihoyoApiService';
import { MihoyoDomain } from './MihoyoDomain';
import { SignApiPath } from './SignApiPath';
import { MihoyoHeaderBuilder, HeaderProfile } from './MihoyoHeaderBuilder';
import { HttpClient } from './HttpClient';

/** 从 gameBiz 提取签到 host（如 hk4e_cn → hk4e） */
function gameBizToHost(gameBiz: string): string {
  if (gameBiz.startsWith('hk4e')) {
    return 'hk4e';
  }
  if (gameBiz.startsWith('hkrpg')) {
    return 'hkrpg';
  }
  if (gameBiz.startsWith('nap') || gameBiz.startsWith('zzz')) {
    return 'zzz';
  }
  // fallback：取下划线前的部分
  const idx = gameBiz.indexOf('_');
  return idx > 0 ? gameBiz.substring(0, idx) : gameBiz;
}

export class SignApiService extends MihoyoApiService {

  async get(path: string, params?: RequestParams, options?: RequestOptions): Promise<object> {
    return HttpClient.get(path, params, options);
  }

  async post(path: string, data?: string | RequestParams, options?: RequestOptions): Promise<object> {
    return HttpClient.post(path, data, options);
  }

  /** 大别野签到 — POST，Domain=BBS_APIHUB，Profile=SIGN */
  async signBBS(cookie: string, challenge?: string): Promise<object> {
    const bodyStr = JSON.stringify({ geetest_challenge: challenge ?? '', geetest_validate: '', geetest_seccode: '' });
    const headers = MihoyoHeaderBuilder.build(HeaderProfile.SIGN, cookie, undefined, bodyStr);
    const opts = new RequestOptions();
    opts.extraHeaders = headers;
    return HttpClient.post(
      MihoyoDomain.BBS_APIHUB + SignApiPath.SIGN_BBS,
      bodyStr,
      opts,
    );
  }

  /** 游戏每日签到 — POST，Domain=TAKUMI，Profile=SIGN */
  async signGame(
    gameBiz: string,
    roleId: string,
    server: string,
    cookie: string,
    challenge?: string,
  ): Promise<object> {
    const host = gameBizToHost(gameBiz);
    const bodyStr = JSON.stringify({
      act_id: `e202311201442471`,
      region: server,
      uid: roleId,
      geetest_challenge: challenge ?? '',
      geetest_validate: '',
      geetest_seccode: '',
    });
    const headers = MihoyoHeaderBuilder.build(HeaderProfile.SIGN, cookie, undefined, bodyStr);
    headers.set('x-rpc-signgame', host);
    const opts = new RequestOptions();
    opts.extraHeaders = headers;
    return HttpClient.post(
      MihoyoDomain.TAKUMI + SignApiPath.SIGN_GAME_BASE + `/${host}/sign`,
      bodyStr,
      opts,
    );
  }

  /** 获取签到状态 — GET，Domain=TAKUMI，Profile=SIGN */
  async getSignInfo(gameBiz: string, roleId: string, server: string, cookie: string): Promise<object> {
    const host = gameBizToHost(gameBiz);
    const params = new RequestParams();
    params.set('region', server);
    params.set('uid', roleId);
    const headers = MihoyoHeaderBuilder.build(HeaderProfile.SIGN, cookie, params);
    headers.set('x-rpc-signgame', host);
    const opts = new RequestOptions();
    opts.extraHeaders = headers;
    return HttpClient.get(
      MihoyoDomain.TAKUMI + SignApiPath.SIGN_GAME_BASE + `/${host}/info`,
      params,
      opts,
    );
  }

  /** 获取今日签到奖励 — GET，Domain=TAKUMI，Profile=SIGN */
  async getSignReward(gameBiz: string, cookie: string): Promise<object> {
    const host = gameBizToHost(gameBiz);
    const params = new RequestParams();
    const headers = MihoyoHeaderBuilder.build(HeaderProfile.SIGN, cookie, params);
    headers.set('x-rpc-signgame', host);
    const opts = new RequestOptions();
    opts.extraHeaders = headers;
    return HttpClient.get(
      MihoyoDomain.TAKUMI + SignApiPath.SIGN_GAME_BASE + `/${host}/home`,
      params,
      opts,
    );
  }
}
