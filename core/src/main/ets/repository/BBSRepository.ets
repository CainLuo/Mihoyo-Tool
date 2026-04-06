// 注意：MihoyoAccountApiService 尚未创建（在 mihoyo-api-redesign spec 中定义）。
// 当前使用 MihoyoApiService 抽象基类作为 service 类型占位。
// 待 MihoyoAccountApiService 创建后，将此处类型替换为 MihoyoAccountApiService。
import { MihoyoApiService } from '../network/MihoyoApiService';
import { AccountDao, GameRoleDao } from '../database/BBSDao';
import { AccountRow } from '../models/AccountRow';
import { GameRoleRow } from '../models/GameRoleRow';

export class BBSRepository {
  // TODO: 待 MihoyoAccountApiService 创建后，将类型替换为 MihoyoAccountApiService
  private service: MihoyoApiService | null = null;
  private accountDao: AccountDao = new AccountDao();
  private gameRoleDao: GameRoleDao = new GameRoleDao();

  // TODO: 待 MihoyoAccountApiService 创建后，将参数类型替换为 MihoyoAccountApiService
  setService(service: MihoyoApiService): void {
    this.service = service;
  }

  private getService(): MihoyoApiService {
    if (this.service === null) {
      throw new Error('BBSRepository: service not initialized');
    }
    return this.service;
  }

  private toErrorMessage(error: Error | object): string {
    if (error instanceof Error) {
      return error.message;
    }
    return `${error}`;
  }

  // ── 账号操作 ──────────────────────────────────────────────────

  /** 保存账号（登录时调用） */
  async saveAccount(row: AccountRow): Promise<void> {
    await this.accountDao.upsert(row);
  }

  /** 查询所有账号 */
  async getAllAccounts(): Promise<AccountRow[]> {
    return this.accountDao.findAll();
  }

  /** 按 id 查询账号 */
  async getAccountById(id: number): Promise<AccountRow | null> {
    return this.accountDao.findById(id);
  }

  /** 按 username 查询账号 */
  async getAccountByUsername(username: string): Promise<AccountRow | null> {
    return this.accountDao.findByUsername(username);
  }

  /** 删除账号 */
  async deleteAccount(id: number): Promise<void> {
    await this.accountDao.deleteById(id);
  }

  // ── 游戏角色操作 ──────────────────────────────────────────────

  /** 查询账号下所有游戏角色 */
  async getGameRoles(accountId: number): Promise<GameRoleRow[]> {
    return this.gameRoleDao.findByAccountId(accountId);
  }

  /** 查询账号下指定游戏的角色 */
  async getGameRolesByGame(accountId: number, gameId: string): Promise<GameRoleRow[]> {
    return this.gameRoleDao.findByAccountAndGame(accountId, gameId);
  }

  /** 批量保存游戏角色 */
  async saveGameRoles(rows: GameRoleRow[]): Promise<void> {
    await this.gameRoleDao.upsertAll(rows);
  }

  /** 删除账号下所有游戏角色 */
  async deleteGameRoles(accountId: number): Promise<void> {
    await this.gameRoleDao.deleteByAccountId(accountId);
  }

  // ── 网络请求 ──────────────────────────────────────────────────
  // 以下方法在 MihoyoAccountApiService 创建后，需将 getService() 返回值强转为具体类型后调用对应方法。
  // 当前 MihoyoApiService 抽象基类未定义这些方法，调用时会在运行时由具体子类实现。

  /** 刷新游戏角色列表（从网络获取并保存到 DB） */
  async refreshGameRoles(accountId: number, cookie: string): Promise<GameRoleRow[]> {
    try {
      // TODO: 待 MihoyoAccountApiService 创建后，调用 this.getService().getGameRoles(cookie)
      // 解析响应，构建 GameRoleRowV2 列表
      // 注意：实际解析逻辑在 ViewModel 层或 Parser 层，这里返回原始响应供上层处理
      // 此处仅作为网络调用的封装
      return [];
    } catch (e) {
      throw new Error(`BBSRepository.refreshGameRoles failed: ${this.toErrorMessage(e instanceof Error ? e : new Error(String(e)))}`);
    }
  }

  /** 获取用户完整信息 */
  async getUserFullInfo(uid: string, cookie: string): Promise<object> {
    // TODO: 待 MihoyoAccountApiService 创建后，调用 this.getService().getUserFullInfo(uid, cookie)
    throw new Error(`BBSRepository.getUserFullInfo: not implemented yet, uid=${uid}`);
  }

  /** 获取游戏战绩卡片 */
  async getGameRecordCard(uid: string, cookie: string): Promise<object> {
    // TODO: 待 MihoyoAccountApiService 创建后，调用 this.getService().getGameRecordCard(uid, cookie)
    throw new Error(`BBSRepository.getGameRecordCard: not implemented yet, uid=${uid}`);
  }

  /** 申请 Geetest 验证 */
  async createVerification(cookie: string): Promise<object> {
    // TODO: 待 MihoyoAccountApiService 创建后，调用 this.getService().createVerification(cookie)
    throw new Error(`BBSRepository.createVerification: not implemented yet`);
  }

  /** 提交 Geetest 验证结果 */
  async verifyVerification(input: object, cookie: string): Promise<object> {
    // TODO: 待 MihoyoAccountApiService 创建后，调用 this.getService().verifyVerification(input, cookie)
    throw new Error(`BBSRepository.verifyVerification: not implemented yet`);
  }

  /** 刷新 cookie_token */
  async refreshCookieToken(stoken: string, stuid: string): Promise<object> {
    // TODO: 待 MihoyoAccountApiService 创建后，调用 this.getService().refreshCookieToken(stoken, stuid)
    throw new Error(`BBSRepository.refreshCookieToken: not implemented yet, stuid=${stuid}`);
  }

  /** 刷新 ltoken */
  async refreshLToken(stoken: string, stuid: string): Promise<object> {
    // TODO: 待 MihoyoAccountApiService 创建后，调用 this.getService().refreshLToken(stoken, stuid)
    throw new Error(`BBSRepository.refreshLToken: not implemented yet, stuid=${stuid}`);
  }

  /** 验证 ltoken 有效性 */
  async verifyLToken(ltoken: string, ltuid: string): Promise<object> {
    // TODO: 待 MihoyoAccountApiService 创建后，调用 this.getService().verifyLToken(ltoken, ltuid)
    throw new Error(`BBSRepository.verifyLToken: not implemented yet, ltuid=${ltuid}`);
  }
}
