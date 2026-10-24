import { MihoyoApiService } from './base/network/MihoyoApiService';
import { MihoyoAccountApiService } from './MihoyoKit/api/MihoyoAccountApiService';
import { GenshinApiService } from './GenshinKit/api/GenshinApiService';
import { StarRailApiService } from './StarRailKit/api/StarRailApiService';
import { ZZZApiService } from './ZZZKit/api/ZZZApiService';
import { SignApiService } from './MihoyoKit/api/SignApiService';

/**
 * 真实 API Service 工厂。
 */
export class ApiServiceFactory {
  static createAccountService(): MihoyoApiService {
    return new MihoyoAccountApiService();
  }

  static createGenshinService(): MihoyoApiService {
    return new GenshinApiService();
  }

  static createStarRailService(): MihoyoApiService {
    return new StarRailApiService();
  }

  static createZZZService(): MihoyoApiService {
    return new ZZZApiService();
  }

  static createSignService(): MihoyoApiService {
    return new SignApiService();
  }
}
