import { common } from '@kit.AbilityKit';
import { RequestParams, RequestOptions } from '../APIs';
import { MockServiceBase } from './MockServiceBase';
import { GenshinApiPath } from '../GenshinApiPath';
import { ApiLogSystem } from '../../log/ApiLogSystem';
import { LogEventType } from '../../log/ApiLogEntry';
import { Logger } from '../../utils/Logger';

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
    const result = await this.readMockFile(GenshinApiPath.CHARACTER_LIST, cookie, roleId);
    return result;
  }

  /** 统一使用 character_detail_all.json（特殊映射表会自动处理） */
  async getCharacterDetail(roleId: string, server: string, characterIds: number[], cookie: string): Promise<object> {
    return this.readMockFile(GenshinApiPath.CHARACTER_DETAIL, cookie, roleId);
  }

  async batchCompute(items: object[], uid: string, region: string, cookie: string): Promise<object> {
    Logger.info('GenshinMockService', `batchCompute: uid=${uid}, region=${region}, items count=${items.length}`);
    // 原神批量计算直接读取 genshin_character_batch_compute.json（已包含完整数据）
    return this.readMockFile(GenshinApiPath.BATCH_COMPUTE, cookie, uid);
  }

  /** Mock 模式没有 sync/avatar/list 数据，返回空列表（调用方会回退到无计算项） */
  async syncCalcAvatarList(uid: string, region: string, cookie: string, page: number, size: number): Promise<object> {
    Logger.info('GenshinMockService', `syncCalcAvatarList: uid=${uid}, page=${page}`);
    const emptyList: Object[] = [];
    const data: Record<string, Object> = {};
    data['list'] = emptyList;
    const resp: Record<string, Object> = {};
    resp['retcode'] = 0;
    resp['message'] = 'OK';
    resp['data'] = data;
    return resp;
  }

  private extractCookie(options?: RequestOptions): string {
    return options?.extraHeaders.get('Cookie') ?? '';
  }
}
