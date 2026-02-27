import { BaseApiService } from './APIs';
import { HttpService } from './HttpService';
import { MockService } from './MockService';
import { CoreInitializer } from '../CoreInitializer';

/**
 * 网络服务工厂类
 * 根据环境配置创建相应的 API 服务实例
 */
export class NetworkFactory {
  private static instance: BaseApiService | null = null;

  /**
   * 检查是否为 Mock 环境
   * @returns 是否为 Mock 环境
   */
  private static isMockEnvironment(): boolean {
    // 从 CoreInitializer 中读取 isMock 配置
    const isMock = CoreInitializer.getIsMock();
    console.log(`Current environment: ${isMock ? 'Mock' : 'Real'}`);
    return isMock;
  }
  /**
   * 获取 API 服务实例（单例模式）
   * @returns BaseApiService 实例
   */
  public static getInstance(): BaseApiService {
    if (!NetworkFactory.instance) {
      if (NetworkFactory.isMockEnvironment()) {
        console.log('Using MockService for API requests');
        NetworkFactory.instance = new MockService();
      } else {
        console.log('Using HttpService for API requests');
        NetworkFactory.instance = new HttpService();
      }
    }
    return NetworkFactory.instance;
  }
}

// 导出默认 API 服务实例
export const apiService = NetworkFactory.getInstance();
