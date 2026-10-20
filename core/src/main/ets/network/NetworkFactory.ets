import { BaseApiService } from './APIs';
import { HttpService } from './HttpService';

/**
 * 网络服务工厂类（旧版，供 AuthRepository 兜底路径使用）。
 * 默认创建 HttpService。
 */
export class NetworkFactory {
  private static instance: BaseApiService | null = null;

  public static reset(): void {
    NetworkFactory.instance = null;
  }

  public static getInstance(): BaseApiService {
    if (!NetworkFactory.instance) {
      NetworkFactory.instance = new HttpService();
    }
    return NetworkFactory.instance;
  }
}
