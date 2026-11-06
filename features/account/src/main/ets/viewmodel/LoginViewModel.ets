/**
 * LoginViewModel.ets（手机号 / 二维码 / Cookie 登录）
 */

import {
  AuthRepository,
  LoginMobileResult,
  QRCodeConfirmedData,
  LoginCookieFields,
  RoleStatItem,
  CoreInitializer,
  LoginResult,
  BBSRepository,
  ApiConfig,
  Logger
} from 'core';
import {
  LoginTab,
  PhoneStep,
  QRCodeStat,
  SMS_COOLDOWN_SECONDS,
  QR_POLL_INTERVAL_MS,
  COOLDOWN_TICK_MS
} from '../constants/LoginConstants';
import { MyAccountVM, MyGameRoleVM, GameStatItem } from '../model/MyModels';
import { getServerDisplayName, CookieExpiredSignal, getGameName, getGameColor } from 'basic';

export { LoginTab, PhoneStep, QRCodeStat };

const TAG: string = 'LoginViewModel';

@ObservedV2
export class LoginViewModel {

  // ── 通用状态 ──────────────────────────────────────────────────
  /** 所有环境默认手机号登录 */
  @Trace activeTab: LoginTab = LoginTab.PHONE;
  @Trace isLoading: boolean = false;
  @Trace errorMsg: string = '';
  @Trace shouldShowStokenMissingDialog: boolean = false;
  @Trace isLoginSuccess: boolean = false;
  @Trace loginedAccountId: string = '';
  @Trace loginedAccountVM: MyAccountVM | null = null;

  // ── 手机号登录状态 ────────────────────────────────────────────
  @Trace phoneStep: PhoneStep = PhoneStep.INPUT_PHONE;
  @Trace phoneNumber: string = '';
  @Trace smsCode: string = '';
  @Trace smsCooldown: number = 0;

  private cooldownTimer: number = -1;

  // ── 二维码登录状态 ────────────────────────────────────────────
  @Trace qrCodeUrl: string = '';
  @Trace qrCodeStat: QRCodeStat = QRCodeStat.LOADING;

  private qrTicket: string = '';
  private deviceId: string = '';
  private pollTimer: number = -1;
  /** 每次停止 / 重启二维码流程递增，用于丢弃过期的异步结果 */
  private qrGeneration: number = 0;
  /** 防止上一轮轮询未返回时重复发起请求 */
  private isPollInFlight: boolean = false;
  /** 二维码获取请求是否仍在进行，避免取消后 isLoading 卡住 */
  private isQrFetching: boolean = false;

  // ── Cookie 登录状态 ───────────────────────────────────────────
  @Trace cookieInput: string = '';

  // ─── 通用 ────────────────────────────────────────────────────

  /** 初始化登录流程（页面 aboutToAppear 时调用） */
  init(): void {
    if (this.activeTab === LoginTab.QRCODE) {
      this.startQRCodeLogin();
    }
  }

  switchTab(tab: LoginTab): void {
    this.activeTab = tab;
    this.errorMsg = '';
    if (tab === LoginTab.QRCODE) {
      this.startQRCodeLogin();
    } else {
      this.stopQRCodePoll();
    }
  }

  dispose(): void {
    this.stopQRCodePoll();
    this.stopCooldown();
  }

  // ─── 手机号登录 ───────────────────────────────────────────────

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
      this.startCooldown(SMS_COOLDOWN_SECONDS);
    } catch (error) {
      const msg = error instanceof Error ? error.message : `${error}`;
      Logger.error(TAG, `sendSmsCode failed: ${msg}`);
      this.errorMsg = msg;
    } finally {
      this.isLoading = false;
    }
  }

  async loginByPhone(): Promise<void> {
    if (this.smsCode.length === 0) {
      this.errorMsg = 'code_empty';
      return;
    }
    this.isLoading = true;
    this.errorMsg = '';
    try {
      const loginResult: LoginMobileResult = await AuthRepository.loginByMobileCaptcha(this.phoneNumber, this.smsCode);
      const stoken = loginResult.stoken;
      const aid = loginResult.aid;
      const mid = loginResult.mid;

      // ltoken 和 cookie_token 通过 stoken 换取（V1 接口）。
      // 原先 v2 stoken 会先调用 V2 接口 getCookieBySToken，国服返回 404 后才退回 V1，现已去掉 V2 调用。
      const ltoken = await AuthRepository.getLTokenBySToken(stoken, mid);
      const cookieToken = await AuthRepository.getCookieBySToken(stoken, mid);
      const cookie = this.buildCookie(aid, aid, stoken, mid, ltoken, cookieToken);
      await this.finalizeLogin(aid, cookie);
    } catch (error) {
      const msg = error instanceof Error ? error.message : `${error}`;
      Logger.error(TAG, `loginByPhone failed: ${msg}`);
      this.errorMsg = msg;
    } finally {
      this.isLoading = false;
    }
  }

  get maskedPhone(): string {
    const p = this.phoneNumber;
    if (p.length < 7) {
      return p;
    }
    return p.substring(0, 3) + '****' + p.substring(p.length - 4);
  }

  backToPhoneInput(): void {
    this.phoneStep = PhoneStep.INPUT_PHONE;
    this.smsCode = '';
    this.errorMsg = '';
  }

  // ─── 二维码登录 ───────────────────────────────────────────────

  async startQRCodeLogin(): Promise<void> {
    this.stopQRCodePoll();
    const generation = this.qrGeneration;
    this.qrCodeStat = QRCodeStat.LOADING;
    this.qrCodeUrl = '';
    this.errorMsg = '';
    if (this.deviceId.length === 0) {
      // 与登录后的所有请求使用同一个 x-rpc-device_id（TeyvatGuide 做法），不再为扫码单独随机生成
      this.deviceId = ApiConfig.getDeviceIdSync();
    }
    this.isQrFetching = true;
    this.isLoading = true;
    try {
      const result = await AuthRepository.fetchQRCode(this.deviceId);
      if (generation !== this.qrGeneration) {
        return;
      }
      this.qrCodeUrl = result.url;
      this.qrTicket = result.ticket;
      this.qrCodeStat = QRCodeStat.READY;
      this.startQRCodePoll(generation);
    } catch (error) {
      if (generation !== this.qrGeneration) {
        return;
      }
      const msg = error instanceof Error ? error.message : `${error}`;
      Logger.error(TAG, `startQRCodeLogin failed: ${msg}`);
      this.qrCodeStat = QRCodeStat.ERROR;
      this.errorMsg = msg;
    } finally {
      // 停止 / 重启二维码流程时，stopQRCodePoll 已经清理过 loading 状态
      if (this.isQrFetching && generation === this.qrGeneration) {
        this.isQrFetching = false;
        this.isLoading = false;
      }
    }
  }

  async refreshQRCode(): Promise<void> {
    await this.startQRCodeLogin();
  }

  private startQRCodePoll(generation: number): void {
    this.pollTimer = setInterval(async () => {
      if (generation !== this.qrGeneration || this.isPollInFlight) {
        return;
      }
      this.isPollInFlight = true;
      try {
        await this.pollQRCodeStatus(generation);
      } finally {
        if (generation === this.qrGeneration) {
          this.isPollInFlight = false;
        }
      }
    }, QR_POLL_INTERVAL_MS) as number;
  }

  private stopQRCodePoll(): void {
    this.qrGeneration += 1;
    this.isPollInFlight = false;
    if (this.pollTimer !== -1) {
      clearInterval(this.pollTimer);
      this.pollTimer = -1;
    }
    if (this.isQrFetching) {
      this.isQrFetching = false;
      this.isLoading = false;
    }
  }

  private async pollQRCodeStatus(generation: number): Promise<void> {
    try {
      const result = await AuthRepository.queryQRCode(this.deviceId, this.qrTicket);
      if (generation !== this.qrGeneration) {
        return;
      }
      if (result.stat === 'scanned') {
        this.qrCodeStat = QRCodeStat.SCANNED;
      } else if (result.stat === 'confirmed') {
        this.stopQRCodePoll();
        if (result.confirmed === null) {
          this.qrCodeStat = QRCodeStat.ERROR;
          this.errorMsg = 'qr_confirm_missing_token';
          return;
        }
        this.qrCodeStat = QRCodeStat.CONFIRMED;
        await this.handleQRCodeConfirmed(result.confirmed);
      } else if (result.stat === 'expired') {
        this.stopQRCodePoll();
        this.qrCodeStat = QRCodeStat.EXPIRED;
      }
    } catch (error) {
      if (generation !== this.qrGeneration) {
        return;
      }
      const msg = error instanceof Error ? error.message : `${error}`;
      Logger.warn(TAG, `pollQRCodeStatus failed: ${msg}`);
    }
  }

  private async handleQRCodeConfirmed(confirmed: QRCodeConfirmedData): Promise<void> {
    this.isLoading = true;
    try {
      // 新版 passport API 直接返回 stoken、mid，无需 getTokenByGameToken 转换。
      // ltoken 和 cookie_token 通过 stoken 换取（与 TeyvatGuide 扫码流程一致）。
      const stoken = confirmed.stoken;
      const mid = confirmed.mid.length > 0 ? confirmed.mid : confirmed.uid;
      const ltoken = await AuthRepository.getLTokenBySToken(stoken, mid);

      // 原先会先调用 V2 接口 /account/auth/api/getCookieBySToken，国服返回 404 后才退回此接口，现已去掉 V2 调用。
      const cookieToken = await AuthRepository.getCookieBySToken(stoken, mid);

      const cookie = this.buildCookie(confirmed.uid, confirmed.uid, stoken, mid, ltoken, cookieToken);
      const isSuccess = await this.finalizeLogin(confirmed.uid, cookie);
      if (!isSuccess) {
        this.qrCodeStat = QRCodeStat.ERROR;
      }
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

  async loginByCookie(): Promise<void> {
    if (this.cookieInput.trim().length === 0) {
      this.errorMsg = 'cookie_empty';
      return;
    }
    this.isLoading = true;
    this.errorMsg = '';
    try {
      const rawCookie = this.cookieInput.trim();
      const stoken = BBSRepository.extractCookieField(rawCookie, 'stoken');
      if (stoken.length === 0) {
        this.shouldShowStokenMissingDialog = true;
        return;
      }

      // 解析用户输入的 Cookie 字段并重新构建 Cookie 字符串（三种登录方式共用 buildCookie）
      const cookie = this.buildCookie(
        BBSRepository.extractCookieField(rawCookie, 'account_id'),
        BBSRepository.extractCookieField(rawCookie, 'ltuid'),
        stoken,
        BBSRepository.extractCookieField(rawCookie, 'mid'),
        BBSRepository.extractCookieField(rawCookie, 'ltoken'),
        BBSRepository.extractCookieField(rawCookie, 'cookie_token'));

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

  private async finalizeLogin(username: string, cookie: string): Promise<boolean> {
    await CoreInitializer.waitForReady();
    let loginResult: LoginResult;
    try {
      loginResult = await CoreInitializer.bbsRepository.login(username, cookie);
    } catch (error) {
      const msg = error instanceof Error ? error.message : `${error}`;
      Logger.error(TAG, `login failed: ${msg}`);
      this.errorMsg = msg;
      return false;
    }
    const roleVMs: MyGameRoleVM[] = [];
    for (let i = 0; i < loginResult.roles.length; i++) {
      const r = loginResult.roles[i];
      const rawStats = RoleStatItem.parseAll(r.statsJson);
      const stats: GameStatItem[] = [];
      for (let j = 0; j < rawStats.length; j++) {
        stats.push(new GameStatItem(rawStats[j].name, rawStats[j].value));
      }
      roleVMs.push(new MyGameRoleVM(
        r.gameId, getGameName(r.gameId), getGameColor(r.gameId),
        r.roleId, r.nickname, getServerDisplayName(r.server, r.gameId) ?? r.server,
        r.level, r.bgImageUrl, stats
      ));
    }
    this.loginedAccountVM = new MyAccountVM(
      loginResult.accountId, loginResult.username, roleVMs,
      loginResult.nickname, loginResult.avatarUrl, loginResult.uid
    );
    this.loginedAccountId = loginResult.accountId;
    // 重新登录成功：移除该账号的过期标记（账号详情页的"重新登录 / 刷新 Cookie"随之隐藏）
    CookieExpiredSignal.getInstance().clearExpired(loginResult.username);
    this.isLoginSuccess = true;
    return true;
  }

  // ─── 工具方法 ─────────────────────────────────────────────────

  /** 填充 Cookie 字段并构造成 Cookie 字符串（手机号 / 二维码 / Cookie 三种登录共用） */
  private buildCookie(accountId: string, ltuid: string, stoken: string, mid: string,
                      ltoken: string, cookieToken: string): string {
    const fields = new LoginCookieFields();
    fields.accountId = accountId;
    fields.ltoken = ltoken;
    fields.cookieToken = cookieToken;
    fields.ltuid = ltuid;
    fields.stoken = stoken;
    fields.mid = mid;
    // v2 Cookie 字段（设备指纹）
    fields.deviceFp = ApiConfig.getDeviceFp();
    fields.mhyUuid = ApiConfig.getDeviceIdSync();
    return AuthRepository.buildCookieString(fields);
  }

  private startCooldown(seconds: number): void {
    this.stopCooldown();
    this.smsCooldown = seconds;
    this.cooldownTimer = setInterval(() => {
      this.smsCooldown -= 1;
      if (this.smsCooldown <= 0) {
        this.smsCooldown = 0;
        this.stopCooldown();
      }
    }, COOLDOWN_TICK_MS) as number;
  }

  private stopCooldown(): void {
    if (this.cooldownTimer !== -1) {
      clearInterval(this.cooldownTimer);
      this.cooldownTimer = -1;
    }
  }
}
