/**
 * MyViewModel.ets — 我的页面 ViewModel
 *
 * 从 Repository 读取账号和角色数据，通过 AuthRepository 补充网络数据（nickname、avatarUrl、statsJson）。
 */
import { CoreInitializer, AuthRepository, RoleStatItem } from 'core';
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
        let roles = await CoreInitializer.bbsRepository.getGameRoles(row.id);

        // 补充/更新 nickname 和 avatarUrl
        if (row.cookie) {
          try {
            const bbsDetail = await AuthRepository.getBbsAccountDetail(row.cookie);
            if (bbsDetail.nickname || bbsDetail.avatarUrl) {
              const updatedRow = await CoreInitializer.bbsRepository.getAccountById(row.id);
              if (updatedRow !== null) {
                updatedRow.nickname = bbsDetail.nickname;
                updatedRow.avatarUrl = bbsDetail.avatarUrl;
                await CoreInitializer.bbsRepository.saveAccount(updatedRow);
              }
              row.nickname = bbsDetail.nickname;
              row.avatarUrl = bbsDetail.avatarUrl;
            }
          } catch (_) {}
        }

        // 如果角色数据缺少 statsJson，调用账号详情接口补充
        let needsRefresh = false;
        for (let i = 0; i < roles.length; i++) {
          if (!roles[i].statsJson || roles[i].statsJson === '') {
            needsRefresh = true;
            break;
          }
        }
        if (needsRefresh && row.cookie) {
          try {
            const detailRoles = await AuthRepository.getGameRecordCard(row.cookie, row.username);
            const updatedRoles = await CoreInitializer.bbsRepository.getGameRoles(row.id);
            for (let i = 0; i < updatedRoles.length; i++) {
              for (let j = 0; j < detailRoles.length; j++) {
                if (detailRoles[j].gameId === updatedRoles[i].gameId) {
                  updatedRoles[i].bgImageUrl = detailRoles[j].bgImageUrl;
                  updatedRoles[i].statsJson = detailRoles[j].statsJson;
                  break;
                }
              }
            }
            await CoreInitializer.bbsRepository.saveGameRoles(updatedRoles);
            roles = await CoreInitializer.bbsRepository.getGameRoles(row.id);
          } catch (_) {}
        }

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
