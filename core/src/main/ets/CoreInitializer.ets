import { common } from '@kit.AbilityKit';
import { RdbManager } from './database/RdbManager';
import { NetworkFactory } from './network/NetworkFactory';

/**
 * 核心库配置接口
 */
interface CoreConfig {
  isMock: boolean;
  context: common.UIAbilityContext;
}

/**
 * 核心库初始化器
 * 在 EntryAbility.onCreate 中调用 initCore，向 core 模块注入全局配置
 */
export class CoreInitializer {
  private static isMock: boolean = false;
  private static initialized: boolean = false;
  private static appContext: common.UIAbilityContext | null = null;
  private static readyResolve: (() => void) | null = null;
  private static readyPromise: Promise<void> = new Promise<void>((resolve) => {
    CoreInitializer.readyResolve = resolve;
  });

  /**
   * 初始化核心库，必须在使用任何 core 能力前调用。
   */
  public static async initCore(config: CoreConfig): Promise<void> {
    CoreInitializer.isMock = config.isMock;
    CoreInitializer.appContext = config.context;
    CoreInitializer.initialized = true;

    NetworkFactory.reset();
    await RdbManager.init(config.context);

    if (CoreInitializer.readyResolve !== null) {
      CoreInitializer.readyResolve();
      CoreInitializer.readyResolve = null;
    }
  }

  public static waitForReady(): Promise<void> {
    return CoreInitializer.readyPromise;
  }

  public static getIsMock(): boolean {
    if (!CoreInitializer.initialized) {
      return false;
    }
    return CoreInitializer.isMock;
  }

  public static getContext(): common.UIAbilityContext {
    if (!CoreInitializer.initialized || CoreInitializer.appContext === null) {
      throw new Error('Core context is not initialized');
    }
    return CoreInitializer.appContext;
  }

  public static isInitialized(): boolean {
    return CoreInitializer.initialized;
  }
}
