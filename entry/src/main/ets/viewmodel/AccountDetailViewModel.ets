/**
 * AccountDetailViewModel.ets — 账号详情页 ViewModel
 */
import { CoreInitializer } from 'core';
import { Logger } from 'core';
import { WidgetFormIdStore } from '../widget/utils/WidgetFormIdStore';
import { CookieExpiredSignal } from '../utils/CookieExpiredSignal';
import { AccountSignal } from '../utils/AccountSignal';
import { DeviceFpCenter } from '../utils/DeviceFpCenter';
import { common } from '@kit.AbilityKit';

const TAG: string = 'AccountDetailViewModel';

// ─── @Monitor 路径常量（必须是顶层 const，ArkTS 不支持通过实例访问作为编译时常量） ───

/** AccountDetailViewModel.deleted 路径 */
export const ACCOUNT_DETAIL_VM_DELETED = 'vm.deleted';
/** AccountDetailViewModel.errorMsg 路径 */
export const ACCOUNT_DETAIL_VM_ERROR = 'vm.errorMsg';

/** 刷新 Cookie 结果 */
export enum RefreshCookieResult {
  NONE = '',
  SUCCESS = 'success',
  FAILED = 'failed',
}

@ObservedV2
export class AccountDetailViewModel {

  /** 删除成功信号，View 层监听后执行 pop */
  @Trace deleted: boolean = false;
  @Trace errorMsg: string = '';
  /** 是否正在刷新 Cookie */
  @Trace isRefreshingCookie: boolean = false;
  /** 刷新 Cookie 结果信号，View 层监听后提示 */
  @Trace refreshCookieResult: RefreshCookieResult = RefreshCookieResult.NONE;
  /** 刷新失败原因（用于提示） */
  @Trace refreshCookieError: string = '';
  /** 是否正在重新生成设备指纹 */
  @Trace isRegeneratingFp: boolean = false;
  /** 重新生成设备指纹结果信号（复用 RefreshCookieResult 的取值），View 层监听后提示 */
  @Trace regenerateFpResult: RefreshCookieResult = RefreshCookieResult.NONE;

  /**
   * 重新生成设备指纹（与 PizzaHelperUnited「重新生成设备指纹」一致），用于 5003 / 10041。
   * 设备指纹全 App 共用，对所有账号生效；成功后首页 / 角色页会重新同步。
   */
  async regenerateDeviceFp(context: common.UIAbilityContext): Promise<void> {
    if (this.isRegeneratingFp) {
      return;
    }
    this.isRegeneratingFp = true;
    try {
      await DeviceFpCenter.regenerate(context);
      this.regenerateFpResult = RefreshCookieResult.SUCCESS;
    } catch (error) {
      const msg = error instanceof Error ? error.message : `${error}`;
      Logger.error(TAG, `regenerateDeviceFp failed: ${msg}`);
      this.regenerateFpResult = RefreshCookieResult.FAILED;
    } finally {
      this.isRegeneratingFp = false;
    }
  }

  /**
   * 刷新 Cookie：用 stoken 重新获取 ltoken / cookie_token 并写回 DB（BBSRepository.refreshCookieIfNeeded，
   * 流程与 TeyvatGuide tc-userBadge refreshUser 一致）。成功后移除过期标记并通知各页面重新加载。
   * stoken 不存在或也已失效时会失败，需要重新登录。
   */
  async refreshCookie(username: string): Promise<void> {
    if (this.isRefreshingCookie) {
      return;
    }
    this.isRefreshingCookie = true;
    try {
      const account = await CoreInitializer.bbsRepository.getAccountByUsername(username);
      if (account === null) {
        throw new Error(`account not found: ${username}`);
      }
      await CoreInitializer.bbsRepository.refreshCookieIfNeeded(username, account.cookie);
      Logger.info(TAG, `refreshCookie success: ${username}`);
      CookieExpiredSignal.instance().clearExpired(username);
      AccountSignal.instance().notify();
      this.refreshCookieError = '';
      this.refreshCookieResult = RefreshCookieResult.SUCCESS;
    } catch (error) {
      const msg = error instanceof Error ? error.message : `${error}`;
      Logger.error(TAG, `refreshCookie failed: ${username}: ${msg}`);
      this.refreshCookieError = msg;
      this.refreshCookieResult = RefreshCookieResult.FAILED;
    } finally {
      this.isRefreshingCookie = false;
    }
  }

  async deleteAccount(accountId: string): Promise<void> {
    try {
      await CoreInitializer.bbsRepository.deleteAccount(accountId);
      Logger.info(TAG, `account deleted: ${accountId}`);
      // 清理该账号关联的所有 Widget formId（Preferences 中的配置记录）
      const formIds = WidgetFormIdStore.getFormIdsByAccount(accountId);
      for (let i = 0; i < formIds.length; i++) {
        await WidgetFormIdStore.remove(formIds[i]);
      }
      if (formIds.length > 0) {
        Logger.info(TAG, `cleaned ${formIds.length} widget formIds for account ${accountId}`);
      }
      this.deleted = true;
    } catch (error) {
      const msg = error instanceof Error ? error.message : `${error}`;
      Logger.error(TAG, `deleteAccount failed: ${msg}`);
      this.errorMsg = msg;
    }
  }
}
