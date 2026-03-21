/**
 * CharactersViewModel.ets
 *
 * 角色 Tab ViewModel。
 *
 * 数据维度：账号 × 游戏
 *   - accounts: 所有账号列表（用于顶部账号选择器）
 *   - selectedAccountIdx: 当前选中账号下标
 *   - games: 当前账号下有角色数据的游戏列表
 *   - selectedGameIdx: 当前选中游戏下标
 *   - characters: 当前账号 × 当前游戏的角色摘要列表
 *
 * 状态机（viewState）：
 *   loading  — 冷启动读 DB
 *   empty    — 无账号或无角色数据，显示 Placeholder
 *   data     — 正常展示角色网格
 */

import { AccountRepository, AccountWithRoles, CharacterRepository, SyncMetaDao, DataType, CoreInitializer } from 'core';
import { GameDataSummary } from 'core';
import { Logger } from '../utils/Logger';
import { ViewState } from '../constants/ViewStates';
import {
  GAME_GENSHIN,
  GAME_STARRAIL,
  GAME_ZZZ,
  GAME_HONKAI3
} from '../components/home/HomeModels';

const TAG: string = 'CharactersViewModel';
const SYNC_INTERVAL_MS: number = 30 * 60 * 1000;

/** 账号选项（用于 Select 组件） */
export class AccountOption {
  accountId: number = 0;
  username: string = '';

  constructor(accountId: number, username: string) {
    this.accountId = accountId;
    this.username = username;
  }
}

/** 游戏 Tab 项 */
export class GameTabItem {
  gameId: string = '';
  roleUid: string = '';
  gameName: Resource;

  constructor(gameId: string, roleUid: string, gameName: Resource) {
    this.gameId = gameId;
    this.roleUid = roleUid;
    this.gameName = gameName;
  }
}

/** CharactersViewModel @Monitor 路径常量类型 */
export class CharactersViewModelKeys {
  networkErrorMsg: string = 'vm.networkErrorMsg';
}

@ObservedV2
export class CharactersViewModel {
  /** @Monitor 路径常量，View 层必须通过此对象引用，禁止直接写字符串字面量 */
  static readonly KEYS: CharactersViewModelKeys = new CharactersViewModelKeys();

  @Trace viewState: ViewState = ViewState.LOADING;
  @Trace accountOptions: AccountOption[] = [];
  @Trace selectedAccountIdx: number = 0;
  @Trace gameTabs: GameTabItem[] = [];
  @Trace selectedGameIdx: number = 0;
  @Trace characters: GameDataSummary[] = [];
  @Trace isRefreshing: boolean = false;
  @Trace networkErrorMsg: string = '';

  // 原始账号+角色数据，切换时复用
  private allPairs: AccountWithRoles[] = [];

  // ─── 公开方法 ────────────────────────────────────────────────

  async loadData(): Promise<void> {
    // 等待 RDB 初始化完成（CoreInitializer.initCore 是异步的）
    await CoreInitializer.waitForReady();
    this.viewState = ViewState.LOADING;
    try {
      this.allPairs = await AccountRepository.findAllAccountsWithRoles();
      if (this.allPairs.length === 0) {
        this.viewState = ViewState.EMPTY;
        return;
      }
      this.accountOptions = CharactersViewModel.buildAccountOptions(this.allPairs);
      this.selectedAccountIdx = 0;
      await this.reloadGameTabs();
    } catch (error) {
      const msg = error instanceof Error ? error.message : `${error}`;
      Logger.error(TAG, `loadData failed: ${msg}`);
      this.viewState = ViewState.EMPTY;
    }
    // 按需同步：若本地无数据则保持 LOADING 直到同步完成，有数据则后台静默同步
    await this.syncIfNeeded();
  }

  /** 切换账号（Select 组件回调） */
  async selectAccount(idx: number): Promise<void> {
    if (idx === this.selectedAccountIdx) {
      return;
    }
    this.selectedAccountIdx = idx;
    this.selectedGameIdx = 0;
    await this.reloadGameTabs();
  }

  /** 切换游戏 Tab */
  async selectGame(idx: number): Promise<void> {
    if (idx === this.selectedGameIdx) {
      return;
    }
    this.selectedGameIdx = idx;
    await this.reloadCharacters();
  }

  /** 手动刷新：强制同步当前游戏角色 */
  async refresh(): Promise<void> {
    if (this.isRefreshing || this.gameTabs.length === 0) {
      return;
    }
    this.isRefreshing = true;
    try {
      const tab = this.gameTabs[this.selectedGameIdx];
      const pair = this.allPairs[this.selectedAccountIdx];
      await CharacterRepository.syncCharacters(
        tab.gameId, tab.roleUid, this.findServer(tab.roleUid), pair.account.cookie
      );
      await this.reloadCharacters();
    } catch (error) {
      const msg = error instanceof Error ? error.message : `${error}`;
      Logger.error(TAG, `refresh failed: ${msg}`);
      this.networkErrorMsg = msg;
    } finally {
      this.isRefreshing = false;
    }
  }

  // ─── 私有方法 ────────────────────────────────────────────────

  /** 重建当前账号的游戏 Tab 列表，并加载第一个游戏的角色 */
  private async reloadGameTabs(): Promise<void> {
    if (this.allPairs.length === 0) {
      this.viewState = ViewState.EMPTY;
      return;
    }
    const pair = this.allPairs[this.selectedAccountIdx];
    const tabs: GameTabItem[] = [];
    for (let i = 0; i < pair.roles.length; i++) {
      const role = pair.roles[i];
      tabs[tabs.length] = new GameTabItem(
        role.gameId,
        role.roleId,
        CharactersViewModel.gameNameResource(role.gameId)
      );
    }
    this.gameTabs = tabs;
    if (tabs.length === 0) {
      this.characters = [];
      this.viewState = ViewState.EMPTY;
      return;
    }
    await this.reloadCharacters();
  }

  /** 从 DB 加载当前选中游戏的角色列表 */
  private async reloadCharacters(): Promise<void> {
    if (this.gameTabs.length === 0) {
      this.characters = [];
      this.viewState = ViewState.EMPTY;
      return;
    }
    const tab = this.gameTabs[this.selectedGameIdx];
    try {
      const rows = await CharacterRepository.findAll(tab.gameId, tab.roleUid);
      this.characters = rows;
      if (rows.length > 0) {
        this.viewState = ViewState.DATA;
      }
      // 本地无数据时不改变 viewState，保持 LOADING 等待 syncIfNeeded 完成后再更新
    } catch (error) {
      const msg = error instanceof Error ? error.message : `${error}`;
      Logger.error(TAG, `reloadCharacters failed: ${msg}`);
      this.characters = [];
      this.viewState = ViewState.EMPTY;
    }
  }

  /** 后台按需同步：遍历当前账号所有游戏角色 */
  private async syncIfNeeded(): Promise<void> {
    if (this.allPairs.length === 0) {
      return;
    }
    const pair = this.allPairs[this.selectedAccountIdx];
    for (let i = 0; i < pair.roles.length; i++) {
      const role = pair.roles[i];
      if (role.gameId !== GAME_GENSHIN) {
        continue; // 目前只支持原神
      }
      let needed = false;
      try {
        needed = await SyncMetaDao.needsSync(role.gameId, role.roleId, DataType.CHARACTER, SYNC_INTERVAL_MS);
      } catch (_) {
        needed = true;
      }
      if (!needed) {
        continue;
      }
      try {
        await CharacterRepository.syncCharacters(
          role.gameId, role.roleId, role.server, pair.account.cookie
        );
        // 如果同步的正好是当前显示的游戏，刷新列表
        if (this.gameTabs.length > 0) {
          const current = this.gameTabs[this.selectedGameIdx];
          if (current.gameId === role.gameId && current.roleUid === role.roleId) {
            await this.reloadCharacters();
          }
        }
      } catch (error) {
        const msg = error instanceof Error ? error.message : `${error}`;
        Logger.warn(TAG, `syncIfNeeded failed for ${role.gameId}/${role.roleId}: ${msg}`);
        if (this.viewState !== ViewState.DATA) {
          this.networkErrorMsg = msg;
        }
      }
    }
    // 所有同步完成后，若仍处于 LOADING（本地始终无数据），转为 EMPTY
    if (this.viewState === ViewState.LOADING) {
      this.viewState = ViewState.EMPTY;
    }
  }

  private findServer(roleUid: string): string {
    if (this.allPairs.length === 0) {
      return '';
    }
    const pair = this.allPairs[this.selectedAccountIdx];
    for (let i = 0; i < pair.roles.length; i++) {
      if (pair.roles[i].roleId === roleUid) {
        return pair.roles[i].server;
      }
    }
    return '';
  }

  private static buildAccountOptions(pairs: AccountWithRoles[]): AccountOption[] {
    const opts: AccountOption[] = [];
    for (let i = 0; i < pairs.length; i++) {
      opts[opts.length] = new AccountOption(pairs[i].account.id, pairs[i].account.username);
    }
    return opts;
  }

  static toSelectOptions(opts: AccountOption[]): SelectOption[] {
    const result: SelectOption[] = [];
    for (let i = 0; i < opts.length; i++) {
      const so: SelectOption = { value: opts[i].username };
      result[result.length] = so;
    }
    return result;
  }

  private static gameNameResource(gameId: string): Resource {
    if (gameId === GAME_GENSHIN) {
      return $r('app.string.game_name_genshin');
    }
    if (gameId === GAME_STARRAIL) {
      return $r('app.string.game_name_starrail');
    }
    if (gameId === GAME_ZZZ) {
      return $r('app.string.game_name_zzz');
    }
    if (gameId === GAME_HONKAI3) {
      return $r('app.string.game_name_honkai3');
    }
    return $r('app.string.game_name_genshin');
  }
}
