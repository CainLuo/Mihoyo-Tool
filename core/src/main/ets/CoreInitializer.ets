
/**
 * 核心库配置接口
 */
interface CoreConfig {
  isMock: boolean;
}

/**
 * 核心库初始化器
 * 用于接收和管理全局配置
 */
export class CoreInitializer {
  private static isMock: boolean = false;
  private static initialized: boolean = false;
  /**
   * 初始化核心库
   * @param config 配置对象
   */
  public static initCore(config: CoreConfig): void {
    CoreInitializer.isMock = config.isMock;
    CoreInitializer.initialized = true;
    console.log(`Core library initialized with isMock: ${CoreInitializer.isMock}`);
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
   * 检查是否已初始化
   * @returns 是否已初始化
   */
  public static isInitialized(): boolean {
    return CoreInitializer.initialized;
  }
}
