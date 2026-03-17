import { common } from '@kit.AbilityKit';

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

  /**
   * 初始化核心库，必须在使用任何 core 能力前调用
   */
  public static initCore(config: CoreConfig): void {
    CoreInitializer.isMock = config.isMock;
    CoreInitializer.appContext = config.context;
    CoreInitializer.initialized = true;
    console.info(`Core initialized. isMock=${CoreInitializer.isMock}`);
  }

  /**
   * 获取是否为 Mock 环境
   */
  public static getIsMock(): boolean {
    if (!CoreInitializer.initialized) {
      console.warn('Core library not initialized, using default isMock: false');
      return false;
    }
    return CoreInitializer.isMock;
  }

  /**
   * 获取应用上下文，未初始化时抛出异常
   */
  public static getContext(): common.UIAbilityContext {
    if (!CoreInitializer.initialized || CoreInitializer.appContext === null) {
      throw new Error('Core context is not initialized');
    }
    return CoreInitializer.appContext;
  }

  /**
   * 检查是否已初始化
   */
  public static isInitialized(): boolean {
    return CoreInitializer.initialized;
  }
}
