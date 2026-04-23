/**
 * MyViewModel.ets — 我的页面 ViewModel
 *
 * 从 Repository 读取账号和角色数据，通过 AuthRepository 补充网络数据（nickname、avatarUrl、statsJson）。
 * 同时管理 About Section 的日志导出和缓存清理逻辑。
 */
import BuildProfile from 'BuildProfile';
import { CoreInitializer, RoleStatItem } from 'core';
import { Logger } from 'core';
import { ApiLogSystem, LogFileManager, LogExporter } from 'core';
import { common } from '@kit.AbilityKit';
import { MyAccountVM, MyGameRoleVM, GameStatItem } from '../models/MyModels';
import { serverDisplayName } from '../utils/ServerNameUtil';
import { gameIdToName, gameIdToColor, gameIdToLogo } from '../utils/GameIdUtil';
import { ViewState } from '../constants/ViewStates';
import { showFeedback } from '../utils/FeedbackUtil';
import { FeedbackType } from '../constants/FeedbackType';

const TAG: string = 'MyViewModel';

/** MyViewModel @Monitor 路径常量类型 */
export class MyViewModelKeys {
  viewState: string = 'vm.viewState';
  accounts: string = 'vm.accounts';
  logSize: string = 'vm.logSize';
}

@ObservedV2
export class MyViewModel {
  static readonly KEYS: MyViewModelKeys = new MyViewModelKeys();

  @Trace viewState: ViewState = ViewState.LOADING;
  @Trace accounts: MyAccountVM[] = [];
  /** 日志文件大小（格式化后的字符串，如 '1.2 MB'） */
  @Trace logSize: string = '0 KB';

  /** 刷新日志文件大小显示 */
  refreshLogSize(): void {
    ApiLogSystem.getInstance().getFileManager().getTotalLogSize()
      .then((bytes: number) => {
        this.logSize = LogFileManager.formatSize(bytes);
      })
      .catch((_: Error | object) => {
        this.logSize = '0 KB';
      });
  }

  /** 导出日志文件 */
  exportLogs(uiCtx: UIContext): void {
    const ctx = uiCtx.getHostContext() as common.UIAbilityContext;
    LogExporter.export(ctx, BuildProfile.VERSION_NAME ?? '1.0.0')
      .catch((_e: Error | object) => {
        showFeedback(uiCtx, FeedbackType.ERROR, $r('app.string.my_export_logs_failed'));
      });
  }

  /** 清理缓存（弹确认框后删除日志） */
  clearCache(uiCtx: UIContext): void {
    uiCtx.getPromptAction().showDialog({
      title: $r('app.string.my_clear_cache_confirm_title'),
      message: $r('app.string.my_clear_cache_confirm_msg'),
      buttons: [
        { text: $r('app.string.dialog_cancel'), color: '#999999' },
        { text: $r('app.string.dialog_confirm'), color: '#E8534A' },
      ],
    }).then((result) => {
      if (result.index !== 1) { return; }
      ApiLogSystem.getInstance().getFileManager().deleteAllLogs()
        .then((deleteResult) => {
          this.logSize = '0 B';
          if (deleteResult.failedCount > 0) {
            showFeedback(uiCtx, FeedbackType.ERROR,
              $r('app.string.my_clear_cache_failed', deleteResult.failedCount));
          } else {
            const freed = LogFileManager.formatSize(deleteResult.freedBytes);
            showFeedback(uiCtx, FeedbackType.SUCCESS,
              $r('app.string.my_clear_cache_success', freed));
          }
        })
        .catch((_e: Error | object) => {});
    }).catch((_: Error | object) => {});
  }

  async loadAccounts(): Promise<void> {
    try {
      const accountRows = await CoreInitializer.bbsRepository.getAllAccounts();
      const vms: MyAccountVM[] = [];
      for (let ai = 0; ai < accountRows.length; ai++) {
        const row = accountRows[ai];
        // 只读取 DB 数据，不做任何写操作（写操作在登录时完成）
        const roles = await CoreInitializer.bbsRepository.getGameRoles(row.uid);
        const roleVMs: MyGameRoleVM[] = [];
        for (let ri = 0; ri < roles.length; ri++) {
          const r = roles[ri];
          const rawStats = RoleStatItem.parseAll(r.statsJson);
          const stats: GameStatItem[] = [];
          for (let i = 0; i < rawStats.length; i++) {
            stats[stats.length] = new GameStatItem(rawStats[i].name, rawStats[i].value);
          }
          roleVMs[roleVMs.length] = new MyGameRoleVM(
            r.gameId, gameIdToName(r.gameId), gameIdToColor(r.gameId),
            r.roleId, r.nickname, serverDisplayName(r.server, r.gameId) ?? r.server,
            r.level, r.bgImageUrl, stats, gameIdToLogo(r.gameId)
          );
        }
        vms[vms.length] = new MyAccountVM(row.uid, row.username, roleVMs, row.nickname, row.avatarUrl, row.uid);
      }
      this.accounts = vms;
      this.viewState = vms.length > 0 ? ViewState.DATA : ViewState.EMPTY;
    } catch (error) {
      const msg = error instanceof Error ? error.message : `${error}`;
      Logger.error(TAG, `loadAccounts failed: ${msg}`);
      this.viewState = ViewState.EMPTY;
    }
  }
}
