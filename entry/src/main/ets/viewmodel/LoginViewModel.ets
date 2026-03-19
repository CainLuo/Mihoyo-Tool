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
  AccountRepository
} from 'core';
import { Logger } from '../utils/Logger';

const TAG: string = 'LoginViewModel';

/** 登录方式 Tab */
export type LoginTab = 'phone' | 'qrcode' | 'cookie';

/** 手机号登录步骤 */
export type PhoneStep = 'input_phone' | 'input_code';

/** 二维码状态 */
export type QRCodeStat = 'loading' | 'ready' | 'scanned' | 'confirmed' | 'expired' | 'error';

@ObservedV2
export class LoginViewModel {
  // ── 通用状态 ──────────────────────────────────────────────────
  @Trace activeTab: LoginTab = 'phone';
  @Trace isLoading: boolean = false;
  @Trace errorMsg: string = '';
  /** 登录成功标志，View 层监听后跳转 */
  @Trace loginSuccess: boolean = false;

  // ── 手机号登录状态 ────────────────────────────────────────────
  @Trace phoneStep: PhoneStep = 'input_phone';
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
  @Trace qrCodeStat: QRCodeStat = 'loading';

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
    if (tab === 'qrcode') {
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
      this.phoneStep = 'input_code';
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

  /** 返回手机号输入步骤 */
  backToPhoneInput(): void {
    this.phoneStep = 'input_phone';
    this.smsCode = '';
    this.errorMsg = '';
  }

  // ─── 二维码登录 ───────────────────────────────────────────────

  /** 开始二维码登录（切换到二维码 Tab 时自动调用） */
  async startQRCodeLogin(): Promise<void> {
    this.stopQRCodePoll();
    this.qrCodeStat = 'loading';
    this.qrCodeUrl = '';
    this.errorMsg = '';
    if (this.deviceId.length === 0) {
      this.deviceId = LoginViewModel.generateDeviceId();
    }
    try {
      const result = await AuthRepository.fetchQRCode(this.deviceId);
      this.qrCodeUrl = result.url;
      this.qrTicket = result.ticket;
      this.qrCodeStat = 'ready';
      this.startQRCodePoll();
    } catch (error) {
      const msg = error instanceof Error ? error.message : `${error}`;
      Logger.error(TAG, `startQRCodeLogin failed: ${msg}`);
      this.qrCodeStat = 'error';
      this.errorMsg = msg;
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
        this.qrCodeStat = 'scanned';
      } else if (result.stat === 'confirmed' && result.confirmed !== null) {
        this.stopQRCodePoll();
        this.qrCodeStat = 'confirmed';
        await this.handleQRCodeConfirmed(result.confirmed);
      } else if (result.stat === 'expired') {
        this.stopQRCodePoll();
        this.qrCodeStat = 'expired';
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
      this.qrCodeStat = 'error';
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
    const accountId = await AccountRepository.insertAccount(username, cookie);
    // 2. 设置为激活账号
    await AccountRepository.setActiveAccount(accountId);
    // 3. 拉取游戏角色并写入
    try {
      const roles = await AuthRepository.getUserGameRoles(cookie);
      if (roles.length > 0) {
        await AccountRepository.replaceRoles(accountId, roles);
      }
    } catch (error) {
      // 角色拉取失败不阻断登录流程，只记录 warn
      const msg = error instanceof Error ? error.message : `${error}`;
      Logger.warn(TAG, `getUserGameRoles failed (non-fatal): ${msg}`);
    }
    // 4. 通知 View 跳转
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
