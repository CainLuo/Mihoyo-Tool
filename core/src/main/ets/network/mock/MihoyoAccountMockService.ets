import { common } from '@kit.AbilityKit';
import { RequestParams, RequestOptions } from '../APIs';
import { MockServiceBase } from './MockServiceBase';
import { MihoyoAccountApiPath } from '../MihoyoAccountApiPath';

export class MihoyoAccountMockService extends MockServiceBase {
  constructor(context: common.UIAbilityContext) {
    super(context);
  }

  async get(path: string, params?: RequestParams, options?: RequestOptions): Promise<object> {
    return this.readMockFile(path, this.extractCookieFromOptions(options));
  }

  async post(path: string, data?: string | RequestParams, options?: RequestOptions): Promise<object> {
    return this.readMockFile(path, this.extractCookieFromOptions(options));
  }

  async getGameRoles(cookie: string): Promise<object> {
    return this.readMockFile(MihoyoAccountApiPath.GET_GAME_ROLES, cookie);
  }

  async getGameRecordCard(uid: string, cookie: string): Promise<object> {
    return this.readMockFile(MihoyoAccountApiPath.GET_GAME_RECORD_CARD, cookie);
  }

  async getUserFullInfo(uid: string, cookie: string): Promise<object> {
    return this.readMockFile(MihoyoAccountApiPath.GET_USER_FULL_INFO, cookie);
  }

  async createVerification(cookie: string): Promise<object> {
    return this.readMockFile(MihoyoAccountApiPath.CREATE_VERIFICATION, cookie);
  }

  async verifyVerification(input: object, cookie: string): Promise<object> {
    return this.readMockFile(MihoyoAccountApiPath.VERIFY_VERIFICATION, cookie);
  }

  async refreshCookieToken(stoken: string, stuid: string): Promise<object> {
    await this.delay();
    const r = new Object() as Record<string, Object>;
    r['retcode'] = 0;
    r['message'] = 'OK';
    const d = new Object() as Record<string, Object>;
    d['cookie_token'] = 'mock_cookie_token';
    r['data'] = d;
    return r;
  }

  async refreshLToken(stoken: string, stuid: string): Promise<object> {
    await this.delay();
    const r = new Object() as Record<string, Object>;
    r['retcode'] = 0;
    r['message'] = 'OK';
    const d = new Object() as Record<string, Object>;
    d['ltoken'] = 'mock_ltoken';
    r['data'] = d;
    return r;
  }

  async verifyLToken(ltoken: string, ltuid: string): Promise<object> {
    await this.delay();
    const r = new Object() as Record<string, Object>;
    r['retcode'] = 0;
    r['message'] = 'OK';
    r['data'] = new Object();
    return r;
  }

  private extractCookieFromOptions(options?: RequestOptions): string {
    if (options === undefined) {
      return '';
    }
    return options.extraHeaders.get('Cookie') ?? '';
  }
}
