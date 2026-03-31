/**
 * MyViewModel.ets — 我的页面 ViewModel
 */
import { AccountRepository, AuthRepository, RoleStatItem } from 'core';
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
      const accountRows = await AccountRepository.findAllAccounts();
      const vms: MyAccountVM[] = [];
      for (const row of accountRows) {
        let roles = await AccountRepository.findRolesByAccountId(row.id);

        // 补充/更新 nickname 和 avatarUrl
        if (row.cookie) {
          try {
            const bbsDetail = await AuthRepository.getBbsAccountDetail(row.cookie);
            if (bbsDetail.nickname || bbsDetail.avatarUrl) {
              await AccountRepository.updateNicknameAndAvatar(row.id, bbsDetail.nickname, bbsDetail.avatarUrl);
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
            for (let i = 0; i < roles.length; i++) {
              for (let j = 0; j < detailRoles.length; j++) {
                if (detailRoles[j].gameId === roles[i].gameId) {
                  roles[i].bgImageUrl = detailRoles[j].bgImageUrl;
                  roles[i].statsJson = detailRoles[j].statsJson;
                  break;
                }
              }
            }
            await AccountRepository.replaceRoles(row.id, roles);
            roles = await AccountRepository.findRolesByAccountId(row.id);
          } catch (_) {}
        }

        const roleVMs: MyGameRoleVM[] = [];
        for (const r of roles) {
          const rawStats = RoleStatItem.parseAll(r.statsJson);
          const stats: GameStatItem[] = [];
          for (let i = 0; i < rawStats.length; i++) {
            stats[stats.length] = new GameStatItem(rawStats[i].name, rawStats[i].value);
          }
          roleVMs[roleVMs.length] = new MyGameRoleVM(
            r.gameId, gameIdToName(r.gameId), gameIdToColor(r.gameId),
            r.roleId, r.nickname, serverDisplayName(r.server, r.gameId),
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
