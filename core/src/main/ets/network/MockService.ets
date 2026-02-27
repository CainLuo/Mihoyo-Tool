
import { BaseApiService } from './APIs';
import resourceManager from '@ohos.resourceManager';
import common from '@ohos.app.ability.common';
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
 * 实现 BaseApiService 抽象类，读取本地 Mock 数据
 */
export class MockService extends BaseApiService {
  private resourceManager: resourceManager.ResourceManager | null = null;

  /**
   * 初始化资源管理器
   */
  private async initResourceManager(): Promise<resourceManager.ResourceManager> {
    if (!this.resourceManager) {
      try {
        const context = getContext(this) as common.UIAbilityContext;
        if (!context?.abilityInfo?.bundleName) {
          throw new Error("Invalid AbilityContext or missing bundleName");
        }
        this.resourceManager = await context.resourceManager;
      } catch (error) {
        throw new Error(`ResourceManager init failed: ${error.message}`);
      }
    }
    return this.resourceManager!;
  }
  /**
   * 读取本地 Mock 数据
   * @param url 请求 URL
   * @returns Mock 数据
   */
  private async getMockData(url: string): Promise<MockResponse> {
    try {
      // 从 URL 路径中提取 Mock 文件名
      const fileName = this.getMockFileName(url);
      const rm = await this.initResourceManager();
      // 读取 rawfile 目录下的 JSON 文件
      const fileContent = await rm.getRawFileContent(`mock/${fileName}.json`);
      const uint8Array = new Uint8Array(fileContent.buffer);
      const jsonString = Array.from(uint8Array).map(byte => String.fromCharCode(byte)).join('');
      return JSON.parse(jsonString);
    } catch (error) {
      console.error('Failed to get mock data:', error);
      // 返回默认的成功响应结构
      const mockResponse: MockResponse = {
        retcode: 0,
        message: 'success',
        data: {}
      };
      return mockResponse;
    }
  }

  /**
   * 根据 URL 生成 Mock 文件名
   * @param url 请求 URL
   * @returns Mock 文件名
   */
  private getMockFileName(url: string): string {
    // 移除路径中的斜杠，替换为下划线
    let fileName = url.replace(/^\/|\/$/g, '').replace(/\//g, '_');
    // 如果文件名为空，使用默认名称
    if (!fileName) {
      fileName = 'default';
    }
    return fileName;
  }

  /**
   * 模拟网络延迟
   * @param ms 延迟毫秒数
   * @returns Promise<void>
   */
  private delay(ms: number): Promise<void> {
    return new Promise((resolve) => {
      setTimeout(resolve, ms);
    });
  }

  /**
   * GET 请求
   * @param url 请求 URL
   * @param params 请求参数
   * @param baseUrlType BaseURL 类型
   * @returns Promise<T>
   */
  public async get(
    url: string,
    params?: Record<string, Object>,
    baseUrlType?: string
  ): Promise<Object> {
    await this.delay(300);
    const mockData = await this.getMockData(url);
    return mockData;
  }

  /**
   * POST 请求
   * @param url 请求 URL
   * @param data 请求数据
   * @param baseUrlType BaseURL 类型
   * @returns Promise<T>
   */
  public async post(
    url: string,
    data?: Record<string, Object>,
    baseUrlType?: string
  ): Promise<Object> {
    await this.delay(300);
    const mockData = await this.getMockData(url);
    return mockData;
  }

  /**
   * PUT 请求
   * @param url 请求 URL
   * @param data 请求数据
   * @param baseUrlType BaseURL 类型
   * @returns Promise<T>
   */
  public async put(
    url: string,
    data?: Record<string, Object>,
    baseUrlType?: string
  ): Promise<Object> {
    await this.delay(300);
    const mockData = await this.getMockData(url);
    return mockData;
  }

  /**
   * DELETE 请求
   * @param url 请求 URL
   * @param params 请求参数
   * @param baseUrlType BaseURL 类型
   * @returns Promise<T>
   */
  public async delete(
    url: string,
    params?: Record<string, Object>,
    baseUrlType?: string
  ): Promise<Object> {
    await this.delay(300);
    const mockData = await this.getMockData(url);
    return mockData;
  }
}
