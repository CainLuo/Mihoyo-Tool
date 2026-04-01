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

import { AccountRepository, AccountWithRoles, CharacterRepository, SyncMetaDao, DataType, CoreInitializer, GameDataDao } from 'core';
import { GameDataSummary } from 'core';
import { Logger } from '../utils/Logger';
import { ViewState } from '../constants/ViewStates';
import { AppConstants } from '../constants/AppConstants';
import {
  GAME_GENSHIN,
  GAME_STARRAIL,
  GAME_ZZZ,
  GAME_HONKAI3
} from '../components/home/HomeModels';
import { CharacterDataSource } from '../components/characters/CharacterDataSource';

const TAG: string = 'CharactersViewModel';

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
  refreshCoolingDown: string = 'vm.refreshCoolingDown';
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
  @Trace refreshCoolingDown: boolean = false;

  /** LazyForEach 数据源，随 characters 同步更新 */
  readonly dataSource: CharacterDataSource = new CharacterDataSource();

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
    // 若本地无数据，转为 EMPTY（不再自动触发网络同步）
    if (this.viewState === ViewState.LOADING) {
      this.viewState = ViewState.EMPTY;
    }
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
    this.viewState = ViewState.LOADING;
    await this.reloadCharacters();
  }

  /** 手动刷新：强制同步当前游戏角色，30 分钟内重复触发时发出冷却信号 */
  async refresh(): Promise<void> {
    if (this.isRefreshing || this.gameTabs.length === 0) {
      return;
    }
    // 检查冷却：30 分钟内已同步过则提示用户
    const tab = this.gameTabs[this.selectedGameIdx];
    let inCooldown = false;
    try {
      inCooldown = !(await SyncMetaDao.needsSync(
        tab.gameId, tab.roleUid, DataType.CHARACTER, AppConstants.AUTO_REFRESH_INTERVAL_MS
      ));
    } catch (_) {
      inCooldown = false;
    }
    if (inCooldown) {
      this.refreshCoolingDown = !this.refreshCoolingDown;
      return;
    }
    this.isRefreshing = true;
    try {
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

  /** 强制刷新：跳过冷却检查，由 View 层在用户确认冷却 Dialog 后调用 */
  async forceRefresh(): Promise<void> {
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
      Logger.error(TAG, `forceRefresh failed: ${msg}`);
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
    let tabs: GameTabItem[] = [];

    if (pair.roles.length > 0) {
      // 优先用 game_role_table 里的角色记录构建 Tab
      for (let i = 0; i < pair.roles.length; i++) {
        const role = pair.roles[i];
        tabs[tabs.length] = new GameTabItem(
          role.gameId,
          role.roleId,
          CharactersViewModel.gameNameResource(role.gameId)
        );
      }
    } else {
      // Fallback：game_role_table 为空（Mock 模式或登录时角色拉取失败），
      // 改为查 game_data 里实际有 character 数据的 (gameId, roleUid) 组合
      try {
        const pairs = await GameDataDao.findDistinctGameRoles(DataType.CHARACTER);
        for (let i = 0; i < pairs.length; i++) {
          tabs[tabs.length] = new GameTabItem(
            pairs[i].gameId,
            pairs[i].roleUid,
            CharactersViewModel.gameNameResource(pairs[i].gameId)
          );
        }
      } catch (error) {
        const msg = error instanceof Error ? error.message : `${error}`;
        Logger.warn(TAG, `findDistinctGameRoles failed: ${msg}`);
      }
    }

    this.gameTabs = tabs;
    if (tabs.length === 0) {
      this.setCharacters([]);
      this.viewState = ViewState.EMPTY;
      return;
    }
    // 只加载第一个 tab，其余 tab 切换时懒加载
    await this.reloadCharacters();
  }

  /** 从 DB 加载当前选中游戏的角色列表，若为空则自动触发一次后台同步 */
  private async reloadCharacters(): Promise<void> {
    if (this.gameTabs.length === 0) {
      this.setCharacters([]);
      this.viewState = ViewState.EMPTY;
      return;
    }
    const tab = this.gameTabs[this.selectedGameIdx];
    try {
      const rows = await CharacterRepository.findAll(tab.gameId, tab.roleUid);
      if (rows.length > 0) {
        this.setCharacters(rows);
        this.viewState = ViewState.DATA;
      } else {
        // DB 无数据，先显示 loading，后台触发同步
        this.viewState = ViewState.LOADING;
        this.autoSyncCharacters(tab.gameId, tab.roleUid);
      }
    } catch (error) {
      const msg = error instanceof Error ? error.message : `${error}`;
      Logger.error(TAG, `reloadCharacters failed: ${msg}`);
      this.setCharacters([]);
      this.viewState = ViewState.EMPTY;
    }
  }

  /** 后台静默同步角色数据，完成后若仍是当前选中 tab 则刷新 UI */
  private autoSyncCharacters(gameId: string, roleUid: string): void {
    if (this.allPairs.length === 0) { return; }
    const pair = this.allPairs[this.selectedAccountIdx];
    const server = this.findServer(roleUid);
    CharacterRepository.syncCharacters(gameId, roleUid, server, pair.account.cookie)
      .then(async () => {
        // 只有当前选中 tab 仍是这个游戏时才更新 UI
        if (this.gameTabs.length > 0 &&
            this.gameTabs[this.selectedGameIdx].gameId === gameId &&
            this.gameTabs[this.selectedGameIdx].roleUid === roleUid) {
          const rows = await CharacterRepository.findAll(gameId, roleUid);
          this.setCharacters(rows);
          this.viewState = rows.length > 0 ? ViewState.DATA : ViewState.EMPTY;
        }
      })
      .catch((error: Error | object) => {
        const msg = error instanceof Error ? error.message : `${error}`;
        Logger.warn(TAG, `autoSyncCharacters failed for ${gameId}/${roleUid}: ${msg}`);
        // 无论当前 tab 是否匹配，只要还在 LOADING 就转 EMPTY，避免永久卡住
        if (this.viewState === ViewState.LOADING) {
          this.viewState = ViewState.EMPTY;
        }
      });
  }

  private setCharacters(rows: GameDataSummary[]): void {
    this.characters = rows;
    this.dataSource.setData(rows);
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
