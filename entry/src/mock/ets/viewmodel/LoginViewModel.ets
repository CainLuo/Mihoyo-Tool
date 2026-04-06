/**
 * LoginViewModel.ets — Mock 版本（source set: mock）
 *
 * 接口与 entry/src/main/ets/viewmodel/LoginViewModel.ets 完全一致，
 * 所有登录方法直接返回 Mock 数据，不发起任何真实网络请求。
 */

import { MmtData, GeetestV4Data, CoreInitializer, AccountRow, GameRoleRow } from 'core';
import { LoginTab, PhoneStep, QRCodeStat } from '../constants/LoginTabEnum';
import { MyAccountVM } from '../../main/ets/components/my/MyModels';
import hilog from '@ohos.hilog';

export { LoginTab, PhoneStep, QRCodeStat };

const TAG: string = 'LoginViewModel[Mock]';
const DOMAIN: number = 0x0001;

function logInfo(msg: string): void {
  hilog.info(DOMAIN, TAG, msg);
}
function logError(msg: string): void {
  hilog.error(DOMAIN, TAG, msg);
}

const MOCK_ACCOUNT_ID: string = '182692936';
const MOCK_COOKIE: string =
  'account_id=182692936; cookie_token=mock_token; ltoken=mock_ltoken; ltuid=182692936';

/** 构建 mock 游戏角色列表（原神 + 星铁） */
function buildMockRoleRows(accountId: number): GameRoleRow[] {
  const roles: GameRoleRow[] = [];

  const genshin = new GameRoleRow();
  genshin.id = 0;
  genshin.accountId = accountId;
  genshin.gameId = 'genshin';
  genshin.roleId = '109050292';
  genshin.nickname = 'Mock旅行者';
  genshin.level = 60;
  genshin.server = 'cn_gf01';
  genshin.bgImageUrl = '';
  genshin.statsJson = '';
  roles[roles.length] = genshin;

  const starrail = new GameRoleRow();
  starrail.id = 0;
  starrail.accountId = accountId;
  starrail.gameId = 'starrail';
  starrail.roleId = '102731382';
  starrail.nickname = 'Mock开拓者';
  starrail.level = 70;
  starrail.server = 'prod_gf_cn';
  starrail.bgImageUrl = '';
  starrail.statsJson = '';
  roles[roles.length] = starrail;

  return roles;
}

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
  /** 登录成功后组装好的账号 VM（mock 环境不组装，保持 null） */
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

  private pollTimer: number = -1;
  private mockPollCount: number = 0;

  // ── Cookie 登录状态 ───────────────────────────────────────────
  @Trace cookieInput: string = '';

  // ─── 通用 ─────────────────────────────────────────────────────

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

  /** 申请人机验证任务（mock 直接返回） */
  async prepareSendSms(): Promise<MmtData> {
    this.errorMsg = '';
    const mock: MmtData = { mmt_key: 'mock_mmt_key', success: 1 };
    return mock;
  }

  /** 发送短信验证码（mock 直接进入下一步） */
  async sendSmsCode(
    _v4Data?: GeetestV4Data,
    _v3Challenge?: string,
    _v3Validate?: string,
    _v3Seccode?: string
  ): Promise<void> {
    if (this.phoneNumber.length === 0) {
      this.errorMsg = 'phone_empty';
      return;
    }
    this.isLoading = true;
    await LoginViewModel.delay(500);
    this.phoneStep = PhoneStep.INPUT_CODE;
    this.startCooldown(60);
    this.isLoading = false;
    logInfo(`Mock 短信已"发送"至 ${this.phoneNumber}`);
  }

  /** 用短信验证码登录（mock 直接写入 DB） */
  async loginByPhone(): Promise<void> {
    if (this.smsCode.length === 0) {
      this.errorMsg = 'code_empty';
      return;
    }
    this.isLoading = true;
    this.errorMsg = '';
    try {
      await LoginViewModel.delay(800);
      await this.finalizeLogin(MOCK_ACCOUNT_ID, MOCK_COOKIE);
    } catch (error) {
      const msg = error instanceof Error ? error.message : `${error}`;
      logError(`loginByPhone mock failed: ${msg}`);
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

  /** 开始二维码登录（mock 生成假二维码，3 次轮询后自动确认） */
  async startQRCodeLogin(): Promise<void> {
    this.stopQRCodePoll();
    this.qrCodeStat = QRCodeStat.LOADING;
    this.qrCodeUrl = '';
    this.errorMsg = '';
    this.mockPollCount = 0;
    await LoginViewModel.delay(300);
    this.qrCodeUrl = 'https://user.mihoyo.com/qr.html#/login?app_id=4&ticket=mock_ticket';
    this.qrCodeStat = QRCodeStat.READY;
    this.startQRCodePoll();
    logInfo('Mock 二维码已生成');
  }

  /** 刷新二维码 */
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
    this.mockPollCount++;
    if (this.mockPollCount <= 2) {
      this.qrCodeStat = QRCodeStat.SCANNED;
    } else {
      this.stopQRCodePoll();
      this.qrCodeStat = QRCodeStat.CONFIRMED;
      this.isLoading = true;
      try {
        await LoginViewModel.delay(500);
        await this.finalizeLogin(MOCK_ACCOUNT_ID, MOCK_COOKIE);
      } catch (error) {
        const msg = error instanceof Error ? error.message : `${error}`;
        logError(`QR confirmed mock failed: ${msg}`);
        this.errorMsg = msg;
        this.qrCodeStat = QRCodeStat.ERROR;
      } finally {
        this.isLoading = false;
      }
    }
  }

  // ─── Cookie 登录 ──────────────────────────────────────────────

  /** 用手动输入的 Cookie 登录（mock 直接写入 DB） */
  async loginByCookie(): Promise<void> {
    if (this.cookieInput.trim().length === 0) {
      this.errorMsg = 'cookie_empty';
      return;
    }
    this.isLoading = true;
    this.errorMsg = '';
    try {
      await LoginViewModel.delay(600);
      const cookie = this.cookieInput.trim();
      const accountId = LoginViewModel.extractCookieField(cookie, 'account_id');
      const username = accountId.length > 0 ? accountId : MOCK_ACCOUNT_ID;
      await this.finalizeLogin(username, cookie);
    } catch (error) {
      const msg = error instanceof Error ? error.message : `${error}`;
      logError(`loginByCookie mock failed: ${msg}`);
      this.errorMsg = msg;
    } finally {
      this.isLoading = false;
    }
  }

  // ─── 登录成功统一流程 ─────────────────────────────────────────

  /**
   * 登录成功后统一处理：写账号 → 写游戏角色 → 通知 View
   * mock 环境不拉取网络数据，直接写入预设的 mock 角色。
   */
  private async finalizeLogin(username: string, cookie: string): Promise<void> {
    // 1. 写入账号
    const now = Math.floor(Date.now() / 1000);
    const accountRow = new AccountRow();
    accountRow.id = 0;
    accountRow.username = username;
    accountRow.cookie = cookie;
    accountRow.isActive = 1;
    accountRow.createTime = now;
    accountRow.updateTime = now;
    await CoreInitializer.bbsRepository.saveAccount(accountRow);

    // 2. 查询自增 id
    const savedAccount = await CoreInitializer.bbsRepository.getAccountByUsername(username);
    const accountId = savedAccount !== null ? savedAccount.id : 0;

    // 3. 写入 mock 游戏角色
    const roleRows = buildMockRoleRows(accountId);
    await CoreInitializer.bbsRepository.saveGameRoles(roleRows);

    logInfo(`Mock 登录成功，accountId=${accountId}`);
    this.loginedAccountId = accountId;
    this.loginSuccess = true;
  }

  // ─── 工具方法 ─────────────────────────────────────────────────

  /** 从 Cookie 字符串中提取指定字段值 */
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

  private static delay(ms: number): Promise<void> {
    return new Promise<void>((resolve) => {
      setTimeout(() => { resolve(); }, ms);
    });
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
