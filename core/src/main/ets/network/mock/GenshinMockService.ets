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
    // 读取基础 Mock 文件作为模板
    const baseResp = await this.readMockFile(GenshinApiPath.BATCH_COMPUTE, cookie, uid);
    
    // 如果请求的 items 为空，直接返回基础响应
    if (!items || items.length === 0) {
      return baseResp;
    }
    
    // 解析基础响应
    const baseObj = JSON.parse(JSON.stringify(baseResp)) as Record<string, Object>;
    const dataObj = baseObj['data'] as Record<string, Object>;
    if (!dataObj) {
      return baseResp;
    }
    
    // 获取模板数据（第一条）
    const templateList = dataObj['items'] !== undefined ? dataObj['items'] : dataObj['list'];
    if (!templateList) {
      return baseResp;
    }
    
    const templateArray = templateList as Object[];
    if (templateArray.length === 0) {
      return baseResp;
    }
    
    const templateItem = templateArray[0] as Record<string, Object>;
    
    // 根据请求的 avatar_id 列表，动态生成响应
    const responseItems: Object[] = [];
    
    for (let i = 0; i < items.length; i++) {
      const requestItem = items[i] as Record<string, Object>;
      const avatarId = requestItem['avatar_id'];
      
      // 深拷贝模板并替换 avatar_id
      const responseItem = JSON.parse(JSON.stringify(templateItem)) as Record<string, Object>;
      responseItem['avatar_id'] = avatarId;
      
      responseItems[responseItems.length] = responseItem as Object;
    }
    
    // 构建新的响应（保持原始结构）
    const newDataObj = JSON.parse(JSON.stringify(dataObj)) as Record<string, Object>;
    // 删除旧的 list 字段（如果存在）
    newDataObj['list'] = responseItems; // 用 items 的值覆盖 list
    newDataObj['items'] = responseItems;
    
    const result = JSON.parse(JSON.stringify(baseObj)) as Record<string, Object>;
    result['data'] = newDataObj;
    
    return result as Object;
  }

  private extractCookie(options?: RequestOptions): string {
    return options?.extraHeaders.get('Cookie') ?? '';
  }
}
