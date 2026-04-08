/**
 * MyViewModel.ets — 我的页面 ViewModel
 *
 * 从 Repository 读取账号和角色数据，通过 AuthRepository 补充网络数据（nickname、avatarUrl、statsJson）。
 */
import { CoreInitializer, RoleStatItem } from 'core';
import { Logger } from '../utils/Logger';
import { MyAccountVM, MyGameRoleVM, GameStatItem } from '../components/my/MyModels';
import { serverDisplayName } from '../utils/ServerNameUtil';
import { gameIdToName, gameIdToColor } from '../utils/GameIdUtil';
import { ViewState } from '../constants/ViewStates';

const TAG: string = 'MyViewModel';

/** MyViewModel @Monitor 路径常量类型 */
export class MyViewModelKeys {
  viewState: string = 'vm.viewState';
  accounts: string = 'vm.accounts';
}

@ObservedV2
export class MyViewModel {
  static readonly KEYS: MyViewModelKeys = new MyViewModelKeys();

  @Trace viewState: ViewState = ViewState.LOADING;
  @Trace accounts: MyAccountVM[] = [];

  async loadAccounts(): Promise<void> {
    try {
      const accountRows = await CoreInitializer.bbsRepository.getAllAccounts();
      const vms: MyAccountVM[] = [];
      for (let ai = 0; ai < accountRows.length; ai++) {
        const row = accountRows[ai];
        // 只读取 DB 数据，不做任何写操作（写操作在登录时完成）
        const roles = await CoreInitializer.bbsRepository.getGameRoles(row.id);
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
            r.level, r.bgImageUrl, stats
          );
        }
        vms[vms.length] = new MyAccountVM(row.id, row.username, roleVMs, row.nickname, row.avatarUrl);
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
