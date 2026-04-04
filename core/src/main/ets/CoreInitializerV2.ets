import { common } from '@kit.AbilityKit';
import { RdbManagerV2 } from './database/v2/RdbManagerV2';
import { MihoyoEnvironment } from './network/v2/MihoyoEnvironment';
import { MihoyoApiServiceFactory } from './network/v2/MihoyoApiServiceFactory';
import { ApiConfigV2 } from './network/v2/ApiConfigV2';
import { DSUtilV2 } from './network/v2/DSUtilV2';
import { BBSRepository } from './repository/v2/BBSRepository';
import { GenshinRepository } from './repository/v2/GenshinRepository';
import { StarRailRepository } from './repository/v2/StarRailRepository';
import { ZZZRepository } from './repository/v2/ZZZRepository';
import { SignRepository } from './repository/v2/SignRepository';

interface CoreConfigV2 {
  isMock: boolean;
  context: common.UIAbilityContext;
}

export class CoreInitializerV2 {
  private static initialized: boolean = false;
  private static readyResolve: (() => void) | null = null;
  private static readyPromise: Promise<void> = new Promise<void>((resolve) => {
    CoreInitializerV2.readyResolve = resolve;
  });

  // 单例 Repository 实例
  static readonly bbsRepository: BBSRepository = new BBSRepository();
  static readonly genshinRepository: GenshinRepository = new GenshinRepository();
  static readonly starRailRepository: StarRailRepository = new StarRailRepository();
  static readonly zzzRepository: ZZZRepository = new ZZZRepository();
  static readonly signRepository: SignRepository = new SignRepository();

  /**
   * 初始化核心库 V2
   * 1. 初始化数据库（RdbManagerV2）
   * 2. 根据 isMock 创建对应的 Service 实例（占位，待 MihoyoApiServiceFactory 创建后替换）
   * 3. 将 Service 注入到各 Repository
   */
  public static async initCore(config: CoreConfigV2): Promise<void> {
    if (CoreInitializerV2.initialized) {
      return;
    }

    // 1. 初始化数据库
    await RdbManagerV2.init(config.context);

    // 2. 预加载设备配置和 salt
    await ApiConfigV2.preloadDeviceId(config.context);
    await ApiConfigV2.preloadDeviceFp(config.context);
    await DSUtilV2.preloadSalts(config.context);

    // 3. 确定运行环境
    const env: MihoyoEnvironment = config.isMock
      ? MihoyoEnvironment.MOCK
      : MihoyoEnvironment.RELEASE;

    // 4. 创建 Service 实例并注入到各 Repository
    const accountService = MihoyoApiServiceFactory.createAccountService(env, config.context);
    const genshinService = MihoyoApiServiceFactory.createGenshinService(env, config.context);
    const starRailService = MihoyoApiServiceFactory.createStarRailService(env, config.context);
    const zzzService = MihoyoApiServiceFactory.createZZZService(env, config.context);
    const signService = MihoyoApiServiceFactory.createSignService(env, config.context);

    CoreInitializerV2.bbsRepository.setService(accountService);
    CoreInitializerV2.genshinRepository.setService(genshinService);
    CoreInitializerV2.starRailRepository.setService(starRailService);
    CoreInitializerV2.zzzRepository.setService(zzzService);
    CoreInitializerV2.signRepository.setService(signService);

    CoreInitializerV2.initialized = true;

    if (CoreInitializerV2.readyResolve !== null) {
      CoreInitializerV2.readyResolve();
      CoreInitializerV2.readyResolve = null;
    }
  }

  public static waitForReady(): Promise<void> {
    return CoreInitializerV2.readyPromise;
  }

  public static isInitialized(): boolean {
    return CoreInitializerV2.initialized;
  }
}
