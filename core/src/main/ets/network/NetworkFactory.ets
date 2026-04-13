import { BaseApiService } from './APIs';
import { HttpService } from './HttpService';
import { MockService } from './MockService';
import { AppEnvManager } from '../constants/AppEnvManager';

/**
 * 网络服务工厂类（旧版，供 AuthRepository 兜底路径使用）
 * 根据环境配置创建相应的 API 服务实例
 */
export class NetworkFactory {
  private static instance: BaseApiService | null = null;

  private static isMockEnvironment(): boolean {
    return AppEnvManager.isMock();
  }

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
