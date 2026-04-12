import { common } from '@kit.AbilityKit';
import { RdbManager } from './database/RdbManager';
import { MihoyoEnvironment } from './network/MihoyoEnvironment';
import { MihoyoApiServiceFactory } from './network/MihoyoApiServiceFactory';
import { ApiConfig } from './network/ApiConfig';
import { DSUtil } from './network/DSUtil';
import { BBSRepository } from './repository/BBSRepository';
import { GenshinRepository } from './repository/GenshinRepository';
import { StarRailRepository } from './repository/StarRailRepository';
import { ZZZRepository } from './repository/ZZZRepository';
import { SignRepository } from './repository/SignRepository';
import { SyncQueueRunner } from './repository/SyncQueueRunner';
import { AuthRepository } from './repository/AuthRepository';

interface CoreConfigV2 {
  isMock: boolean;
  context: common.UIAbilityContext;
}

export class CoreInitializer {
  private static initialized: boolean = false;
  private static isMockEnv: boolean = false;
  private static appContext: common.UIAbilityContext | null = null;
  private static readyResolve: (() => void) | null = null;
  private static readyPromise: Promise<void> = new Promise<void>((resolve) => {
    CoreInitializer.readyResolve = resolve;
  });

  // 单例 Repository 实例
  static readonly bbsRepository: BBSRepository = new BBSRepository();
  static readonly genshinRepository: GenshinRepository = new GenshinRepository();
  static readonly starRailRepository: StarRailRepository = new StarRailRepository();
  static readonly zzzRepository: ZZZRepository = new ZZZRepository();
  static readonly signRepository: SignRepository = new SignRepository();

  /**
   * 初始化核心库
   * 1. 初始化数据库（RdbManager）
   * 2. 根据 isMock 创建对应的 Service 实例（占位，待 MihoyoApiServiceFactory 创建后替换）
   * 3. 将 Service 注入到各 Repository
   */
  public static async initCore(config: CoreConfigV2): Promise<void> {
    if (CoreInitializer.initialized) {
      return;
    }

    CoreInitializer.isMockEnv = config.isMock;
    CoreInitializer.appContext = config.context;

    // 同步给 AuthRepository，让登录接口在 mock 环境下跳过真实网络请求
    AuthRepository.isMock = config.isMock;

    // 1. 初始化数据库
    await RdbManager.init(config.context);

    // 2. 预加载设备配置和 salt
    await ApiConfig.preloadDeviceId(config.context);
    await ApiConfig.preloadDeviceFp(config.context);
    await DSUtil.preloadSalts(config.context);

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

    // 5. 恢复未完成的同步任务（持久化队列）
    SyncQueueRunner.resumeOnStartup().catch((_: Error | object) => {});
  }

  public static waitForReady(): Promise<void> {
    return CoreInitializer.readyPromise;
  }

  public static isInitialized(): boolean {
    return CoreInitializer.initialized;
  }

  /** 获取是否为 Mock 环境（供旧版网络层使用） */
  public static getIsMock(): boolean {
    return CoreInitializer.isMockEnv;
  }

  /** 获取 UIAbilityContext（供旧版网络层使用） */
  public static getContext(): common.UIAbilityContext {
    if (CoreInitializer.appContext === null) {
      throw new Error('CoreInitializer: context not initialized, call initCore() first');
    }
    return CoreInitializer.appContext;
  }
}
