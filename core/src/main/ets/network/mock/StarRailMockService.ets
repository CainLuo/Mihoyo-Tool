import { common } from '@kit.AbilityKit';
import { RequestParams, RequestOptions } from '../APIs';
import { MockServiceBase } from './MockServiceBase';
import { StarRailApiPath } from '../StarRailApiPath';

export class StarRailMockService extends MockServiceBase {
  constructor(context: common.UIAbilityContext) {
    super(context);
  }

  async get(path: string, params?: RequestParams, options?: RequestOptions): Promise<object> {
    return this.readMockFile(path, this.extractCookie(options));
  }

  async post(path: string, data?: string | RequestParams, options?: RequestOptions): Promise<object> {
    return this.readMockFile(path, this.extractCookie(options));
  }

  async getDailyNote(roleId: string, server: string, cookie: string): Promise<object> {
    return this.readMockFile(StarRailApiPath.DAILY_NOTE, cookie);
  }

  async getAvatarBasic(roleId: string, server: string, cookie: string): Promise<object> {
    return this.readMockFile(StarRailApiPath.AVATAR_BASIC, cookie);
  }

  async getAvatarInfo(roleId: string, server: string, id: string, cookie: string): Promise<object> {
    return this.readMockFile(StarRailApiPath.AVATAR_INFO, cookie);
  }

  async compute(avatar: object, skillList: object[], uid: string, region: string, cookie: string): Promise<object> {
    return this.readMockFile(StarRailApiPath.COMPUTE, cookie);
  }

  private extractCookie(options?: RequestOptions): string {
    return options?.extraHeaders.get('Cookie') ?? '';
  }
}
