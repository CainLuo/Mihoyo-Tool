/**
 * MihoyoAccountMockService — 账号相关接口 Mock 实现（internal 版，含手机号 mock）
 *
 * 手机号映射：
 *   13800138000 → 账号 182692936（凹凸曼的小怪兽）
 *   13800138001 → 账号 348366494（狂野的沙滩裤）
 *
 * 验证码规则：固定 111111，其他均返回错误
 *
 * 二维码登录：fetch 返回假 URL，query 直接返回 confirmed（账号 182692936）
 */

import { common } from '@kit.AbilityKit';
import { RequestParams, RequestOptions } from '../APIs';
import { MockServiceBase } from './MockServiceBase';
import { MihoyoAccountApiService } from '../MihoyoAccountApiService';
import { MihoyoAccountApiPath } from '../MihoyoAccountApiPath';

const MOCK_PHONE_182 = '13800138000';
const MOCK_PHONE_348 = '13800138001';
const MOCK_AID_182 = '182692936';
const MOCK_AID_348 = '348366494';
const MOCK_CAPTCHA = '111111';
const MOCK_STOKEN_PREFIX = 'mock_stoken_';

export class MihoyoAccountMockService extends MihoyoAccountApiService {
  private readonly mockContext: common.UIAbilityContext;

  constructor(context: common.UIAbilityContext) {
    super();
    this.mockContext = context;
  }

  async get(path: string, params?: RequestParams, options?: RequestOptions): Promise<object> {
    return MockServiceBase.readMockFileStatic(path, this.extractCookieFromOptions(options), this.mockContext);
  }

  async post(path: string, data?: string | RequestParams, options?: RequestOptions): Promise<object> {
    return MockServiceBase.readMockFileStatic(path, this.extractCookieFromOptions(options), this.mockContext);
  }

  // ── 手机号登录 ────────────────────────────────────────────────

  async createLoginCaptcha(encryptedMobile: string, _encryptedAreaCode: string): Promise<object> {
    await MockServiceBase.delayStatic();
    const mobile = encryptedMobile;
    if (mobile !== MOCK_PHONE_182 && mobile !== MOCK_PHONE_348) {
      return this.errorResp(-3101, '手机号未注册');
    }
    const d = new Object() as Record<string, Object>;
    d['sent_new'] = true;
    d['countdown'] = 60;
    d['action_type'] = 'login_by_mobile_captcha';
    return this.okResp(d);
  }

  async loginByMobileCaptcha(
    encryptedMobile: string,
    _encryptedAreaCode: string,
    captcha: string,
  ): Promise<object> {
    await MockServiceBase.delayStatic();
    const mobile = encryptedMobile;
    let aid = '';
    if (mobile === MOCK_PHONE_182) {
      aid = MOCK_AID_182;
    } else if (mobile === MOCK_PHONE_348) {
      aid = MOCK_AID_348;
    } else {
      return this.errorResp(-3101, '手机号未注册');
    }
    if (captcha !== MOCK_CAPTCHA) {
      return this.errorResp(-3001, '验证码错误');
    }
    const mid = `mock_mid_${aid}`;
    const tokenObj = new Object() as Record<string, Object>;
    tokenObj['token_type'] = 1;
    tokenObj['token'] = `${MOCK_STOKEN_PREFIX}${aid}`;
    const userInfoObj = new Object() as Record<string, Object>;
    userInfoObj['aid'] = aid;
    userInfoObj['mid'] = mid;
    userInfoObj['mobile'] = mobile;
    const d = new Object() as Record<string, Object>;
    d['token'] = tokenObj;
    d['user_info'] = userInfoObj;
    return this.okResp(d);
  }

  // ── Token 换取 ────────────────────────────────────────────────

  async getLTokenBySToken(stoken: string, _mid: string): Promise<object> {
    await MockServiceBase.delayStatic();
    const d = new Object() as Record<string, Object>;
    d['ltoken'] = `mock_ltoken_${this.extractAidFromStoken(stoken)}`;
    return this.okResp(d);
  }

  async getCookieTokenBySToken(stoken: string, _mid: string): Promise<object> {
    await MockServiceBase.delayStatic();
    const aid = this.extractAidFromStoken(stoken);
    const d = new Object() as Record<string, Object>;
    d['uid'] = aid;
    d['cookie_token'] = `mock_cookie_token_${aid}`;
    return this.okResp(d);
  }

  // ── 二维码登录 ────────────────────────────────────────────────

  async fetchQRCode(_deviceId: string): Promise<object> {
    await MockServiceBase.delayStatic();
    const d = new Object() as Record<string, Object>;
    d['ticket'] = `mock_ticket_${MOCK_AID_182}`;
    d['url'] = `https://user.mihoyo.com/qr_code_in_game.html?ticket=mock_ticket_${MOCK_AID_182}`;
    return this.okResp(d);
  }

  async queryQRCode(_deviceId: string, _ticket: string): Promise<object> {
    await MockServiceBase.delayStatic();
    // 新版 passport API 直接返回 tokens 和 user_info
    const tokens: Object[] = [];
    const t1 = new Object() as Record<string, Object>;
    t1['token'] = `${MOCK_STOKEN_PREFIX}${MOCK_AID_182}`;
    t1['token_type'] = 1;
    tokens.push(t1);
    const t2 = new Object() as Record<string, Object>;
    t2['token'] = `mock_ltoken_${MOCK_AID_182}`;
    t2['token_type'] = 2;
    tokens.push(t2);
    const t3 = new Object() as Record<string, Object>;
    t3['token'] = `mock_cookie_token_${MOCK_AID_182}`;
    t3['token_type'] = 4;
    tokens.push(t3);
    const userInfo = new Object() as Record<string, Object>;
    userInfo['aid'] = MOCK_AID_182;
    userInfo['mid'] = `mock_mid_${MOCK_AID_182}`;
    userInfo['account_name'] = 'MockAccount';
    const d = new Object() as Record<string, Object>;
    d['status'] = 'Confirmed';
    d['tokens'] = tokens;
    d['user_info'] = userInfo;
    return this.okResp(d);
  }

  // ── 账号相关 ──────────────────────────────────────────────────

  async getGameRoles(cookie: string): Promise<object> {
    return MockServiceBase.readMockFileStatic(MihoyoAccountApiPath.GET_GAME_ROLES, cookie, this.mockContext);
  }

  async getGameRecordCard(uid: string, cookie: string): Promise<object> {
    return MockServiceBase.readMockFileStatic(MihoyoAccountApiPath.GET_GAME_RECORD_CARD, cookie, this.mockContext);
  }

  async getUserFullInfo(uid: string, cookie: string): Promise<object> {
    return MockServiceBase.readMockFileStatic(MihoyoAccountApiPath.GET_USER_FULL_INFO, cookie, this.mockContext);
  }

  async createVerification(cookie: string): Promise<object> {
    return MockServiceBase.readMockFileStatic(MihoyoAccountApiPath.CREATE_VERIFICATION, cookie, this.mockContext);
  }

  async verifyVerification(input: object, cookie: string): Promise<object> {
    return MockServiceBase.readMockFileStatic(MihoyoAccountApiPath.VERIFY_VERIFICATION, cookie, this.mockContext);
  }

  async refreshCookieToken(_stoken: string, _stuid: string): Promise<object> {
    await MockServiceBase.delayStatic();
    const d = new Object() as Record<string, Object>;
    d['cookie_token'] = 'mock_cookie_token';
    return this.okResp(d);
  }

  async refreshLToken(_stoken: string, _stuid: string): Promise<object> {
    await MockServiceBase.delayStatic();
    const d = new Object() as Record<string, Object>;
    d['ltoken'] = 'mock_ltoken';
    return this.okResp(d);
  }

  async verifyLToken(_ltoken: string, _ltuid: string): Promise<object> {
    await MockServiceBase.delayStatic();
    return this.okResp(new Object());
  }

  // ── 工具方法 ─────────────────────────────────────────────────

  private okResp(data: object): object {
    const r = new Object() as Record<string, Object>;
    r['retcode'] = 0;
    r['message'] = 'OK';
    r['data'] = data;
    return r;
  }

  private errorResp(retcode: number, message: string): object {
    const r = new Object() as Record<string, Object>;
    r['retcode'] = retcode;
    r['message'] = message;
    r['data'] = new Object();
    return r;
  }

  private extractAidFromStoken(stoken: string): string {
    if (stoken.startsWith(MOCK_STOKEN_PREFIX)) {
      return stoken.substring(MOCK_STOKEN_PREFIX.length);
    }
    return MOCK_AID_182;
  }

  private extractCookieFromOptions(options?: RequestOptions): string {
    if (options === undefined) { return ''; }
    return options.extraHeaders.get('Cookie') ?? '';
  }
}
