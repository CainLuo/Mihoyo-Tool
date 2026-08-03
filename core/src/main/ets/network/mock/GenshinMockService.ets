import { common } from '@kit.AbilityKit';
import { RequestParams, RequestOptions } from '../APIs';
import { MockServiceBase } from './MockServiceBase';
import { GenshinApiPath } from '../GenshinApiPath';
import { ApiLogSystem } from '../../log/ApiLogSystem';
import { LogEventType } from '../../log/ApiLogEntry';

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
    await this.delay();
    // 按请求中的 avatar_id 列表读取对应的独立 Mock 文件，然后组装成批量响应
    // 真实 API 响应的 items[] 不包含 avatar_id，需要 Repository 从请求参数按索引提取
    // 重要：每个文件的 overall_consume 包含真实的 lack_num 数据
    const accountId = MockServiceBase.extractAccountId(cookie).toString();
    const rm = this.context.resourceManager;
    
    // 组装所有角色的 items（使用 single_role_result 格式）
    const singleRoleResults: object[] = [];
    
    for (const item of items) {
      const itemObj = item as Record<string, Object>;
      const avatarId = itemObj['avatar_id'] as string;
      if (avatarId === undefined || avatarId === '') {
        continue;
      }
      
      const fileName = `${avatarId}.json`;
      const startTime = Date.now();
      
      // 记录请求日志
      try {
        ApiLogSystem.getInstance().debug(
          'MockService',
          '[MOCK] batch_compute item → ' + fileName,
          LogEventType.API_REQUEST,
          JSON.stringify({ avatarId, fileName, accountId, uid }),
        );
      } catch (_) {}
      
      try {
        // 尝试读取 avatar_compute/{avatarId}.json
        const fileContent = await rm.getRawFileContent(`mock/${accountId}/${uid}/avatar_compute/${fileName}`);
        const parsed = MockServiceBase.parseAndCheck(fileContent) as Record<string, Object>;
        const data = parsed['data'] as Record<string, Object>;
        const itemData = data['items'] as object[];
        const overallConsume = data['overall_consume'] as object[];
        
        if (itemData !== undefined && itemData.length > 0) {
          // 构造 single_role_result 格式
          const roleResult: Record<string, Object> = new Object() as Record<string, Object>;
          roleResult['items'] = itemData;
          // 关键：包含 overall_consume（真实 lack_num 数据）
          if (overallConsume !== undefined && overallConsume.length > 0) {
            roleResult['overall_consume'] = overallConsume;
          }
          singleRoleResults.push(roleResult);
          
          const durationMs = Date.now() - startTime;
          try {
            ApiLogSystem.getInstance().debug(
              'MockService',
              '[MOCK] batch_compute item → 200 (' + durationMs + 'ms)',
              LogEventType.API_RESPONSE,
              JSON.stringify({ statusCode: 200, durationMs, mockFile: `mock/${accountId}/${uid}/avatar_compute/${fileName}`, overallConsumeLength: overallConsume?.length ?? 0 }),
            );
          } catch (_) {}
        }
      } catch (_) {
        // 文件不存在，跳过这个角色
        try {
          ApiLogSystem.getInstance().warning(
            'MockService',
            '[MOCK] File not found: mock/' + accountId + '/' + uid + '/avatar_compute/' + fileName + ' → skipped',
            LogEventType.API_ERROR,
            JSON.stringify({ mockFile: `mock/${accountId}/${uid}/avatar_compute/${fileName}` }),
          );
        } catch (_) {}
      }
    }
    
    // 返回组装后的响应（使用 single_role_result 格式，与真实批量 API 一致）
    const response: Record<string, Object> = new Object() as Record<string, Object>;
    response['retcode'] = 0;
    response['message'] = 'OK';
    const dataObj: Record<string, Object> = new Object() as Record<string, Object>;
    dataObj['single_role_result'] = singleRoleResults;
    response['data'] = dataObj;
    return response;
  }

  private extractCookie(options?: RequestOptions): string {
    return options?.extraHeaders.get('Cookie') ?? '';
  }
}
