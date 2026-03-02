import common from '@ohos.app.ability.common';

/**
 * 核心库配置接口
 */
interface CoreConfig {
  isMock: boolean;
  context: common.UIAbilityContext;
}

/**
 * 核心库初始化器
 * 用于接收和管理全局配置
 */
export class CoreInitializer {
  private static isMock: boolean = false;
  private static initialized: boolean = false;
  private static appContext: common.UIAbilityContext | null = null;

  /**
   * 初始化核心库
   * @param config 配置对象
   */
  public static initCore(config: CoreConfig): void {
    CoreInitializer.isMock = config.isMock;
    CoreInitializer.appContext = config.context;
    CoreInitializer.initialized = true;
    console.info(`Core initialized. isMock=${CoreInitializer.isMock}`);
  }

  /**
   * 获取是否为 Mock 环境
   * @returns 是否为 Mock 环境
   */
  public static getIsMock(): boolean {
    if (!CoreInitializer.initialized) {
      console.warn('Core library not initialized, using default isMock: false');
      return false;
    }
    return CoreInitializer.isMock;
  }

  /**
   * 获取应用上下文
   */
  public static getContext(): common.UIAbilityContext {
    if (!CoreInitializer.initialized || CoreInitializer.appContext === null) {
      throw new Error('Core context is not initialized');
    }
    return CoreInitializer.appContext;
  }

  /**
   * 检查是否已初始化
   * @returns 是否已初始化
   */
  public static isInitialized(): boolean {
    return CoreInitializer.initialized;
  }
}
