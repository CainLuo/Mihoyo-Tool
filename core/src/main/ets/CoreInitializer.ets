import { common } from '@kit.AbilityKit';
import { RdbManager } from './database/RdbManager';
import { AccountRepository, GameRoleRow } from './repository/AccountRepository';
import { NetworkFactory } from './network/NetworkFactory';
import { GameDataDao } from './database/GameDataDao';
import { SyncMetaDao } from './database/SyncMetaDao';
import { DataType } from './models/GameDataRow';

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
  // 就绪 Promise，供 ViewModel 等待 RDB 初始化完成
  private static readyResolve: (() => void) | null = null;
  private static readyPromise: Promise<void> = new Promise<void>((resolve) => {
    CoreInitializer.readyResolve = resolve;
  });

  /**
   * 初始化核心库，必须在使用任何 core 能力前调用。
   * 内部会完成：RDB 初始化 + Mock 模式下预填充测试数据。
   */
  public static async initCore(config: CoreConfig): Promise<void> {
    CoreInitializer.isMock = config.isMock;
    CoreInitializer.appContext = config.context;
    CoreInitializer.initialized = true;

    // isMock 已确定，重置 NetworkFactory 单例，确保下次 getInstance() 用正确的实现
    NetworkFactory.reset();

    // 初始化数据库（幂等，已初始化则直接返回）
    await RdbManager.init(config.context);

    // Mock 模式下预填充测试账号和角色数据
    if (config.isMock) {
      await CoreInitializer.seedMockData();
    }

    // 通知所有等待方：RDB 已就绪
    if (CoreInitializer.readyResolve !== null) {
      CoreInitializer.readyResolve();
      CoreInitializer.readyResolve = null;
    }
  }

  /**
   * 等待核心库（含 RDB）初始化完成。
   * ViewModel 在 loadData() 开头调用，避免 RDB 未就绪时查询报错。
   */
  public static waitForReady(): Promise<void> {
    return CoreInitializer.readyPromise;
  }

  /**
   * 预填充 Mock 测试数据。
   * 每次 Mock 启动都清空角色数据并重置同步时间，确保使用最新格式的 raw_json。
   */
  private static async seedMockData(): Promise<void> {
    try {
      // 每次 Mock 启动都清空角色数据，强制重新同步（确保 raw_json 格式最新）
      try {
        await GameDataDao.deleteByType('genshin', '109050292', DataType.CHARACTER);
        await SyncMetaDao.resetSyncTime('genshin', '109050292', DataType.CHARACTER);
      } catch (_) {}

      const accounts = await AccountRepository.findAllAccounts();
      // 已有账号则跳过账号/角色插入
      if (accounts.length > 0) {
        return;
      }

      // 插入米游社账号（UID 作为 username）
      const accountId = await AccountRepository.insertAccount('182692936', 'mock_cookie');

      // 插入原神角色
      const genshinRole = new GameRoleRow();
      genshinRole.accountId = accountId;
      genshinRole.gameId = 'genshin';
      genshinRole.roleId = '109050292';
      genshinRole.nickname = '旅行者';
      genshinRole.level = 60;
      genshinRole.server = 'cn_gf01';

      // 插入星穹铁道角色
      const starrailRole = new GameRoleRow();
      starrailRole.accountId = accountId;
      starrailRole.gameId = 'starrail';
      starrailRole.roleId = '102731382';
      starrailRole.nickname = '开拓者';
      starrailRole.level = 70;
      starrailRole.server = 'prod_gf_cn';

      const roles: GameRoleRow[] = [genshinRole, starrailRole];
      await AccountRepository.replaceRoles(accountId, roles);
    } catch (error) {
      const msg = error instanceof Error ? error.message : `${error}`;
      // Mock 数据预填充失败不影响主流程，仅记录
      console.warn(`CoreInitializer.seedMockData failed: ${msg}`);
    }
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
