import { common } from '@kit.AbilityKit';
import { RequestParams, RequestOptions } from '../APIs';
import { MockServiceBase } from './MockServiceBase';
import { ZZZApiPath } from '../ZZZApiPath';

export class ZZZMockService extends MockServiceBase {
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
    return this.readMockFile(ZZZApiPath.DAILY_NOTE, cookie, roleId);
  }

  async getDailyNoteWidget(cookie: string): Promise<object> {
    // Widget API 是账号级的，Mock 文件放在 {accountId}/ 目录下
    return this.readMockFile(ZZZApiPath.DAILY_NOTE_WIDGET, cookie);
  }

  async getAvatarBasic(roleId: string, server: string, cookie: string): Promise<object> {
    return this.readMockFile(ZZZApiPath.AVATAR_BASIC, cookie, roleId);
  }

  async getAvatarInfo(roleId: string, server: string, idList: string[], cookie: string): Promise<object> {
    // 绝区零：用 idList[0] 作为文件名，路由到 {accountId}/{roleId}/{avatarId}.json
    const avatarId = idList.length > 0 ? idList[0] : '';
    return this.readMockFile(ZZZApiPath.AVATAR_INFO, cookie, roleId, avatarId);
  }

  async getBuddyList(roleId: string, server: string, cookie: string): Promise<object> {
    return this.readMockFile(ZZZApiPath.BUDDY_LIST, cookie, roleId);
  }

  async compute(
    avatarId: string,
    avatarLevel: number,
    avatarCurrentLevel: number,
    avatarCurrentPromotes: number,
    skills: object[],
    uid: string,
    region: string,
    cookie: string,
  ): Promise<object> {
    return this.readMockFile(ZZZApiPath.COMPUTE, cookie);
  }

  private extractCookie(options?: RequestOptions): string {
    return options?.extraHeaders.get('Cookie') ?? '';
  }
}
