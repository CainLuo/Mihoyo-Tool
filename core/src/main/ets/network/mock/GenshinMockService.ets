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
    const accountId = MockServiceBase.extractAccountId(cookie).toString();
    const rm = this.context.resourceManager;
    
    // 组装所有角色的 items（使用 single_role_result 格式）
    const singleRoleResults: object[] = [];
    
    // 日志：开始批量计算
    try {
      ApiLogSystem.getInstance().info(
        'MockService',
        '💥💥💥 [MOCK] batch_compute start: items=' + items.length + ', accountId=' + accountId + ', uid=' + uid,
        LogEventType.API_REQUEST,
        JSON.stringify({ itemCount: items.length, accountId, uid }),
      );
    } catch (_) {}
    
    for (const item of items) {
      const itemObj = item as Record<string, Object>;
      const avatarId = itemObj['avatar_id'] as string;
      if (avatarId === undefined || avatarId === '') {
        try {
          ApiLogSystem.getInstance().warning(
            'MockService',
            '[MOCK] batch_compute: item has no avatar_id, skipping',
            LogEventType.API_ERROR,
            JSON.stringify({ item: itemObj }),
          );
        } catch (_) {}
        continue;
      }
      
      const fileName = `${avatarId}.json`;
      const startTime = Date.now();
      
      try {
        // 尝试读取 avatar_compute/{avatarId}.json
        const mockFilePath = `mock/${accountId}/${uid}/avatar_compute/${fileName}`;
        const fileContent = await rm.getRawFileContent(mockFilePath);
        const parsed = MockServiceBase.parseAndCheck(fileContent) as Record<string, Object>;
        const data = parsed['data'] as Record<string, Object>;
        const itemData = data['items'] as object[];
        const overallConsume = data['overall_consume'] as object[];
        
        // 日志：读取到的数据结构
        try {
          ApiLogSystem.getInstance().info(
            'MockService',
            '💥💥💥 [MOCK] batch_compute file loaded: ' + mockFilePath,
            LogEventType.API_RESPONSE,
            JSON.stringify({ 
              avatarId, 
              mockFilePath,
              hasItems: itemData !== undefined && itemData !== null,
              itemsLength: itemData?.length ?? 0,
              hasOverallConsume: overallConsume !== undefined && overallConsume !== null,
              overallConsumeLength: overallConsume?.length ?? 0,
              dataKeys: data !== undefined && data !== null ? Object.keys(data).join(',') : 'null'
            }),
          );
        } catch (_) {}
        
        if (itemData !== undefined && itemData !== null && itemData.length > 0) {
          // 构造 single_role_result 格式
          const roleResult: Record<string, Object> = new Object() as Record<string, Object>;
          // 关键：添加 avatar_id 到 items 中（解析时需要）
          const itemsWithAvatarId: Record<string, Object>[] = [];
          for (let k = 0; k < itemData.length; k++) {
            const itemRecord = itemData[k] as Record<string, Object>;
            const itemWithId: Record<string, Object> = new Object() as Record<string, Object>;
            // 复制所有字段
            const keys = Object.keys(itemRecord);
            for (let m = 0; m < keys.length; m++) {
              itemWithId[keys[m]] = itemRecord[keys[m]];
            }
            // 添加 avatar_id
            itemWithId['avatar_id'] = avatarId;
            itemsWithAvatarId[itemsWithAvatarId.length] = itemWithId;
          }
          roleResult['items'] = itemsWithAvatarId;
          // 关键：包含 overall_consume（如果有）
          if (overallConsume !== undefined && overallConsume !== null && overallConsume.length > 0) {
            roleResult['overall_consume'] = overallConsume;
          }
          singleRoleResults.push(roleResult);
          
          const durationMs = Date.now() - startTime;
          try {
            ApiLogSystem.getInstance().debug(
              'MockService',
              '[MOCK] batch_compute item → 200 (' + durationMs + 'ms)',
              LogEventType.API_RESPONSE,
              JSON.stringify({ statusCode: 200, durationMs, mockFilePath, overallConsumeLength: overallConsume?.length ?? 0 }),
            );
          } catch (_) {}
        } else {
          // items 为空，记录警告
          try {
            ApiLogSystem.getInstance().warning(
              'MockService',
              '[MOCK] batch_compute: file loaded but items is empty or null: ' + mockFilePath,
              LogEventType.API_ERROR,
              JSON.stringify({ avatarId, mockFilePath, hasItems: itemData !== undefined && itemData !== null, itemsLength: itemData?.length ?? 0 }),
            );
          } catch (_) {}
        }
      } catch (e) {
        // 文件不存在，跳过这个角色
        try {
          ApiLogSystem.getInstance().warning(
            'MockService',
            '[MOCK] File not found: mock/' + accountId + '/' + uid + '/avatar_compute/' + fileName + ' → skipped',
            LogEventType.API_ERROR,
            JSON.stringify({ mockFile: `mock/${accountId}/${uid}/avatar_compute/${fileName}`, error: e instanceof Error ? e.message : String(e) }),
          );
        } catch (_) {}
      }
    }
    
    // 日志：最终组装结果
    try {
      ApiLogSystem.getInstance().info(
        'MockService',
        '💥💥💥 [MOCK] batch_compute done: singleRoleResults=' + singleRoleResults.length,
        LogEventType.API_RESPONSE,
        JSON.stringify({ singleRoleResultsLength: singleRoleResults.length }),
      );
    } catch (_) {}
    
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
