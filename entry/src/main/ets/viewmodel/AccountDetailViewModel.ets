/**
 * AccountDetailViewModel.ets — 账号详情页 ViewModel
 */
import { CoreInitializer } from 'core';
import { Logger } from 'core';
import { WidgetFormIdStore } from '../widget/utils/WidgetFormIdStore';

const TAG: string = 'AccountDetailViewModel';

// ─── @Monitor 路径常量（必须是顶层 const，ArkTS 不支持通过实例访问作为编译时常量） ───

/** AccountDetailViewModel.deleted 路径 */
export const ACCOUNT_DETAIL_VM_DELETED = 'vm.deleted';
/** AccountDetailViewModel.errorMsg 路径 */
export const ACCOUNT_DETAIL_VM_ERROR = 'vm.errorMsg';

@ObservedV2
export class AccountDetailViewModel {

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
