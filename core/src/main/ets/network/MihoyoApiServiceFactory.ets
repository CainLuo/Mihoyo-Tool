import { MihoyoApiService } from './MihoyoApiService';
import { MihoyoAccountApiService } from './MihoyoAccountApiService';
import { GenshinApiService } from './GenshinApiService';
import { StarRailApiService } from './StarRailApiService';
import { ZZZApiService } from './ZZZApiService';
import { SignApiService } from './SignApiService';

/**
 * 真实 API Service 工厂。
 */
export class MihoyoApiServiceFactory {
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
