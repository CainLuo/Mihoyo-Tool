import { MihoyoApiService } from '../base/network/MihoyoApiService';
import { SignApiService } from '../network/SignApiService';

/**
 * SignRepository 签到功能仓库
 *
 * 接受方法签名与 SignApiService 一致的签到 Service 实现。
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
   * 将 service 转换为 SignApiService 类型。
   * 兼容实现只要方法签名一致即可。
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
