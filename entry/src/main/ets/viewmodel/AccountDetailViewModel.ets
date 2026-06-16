/**
 * AccountDetailViewModel.ets — 账号详情页 ViewModel
 */
import { CoreInitializer } from 'core';
import { Logger } from 'core';
import { WidgetFormIdStore } from '../widget/utils/WidgetFormIdStore';

const TAG: string = 'AccountDetailViewModel';

/** AccountDetailViewModel @Monitor 路径常量类型 */
export class AccountDetailViewModelKeys {
  deleted: string = 'vm.deleted';
  errorMsg: string = 'vm.errorMsg';
}

@ObservedV2
export class AccountDetailViewModel {
  static readonly KEYS: AccountDetailViewModelKeys = new AccountDetailViewModelKeys();

  /** 删除成功信号，View 层监听后执行 pop */
  @Trace deleted: boolean = false;
  @Trace errorMsg: string = '';

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
