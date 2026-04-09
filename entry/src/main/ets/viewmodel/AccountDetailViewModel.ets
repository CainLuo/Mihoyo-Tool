/**
 * AccountDetailViewModel.ets — 账号详情页 ViewModel
 */
import { CoreInitializer } from 'core';
import { Logger } from '../utils/Logger';

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

  async deleteAccount(accountId: number): Promise<void> {
    try {
      await CoreInitializer.bbsRepository.deleteAccount(accountId);
      Logger.info(TAG, `account deleted: ${accountId}`);
      this.deleted = true;
    } catch (error) {
      const msg = error instanceof Error ? error.message : `${error}`;
      Logger.error(TAG, `deleteAccount failed: ${msg}`);
      this.errorMsg = msg;
    }
  }
}
