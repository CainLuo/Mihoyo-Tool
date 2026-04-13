import { AppEnv } from './AppEnv';

/**
 * 应用环境管理器（全局单例）。
 *
 * 职责：持有当前运行环境，提供环境判断方法。
 * 初始化：由 CoreInitializer.initCore() 在启动时调用 AppEnvManager.setup(env)。
 *
 * 使用方：
 *   - core 层：Repository、Service、DAO 直接 import 使用
 *   - entry 层：通过 'core' 导出 import 使用
 *   - Logger：通过 AppEnvManager.getEnv() 获取环境标签，不持有判断逻辑
 */
export class AppEnvManager {
  private static currentEnv: AppEnv = AppEnv.DEBUG;

  /**
   * 由 CoreInitializer 在启动时调用，设置当前环境。
   * CoreInitializer 自身有 initialized 保护，实际只调用一次。
   */
  static setup(env: AppEnv): void {
    AppEnvManager.currentEnv = env;
  }

  /** 获取当前运行环境 */
  static getEnv(): AppEnv {
    return AppEnvManager.currentEnv;
  }

  /** 是否为 Mock 环境 */
  static isMock(): boolean {
    return AppEnvManager.currentEnv === AppEnv.MOCK;
  }

  /** 是否为 Debug 环境 */
  static isDebug(): boolean {
    return AppEnvManager.currentEnv === AppEnv.DEBUG;
  }

  /** 是否为 Release 环境 */
  static isRelease(): boolean {
    return AppEnvManager.currentEnv === AppEnv.RELEASE;
  }
}
