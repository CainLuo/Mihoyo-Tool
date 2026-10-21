import { common } from '@kit.AbilityKit';
import { RdbManager } from './database/RdbManager';
import { AppEnv } from './common/constants/AppEnv';
import { AppEnvManager } from './common/constants/AppEnvManager';
import { MihoyoApiServiceFactory } from './ApiServiceFactory';
import { ApiConfig } from './base/network/ApiConfig';
import { DSUtil } from './base/network/DSUtil';
import { BBSRepository } from './MihoyoKit/repository/BBSRepository';
import { GenshinRepository } from './GenshinKit/repository/GenshinRepository';
import { StarRailRepository } from './StarRailKit/repository/StarRailRepository';
import { ZZZRepository } from './ZZZKit/repository/ZZZRepository';
import { SignRepository } from './MihoyoKit/repository/SignRepository';
import { SyncQueueRunner } from './sync/SyncQueueRunner';
import { MaterialTargetConfigRepository } from './common/material/repository/MaterialTargetConfigRepository';
import { ApiLogSystem } from './base/log/ApiLogSystem';
import { LogEventType } from './base/log/ApiLogEntry';
import { Logger } from './base/utils/Logger';
import { ZZZRecordRequest } from './ZZZKit/api/ZZZRecordRequest';

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
  private static _materialTargetConfigRepository: MaterialTargetConfigRepository | null = null;

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

  static get materialTargetConfigRepository(): MaterialTargetConfigRepository {
    if (CoreInitializer._materialTargetConfigRepository === null) {
      CoreInitializer._materialTargetConfigRepository = new MaterialTargetConfigRepository();
    }
    return CoreInitializer._materialTargetConfigRepository;
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

    Logger.info('CoreInitializer', 'initCore called, env=' + config.env);
    AppEnvManager.setup(config.env);
    CoreInitializer.appContext = config.context;

    // 写入启动日志（此时 ApiLogSystem 尚未初始化，进入 pendingQueue）
    ApiLogSystem.getInstance().info(
      'CoreInitializer',
      'initCore started, env=' + config.env,
      LogEventType.LIFECYCLE,
    );

    // 1. 初始化数据库
    await RdbManager.init(config.context);

    // 2. 初始化日志系统（DB 之后，pendingQueue 中的日志批量写入）
    // 即使 DB 初始化失败，日志系统也应该独立初始化
    try {
      await ApiLogSystem.getInstance().init(config.context);
    } catch (logErr) {
      Logger.error('CoreInitializer', 'ApiLogSystem init failed: ' + String(logErr));
    }

    // 2. 预加载设备配置和 salt
    await ApiConfig.preloadDeviceId(config.context);
    await ApiConfig.preloadDeviceFp(config.context);
    await DSUtil.preloadSalts(config.context);
    // 绝区零战绩接口（ZZZ-Plugin 方式）：每个账号的设备指纹缓存
    ZZZRecordRequest.init(config.context, ApiConfig.getDeviceIdSync());

    // 3. 创建 Service 实例并注入到各 Repository
    const accountService = MihoyoApiServiceFactory.createAccountService();
    const genshinService = MihoyoApiServiceFactory.createGenshinService();
    const starRailService = MihoyoApiServiceFactory.createStarRailService();
    const zzzService = MihoyoApiServiceFactory.createZZZService();
    const signService = MihoyoApiServiceFactory.createSignService();

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
