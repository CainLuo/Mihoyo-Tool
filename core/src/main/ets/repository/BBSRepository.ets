import { MihoyoApiService } from '../network/MihoyoApiService';
import { AccountDao, GameRoleDao } from '../database/BBSDao';
import { AccountRow } from '../models/AccountRow';
import { GameRoleRow } from '../models/GameRoleRow';
import { AuthRepository } from './AuthRepository';
import { CoreInitializer } from '../CoreInitializer';

/** login() 方法的返回值，供 entry 层组装 AccountVM */
export class LoginResult {
  accountId: number = 0;
  username: string = '';
  nickname: string = '';
  avatarUrl: string = '';
  roles: GameRoleRow[] = [];
}

export class BBSRepository {
  private service: MihoyoApiService | null = null;
  private accountDao: AccountDao = new AccountDao();
  private gameRoleDao: GameRoleDao = new GameRoleDao();

  setService(service: MihoyoApiService): void {
    this.service = service;
  }

  private toErrorMessage(error: Error | object): string {
    return error instanceof Error ? error.message : `${error}`;
  }

  // ── 登录 ──────────────────────────────────────────────────────

  /**
   * 完整登录流程：写账号 → 拉游戏角色 → 补充详情 → 返回结果。
   * entry 层只需调用此方法，不接触任何 DB 操作和环境判断。
   *
   * mock 环境下，core 内部自动将 username/cookie 替换为 mockIdx，
   * 确保 MockService 能路由到正确的 account1/ 或 account2/ 目录。
   */
  async login(username: string, cookie: string): Promise<LoginResult> {
    // mock 环境：username 和 cookie 里的 account_id 统一使用 mockIdx，保证一致性
    // 此逻辑由 core 内部处理，entry 层不感知环境
    let effectiveCookie = cookie;
    let effectiveUsername = username;
    if (CoreInitializer.getIsMock()) {
      const allAccounts = await this.accountDao.findAll();
      const mockIdx = (allAccounts.length % 2) + 1;
      effectiveCookie = `account_id=${mockIdx}; cookie_token=mock_token; ltoken=mock_ltoken; ltuid=${mockIdx}`;
      effectiveUsername = `${mockIdx}`;
    }

    // 1. 写入账号（INSERT OR IGNORE + UPDATE，不触发 CASCADE）
    const accountId = await this.upsertOrUpdateAccount(effectiveUsername, effectiveCookie);

    // 2. 拉取游戏角色并写入
    try {
      const roles = await AuthRepository.getUserGameRoles(effectiveCookie);
      if (roles.length > 0) {
        try {
          const uid = BBSRepository.extractCookieField(effectiveCookie, 'account_id') || effectiveUsername;
          const detailRoles = await AuthRepository.getGameRecordCard(effectiveCookie, uid);
          for (let i = 0; i < roles.length; i++) {
            for (let j = 0; j < detailRoles.length; j++) {
              if (detailRoles[j].gameId === roles[i].gameId &&
                  detailRoles[j].roleId === roles[i].roleId) {
                roles[i].bgImageUrl = detailRoles[j].bgImageUrl;
                roles[i].statsJson = detailRoles[j].statsJson;
                break;
              }
            }
          }
        } catch (_) {}
        const roleRows: GameRoleRow[] = [];
        for (let i = 0; i < roles.length; i++) {
          const r = roles[i];
          const row = new GameRoleRow();
          row.id = 0;
          row.accountId = accountId;
          row.gameId = r.gameId;
          row.roleId = r.roleId;
          row.nickname = r.nickname;
          row.level = r.level;
          row.server = r.server;
          row.bgImageUrl = r.bgImageUrl;
          row.statsJson = r.statsJson;
          roleRows[roleRows.length] = row;
        }
        await this.gameRoleDao.upsertAll(roleRows);
      }
    } catch (_) {}

    // 3. 补充 BBS 账号详情（nickname、avatarUrl）
    let nickname = '';
    let avatarUrl = '';
    try {
      const bbsDetail = await AuthRepository.getBbsAccountDetail(effectiveCookie);
      if (bbsDetail.nickname || bbsDetail.avatarUrl) {
        nickname = bbsDetail.nickname;
        avatarUrl = bbsDetail.avatarUrl;
        const latestRow = await this.accountDao.findById(accountId);
        if (latestRow !== null) {
          latestRow.nickname = nickname;
          latestRow.avatarUrl = avatarUrl;
          await this.accountDao.upsert(latestRow);
        }
      }
    } catch (_) {}

    // 4. 返回结果
    const result = new LoginResult();
    result.accountId = accountId;
    result.username = effectiveUsername;
    result.nickname = nickname;
    result.avatarUrl = avatarUrl;
    result.roles = await this.gameRoleDao.findByAccountId(accountId);
    return result;
  }

  // ── 账号操作 ──────────────────────────────────────────────────

  /** 保存账号（更新已有账号的字段，如 nickname/avatarUrl） */
  async saveAccount(row: AccountRow): Promise<void> {
    await this.accountDao.upsert(row);
  }

  /**
   * 登录时写入账号：INSERT OR IGNORE + UPDATE cookie，不触发 CASCADE。
   * @returns 写入后的账号数据库 id
   */
  async upsertOrUpdateAccount(username: string, cookie: string): Promise<number> {
    const now = Math.floor(Date.now() / 1000);
    await this.accountDao.insertOrIgnore(username, cookie, now);
    await this.accountDao.updateCookie(username, cookie, now);
    const saved = await this.accountDao.findByUsername(username);
    return saved !== null ? saved.id : 0;
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

  /** 删除账号下所有游戏角色 */
  async deleteGameRoles(accountId: number): Promise<void> {
    await this.gameRoleDao.deleteByAccountId(accountId);
  }

  // ── 工具方法 ─────────────────────────────────────────────────

  private static extractCookieField(cookie: string, field: string): string {
    const parts = cookie.split(';');
    for (let i = 0; i < parts.length; i++) {
      const trimmed = parts[i].trim();
      const prefix = field + '=';
      if (trimmed.startsWith(prefix)) {
        return trimmed.substring(prefix.length).trim();
      }
    }
    return '';
  }
}
