import { common } from '@kit.AbilityKit';
import { RdbManager } from './database/RdbManager';
import { AccountRepository, GameRoleRow } from './repository/AccountRepository';
import { NetworkFactory } from './network/NetworkFactory';
import { GameDataDao } from './database/GameDataDao';
import { SyncMetaDao } from './database/SyncMetaDao';
import { DataType } from './models/GameDataRow';
import { CharacterRepository } from './repository/CharacterRepository';
import { DailyNoteRepository } from './repository/DailyNoteRepository';

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

    // 通知所有等待方：RDB 已就绪（seedMockData 已完成，数据已填充）
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
   * 每次 Mock 启动都清空角色数据并重新从 Mock JSON 填充，确保使用最新格式的 raw_json。
   */
  private static async seedMockData(): Promise<void> {
    try {
      const accounts = await AccountRepository.findAllAccounts();
      let accountId: number;

      if (accounts.length === 0) {
        // 首次启动：插入账号和角色记录
        accountId = await AccountRepository.insertAccount('182692936', 'mock_cookie');

        const genshinRole = new GameRoleRow();
        genshinRole.accountId = accountId;
        genshinRole.gameId = 'genshin';
        genshinRole.roleId = '109050292';
        genshinRole.nickname = '旅行者';
        genshinRole.level = 60;
        genshinRole.server = 'cn_gf01';

        const starrailRole = new GameRoleRow();
        starrailRole.accountId = accountId;
        starrailRole.gameId = 'starrail';
        starrailRole.roleId = '102731382';
        starrailRole.nickname = '开拓者';
        starrailRole.level = 70;
        starrailRole.server = 'prod_gf_cn';

        const zzzRole = new GameRoleRow();
        zzzRole.accountId = accountId;
        zzzRole.gameId = 'zzz';
        zzzRole.roleId = '10000001';
        zzzRole.nickname = '绳匠';
        zzzRole.level = 60;
        zzzRole.server = 'prod_gf_cn';

        await AccountRepository.replaceRoles(accountId, [genshinRole, starrailRole, zzzRole]);
        // 激活 Mock 账号，确保 findActiveAccount() 能找到它
        await AccountRepository.setActiveAccount(accountId);
      } else {
        accountId = accounts[0].id;
        // 确保已有账号处于激活状态（兼容旧数据）
        if (!accounts[0].isActive) {
          await AccountRepository.setActiveAccount(accountId);
        }
        // 每次启动都强制更新角色列表（确保新增游戏角色生效）
        const genshinRole2 = new GameRoleRow();
        genshinRole2.accountId = accountId;
        genshinRole2.gameId = 'genshin';
        genshinRole2.roleId = '109050292';
        genshinRole2.nickname = '旅行者';
        genshinRole2.level = 60;
        genshinRole2.server = 'cn_gf01';
        const starrailRole2 = new GameRoleRow();
        starrailRole2.accountId = accountId;
        starrailRole2.gameId = 'starrail';
        starrailRole2.roleId = '102731382';
        starrailRole2.nickname = '开拓者';
        starrailRole2.level = 70;
        starrailRole2.server = 'prod_gf_cn';
        const zzzRole2 = new GameRoleRow();
        zzzRole2.accountId = accountId;
        zzzRole2.gameId = 'zzz';
        zzzRole2.roleId = '10000001';
        zzzRole2.nickname = '绳匠';
        zzzRole2.level = 60;
        zzzRole2.server = 'prod_gf_cn';
        await AccountRepository.replaceRoles(accountId, [genshinRole2, starrailRole2, zzzRole2]);
      }

      // 每次 Mock 启动都清空并重新同步所有数据（确保 raw_json 格式最新）
      try {
        await GameDataDao.deleteByType('genshin', '109050292', DataType.CHARACTER);
        await SyncMetaDao.resetSyncTime('genshin', '109050292', DataType.CHARACTER);
        await GameDataDao.deleteByType('genshin', '109050292', DataType.DAILY_NOTE);
        await SyncMetaDao.resetSyncTime('genshin', '109050292', DataType.DAILY_NOTE);
        await GameDataDao.deleteByType('starrail', '102731382', DataType.DAILY_NOTE);
        await SyncMetaDao.resetSyncTime('starrail', '102731382', DataType.DAILY_NOTE);
        await GameDataDao.deleteByType('zzz', '10000001', DataType.DAILY_NOTE);
        await SyncMetaDao.resetSyncTime('zzz', '10000001', DataType.DAILY_NOTE);
      } catch (_) {}

      // 立即从 Mock JSON 填充原神角色数据
      try {
        await CharacterRepository.syncCharacters('genshin', '109050292', 'cn_gf01', 'mock_cookie');
      } catch (_) {}

      // 立即从 Mock JSON 填充原神便笺数据
      try {
        await DailyNoteRepository.syncDailyNote('genshin', '109050292', 'cn_gf01', 'mock_cookie');
      } catch (_) {}

      // 立即从 Mock JSON 填充崩铁便笺数据
      try {
        await DailyNoteRepository.syncDailyNote('starrail', '102731382', 'prod_gf_cn', 'mock_cookie');
      } catch (_) {}

      // 立即从 Mock JSON 填充绝区零便笺数据（如有角色）
      try {
        await DailyNoteRepository.syncDailyNote('zzz', '10000001', 'prod_gf_cn', 'mock_cookie');
      } catch (_) {}

    } catch (error) {
      const msg = error instanceof Error ? error.message : `${error}`;
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
