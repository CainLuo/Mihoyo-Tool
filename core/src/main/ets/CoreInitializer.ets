import { common } from '@kit.AbilityKit';
import { RdbManager } from './db/RdbManager';
import { SCHEMA_REGISTRY } from './SchemaRegistry';
import { AppEnv } from './common/constants/AppEnv';
import { AppEnvManager } from './common/constants/AppEnvManager';
import { ApiServiceFactory } from './ApiServiceFactory';
import { ApiConfig } from './base/network/ApiConfig';
import { DSUtil } from './base/network/DSUtil';
import { GeetestService } from './base/network/GeetestService';
import { MihoyoDomain } from './base/network/MihoyoDomain';
import { GameId } from './common/constants/GameId';
import { GenshinApiPath } from './GenshinKit/api/GenshinApiPath';
import { StarRailApiPath } from './StarRailKit/api/StarRailApiPath';
import { ZZZApiPath } from './ZZZKit/api/ZZZApiPath';
import { BBSRepository } from './MihoyoKit/repository/BBSRepository';
import { GenshinRepository } from './GenshinKit/repository/GenshinRepository';
import { StarRailRepository } from './StarRailKit/repository/StarRailRepository';
import { ZZZRepository } from './ZZZKit/repository/ZZZRepository';
import { SignRepository } from './MihoyoKit/repository/SignRepository';
import { SyncQueueRunner } from './sync/SyncQueueRunner';
import { SyncDependencies } from './sync/SyncPorts';
import { CookieRefreshCoordinator } from './MihoyoKit/cookie/CookieRefreshCoordinator';
import { MaterialTargetConfigRepository } from './common/material/repository/MaterialTargetConfigRepository';
import { ApiLogSystem } from './base/log/ApiLogSystem';
import { LogEventType } from './base/log/ApiLogEntry';
import { Logger } from './base/utils/Logger';
import { ZZZGeetestRecordHandler, ZZZRecordRequest } from './ZZZKit/api/ZZZRecordRequest';

export interface CoreConfig {
  env: AppEnv;
  context: common.UIAbilityContext;
}

export class CoreInitializer {
  private static initialized: boolean = false;
  private static appContext: common.UIAbilityContext | null = null;
  private static readyResolve: (() => void) | null = null;
  private static readyReject: ((reason: Error) => void) | null = null;
  private static readyPromise: Promise<void> = CoreInitializer.createReadyPromise();
  /** 进行中的初始化任务；重试时复用它，避免并发重复初始化 DB */
  private static initInFlight: Promise<void> | null = null;
  /** 初始化成功后的附加初始化（Widget 存储、通知服务等）；重试成功后同样执行 */
  private static readyHooks: Array<() => Promise<void>> = [];

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
  public static initCore(config: CoreConfig): Promise<void> {
    if (CoreInitializer.initialized) {
      return Promise.resolve();
    }
    if (CoreInitializer.initInFlight !== null) {
      return CoreInitializer.initInFlight;
    }
    const task = CoreInitializer.doInit(config);
    CoreInitializer.initInFlight = task;
    return task;
  }

  private static async doInit(config: CoreConfig): Promise<void> {
    // 重试时重建 readyPromise，否则 waitForReady() 会一直返回上一次失败的 Promise
    CoreInitializer.resetReady();

    try {
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
      await RdbManager.init(config.context, SCHEMA_REGISTRY);

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
      GeetestService.registerGame(GameId.GENSHIN, MihoyoDomain.TAKUMI_RECORD + GenshinApiPath.DAILY_NOTE, '2');
      GeetestService.registerGame(GameId.STARRAIL, MihoyoDomain.TAKUMI_RECORD + StarRailApiPath.DAILY_NOTE, '6');
      GeetestService.registerGame(GameId.ZZZ, MihoyoDomain.TAKUMI_RECORD + ZZZApiPath.DAILY_NOTE, '8');
      GeetestService.setRecordHandler(new ZZZGeetestRecordHandler());

      // 3. 创建 Service 实例并注入到各 Repository
      const accountService = ApiServiceFactory.createAccountService();
      const genshinService = ApiServiceFactory.createGenshinService();
      const starRailService = ApiServiceFactory.createStarRailService();
      const zzzService = ApiServiceFactory.createZZZService();
      const signService = ApiServiceFactory.createSignService();

      CoreInitializer.bbsRepository.setService(accountService);
      CookieRefreshCoordinator.init(CoreInitializer.bbsRepository);
      CoreInitializer.genshinRepository.setService(genshinService);
      CoreInitializer.starRailRepository.setService(starRailService);
      CoreInitializer.zzzRepository.setService(zzzService);
      CoreInitializer.signRepository.setService(signService);

      SyncQueueRunner.init(new SyncDependencies(
        CoreInitializer.bbsRepository,
        CoreInitializer.genshinRepository,
        CoreInitializer.starRailRepository,
        CoreInitializer.zzzRepository,
      ));

      CoreInitializer.initialized = true;
      CoreInitializer.initInFlight = null;
      CoreInitializer.resolveReady();

      // 附加初始化（Widget 存储 / 通知服务）不阻塞 ready，失败只记日志
      CoreInitializer.runReadyHooks();

      // 4. 恢复未完成的同步任务（持久化队列）
      SyncQueueRunner.resumeOnStartup().catch((_: Error | object) => {});
    } catch (error) {
      const err = error instanceof Error ? error : new Error(`${error}`);
      Logger.error('CoreInitializer', `initCore failed: ${err.message}`);
      CoreInitializer.initInFlight = null;
      CoreInitializer.rejectReady(err);
      throw err;
    }
  }

  private static createReadyPromise(): Promise<void> {
    const promise = new Promise<void>((resolve: () => void, reject: (reason: Error) => void) => {
      CoreInitializer.readyResolve = resolve;
      CoreInitializer.readyReject = reject;
    });
    // 隐私协议未同意时启动页不会等待 ready，这里兜住 reject 避免 unhandled rejection
    promise.catch((_e: Error) => {});
    return promise;
  }

  /** 重建 readyPromise（初始化重试时调用） */
  private static resetReady(): void {
    CoreInitializer.readyPromise = CoreInitializer.createReadyPromise();
  }

  private static resolveReady(): void {
    const resolve = CoreInitializer.readyResolve;
    CoreInitializer.readyResolve = null;
    CoreInitializer.readyReject = null;
    if (resolve !== null) {
      resolve();
    }
  }

  private static rejectReady(error: Error): void {
    const reject = CoreInitializer.readyReject;
    CoreInitializer.readyResolve = null;
    CoreInitializer.readyReject = null;
    if (reject !== null) {
      reject(error);
    }
  }

  /**
   * 注册初始化成功后的附加初始化任务（Widget 存储、通知服务等）。
   *
   * 必须早于 initCore 调用；任务只执行一次，启动页重试初始化成功后同样会执行。
   * 任务不阻塞 ready 通知，失败只记日志。
   */
  public static registerReadyHook(hook: () => Promise<void>): void {
    if (CoreInitializer.initialized) {
      hook().catch((error: Error | object) => {
        Logger.warning('CoreInitializer', `ready hook failed: ${String(error)}`);
      });
      return;
    }
    CoreInitializer.readyHooks.push(hook);
  }

  private static runReadyHooks(): void {
    const hooks = CoreInitializer.readyHooks;
    CoreInitializer.readyHooks = [];
    for (let i = 0; i < hooks.length; i++) {
      hooks[i]().catch((error: Error | object) => {
        Logger.warning('CoreInitializer', `ready hook failed: ${String(error)}`);
      });
    }
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
