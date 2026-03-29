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
    if (!context.abilityInfo.bundleName) {
      throw new Error('Invalid UIAbilityContext or missing bundleName');
    }
    this.rm = context.resourceManager;
    return this.rm;
  }

  /**
   * 从 Cookie 字符串中提取 account_id，用于定位 mock 子目录
   * account_id=1 → account1，account_id=2 → account2，其他 → 根目录
   */
  private getAccountDir(options?: RequestOptions): string {
    if (!options) { return '' }
    const cookie = options.extraHeaders.get('Cookie') ?? ''
    const match = cookie.match(/account_id=(\d+)/)
    if (match) {
      return `account${match[1]}/`
    }
    return ''
  }

  /**
   * 读取本地 Mock JSON 文件
   * 优先读账号子目录，找不到则回退到根目录
   */
  private async getMockData(url: string, options?: RequestOptions): Promise<MockResponse> {
    try {
      const fileName = this.getMockFileName(url)
      const rm = await this.initResourceManager()
      const accountDir = this.getAccountDir(options)

      // 优先尝试账号子目录
      if (accountDir) {
        try {
          const fileContent = await rm.getRawFileContent(`mock/${accountDir}${fileName}.json`)
          const decoder = new util.TextDecoder('utf-8')
          const jsonString = decoder.decodeToString(new Uint8Array(fileContent.buffer))
          return JSON.parse(jsonString) as MockResponse
        } catch (_) {
          // 子目录没有，回退到根目录
        }
      }

      // 根目录
      const fileContent = await rm.getRawFileContent(`mock/${fileName}.json`)
      const decoder = new util.TextDecoder('utf-8')
      const jsonString = decoder.decodeToString(new Uint8Array(fileContent.buffer))
      return JSON.parse(jsonString) as MockResponse
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
    return this.getMockData(url, options);
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
