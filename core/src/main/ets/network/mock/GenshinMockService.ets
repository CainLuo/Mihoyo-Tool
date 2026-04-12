import { common } from '@kit.AbilityKit';
import { RequestParams, RequestOptions } from '../APIs';
import { MockServiceBase } from './MockServiceBase';
import { GenshinApiPath } from '../GenshinApiPath';

export class GenshinMockService extends MockServiceBase {
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
    return this.readMockFile(GenshinApiPath.DAILY_NOTE, cookie, roleId);
  }

  async getCharacterList(roleId: string, server: string, cookie: string): Promise<object> {
    return this.readMockFile(GenshinApiPath.CHARACTER_LIST, cookie, roleId);
  }

  /** 统一使用 character_detail_all.json（特殊映射表会自动处理） */
  async getCharacterDetail(roleId: string, server: string, characterIds: number[], cookie: string): Promise<object> {
    return this.readMockFile(GenshinApiPath.CHARACTER_DETAIL, cookie, roleId);
  }

  async batchCompute(items: object[], uid: string, region: string, cookie: string): Promise<object> {
    return this.readMockFile(GenshinApiPath.BATCH_COMPUTE, cookie, uid);
  }

  private extractCookie(options?: RequestOptions): string {
    return options?.extraHeaders.get('Cookie') ?? '';
  }
}
