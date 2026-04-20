import { MihoyoApiService } from '../network/MihoyoApiService';
import { MihoyoAccountApiService } from '../network/MihoyoAccountApiService';
import { AccountDao, GameRoleDao } from '../database/BBSDao';
import { RdbManager } from '../database/RdbManager';
import { AppEnvManager } from '../constants/AppEnvManager';
import { AccountRow } from '../models/AccountRow';
import { GameRoleRow } from '../models/GameRoleRow';
import { AuthRepository } from './AuthRepository';
import { SyncQueueRunner } from './SyncQueueRunner';
import { NetworkFactory } from '../network/NetworkFactory';
import { RequestParams, RequestOptions } from '../network/APIs';
import { GameId } from '../constants/GameId';
import { gameBizToGameId } from '../constants/GameServer';
import { MihoyoDomain } from '../network/MihoyoDomain';
import { HKey } from '../network/MihoyoHeaderKey';
import { MihoyoAccountApiPath } from '../network/MihoyoAccountApiPath';
import {
  BbsAccountDetailResult,
  BbsAccountDetailResponse,
} from '../models/BbsAccountModels';
import {
  GameRoleRecord,
  GameRolesResponse,
  GameRecordCardResponse,
} from '../models/GameRoleModels';
import { ApiLogSystem } from '../log/ApiLogSystem';
import { LogEventType } from '../log/ApiLogEntry';
import { AuthExpiredError, GeetestRequiredError, GeetestSignRequiredError } from '../errors/ApiErrors';

export {
  GameRoleRecord,
  RoleStatItem,
} from '../models/GameRoleModels';
export {
  BbsAccountDetailResult,
} from '../models/BbsAccountModels';
export {
  GameRoleApiInfo,
  GameRolesResponse,
} from '../models/GameRoleModels';

/** login() 方法的返回值，供 entry 层组装 AccountVM */
export class LoginResult {
  accountId: string = '';
  username: string = '';
  uid: string = '';
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
    // 同步给 AuthRepository，让登录接口走同一个 service（mock/release 统一）
    if (service instanceof MihoyoAccountApiService) {
      AuthRepository.accountService = service;
    }
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
    // entry 层传入的 username 和 cookie 直接使用，core 不做任何替换
    const effectiveCookie = cookie;
    const effectiveUsername = username;

    // 1. 写入账号（INSERT OR IGNORE + UPDATE，不触发 CASCADE）
    await this.upsertOrUpdateAccount(effectiveUsername, effectiveCookie);
    // username 就是 Cookie 里的 account_id（米游社 UID），直接用作 accountId
    const accountId = effectiveUsername;

    // 2. 拉取游戏角色并写入
    // 策略：以 getGameRecordCard 为主数据源（roleId 更准确，含 bgImageUrl/statsJson）
    // getUserGameRolesByCookie 作为补充（包含 getGameRecordCard 没有的角色）
    try {
      const uid = BBSRepository.extractCookieField(effectiveCookie, 'account_id') || effectiveUsername;
      let finalRoles: GameRoleRecord[] = [];

      // 优先尝试 getGameRecordCard
      try {
        const detailRoles = await this.getGameRecordCard(effectiveCookie, uid);
        if (detailRoles.length > 0) {
          finalRoles = detailRoles;
        }
      } catch (_) {}

      // 如果 getGameRecordCard 失败或返回空，回退到 getUserGameRolesByCookie
      if (finalRoles.length === 0) {
        try {
          const bindingRoles = await this.getUserGameRoles(effectiveCookie);
          finalRoles = bindingRoles;
        } catch (_) {}
      } else {
        // getGameRecordCard 成功，用 getUserGameRolesByCookie 补充 getGameRecordCard 没有的角色
        try {
          const bindingRoles = await this.getUserGameRoles(effectiveCookie);
          for (let i = 0; i < bindingRoles.length; i++) {
            let found = false;
            for (let j = 0; j < finalRoles.length; j++) {
              if (finalRoles[j].gameId === bindingRoles[i].gameId &&
                  finalRoles[j].roleId === bindingRoles[i].roleId) {
                found = true;
                break;
              }
            }
            if (!found) {
              finalRoles[finalRoles.length] = bindingRoles[i];
            }
          }
        } catch (_) {}
      }

      if (finalRoles.length > 0) {
        const roleRows: GameRoleRow[] = [];
        for (let i = 0; i < finalRoles.length; i++) {
          const r = finalRoles[i];
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

    // 3. 补充 BBS 账号详情（nickname、avatarUrl、uid）
    let nickname = '';
    let avatarUrl = '';
    let uid = '';
    try {
      const bbsDetail = await this.getBbsAccountDetail(effectiveCookie);
      if (bbsDetail.nickname || bbsDetail.avatarUrl || bbsDetail.uid) {
        nickname = bbsDetail.nickname;
        avatarUrl = bbsDetail.avatarUrl;
        uid = bbsDetail.uid;
        const latestRow = await this.accountDao.findByUsername(effectiveUsername);
        if (latestRow !== null) {
          latestRow.nickname = nickname;
          latestRow.avatarUrl = avatarUrl;
          latestRow.uid = uid;
          latestRow.rawJson = bbsDetail.rawJson;
          await this.accountDao.upsert(latestRow);
        }
      }
    } catch (_) {}

    // 4. 返回结果
    const finalUid = uid !== '' ? uid : accountId;
    // 重新从 DB 读取最新账号数据，确保 nickname/avatarUrl 是 step 3 写入后的最新值
    const latestAccount = await this.accountDao.findByUsername(effectiveUsername);
    const result = new LoginResult();
    result.accountId = finalUid;
    result.username = effectiveUsername;
    result.uid = finalUid;
    result.nickname = latestAccount?.nickname ?? nickname;
    result.avatarUrl = latestAccount?.avatarUrl ?? avatarUrl;
    result.roles = await this.getGameRoles(finalUid);

    // 5. 后台异步同步各游戏角色列表和详情（持久化队列，防止 App 被杀后丢失）
    const tasks = SyncQueueRunner.buildTasksForRoles(finalUid, result.roles, effectiveCookie);
    SyncQueueRunner.enqueue(tasks)
      .then(() => SyncQueueRunner.runTasks(tasks))
      .catch((_: Error | object) => {});

    return result;
  }

  // ── 账号操作 ──────────────────────────────────────────────────

  /** 保存账号（更新已有账号的字段，如 nickname/avatarUrl） */
  async saveAccount(row: AccountRow): Promise<void> {
    await this.accountDao.upsert(row);
  }

  /**
   * 登录时写入账号：INSERT OR IGNORE + UPDATE cookie，不触发 CASCADE。
   * @returns 写入后的账号 uid（米游社 UID，string）
   */
  async upsertOrUpdateAccount(username: string, cookie: string): Promise<string> {
    const now = Math.floor(Date.now() / 1000);
    await this.accountDao.insertOrIgnore(username, cookie, now);
    await this.accountDao.updateCookie(username, cookie, now);
    const saved = await this.accountDao.findByUsername(username);
    return saved !== null ? saved.uid : '';
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

  /** 按 uid 查询账号（米游社 UID） */
  async getAccountByUid(uid: string): Promise<AccountRow | null> {
    return this.accountDao.findByUid(uid);
  }

  /** 删除账号（按米游社 UID） */
  async deleteAccount(uid: string): Promise<void> {
    const row = await this.accountDao.findByUid(uid);
    if (row !== null) {
      await this.accountDao.deleteById(row.id);
    }
  }

  // ── 游戏角色操作 ──────────────────────────────────────────────

  /** 查询账号下所有游戏角色（只返回当前支持的游戏） */
  async getGameRoles(accountId: string): Promise<GameRoleRow[]> {
    const all = await this.gameRoleDao.findByAccountId(accountId);
    const supported: GameRoleRow[] = [];
    for (let i = 0; i < all.length; i++) {
      if (GameId.isSupported(all[i].gameId)) {
        supported[supported.length] = all[i];
      }
    }
    return supported;
  }

  /** 查询账号下指定游戏的角色 */
  async getGameRolesByGame(accountId: string, gameId: string): Promise<GameRoleRow[]> {
    return this.gameRoleDao.findByAccountAndGame(accountId, gameId);
  }

  /** 删除账号下所有游戏角色 */
  async deleteGameRoles(accountId: string): Promise<void> {
    await this.gameRoleDao.deleteByAccountId(accountId);
  }

  // ── 工具方法 ─────────────────────────────────────────────────

  static extractCookieField(cookie: string, field: string): string {
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

  /**
   * 从完整 Cookie 中构造 Widget API 所需的 Cookie 格式：stuid=xxx;stoken=v2_xxx;mid=xxx
   *
   * Widget API 需要 stoken（v2_ 格式），优先从以下字段提取：
   * 1. stoken（手机号/二维码登录后有此字段）
   * 2. ltoken_v2（Cookie 登录用户，ltoken_v2 与 stoken 格式相同，均为 v2_ 开头）
   *
   * stuid 优先从 stuid 字段提取，其次用 account_id / ltuid_v2 / ltuid
   * mid 优先从 mid 字段提取，其次用 account_mid_v2 / ltmid_v2
   *
   * 返回空字符串表示无法构造（Cookie 中既无 stoken 也无 ltoken_v2）
   */
  static buildWidgetCookie(cookie: string): string {
    // 提取 stoken（优先）或 ltoken_v2（降级）
    let stoken = BBSRepository.extractCookieField(cookie, 'stoken');
    if (stoken.length === 0) {
      stoken = BBSRepository.extractCookieField(cookie, 'ltoken_v2');
    }
    if (stoken.length === 0) {
      return '';
    }

    // 提取 stuid（优先）或 account_id / ltuid_v2 / ltuid
    let stuid = BBSRepository.extractCookieField(cookie, 'stuid');
    if (stuid.length === 0) {
      stuid = BBSRepository.extractCookieField(cookie, 'account_id');
    }
    if (stuid.length === 0) {
      stuid = BBSRepository.extractCookieField(cookie, 'ltuid_v2');
    }
    if (stuid.length === 0) {
      stuid = BBSRepository.extractCookieField(cookie, 'ltuid');
    }

    // 提取 mid（优先）或 account_mid_v2 / ltmid_v2
    let mid = BBSRepository.extractCookieField(cookie, 'mid');
    if (mid.length === 0) {
      mid = BBSRepository.extractCookieField(cookie, 'account_mid_v2');
    }
    if (mid.length === 0) {
      mid = BBSRepository.extractCookieField(cookie, 'ltmid_v2');
    }

    if (stuid.length === 0 || mid.length === 0) {
      return '';
    }

    return `stuid=${stuid};stoken=${stoken};mid=${mid}`;
  }

  /**
   * 替换 cookie 字符串里某个字段的值，字段不存在时追加到末尾。
   */
  static replaceCookieField(cookie: string, field: string, newValue: string): string {
    const parts = cookie.split(';');
    let found = false;
    const result: string[] = [];
    for (let i = 0; i < parts.length; i++) {
      const trimmed = parts[i].trim();
      const prefix = field + '=';
      if (trimmed.startsWith(prefix)) {
        result[result.length] = ' ' + field + '=' + newValue;
        found = true;
      } else {
        result[result.length] = parts[i];
      }
    }
    if (!found) {
      result[result.length] = ' ' + field + '=' + newValue;
    }
    return result.join(';');
  }

  // ── 测试工具（仅 Mock 环境使用）─────────────────────────────────

  /**
   * 将所有账号的 update_time 设置为 8 天前，并确保 cookie 里有 stoken，
   * 用于手动触发冷启动刷新测试（T1 场景）。
   * 仅供 Mock 环境的测试入口调用，禁止在业务逻辑中使用。
   */
  async setAllUpdateTimeTo8DaysAgo(): Promise<void> {
    const eightDaysAgo = Math.floor(Date.now() / 1000) - 8 * 24 * 3600;
    const accounts = await this.accountDao.findAll();
    for (let i = 0; i < accounts.length; i++) {
      // 确保 cookie 里有 stoken，否则 ColdStartCookieChecker 会静默跳过
      let cookie = accounts[i].cookie;
      const existingStoken = BBSRepository.extractCookieField(cookie, 'stoken');
      if (existingStoken.length === 0) {
        cookie = cookie + '; stoken=mock_stoken_for_testing';
      }
      await RdbManager.executeSql(
        `UPDATE account_table SET update_time = ?, cookie = ? WHERE username = ?`,
        [eightDaysAgo, cookie, accounts[i].username]
      );
    }
  }

  /**
   * 将所有账号的 cookie 替换为不含 stoken 的版本，用于测试 T3 场景（静默跳过）。
   * 仅供 Mock 环境的测试入口调用，禁止在业务逻辑中使用。
   */
  async setAllCookieWithoutStoken(): Promise<void> {
    const eightDaysAgo = Math.floor(Date.now() / 1000) - 8 * 24 * 3600;
    const accounts = await this.accountDao.findAll();
    for (let i = 0; i < accounts.length; i++) {
      // 移除 stoken 字段
      const parts = accounts[i].cookie.split(';');
      const filtered: string[] = [];
      for (let j = 0; j < parts.length; j++) {
        const trimmed = parts[j].trim();
        if (!trimmed.startsWith('stoken=')) {
          filtered[filtered.length] = parts[j];
        }
      }
      const newCookie = filtered.join(';');
      await RdbManager.executeSql(
        `UPDATE account_table SET update_time = ?, cookie = ? WHERE username = ?`,
        [eightDaysAgo, newCookie, accounts[i].username]
      );
    }
  }

  // ── Cookie 刷新 ───────────────────────────────────────────────

  /**
   * 当 API 返回 retcode=-100（Cookie 过期）时，尝试用 stoken 刷新 ltoken 和 cookie_token。
   *
   * 刷新成功：更新 DB 中的 cookie 字段，返回新 cookie 字符串。
   * 无 stoken：抛出 AuthExpiredError，调用方提示用户重新登录。
   * 刷新失败：抛出 AuthExpiredError。
   *
   * @param username 账号 username（用于查找和更新 DB）
   * @param cookie   当前 cookie 字符串
   * @returns 刷新后的新 cookie 字符串
   */
  async refreshCookieIfNeeded(username: string, cookie: string): Promise<string> {
    // Mock 环境：直接模拟刷新成功，更新 update_time，不发真实网络请求
    if (AppEnvManager.isMock()) {
      const now = Math.floor(Date.now() / 1000);
      await this.accountDao.updateCookie(username, cookie, now);
      return cookie;
    }

    const stoken = BBSRepository.extractCookieField(cookie, 'stoken');
    const mid = BBSRepository.extractCookieField(cookie, 'mid');

    if (stoken.length === 0) {
      throw new AuthExpiredError('Cookie expired and no stoken available, please re-login');
    }

    try {
      const ltoken = await AuthRepository.getLTokenBySToken(stoken, mid);
      const cookieToken = await AuthRepository.getCookieBySToken(stoken, mid);

      // 替换 cookie 字符串里的 ltoken 和 cookie_token
      let newCookie = BBSRepository.replaceCookieField(cookie, 'ltoken', ltoken);
      newCookie = BBSRepository.replaceCookieField(newCookie, 'ltoken_v2', ltoken);
      newCookie = BBSRepository.replaceCookieField(newCookie, 'cookie_token', cookieToken);
      newCookie = BBSRepository.replaceCookieField(newCookie, 'cookie_token_v2', cookieToken);

      // 写入 DB
      const now = Math.floor(Date.now() / 1000);
      await this.accountDao.updateCookie(username, newCookie, now);

      return newCookie;
    } catch (e) {
      if (e instanceof AuthExpiredError) {
        throw e;
      }
      throw new AuthExpiredError('Cookie refresh failed: ' + (e instanceof Error ? e.message : String(e)));
    }
  }

  // ── 账号信息查询 ──────────────────────────────────────────────

  /**
   * 获取米游社 BBS 账号详情（nickname、avatar_url）。
   * 接口：GET /user/wapi/getUserFullInfo
   */
  async getBbsAccountDetail(cookie: string): Promise<BbsAccountDetailResult> {
    try {
      const uid = BBSRepository.extractCookieField(cookie, 'account_id');
      // 优先走 service（mock/release 自动适配），兜底走 NetworkFactory
      let resp: BbsAccountDetailResponse;
      if (this.service !== null) {
        resp = await (this.service as MihoyoAccountApiService).getUserFullInfo(uid, cookie) as BbsAccountDetailResponse;
      } else {
        const options = new RequestOptions();
        options.extraHeaders.set(HKey.COOKIE, cookie);
        const params = new RequestParams();
        if (uid.length > 0) {
          params.set('uid', uid);
          params.set('gids', '2');
        }
        resp = await NetworkFactory.getInstance().get(
          MihoyoDomain.BBS + MihoyoAccountApiPath.GET_USER_FULL_INFO,
          params,
          options
        ) as BbsAccountDetailResponse;
      }
      if (resp.retcode !== 0) {
        throw new Error(`getBbsAccountDetail failed: [${resp.retcode}] ${resp.message}`);
      }
      const result = new BbsAccountDetailResult();
      result.uid = resp.data.user_info.uid ?? '';
      result.nickname = resp.data.user_info.nickname ?? '';
      result.avatarUrl = resp.data.user_info.avatar_url ?? '';
      result.rawJson = JSON.stringify(resp.data);
      return result;
    } catch (error) {
      const msg = error instanceof Error ? error.message : `${error}`;
      try {
        if (error instanceof AuthExpiredError) {
          ApiLogSystem.getInstance().warning('BBSRepository', 'AuthExpiredError in getBbsAccountDetail: ' + msg, LogEventType.GENERAL);
        } else if (error instanceof GeetestRequiredError || error instanceof GeetestSignRequiredError) {
          ApiLogSystem.getInstance().warning('BBSRepository', 'GeetestError in getBbsAccountDetail: ' + msg, LogEventType.GENERAL);
        } else {
          ApiLogSystem.getInstance().error('BBSRepository', 'getBbsAccountDetail failed: ' + msg, LogEventType.GENERAL);
        }
      } catch (_) {}
      throw new Error(`BBSRepository.getBbsAccountDetail failed: ${msg}`);
    }
  }

  /**
   * 获取账号绑定的所有游戏角色。
   * 接口：GET /binding/api/getUserGameRolesByCookie
   */
  async getUserGameRoles(cookie: string): Promise<GameRoleRecord[]> {
    try {
      const options = new RequestOptions();
      options.extraHeaders.set(HKey.COOKIE, cookie);
      const resp = await NetworkFactory.getInstance().get(
        `${MihoyoDomain.TAKUMI}/binding/api/getUserGameRolesByCookie`,
        new RequestParams(),
        options
      ) as GameRolesResponse;
      if (resp.retcode !== 0) {
        throw new Error(`getUserGameRoles failed: [${resp.retcode}] ${resp.message}`);
      }
      const rows: GameRoleRecord[] = [];
      for (const info of resp.data.list) {
        const row = new GameRoleRecord();
        row.gameId = gameBizToGameId(info.game_biz);
        row.roleId = info.game_uid;
        row.nickname = info.nickname;
        row.level = info.level;
        row.server = info.region;
        rows[rows.length] = row;
      }
      return rows;
    } catch (error) {
      const msg = error instanceof Error ? error.message : `${error}`;
      try {
        if (error instanceof AuthExpiredError) {
          ApiLogSystem.getInstance().warning('BBSRepository', 'AuthExpiredError in getUserGameRoles: ' + msg, LogEventType.GENERAL);
        } else if (error instanceof GeetestRequiredError || error instanceof GeetestSignRequiredError) {
          ApiLogSystem.getInstance().warning('BBSRepository', 'GeetestError in getUserGameRoles: ' + msg, LogEventType.GENERAL);
        } else {
          ApiLogSystem.getInstance().error('BBSRepository', 'getUserGameRoles failed: ' + msg, LogEventType.GENERAL);
        }
      } catch (_) {}
      throw new Error(`BBSRepository.getUserGameRoles failed: ${msg}`);
    }
  }

  /**
   * 获取账号详情（含 background_image_v2 和游戏内统计数据）。
   * 接口：GET /game_record/app/card/wapi/getGameRecordCard
   */
  async getGameRecordCard(cookie: string, uid: string): Promise<GameRoleRecord[]> {
    try {
      const options = new RequestOptions();
      options.extraHeaders.set(HKey.COOKIE, cookie);
      const params = new RequestParams();
      params.set('uid', uid);
      const resp = await NetworkFactory.getInstance().get(
        MihoyoDomain.TAKUMI_RECORD + MihoyoAccountApiPath.GET_GAME_RECORD_CARD,
        params,
        options
      ) as GameRecordCardResponse;
      if (resp.retcode !== 0) {
        throw new Error(`getGameRecordCard failed: [${resp.retcode}] ${resp.message}`);
      }
      const rows: GameRoleRecord[] = [];
      for (const item of resp.data.list) {
        const row = new GameRoleRecord();
        row.gameId = GameId.fromMihoyoGameId(item.game_id);
        row.roleId = item.game_role_id;
        row.nickname = item.nickname;
        row.level = item.level;
        row.server = item.region;
        row.bgImageUrl = item.background_image_v2 ?? '';
        row.statsJson = JSON.stringify(item.data ?? []);
        rows[rows.length] = row;
      }
      return rows;
    } catch (error) {
      const msg = error instanceof Error ? error.message : `${error}`;
      try {
        if (error instanceof AuthExpiredError) {
          ApiLogSystem.getInstance().warning('BBSRepository', 'AuthExpiredError in getGameRecordCard: ' + msg, LogEventType.GENERAL);
        } else if (error instanceof GeetestRequiredError || error instanceof GeetestSignRequiredError) {
          ApiLogSystem.getInstance().warning('BBSRepository', 'GeetestError in getGameRecordCard: ' + msg, LogEventType.GENERAL);
        } else {
          ApiLogSystem.getInstance().error('BBSRepository', 'getGameRecordCard failed: ' + msg, LogEventType.GENERAL);
        }
      } catch (_) {}
      throw new Error(`BBSRepository.getGameRecordCard failed: ${msg}`);
    }
  }
}
