import { MihoyoApiService } from '../network/MihoyoApiService';
import { SignApiService } from '../network/SignApiService';

/**
 * SignRepository 签到功能仓库
 *
 * 支持两种 Service：
 * - SignApiService（DEBUG/RELEASE 环境）
 * - SignMockService（MOCK 环境）
 *
 * SignMockService 继承 MockServiceBase，签到大纲方法签名与 SignApiService 一致。
 */
export class SignRepository {
  private service: MihoyoApiService | null = null;

  setService(service: MihoyoApiService): void {
    this.service = service;
  }

  private getService(): MihoyoApiService {
    if (this.service === null) {
      throw new Error('SignRepository: service not initialized');
    }
    return this.service;
  }

  /**
   * 将 service 转换为 SignApiService 类型
   * 注意：SignMockService 虽然不是 SignApiService 子类，但方法签名一致，
   * ArkTS 运行时会正确调用对应方法。
   */
  private asSignService(): SignApiService {
    return this.getService() as SignApiService;
  }

  private toErrorMessage(error: Error | object): string {
    if (error instanceof Error) {
      return error.message;
    }
    return `${error}`;
  }

  /** 大别野签到 */
  async signBBS(cookie: string, challenge?: string): Promise<object> {
    return this.asSignService().signBBS(cookie, challenge);
  }

  /** 游戏每日签到 */
  async signGame(gameBiz: string, roleId: string, server: string, cookie: string, challenge?: string): Promise<object> {
    return this.asSignService().signGame(gameBiz, roleId, server, cookie, challenge);
  }

  /** 获取签到状态 */
  async getSignInfo(gameBiz: string, roleId: string, server: string, cookie: string): Promise<object> {
    return this.asSignService().getSignInfo(gameBiz, roleId, server, cookie);
  }

  /** 获取今日签到奖励 */
  async getSignReward(gameBiz: string, cookie: string): Promise<object> {
    return this.asSignService().getSignReward(gameBiz, cookie);
  }
}
