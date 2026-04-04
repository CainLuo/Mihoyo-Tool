import { common } from '@kit.AbilityKit';
import { MihoyoApiService } from './MihoyoApiService';
import { MihoyoEnvironment } from './MihoyoEnvironment';
import { MihoyoAccountApiService } from './MihoyoAccountApiService';
import { GenshinApiService } from './GenshinApiService';
import { StarRailApiService } from './StarRailApiService';
import { ZZZApiService } from './ZZZApiService';
import { SignApiService } from './SignApiService';
import { MihoyoAccountMockService } from './mock/MihoyoAccountMockService';
import { GenshinMockService } from './mock/GenshinMockService';
import { StarRailMockService } from './mock/StarRailMockService';
import { ZZZMockService } from './mock/ZZZMockService';
import { SignMockService } from './mock/SignMockService';

export class MihoyoApiServiceFactory {
  /**
   * Mock Service 需要 context 来读取 rawfile，Release Service 不需要。
   * ArkTS 严格模式：禁止 ! 非空断言，改为显式 undefined 检查。
   */
  private static requireContext(context?: common.UIAbilityContext): common.UIAbilityContext {
    if (context === undefined) {
      throw new Error('MihoyoApiServiceFactory: context is required for Mock environment');
    }
    return context;
  }

  static createAccountService(
    env: MihoyoEnvironment,
    context?: common.UIAbilityContext,
  ): MihoyoApiService {
    if (env === MihoyoEnvironment.MOCK) {
      return new MihoyoAccountMockService(MihoyoApiServiceFactory.requireContext(context));
    }
    return new MihoyoAccountApiService();
  }

  static createGenshinService(
    env: MihoyoEnvironment,
    context?: common.UIAbilityContext,
  ): MihoyoApiService {
    if (env === MihoyoEnvironment.MOCK) {
      return new GenshinMockService(MihoyoApiServiceFactory.requireContext(context));
    }
    return new GenshinApiService();
  }

  static createStarRailService(
    env: MihoyoEnvironment,
    context?: common.UIAbilityContext,
  ): MihoyoApiService {
    if (env === MihoyoEnvironment.MOCK) {
      return new StarRailMockService(MihoyoApiServiceFactory.requireContext(context));
    }
    return new StarRailApiService();
  }

  static createZZZService(
    env: MihoyoEnvironment,
    context?: common.UIAbilityContext,
  ): MihoyoApiService {
    if (env === MihoyoEnvironment.MOCK) {
      return new ZZZMockService(MihoyoApiServiceFactory.requireContext(context));
    }
    return new ZZZApiService();
  }

  static createSignService(
    env: MihoyoEnvironment,
    context?: common.UIAbilityContext,
  ): MihoyoApiService {
    if (env === MihoyoEnvironment.MOCK) {
      return new SignMockService(MihoyoApiServiceFactory.requireContext(context));
    }
    return new SignApiService();
  }
}
