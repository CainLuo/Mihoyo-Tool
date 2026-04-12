import { BaseApiService, RequestOptions, RequestParams } from './APIs';
import { resourceManager } from '@kit.LocalizationKit';
import { util } from '@kit.ArkTS';
import { CoreInitializer } from '../CoreInitializer';

/**
 * Mock 响应接口
 */
interface MockResponse {
  retcode: number;
  message: string;
  data: Record<string, object>;
}

/**
 * Mock 服务类
 * 实现 BaseApiService，从 rawfile/mock/ 目录读取本地 JSON 文件作为响应。
 * options 参数（含 extraHeaders）在 Mock 模式下被忽略，仅保持签名兼容。
 */
export class MockService extends BaseApiService {
  private rm: resourceManager.ResourceManager | null = null;

  private async initResourceManager(): Promise<resourceManager.ResourceManager> {
    if (this.rm) {
      return this.rm;
    }
    const context = CoreInitializer.getContext();
    this.rm = context.resourceManager;
    return this.rm;
  }

  /**
   * 从 Cookie 字符串中提取 account_id
   */
  private getAccountId(options?: RequestOptions): string {
    if (!options) { return '' }
    const cookie = options.extraHeaders.get('Cookie') ?? ''
    const match = cookie.match(/account_id=(\d+)/)
    return match ? match[1] : ''
  }

  /**
   * 从 URL 的 query string 或 body 中提取 role_id / uid
   * 游戏数据接口用 role_id（原神/星铁/绝区零），getGameRecordCard 用 uid
   */
  private getRoleId(url: string, body?: string): string {
    // 先从 query string 里找
    const qIdx = url.indexOf('?')
    if (qIdx !== -1) {
      const query = url.substring(qIdx + 1)
      const parts = query.split('&')
      for (let i = 0; i < parts.length; i++) {
        const kv = parts[i].split('=')
        if (kv[0] === 'role_id' || kv[0] === 'uid') {
          return kv[1] ?? ''
        }
      }
    }
    // 再从 body JSON 里找
    if (body) {
      try {
        const parsed = JSON.parse(body) as Record<string, string>
        if (parsed['role_id']) { return parsed['role_id'] }
        if (parsed['uid']) { return parsed['uid'] }
      } catch (_) {}
    }
    return ''
  }

  /**
   * 从 URL query string 中提取绝区零单个角色详情的 id_list[] 第一个值
   * 例：?role_id=37716744&id_list[]=1171&id_list[]=1141 → '1171'
   */
  private getZZZAvatarId(url: string): string {
    const qIdx = url.indexOf('?')
    if (qIdx === -1) { return '' }
    const query = url.substring(qIdx + 1)
    const parts = query.split('&')
    for (let i = 0; i < parts.length; i++) {
      if (parts[i].startsWith('id_list[]=')) {
        return parts[i].substring('id_list[]='.length)
      }
    }
    return ''
  }

  /**
   * 根据 URL 路径判断是否为绝区零角色详情接口
   * 对应 ZZZApiPath.AVATAR_INFO（event/game_record_zzz/api/zzz/avatar/info）
   */
  private isZZZAvatarInfoUrl(url: string): boolean {
    return url.indexOf('zzz/avatar/info') !== -1
  }

  /**
   * 读取本地 Mock JSON 文件
   * 路由优先级：
   *   绝区零角色详情：{account_id}/{role_id}/{avatarId}.json
   *   其他游戏数据：{account_id}/{role_id}/文件名.json
   *   账号级数据：{account_id}/文件名.json
   *   兜底：根目录/文件名.json
   */
  private async getMockData(url: string, options?: RequestOptions, body?: string): Promise<MockResponse> {
    try {
      const rm = await this.initResourceManager()
      const accountId = this.getAccountId(options)
      const roleId = this.getRoleId(url, body)

      // 绝区零角色详情：用 avatarId 作为文件名
      if (this.isZZZAvatarInfoUrl(url)) {
        const avatarId = this.getZZZAvatarId(url)
        if (accountId && roleId && avatarId) {
          try {
            const content = await rm.getRawFileContent(`mock/${accountId}/${roleId}/${avatarId}.json`)
            const decoder = new util.TextDecoder('utf-8')
            return JSON.parse(decoder.decodeToString(new Uint8Array(content.buffer))) as MockResponse
          } catch (_) {}
        }
      }

      const fileName = this.getMockFileName(url)

      // 第一优先：{account_id}/{role_id}/文件名
      if (accountId && roleId) {
        try {
          const content = await rm.getRawFileContent(`mock/${accountId}/${roleId}/${fileName}.json`)
          const decoder = new util.TextDecoder('utf-8')
          return JSON.parse(decoder.decodeToString(new Uint8Array(content.buffer))) as MockResponse
        } catch (_) {}
      }

      // 第二优先：{account_id}/文件名（账号级数据，如 getUserFullInfo、binding）
      if (accountId) {
        try {
          const content = await rm.getRawFileContent(`mock/${accountId}/${fileName}.json`)
          const decoder = new util.TextDecoder('utf-8')
          return JSON.parse(decoder.decodeToString(new Uint8Array(content.buffer))) as MockResponse
        } catch (_) {}
      }

      // 兜底：根目录
      const content = await rm.getRawFileContent(`mock/${fileName}.json`)
      const decoder = new util.TextDecoder('utf-8')
      return JSON.parse(decoder.decodeToString(new Uint8Array(content.buffer))) as MockResponse
    } catch (error) {
      console.error(`Failed to get mock data: ${this.toErrorMessage(error)}`)
      return { retcode: 0, message: 'success', data: {} }
    }
  }

  /**
   * 将 URL 路径转换为 Mock 文件名
   * 例：https://api.mihoyo.com/game_record/app/genshin/api/character/list
   *   → game_record_app_genshin_api_character_list
   * 例：/game_record/app/genshin/api/character/list
   *   → game_record_app_genshin_api_character_list
   */
  private getMockFileName(url: string): string {
    // 提取路径部分：去掉协议+域名，只保留 path
    let path = url;
    const protoIdx = url.indexOf('://');
    if (protoIdx !== -1) {
      const slashIdx = url.indexOf('/', protoIdx + 3);
      path = slashIdx !== -1 ? url.substring(slashIdx) : '/';
    }
    // 去掉查询参数
    const qIdx = path.indexOf('?');
    if (qIdx !== -1) {
      path = path.substring(0, qIdx);
    }
    // 去掉首尾斜杠，把剩余斜杠替换为下划线
    const fileName = path.replace(/^\/|\/$/g, '').replace(/\//g, '_');
    return fileName || 'default';
  }

  private delay(ms: number): Promise<void> {
    return new Promise((resolve) => setTimeout(resolve, ms));
  }

  private toErrorMessage(error: Error | object): string {
    if (error instanceof Error) {
      return error.message;
    }
    return `${error}`;
  }

  public async get(url: string, _params?: RequestParams, options?: RequestOptions): Promise<object> {
    await this.delay(300);
    return this.getMockData(url, options);
  }

  public async post(url: string, _data?: RequestParams, options?: RequestOptions): Promise<object> {
    await this.delay(300);
    const body = typeof _data === 'string' ? _data : undefined;
    return this.getMockData(url, options, body);
  }

  public async put(url: string, _data?: RequestParams, options?: RequestOptions): Promise<object> {
    await this.delay(300);
    return this.getMockData(url, options);
  }

  public async delete(url: string, _params?: RequestParams, options?: RequestOptions): Promise<object> {
    await this.delay(300);
    return this.getMockData(url, options);
  }
}
