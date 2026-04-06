/**
 * LoginViewModel.ets
 *
 * 登录页 ViewModel，支持三种登录方式：
 *   - 手机号 + 短信验证码
 *   - 二维码扫码
 *   - 手动输入 Cookie
 *
 * 登录成功后统一流程：
 *   写 AccountRepository → 写游戏角色 → 通知 View 跳转首页
 */

import {
  AuthRepository,
  MmtData,
  GeetestV4Data,
  PhoneLoginAccountInfo,
  QRCodeConfirmedData,
  LoginCookieFields,
  RoleStatItem,
  CoreInitializer,
  AccountRow,
  GameRoleRow
} from 'core';
import { Logger } from '../utils/Logger';
import { LoginTab, PhoneStep, QRCodeStat } from '../constants/LoginTabEnum';
import { MyAccountVM, MyGameRoleVM, GameStatItem } from '../components/my/MyModels';
import { serverDisplayName } from '../utils/ServerNameUtil';
import { gameIdToName, gameIdToColor } from '../utils/GameIdUtil';

export { LoginTab, PhoneStep, QRCodeStat };

const TAG: string = 'LoginViewModel';

/** LoginViewModel @Monitor 路径常量类型 */
export class LoginViewModelKeys {
  loginSuccess: string = 'vm.loginSuccess';
  loginedAccountId: string = 'vm.loginedAccountId';
  loginedAccountVM: string = 'vm.loginedAccountVM';
}

@ObservedV2
export class LoginViewModel {
  /** @Monitor 路径常量，View 层必须通过此对象引用，禁止直接写字符串字面量 */
  static readonly KEYS: LoginViewModelKeys = new LoginViewModelKeys();

  // ── 通用状态 ──────────────────────────────────────────────────
  @Trace activeTab: LoginTab = LoginTab.PHONE;
  @Trace isLoading: boolean = false;
  @Trace errorMsg: string = '';
  /** 登录成功标志，View 层监听后跳转 */
  @Trace loginSuccess: boolean = false;
  /** 登录成功后的账号 ID，View 层用于跳转到 AccountDetail */
  @Trace loginedAccountId: number = -1;
  /** 登录成功后组装好的账号 VM，View 层直接用于跳转 */
  @Trace loginedAccountVM: MyAccountVM | null = null;

  // ── 手机号登录状态 ────────────────────────────────────────────
  @Trace phoneStep: PhoneStep = PhoneStep.INPUT_PHONE;
  @Trace phoneNumber: string = '';
  @Trace smsCode: string = '';
  @Trace smsCooldown: number = 0;  // 倒计时秒数，0 表示可发送

  /** 当前 mmt_key（发短信时需要） */
  private mmtKey: string = '';
  /** 当前 mmt_type（0=无需验证，1=需要验证） */
  private mmtType: number = 0;
  /** 当前 mmt_data（需要 Geetest 时传给 GeetestDialog） */
  private mmtData: MmtData | null = null;
  /** 手机号登录成功后的账号信息（用于后续 Token 换取） */
  private phoneAccountInfo: PhoneLoginAccountInfo | null = null;
  /** 倒计时 timer ID */
  private cooldownTimer: number = -1;

  // ── 二维码登录状态 ────────────────────────────────────────────
  @Trace qrCodeUrl: string = '';
  @Trace qrCodeStat: QRCodeStat = QRCodeStat.LOADING;

  /** 当前二维码 ticket */
  private qrTicket: string = '';
  /** 设备 ID（持久化，每次使用同一个） */
  private deviceId: string = '';
  /** 轮询 timer ID */
  private pollTimer: number = -1;

  // ── Cookie 登录状态 ───────────────────────────────────────────
  @Trace cookieInput: string = '';

  // ─── 通用 ────────────────────────────────────────────────────

  /** 切换 Tab */
  switchTab(tab: LoginTab): void {
    this.activeTab = tab;
    this.errorMsg = '';
    if (tab === LoginTab.QRCODE) {
      this.startQRCodeLogin();
    } else {
      this.stopQRCodePoll();
    }
  }

  /** 清理资源（页面销毁时调用） */
  dispose(): void {
    this.stopQRCodePoll();
    this.stopCooldown();
  }

  // ─── 手机号登录 ───────────────────────────────────────────────

  /**
   * 第一步：申请人机验证任务
   * 返回 MmtData，View 层根据 mmt_type 决定是否弹出 GeetestDialog
   */
  async prepareSendSms(): Promise<MmtData> {
    this.errorMsg = '';
    this.isLoading = true;
    try {
      const mmt = await AuthRepository.createMmt();
      this.mmtKey = mmt.mmt_key;
      this.mmtType = mmt.use_v4 === true ? 1 : (mmt.gt !== undefined ? 1 : 0);
      this.mmtData = mmt;
      return mmt;
    } catch (error) {
      const msg = error instanceof Error ? error.message : `${error}`;
      Logger.error(TAG, `prepareSendSms failed: ${msg}`);
      this.errorMsg = msg;
      throw new Error(msg);
    } finally {
      this.isLoading = false;
    }
  }

  /**
   * 第二步：发送短信验证码
   * @param v4Data    Geetest v4 验证结果（mmt_type=1 且 use_v4=true 时传）
   * @param v3Challenge  Geetest v3 challenge（v3 验证时传）
   * @param v3Validate   Geetest v3 validate
   * @param v3Seccode    Geetest v3 seccode
   */
  async sendSmsCode(
    v4Data?: GeetestV4Data,
    v3Challenge?: string,
    v3Validate?: string,
    v3Seccode?: string
  ): Promise<void> {
    if (this.phoneNumber.length === 0) {
      this.errorMsg = 'phone_empty';
      return;
    }
    this.isLoading = true;
    this.errorMsg = '';
    try {
      await AuthRepository.sendSmsCode(
        this.phoneNumber,
        this.mmtKey,
        v4Data,
        v3Challenge,
        v3Validate,
        v3Seccode
      );
      this.phoneStep = PhoneStep.INPUT_CODE;
      this.startCooldown(60);
    } catch (error) {
      const msg = error instanceof Error ? error.message : `${error}`;
      Logger.error(TAG, `sendSmsCode failed: ${msg}`);
      this.errorMsg = msg;
    } finally {
      this.isLoading = false;
    }
  }

  /**
   * 第三步：用短信验证码登录，完成后写入 DB
   */
  async loginByPhone(): Promise<void> {
    if (this.smsCode.length === 0) {
      this.errorMsg = 'code_empty';
      return;
    }
    this.isLoading = true;
    this.errorMsg = '';
    try {
      const accountInfo = await AuthRepository.loginByPhone(this.phoneNumber, this.smsCode);
      this.phoneAccountInfo = accountInfo;
      // 用 LoginTicket 换取 LToken
      const ltoken = await AuthRepository.getLTokenByTicket(
        accountInfo.weblogin_token,
        accountInfo.account_id
      );
      const fields = new LoginCookieFields();
      fields.accountId = `${accountInfo.account_id}`;
      fields.cookieToken = accountInfo.weblogin_token;
      fields.ltoken = ltoken;
      fields.ltuid = `${accountInfo.account_id}`;
      const cookie = AuthRepository.buildCookieString(fields);
      await this.finalizeLogin(`${accountInfo.account_id}`, cookie);
    } catch (error) {
      const msg = error instanceof Error ? error.message : `${error}`;
      Logger.error(TAG, `loginByPhone failed: ${msg}`);
      this.errorMsg = msg;
    } finally {
      this.isLoading = false;
    }
  }

  /** 脱敏手机号，如 138****8888 */
  get maskedPhone(): string {
    const p = this.phoneNumber;
    if (p.length < 7) {
      return p;
    }
    return p.substring(0, 3) + '****' + p.substring(p.length - 4);
  }

  /** 返回手机号输入步骤 */
  backToPhoneInput(): void {
    this.phoneStep = PhoneStep.INPUT_PHONE;
    this.smsCode = '';
    this.errorMsg = '';
  }

  // ─── 二维码登录 ───────────────────────────────────────────────

  /** 开始二维码登录（切换到二维码 Tab 时自动调用） */
  async startQRCodeLogin(): Promise<void> {
    this.stopQRCodePoll();
    this.qrCodeStat = QRCodeStat.LOADING;
    this.qrCodeUrl = '';
    this.errorMsg = '';
    if (this.deviceId.length === 0) {
      this.deviceId = LoginViewModel.generateDeviceId();
    }
    this.isLoading = true;
    try {
      const result = await AuthRepository.fetchQRCode(this.deviceId);
      this.qrCodeUrl = result.url;
      this.qrTicket = result.ticket;
      this.qrCodeStat = QRCodeStat.READY;
      this.startQRCodePoll();
    } catch (error) {
      const msg = error instanceof Error ? error.message : `${error}`;
      Logger.error(TAG, `startQRCodeLogin failed: ${msg}`);
      this.qrCodeStat = QRCodeStat.ERROR;
      this.errorMsg = msg;
    } finally {
      this.isLoading = false;
    }
  }

  /** 刷新二维码（过期后用户点击刷新） */
  async refreshQRCode(): Promise<void> {
    await this.startQRCodeLogin();
  }

  /** 开始轮询二维码状态（每 2 秒一次） */
  private startQRCodePoll(): void {
    this.pollTimer = setInterval(async () => {
      await this.pollQRCodeStatus();
    }, 2000) as number;
  }

  /** 停止轮询 */
  private stopQRCodePoll(): void {
    if (this.pollTimer !== -1) {
      clearInterval(this.pollTimer);
      this.pollTimer = -1;
    }
  }

  /** 单次轮询 */
  private async pollQRCodeStatus(): Promise<void> {
    try {
      const result = await AuthRepository.queryQRCode(this.deviceId, this.qrTicket);
      if (result.stat === 'scanned') {
        this.qrCodeStat = QRCodeStat.SCANNED;
      } else if (result.stat === 'confirmed' && result.confirmed !== null) {
        this.stopQRCodePoll();
        this.qrCodeStat = QRCodeStat.CONFIRMED;
        await this.handleQRCodeConfirmed(result.confirmed);
      } else if (result.stat === 'expired') {
        this.stopQRCodePoll();
        this.qrCodeStat = QRCodeStat.EXPIRED;
      }
    } catch (error) {
      const msg = error instanceof Error ? error.message : `${error}`;
      Logger.warn(TAG, `pollQRCodeStatus failed: ${msg}`);
    }
  }

  /** 二维码确认后，换取 Token 并写入 DB */
  private async handleQRCodeConfirmed(confirmed: QRCodeConfirmedData): Promise<void> {
    this.isLoading = true;
    try {
      const tokenResult = await AuthRepository.getTokenByGameToken(
        confirmed.uid,
        confirmed.token
      );
      const stoken = tokenResult.stoken;
      const userInfo = tokenResult.userInfo;
      const ltoken = await AuthRepository.getLTokenBySToken(stoken, confirmed.uid);
      const cookieToken = await AuthRepository.getCookieBySToken(stoken, confirmed.uid);
      const fields = new LoginCookieFields();
      fields.accountId = confirmed.uid;
      fields.cookieToken = cookieToken;
      fields.ltoken = ltoken;
      fields.ltuid = confirmed.uid;
      const cookie = AuthRepository.buildCookieString(fields);
      await this.finalizeLogin(userInfo.mid.length > 0 ? userInfo.mid : confirmed.uid, cookie);
    } catch (error) {
      const msg = error instanceof Error ? error.message : `${error}`;
      Logger.error(TAG, `handleQRCodeConfirmed failed: ${msg}`);
      this.errorMsg = msg;
      this.qrCodeStat = QRCodeStat.ERROR;
    } finally {
      this.isLoading = false;
    }
  }

  // ─── Cookie 登录 ──────────────────────────────────────────────

  /**
   * 用手动输入的 Cookie 登录
   * 直接调用 getUserGameRoles 验证有效性
   */
  async loginByCookie(): Promise<void> {
    if (this.cookieInput.trim().length === 0) {
      this.errorMsg = 'cookie_empty';
      return;
    }
    this.isLoading = true;
    this.errorMsg = '';
    try {
      const cookie = this.cookieInput.trim();
      // 从 Cookie 中提取 account_id 作为用户名
      const accountId = LoginViewModel.extractCookieField(cookie, 'account_id');
      const username = accountId.length > 0 ? accountId : 'unknown';
      await this.finalizeLogin(username, cookie);
    } catch (error) {
      const msg = error instanceof Error ? error.message : `${error}`;
      Logger.error(TAG, `loginByCookie failed: ${msg}`);
      this.errorMsg = msg;
    } finally {
      this.isLoading = false;
    }
  }

  // ─── 登录成功统一流程 ─────────────────────────────────────────

  /**
   * 登录成功后统一处理：写账号 → 写游戏角色 → 设置激活 → 通知 View
   * @param username  用于展示的账号标识（account_id 或 mid）
   * @param cookie    完整 Cookie 字符串
   */
  private async finalizeLogin(username: string, cookie: string): Promise<void> {
    // 1. 写入账号
    const now = Math.floor(Date.now() / 1000);
    const accountRow = new AccountRow();
    accountRow.id = 0; // 新账号，自增
    accountRow.username = username;
    accountRow.cookie = cookie;
    accountRow.isActive = 1;
    accountRow.createTime = now;
    accountRow.updateTime = now;
    await CoreInitializer.bbsRepository.saveAccount(accountRow);

    // 查询刚写入的账号 id
    const savedAccount = await CoreInitializer.bbsRepository.getAccountByUsername(username);
    const accountId = savedAccount !== null ? savedAccount.id : 0;

    // 2. 拉取游戏角色并写入
    try {
      const roles = await AuthRepository.getUserGameRoles(cookie);
      if (roles.length > 0) {
        // 额外调用账号详情接口，补充 bgImageUrl 和 statsJson
        try {
          const uid = LoginViewModel.extractCookieField(cookie, 'account_id') ||
                      LoginViewModel.extractCookieField(cookie, 'ltuid_v2') ||
                      username;
          const detailRoles = await AuthRepository.getGameRecordCard(cookie, uid);
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
        } catch (_) {
          // 账号详情拉取失败不阻断流程
        }
        // 转换为 GameRoleRow 并保存
        const roleRows: GameRoleRow[] = [];
        for (let i = 0; i < roles.length; i++) {
          const r = roles[i];
          const roleRow = new GameRoleRow();
          roleRow.id = 0;
          roleRow.accountId = accountId;
          roleRow.gameId = r.gameId;
          roleRow.roleId = r.roleId;
          roleRow.nickname = r.nickname;
          roleRow.level = r.level;
          roleRow.server = r.server;
          roleRow.bgImageUrl = r.bgImageUrl;
          roleRow.statsJson = r.statsJson;
          roleRows[roleRows.length] = roleRow;
        }
        await CoreInitializer.bbsRepository.saveGameRoles(roleRows);
      }
    } catch (error) {
      // 角色拉取失败不阻断登录流程，只记录 warn
      const msg = error instanceof Error ? error.message : `${error}`;
      Logger.warn(TAG, `getUserGameRoles failed (non-fatal): ${msg}`);
    }

    // 3. 拉取 BBS 账号详情（nickname、avatarUrl）
    try {
      const bbsDetail = await AuthRepository.getBbsAccountDetail(cookie);
      if (bbsDetail.nickname || bbsDetail.avatarUrl) {
        const latestRow = await CoreInitializer.bbsRepository.getAccountById(accountId);
        if (latestRow !== null) {
          latestRow.nickname = bbsDetail.nickname;
          latestRow.avatarUrl = bbsDetail.avatarUrl;
          await CoreInitializer.bbsRepository.saveAccount(latestRow);
        }
      }
    } catch (error) {
      const msg = error instanceof Error ? error.message : `${error}`;
      Logger.warn(TAG, `getBbsAccountDetail failed (non-fatal): ${msg}`);
    }

    // 4. 组装 AccountVM 并通知 View 跳转
    try {
      const row = await CoreInitializer.bbsRepository.getAccountById(accountId);
      if (row !== null) {
        const roleRows = await CoreInitializer.bbsRepository.getGameRoles(accountId);
        const roleVMs: MyGameRoleVM[] = [];
        for (let i = 0; i < roleRows.length; i++) {
          const r = roleRows[i];
          const rawStats = RoleStatItem.parseAll(r.statsJson);
          const stats: GameStatItem[] = [];
          for (let j = 0; j < rawStats.length; j++) {
            stats[stats.length] = new GameStatItem(rawStats[j].name, rawStats[j].value);
          }
          roleVMs[roleVMs.length] = new MyGameRoleVM(
            r.gameId, gameIdToName(r.gameId), gameIdToColor(r.gameId),
            r.roleId, r.nickname, serverDisplayName(r.server, r.gameId) ?? r.server,
            r.level, r.bgImageUrl, stats
          );
        }
        this.loginedAccountVM = new MyAccountVM(row.id, row.username, roleVMs, row.nickname, row.avatarUrl);
      }
    } catch (error) {
      const msg = error instanceof Error ? error.message : `${error}`;
      Logger.warn(TAG, `buildLoginedAccountVM failed (non-fatal): ${msg}`);
    }
    this.loginedAccountId = accountId;
    this.loginSuccess = true;
  }

  // ─── 工具方法 ─────────────────────────────────────────────────

  /** 从 Cookie 字符串中提取指定字段值 */
  private static extractCookieField(cookie: string, field: string): string {
    const parts = cookie.split(';');
    for (const part of parts) {
      const trimmed = part.trim();
      const prefix = field + '=';
      if (trimmed.startsWith(prefix)) {
        return trimmed.substring(prefix.length).trim();
      }
    }
    return '';
  }

  /** 生成随机设备 ID */
  private static generateDeviceId(): string {
    const chars = '0123456789abcdef';
    let id = '';
    const groups = [8, 4, 4, 4, 12];
    for (let g = 0; g < groups.length; g++) {
      if (g > 0) {
        id += '-';
      }
      for (let i = 0; i < groups[g]; i++) {
        id += chars.charAt(Math.floor(Math.random() * chars.length));
      }
    }
    return id;
  }

  /** 开始短信倒计时 */
  private startCooldown(seconds: number): void {
    this.smsCooldown = seconds;
    this.cooldownTimer = setInterval(() => {
      this.smsCooldown -= 1;
      if (this.smsCooldown <= 0) {
        this.smsCooldown = 0;
        this.stopCooldown();
      }
    }, 1000) as number;
  }

  /** 停止倒计时 */
  private stopCooldown(): void {
    if (this.cooldownTimer !== -1) {
      clearInterval(this.cooldownTimer);
      this.cooldownTimer = -1;
    }
  }
}
