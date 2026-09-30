/**
 * LoginViewModel.ets（release 版，仅支持二维码和 Cookie 登录）
 *
 * 手机号登录相关代码已物理隔离至 src/internal/ets/，
 * 本文件不包含任何手机号字段、方法或 API 调用。
 */

import {
  AuthRepository,
  QRCodeConfirmedData,
  LoginCookieFields,
  RoleStatItem,
  CoreInitializer,
  LoginResult,
  BBSRepository,
  ApiConfig
} from 'core';
import { Logger } from 'core';
import { LoginTab, QRCodeStat } from '../constants/LoginTabEnum';
import { MyAccountVM, MyGameRoleVM, GameStatItem } from '../models/MyModels';
import { serverDisplayName } from '../utils/ServerNameUtil';
import { gameIdToName, gameIdToColor } from '../utils/GameIdUtil';

export { LoginTab, QRCodeStat };

const TAG: string = 'LoginViewModel';

// ─── @Monitor 路径常量（必须是顶层 const，ArkTS 不支持通过实例访问作为编译时常量） ───

/** LoginViewModel.loginSuccess 路径 */
export const LOGIN_VM_SUCCESS = 'vm.loginSuccess';
/** LoginViewModel.loginedAccountId 路径 */
export const LOGIN_VM_ACCOUNT_ID = 'vm.loginedAccountId';
/** LoginViewModel.loginedAccountVM 路径 */
export const LOGIN_VM_ACCOUNT_VM = 'vm.loginedAccountVM';
/** LoginViewModel.showNoStokenDialog 路径 */
export const LOGIN_VM_NO_STOKEN = 'vm.showNoStokenDialog';

@ObservedV2
export class LoginViewModel {

  // ── 通用状态 ──────────────────────────────────────────────────
  /** release 版默认 Tab 为二维码 */
  @Trace activeTab: LoginTab = LoginTab.QRCODE;
  @Trace isLoading: boolean = false;
  @Trace errorMsg: string = '';
  @Trace showNoStokenDialog: boolean = false;
  @Trace loginSuccess: boolean = false;
  @Trace loginedAccountId: string = '';
  @Trace loginedAccountVM: MyAccountVM | null = null;

  // ── 二维码登录状态 ────────────────────────────────────────────
  @Trace qrCodeUrl: string = '';
  @Trace qrCodeStat: QRCodeStat = QRCodeStat.LOADING;

  private qrTicket: string = '';
  private deviceId: string = '';
  private pollTimer: number = -1;

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
  }

  // ─── 二维码登录 ───────────────────────────────────────────────

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

  async refreshQRCode(): Promise<void> {
    await this.startQRCodeLogin();
  }

  private startQRCodePoll(): void {
    this.pollTimer = setInterval(async () => {
      await this.pollQRCodeStatus();
    }, 2000) as number;
  }

  private stopQRCodePoll(): void {
    if (this.pollTimer !== -1) {
      clearInterval(this.pollTimer);
      this.pollTimer = -1;
    }
  }

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

  private async handleQRCodeConfirmed(confirmed: QRCodeConfirmedData): Promise<void> {
    this.isLoading = true;
    try {
      // 新版 passport API 直接返回 stoken、ltoken、mid，无需 getTokenByGameToken 转换
      const stoken = confirmed.stoken;
      const ltoken = confirmed.ltoken;
      const mid = confirmed.mid.length > 0 ? confirmed.mid : confirmed.uid;
      // cookie_token 仍需通过 stoken 换取
      const cookieToken = await AuthRepository.getCookieBySToken(stoken, mid);
      const fields = new LoginCookieFields();
      fields.accountId = confirmed.uid;
      fields.cookieToken = cookieToken;
      fields.ltoken = ltoken;
      fields.ltuid = confirmed.uid;
      fields.stoken = stoken;
      fields.mid = mid;
      // v2 Cookie 字段（设备指纹）
      fields.deviceFp = ApiConfig.getDeviceFp();
      fields.mhyUuid = ApiConfig.getDeviceIdSync();
      const cookie = AuthRepository.buildCookieString(fields);
      Logger.info(TAG, `buildCookieString result: ${cookie}`);
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
        this.showNoStokenDialog = true;
        return;
      }

      // 解析用户输入的 Cookie 字段
      const fields = new LoginCookieFields();
      fields.accountId = BBSRepository.extractCookieField(rawCookie, 'account_id');
      fields.cookieToken = BBSRepository.extractCookieField(rawCookie, 'cookie_token');
      fields.ltoken = BBSRepository.extractCookieField(rawCookie, 'ltoken');
      fields.ltuid = BBSRepository.extractCookieField(rawCookie, 'ltuid');
      fields.stoken = stoken;
      fields.mid = BBSRepository.extractCookieField(rawCookie, 'mid');

      // 补充 v2 Cookie 字段（设备指纹）
      fields.deviceFp = ApiConfig.getDeviceFp();
      fields.mhyUuid = ApiConfig.getDeviceIdSync();

      // 重新构建 Cookie 字符串
      const cookie = AuthRepository.buildCookieString(fields);
      Logger.info(TAG, `loginByCookie: buildCookieString result: ${cookie}`);

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

  private async finalizeLogin(username: string, cookie: string): Promise<void> {
    await CoreInitializer.waitForReady();
    let loginResult: LoginResult;
    try {
      loginResult = await CoreInitializer.bbsRepository.login(username, cookie);
    } catch (error) {
      const msg = error instanceof Error ? error.message : `${error}`;
      Logger.error(TAG, `login failed: ${msg}`);
      this.errorMsg = msg;
      return;
    }
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
}
