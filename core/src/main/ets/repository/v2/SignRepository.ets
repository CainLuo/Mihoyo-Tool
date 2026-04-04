import { MihoyoApiService } from '../../network/v2/MihoyoApiService';

export class SignRepository {
  // TODO: 待 SignApiService 创建后，将类型替换为 SignApiService
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

  private toErrorMessage(error: Error | object): string {
    if (error instanceof Error) {
      return error.message;
    }
    return `${error}`;
  }

  /** 大别野签到 */
  async signBBS(cookie: string, challenge?: string): Promise<object> {
    // TODO: 待 SignApiService 创建后，调用 this.getService().signBBS(cookie, challenge)
    throw new Error(`SignRepository.signBBS: not implemented yet`);
  }

  /** 游戏每日签到 */
  async signGame(gameBiz: string, roleId: string, server: string, cookie: string, challenge?: string): Promise<object> {
    // TODO: 待 SignApiService 创建后，调用 this.getService().signGame(gameBiz, roleId, server, cookie, challenge)
    throw new Error(`SignRepository.signGame: not implemented yet, gameBiz=${gameBiz}`);
  }

  /** 获取签到状态 */
  async getSignInfo(gameBiz: string, roleId: string, server: string, cookie: string): Promise<object> {
    // TODO: 待 SignApiService 创建后，调用 this.getService().getSignInfo(gameBiz, roleId, server, cookie)
    throw new Error(`SignRepository.getSignInfo: not implemented yet, gameBiz=${gameBiz}`);
  }

  /** 获取今日签到奖励 */
  async getSignReward(gameBiz: string, cookie: string): Promise<object> {
    // TODO: 待 SignApiService 创建后，调用 this.getService().getSignReward(gameBiz, cookie)
    throw new Error(`SignRepository.getSignReward: not implemented yet, gameBiz=${gameBiz}`);
  }
}
