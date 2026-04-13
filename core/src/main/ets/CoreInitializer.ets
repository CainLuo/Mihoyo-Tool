import { common } from '@kit.AbilityKit';
import { RdbManager } from './database/RdbManager';
import { AppEnv } from './constants/AppEnv';
import { AppEnvManager } from './constants/AppEnvManager';
import { MihoyoApiServiceFactory } from './network/MihoyoApiServiceFactory';
import { ApiConfig } from './network/ApiConfig';
import { DSUtil } from './network/DSUtil';
import { BBSRepository } from './repository/BBSRepository';
import { GenshinRepository } from './repository/GenshinRepository';
import { StarRailRepository } from './repository/StarRailRepository';
import { ZZZRepository } from './repository/ZZZRepository';
import { SignRepository } from './repository/SignRepository';
import { SyncQueueRunner } from './repository/SyncQueueRunner';

export interface CoreConfig {
  env: AppEnv;
  context: common.UIAbilityContext;
}

export class CoreInitializer {
  private static initialized: boolean = false;
  private static appContext: common.UIAbilityContext | null = null;
  private static readyResolve: (() => void) | null = null;
  private static readyPromise: Promise<void> = new Promise<void>((resolve) => {
    CoreInitializer.readyResolve = resolve;
  });

  // 单例 Repository 实例（懒加载，避免模块加载时触发循环依赖）
  private static _bbsRepository: BBSRepository | null = null;
  private static _genshinRepository: GenshinRepository | null = null;
  private static _starRailRepository: StarRailRepository | null = null;
  private static _zzzRepository: ZZZRepository | null = null;
  private static _signRepository: SignRepository | null = null;

  static get bbsRepository(): BBSRepository {
    if (CoreInitializer._bbsRepository === null) {
      CoreInitializer._bbsRepository = new BBSRepository();
    }
    return CoreInitializer._bbsRepository;
  }

  static get genshinRepository(): GenshinRepository {
    if (CoreInitializer._genshinRepository === null) {
      CoreInitializer._genshinRepository = new GenshinRepository();
    }
    return CoreInitializer._genshinRepository;
  }

  static get starRailRepository(): StarRailRepository {
    if (CoreInitializer._starRailRepository === null) {
      CoreInitializer._starRailRepository = new StarRailRepository();
    }
    return CoreInitializer._starRailRepository;
  }

  static get zzzRepository(): ZZZRepository {
    if (CoreInitializer._zzzRepository === null) {
      CoreInitializer._zzzRepository = new ZZZRepository();
    }
    return CoreInitializer._zzzRepository;
  }

  static get signRepository(): SignRepository {
    if (CoreInitializer._signRepository === null) {
      CoreInitializer._signRepository = new SignRepository();
    }
    return CoreInitializer._signRepository;
  }

  /**
   * 初始化核心库：
   * 1. 注入全局环境（AppEnvManager）
   * 2. 初始化数据库（RdbManager）
   * 3. 预加载设备配置和 salt
   * 4. 创建 Service 实例并注入到各 Repository
   */
  public static async initCore(config: CoreConfig): Promise<void> {
    if (CoreInitializer.initialized) {
      return;
    }

    // 第一步：注入全局环境，后续所有 AppEnvManager.isMock() 调用均依赖此
    AppEnvManager.setup(config.env);
    CoreInitializer.appContext = config.context;

    // 1. 初始化数据库
    await RdbManager.init(config.context);

    // 2. 预加载设备配置和 salt
    await ApiConfig.preloadDeviceId(config.context);
    await ApiConfig.preloadDeviceFp(config.context);
    await DSUtil.preloadSalts(config.context);

    // 3. 创建 Service 实例并注入到各 Repository
    const accountService = MihoyoApiServiceFactory.createAccountService(config.env, config.context);
    const genshinService = MihoyoApiServiceFactory.createGenshinService(config.env, config.context);
    const starRailService = MihoyoApiServiceFactory.createStarRailService(config.env, config.context);
    const zzzService = MihoyoApiServiceFactory.createZZZService(config.env, config.context);
    const signService = MihoyoApiServiceFactory.createSignService(config.env, config.context);

    CoreInitializer.bbsRepository.setService(accountService);
    CoreInitializer.genshinRepository.setService(genshinService);
    CoreInitializer.starRailRepository.setService(starRailService);
    CoreInitializer.zzzRepository.setService(zzzService);
    CoreInitializer.signRepository.setService(signService);

    CoreInitializer.initialized = true;

    if (CoreInitializer.readyResolve !== null) {
      CoreInitializer.readyResolve();
      CoreInitializer.readyResolve = null;
    }

    // 4. 恢复未完成的同步任务（持久化队列）
    SyncQueueRunner.resumeOnStartup().catch((_: Error | object) => {});
  }

  public static waitForReady(): Promise<void> {
    return CoreInitializer.readyPromise;
  }

  public static isInitialized(): boolean {
    return CoreInitializer.initialized;
  }

  /** 获取 UIAbilityContext */
  public static getContext(): common.UIAbilityContext {
    if (CoreInitializer.appContext === null) {
      throw new Error('CoreInitializer: context not initialized, call initCore() first');
    }
    return CoreInitializer.appContext;
  }
}
