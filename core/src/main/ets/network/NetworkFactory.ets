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
    return CoreInitializer.getIsMock();
  }
  /**
   * 获取 API 服务实例（单例模式）
   * @returns BaseApiService 实例
   */
  /**
   * 重置单例，下次 getInstance() 时重新按当前 isMock 创建。
   * 在 CoreInitializer.initCore 完成后调用，确保单例与环境一致。
   */
  public static reset(): void {
    NetworkFactory.instance = null;
  }

  public static getInstance(): BaseApiService {
    if (!NetworkFactory.instance) {
      if (NetworkFactory.isMockEnvironment()) {
        NetworkFactory.instance = new MockService();
      } else {
        NetworkFactory.instance = new HttpService();
      }
    }
    if (NetworkFactory.instance === null) {
      throw new Error('ApiService instance initialize failed');
    }
    return NetworkFactory.instance;
  }
}
