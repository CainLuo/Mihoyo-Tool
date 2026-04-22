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
  LoginMobileResult,
  QRCodeConfirmedData,
  LoginCookieFields,
  RoleStatItem,
  CoreInitializer,
  LoginResult,
  BBSRepository
} from 'core';
import { Logger } from 'core';
import { LoginTab, PhoneStep, QRCodeStat } from '../constants/LoginTabEnum';
import { MyAccountVM, MyGameRoleVM, GameStatItem } from '../models/MyModels';
import { serverDisplayName } from '../utils/ServerNameUtil';
import { gameIdToName, gameIdToColor } from '../utils/GameIdUtil';

export { LoginTab, PhoneStep, QRCodeStat };

const TAG: string = 'LoginViewModel';

/** LoginViewModel @Monitor 路径常量类型 */
export class LoginViewModelKeys {
  loginSuccess: string = 'vm.loginSuccess';
  loginedAccountId: string = 'vm.loginedAccountId';
  loginedAccountVM: string = 'vm.loginedAccountVM';
  showNoStokenDialog: string = 'vm.showNoStokenDialog';
}

@ObservedV2
export class LoginViewModel {
  /** @Monitor 路径常量，View 层必须通过此对象引用，禁止直接写字符串字面量 */
  static readonly KEYS: LoginViewModelKeys = new LoginViewModelKeys();

  // ── 通用状态 ──────────────────────────────────────────────────
  @Trace activeTab: LoginTab = LoginTab.PHONE;
  @Trace isLoading: boolean = false;
  @Trace errorMsg: string = '';
  /** Cookie 缺少 stoken 时触发，View 层监听后弹 Dialog */
  @Trace showNoStokenDialog: boolean = false;
  /** 登录成功标志，View 层监听后跳转 */
  @Trace loginSuccess: boolean = false;
  /** 登录成功后的米游社 UID，View 层用于跳转到 AccountDetail */
  @Trace loginedAccountId: string = '';
  /** 登录成功后组装好的账号 VM，View 层直接用于跳转 */
  @Trace loginedAccountVM: MyAccountVM | null = null;

  // ── 手机号登录状态 ────────────────────────────────────────────
  @Trace phoneStep: PhoneStep = PhoneStep.INPUT_PHONE;
  @Trace phoneNumber: string = '';
  @Trace smsCode: string = '';
  @Trace smsCooldown: number = 0;  // 倒计时秒数，0 表示可发送

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
   * 发送短信验证码（新版接口）
   * 调用 createLoginCaptcha，mobile/areaCode 由 AuthRepository 内部 RSA 加密
   */
  async sendSmsCode(): Promise<void> {
    if (this.phoneNumber.length === 0) {
      this.errorMsg = 'phone_empty';
      return;
    }
    this.isLoading = true;
    this.errorMsg = '';
    try {
      await AuthRepository.createLoginCaptcha(this.phoneNumber);
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
   * 提交验证码登录（新版接口）
   * loginByMobileCaptcha → getLTokenBySToken → getCookieBySToken → finalizeLogin
   */
  async loginByPhone(): Promise<void> {
    if (this.smsCode.length === 0) {
      this.errorMsg = 'code_empty';
      return;
    }
    this.isLoading = true;
    this.errorMsg = '';
    try {
      // 1. 提交验证码，获取 stoken + aid + mid
      const loginResult: LoginMobileResult = await AuthRepository.loginByMobileCaptcha(this.phoneNumber, this.smsCode);
      const stoken = loginResult.stoken;
      const aid = loginResult.aid;
      const mid = loginResult.mid;

      // 2. stoken → ltoken
      const ltoken = await AuthRepository.getLTokenBySToken(stoken, mid);

      // 3. stoken → cookie_token
      const cookieToken = await AuthRepository.getCookieBySToken(stoken, mid);

      // 4. 组装 Cookie
      const fields = new LoginCookieFields();
      fields.accountId = aid;
      fields.cookieToken = cookieToken;
      fields.ltoken = ltoken;
      fields.ltuid = aid;
      fields.stoken = stoken;
      fields.mid = mid;
      const cookie = AuthRepository.buildCookieString(fields);

      await this.finalizeLogin(aid, cookie);
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
      const mid = userInfo.mid.length > 0 ? userInfo.mid : confirmed.uid;
      const ltoken = await AuthRepository.getLTokenBySToken(stoken, mid);
      const cookieToken = await AuthRepository.getCookieBySToken(stoken, mid);
      const fields = new LoginCookieFields();
      fields.accountId = confirmed.uid;
      fields.cookieToken = cookieToken;
      fields.ltoken = ltoken;
      fields.ltuid = confirmed.uid;
      fields.stoken = stoken;
      fields.mid = mid;
      const cookie = AuthRepository.buildCookieString(fields);
      await this.finalizeLogin(confirmed.uid, cookie);
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
   * 先调用 getUserFullInfo 验证 Cookie 有效性并获取 uid，
   * 再检查 Cookie 是否包含 stoken（缺少 stoken 会导致便笺同步失败）。
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

      // 检查 stoken 是否存在，缺少则触发 Dialog 提示
      const stoken = BBSRepository.extractCookieField(cookie, 'stoken');
      if (stoken.length === 0) {
        this.showNoStokenDialog = true;
        return;
      }

      // 用 getUserFullInfo 验证 Cookie 有效性，同时获取 uid
      const bbsDetail = await CoreInitializer.bbsRepository.getBbsAccountDetail(cookie);
      const username = bbsDetail.uid.length > 0 ? bbsDetail.uid : 'unknown';
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
   * 登录成功后统一处理：委托给 BBSRepository.login() 完成所有 DB 操作，
   * 拿到结果后组装 AccountVM 通知 View 跳转。
   */
  private async finalizeLogin(username: string, cookie: string): Promise<void> {
    await CoreInitializer.waitForReady();

    // 全部 DB 操作和环境适配委托给 core 层，entry 不感知 mock/release 环境
    let loginResult: LoginResult;
    try {
      loginResult = await CoreInitializer.bbsRepository.login(username, cookie);
    } catch (error) {
      const msg = error instanceof Error ? error.message : `${error}`;
      Logger.error(TAG, `login failed: ${msg}`);
      this.errorMsg = msg;
      return;
    }

    // 组装 AccountVM 并通知 View 跳转
    const roleVMs: MyGameRoleVM[] = [];
    for (let i = 0; i < loginResult.roles.length; i++) {
      const r = loginResult.roles[i];
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
    this.loginedAccountVM = new MyAccountVM(
      loginResult.accountId, loginResult.username, roleVMs,
      loginResult.nickname, loginResult.avatarUrl, loginResult.uid
    );
    this.loginedAccountId = loginResult.accountId;
    this.loginSuccess = true;
  }

  // ─── 工具方法 ─────────────────────────────────────────────────

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
