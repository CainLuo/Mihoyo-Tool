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
 *   LOADING  — 冷启动读 DB
 *   EMPTY    — 无账号或无角色数据，显示 Placeholder
 *   DATA     — 正常展示角色网格
 */

import {
  CoreInitializer,
  GameDataSummary,
  AccountRow,
  GameRoleRow,
  SyncQueueRunner,
  Logger,
  GameId,
} from 'core';
import { ViewState, AccountOption, SegmentedTabItem, AppRoutes } from 'basic';
import { CharacterDataSource } from './CharacterDataSource';
import { CharactersDataLoader } from './CharactersDataLoader';
import { CharDetailRouterParam } from 'chardetail';


const TAG: string = 'CharactersViewModel';

/** 内部游戏 Tab 数据，存储 gameId/roleUid，不暴露给 View 层 */
class GameTabInternal {
  gameId: GameId = GameId.GENSHIN;
  roleUid: string = '';
}

/** 角色卡片点击后的路由信息，由 ViewModel 构建，View 层执行跳转 */
export class CardTapRoute {
  /** 路由名称（对应 AppRoutes 常量） */
  routeName: string = '';
  /** 路由参数 */
  param: CharDetailRouterParam = new CharDetailRouterParam();
}

@ObservedV2
export class CharactersViewModel {

  @Trace viewState: ViewState = ViewState.LOADING;
  @Trace accountOptions: AccountOption[] = [];
  /** 是否显示账号切换按钮（多账号时为 true） */
  @Trace shouldShowAccountSwitcher: boolean = false;
  /** 是否显示刷新按钮（有游戏数据时为 true） */
  @Trace shouldShowRefreshButton: boolean = false;
  @Trace selectedAccountIdx: number = 0;
  /** 游戏 Tab 列表（SegmentedTabItem 格式，直接传给 SegmentedTabBar） */
  @Trace gameTabItems: SegmentedTabItem[] = [];
  @Trace selectedGameIdx: number = 0;
  @Trace characters: GameDataSummary[] = [];
  @Trace isRefreshing: boolean = false;
  /** 当前选中游戏 ID（无 Tab 时为 GENSHIN） */
  get currentGameId(): GameId {
    if (this.gameTabsInternal.length > 0) {
      return this.gameTabsInternal[this.selectedGameIdx].gameId;
    }
    return GameId.GENSHIN;
  }
  @Trace networkErrorMsg: string = '';
  @Trace isRefreshCoolingDown: boolean = false;
  /** 手动刷新结果信号：'success' | 'error' | ''，View 层监听后调用 showFeedback */
  @Trace refreshResult: string = '';
  /** 同步正在进行时点击刷新：翻转该值，View 层提示"正在刷新，请勿频繁刷新" */
  @Trace isRefreshBusy: boolean = false;

  /** LazyForEach 数据源，随 characters 同步更新 */
  readonly dataSource: CharacterDataSource = new CharacterDataSource();

  // 原始账号+角色数据，切换时复用
  private allAccounts: AccountRow[] = [];
  private allRoles: GameRoleRow[][] = [];

  /** 内部 Tab 数据，存储 gameId/roleUid，与 gameTabItems 一一对应 */
  private gameTabsInternal: GameTabInternal[] = [];

  /** 切换账号后保留原选中游戏（如该账号也有相同 gameId） */
  private lastSelectedGameId: GameId = GameId.GENSHIN;

  // ─── 公开方法 ────────────────────────────────────────────────

  async loadData(): Promise<void> {
    await CoreInitializer.waitForReady();
    this.viewState = ViewState.LOADING;
    try {
      this.allAccounts = await CoreInitializer.bbsRepository.getAllAccounts();
      this.allRoles = [];
      for (let i = 0; i < this.allAccounts.length; i++) {
        const roles = await CoreInitializer.bbsRepository.getGameRoles(this.allAccounts[i].uid);
        this.allRoles[this.allRoles.length] = roles;
      }
      if (this.allAccounts.length === 0) {
        this.shouldShowAccountSwitcher = false;
        this.shouldShowRefreshButton = false;
        this.viewState = ViewState.EMPTY;
        return;
      }
      this.accountOptions = CharactersDataLoader.buildAccountOptions(this.allAccounts);
      this.shouldShowAccountSwitcher = this.accountOptions.length > 1;
      // 保留上次选中的账号（账号被删除时 clamp 到最后一个）
      this.selectedAccountIdx = Math.min(this.selectedAccountIdx, this.allAccounts.length - 1);
      if (this.selectedAccountIdx < 0) { this.selectedAccountIdx = 0; }
      await this.reloadGameTabs();
    } catch (error) {
      const msg = error instanceof Error ? error.message : `${error}`;
      Logger.error(TAG, `loadData failed: ${msg}`);
      this.viewState = ViewState.EMPTY;
    }
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

  /**
   * 手动刷新：同步当前账号下所有游戏角色（不只是当前 Tab 的游戏）。
   * 所有游戏都在 30 分钟冷却内时发出冷却信号，由用户确认后 forceRefresh。
   */
  async refresh(): Promise<void> {
    if (this.gameTabsInternal.length === 0) {
      return;
    }
    // 先判断是否正在同步（含后台同步，如绝区零逐个请求角色详情），再判断 30 分钟冷却
    if (this.isRefreshing || SyncQueueRunner.isBusy()) {
      this.isRefreshBusy = !this.isRefreshBusy;
      return;
    }
    // 冷却：只要有一个游戏需要同步就不算冷却
    let inCooldown = true;
    const accountId = this.allAccounts[this.selectedAccountIdx].uid;
    for (let i = 0; i < this.gameTabsInternal.length; i++) {
      const tab = this.gameTabsInternal[i];
      try {
        if (await CharactersDataLoader.shouldSyncCharacters(accountId, tab.roleUid, tab.gameId)) {
          inCooldown = false;
          break;
        }
      } catch (_) {
        inCooldown = false;
        break;
      }
    }
    if (inCooldown) {
      this.isRefreshCoolingDown = !this.isRefreshCoolingDown;
      return;
    }
    await this.syncAllGamesAndReload('refresh');
  }

  /** 强制刷新：跳过冷却检查，由 View 层在用户确认冷却 Dialog 后调用 */
  async forceRefresh(): Promise<void> {
    if (this.gameTabsInternal.length === 0) {
      return;
    }
    if (this.isRefreshing || SyncQueueRunner.isBusy()) {
      this.isRefreshBusy = !this.isRefreshBusy;
      return;
    }
    await this.syncAllGamesAndReload('forceRefresh');
  }

  /**
   * 人机验证通过 / 重新生成设备指纹后的自动重新同步：不做"正在刷新"与冷却判断，
   * 有同步在执行时由 SyncQueueRunner 排队，等前一轮结束后执行（不能被丢弃）
   */
  async syncAfterRetrySignal(): Promise<void> {
    if (this.gameTabsInternal.length === 0) {
      return;
    }
    await this.syncAllGamesAndReload('syncRetry');
  }

  /** 同步当前账号下所有游戏角色，完成后重新加载当前 Tab */
  private async syncAllGamesAndReload(from: string): Promise<void> {
    this.isRefreshing = true;
    try {
      const account = this.allAccounts[this.selectedAccountIdx];
      const roles: GameRoleRow[] = [];
      for (let i = 0; i < this.gameTabsInternal.length; i++) {
        const tab = this.gameTabsInternal[i];
        const roleRow = new GameRoleRow();
        roleRow.gameId = tab.gameId;
        roleRow.roleId = tab.roleUid;
        roleRow.server = this.findServer(tab.roleUid);
        roles[roles.length] = roleRow;
      }
      Logger.info(TAG, `${from}: sync all games of account=${account.uid}, roles=${roles.map((r: GameRoleRow) => `${r.gameId}/${r.roleId}`).join(',')}`);
      const tasks = SyncQueueRunner.buildTasksForRoles(account.uid, roles, account.cookie);
      await SyncQueueRunner.enqueue(tasks);
      // 有任务失败时不提示"刷新成功"：人机验证 / 设备指纹无效已由 GeetestCenter / DeviceFpCenter 统一弹框，
      // 其他失败提示"刷新失败"
      let failure: Error | null = null;
      try {
        await SyncQueueRunner.runTasks(tasks);
      } catch (error) {
        if (!SyncQueueRunner.isTasksFailed(error)) {
          throw error as Error;
        }
        failure = error as Error;
        Logger.warn(TAG, `${from}: some sync tasks failed: ${failure.message}`);
      }
      await this.reloadCharacters(false);
      if (failure === null) {
        this.refreshResult = 'success';
      } else if (!SyncQueueRunner.isGeetestRequired(failure) && !SyncQueueRunner.isFingerprintInvalid(failure)) {
        this.refreshResult = 'error';
      }
    } catch (error) {
      const msg = error instanceof Error ? error.message : `${error}`;
      Logger.error(TAG, `${from} failed: ${msg}`);
      this.networkErrorMsg = msg;
      this.refreshResult = 'error';
    } finally {
      this.isRefreshing = false;
    }
  }

  /**
   * 根据点击的角色和当前选中游戏，返回路由名称和参数。
   * View 层只负责调用 pushPath / replacePath，不做任何 gameId 判断。
   * 返回 null 表示该游戏暂不支持跳转（如 honkai3）。
   */
  buildCardTapRoute(character: GameDataSummary): CardTapRoute | null {
    const gameId = this.currentGameId;
    const roleUid = this.gameTabsInternal.length > 0 ? this.gameTabsInternal[this.selectedGameIdx].roleUid : '';
    const accountId = this.accountOptions.length > 0
      ? this.accountOptions[this.selectedAccountIdx].accountId : '';

    const param = new CharDetailRouterParam();
    param.accountId = accountId;
    param.roleUid = roleUid;
    param.entityId = character.entityId;

    const route = new CardTapRoute();
    route.param = param;

    if (gameId === GameId.GENSHIN) {
      route.routeName = AppRoutes.GENSHIN_CHARACTER_DETAIL;
      return route;
    }
    if (gameId === GameId.STARRAIL) {
      route.routeName = AppRoutes.STARRAIL_CHARACTER_DETAIL;
      return route;
    }
    if (gameId === GameId.ZZZ) {
      route.routeName = AppRoutes.ZZZ_CHARACTER_DETAIL;
      return route;
    }
    // honkai3 等暂不支持，静默忽略
    return null;
  }

  // ─── 私有方法 ────────────────────────────────────────────────

  /** 重建当前账号的游戏 Tab 列表，并加载第一个游戏的角色 */
  private async reloadGameTabs(): Promise<void> {
    if (this.allAccounts.length === 0) {
      this.viewState = ViewState.EMPTY;
      return;
    }
    const roles = this.allRoles[this.selectedAccountIdx];
    const tabItems: SegmentedTabItem[] = [];
    const internalTabs: GameTabInternal[] = [];

    if (roles.length > 0) {
      // 尝试保留上次选中的游戏
      let foundLastGame = false;
      for (let i = 0; i < roles.length; i++) {
        const role = roles[i];
        const tabItem = new SegmentedTabItem(
          `${role.gameId}_${role.roleId}`,
          CharactersDataLoader.getGameNameResource(role.gameId)
        );
        tabItems[tabItems.length] = tabItem;

        const internal = new GameTabInternal();
        internal.gameId = role.gameId;
        internal.roleUid = role.roleId;
        internalTabs[internalTabs.length] = internal;

        if (role.gameId === this.lastSelectedGameId && !foundLastGame) {
          this.selectedGameIdx = i;
          foundLastGame = true;
        }
      }
      // 如果没找到上次游戏，重置为 0
      if (!foundLastGame) {
        this.selectedGameIdx = 0;
      }
    }

    this.gameTabItems = tabItems;
    this.gameTabsInternal = internalTabs;

    if (tabItems.length === 0) {
      this.setCharacters([]);
      this.shouldShowRefreshButton = false;
      this.viewState = ViewState.EMPTY;
      return;
    }
    // 记录当前选中游戏
    this.lastSelectedGameId = this.gameTabsInternal[this.selectedGameIdx].gameId;
    this.shouldShowRefreshButton = true;
    await this.reloadCharacters();
  }

  /** 从 DB 加载当前选中游戏的角色列表，若为空则自动触发一次后台同步 */
  /**
   * @param shouldAutoSyncIfEmpty 本地没有数据时是否自动同步；刚做完全量同步后传 false，避免对失败的接口立刻重复请求
   */
  private async reloadCharacters(shouldAutoSyncIfEmpty: boolean = true): Promise<void> {
    if (this.gameTabsInternal.length === 0) {
      this.setCharacters([]);
      this.viewState = ViewState.EMPTY;
      return;
    }
    const tab = this.gameTabsInternal[this.selectedGameIdx];
    const accountId = this.allAccounts[this.selectedAccountIdx].uid;
    try {
      const rows = await CharactersDataLoader.loadCharacters(accountId, tab.gameId, tab.roleUid);
      if (rows.length > 0) {
        this.setCharacters(rows);
        this.viewState = ViewState.DATA;
      } else if (shouldAutoSyncIfEmpty) {
        this.viewState = ViewState.LOADING;
        this.syncCharactersInBackground(tab.gameId, tab.roleUid);
      } else {
        this.setCharacters([]);
        this.viewState = ViewState.EMPTY;
      }
    } catch (error) {
      const msg = error instanceof Error ? error.message : `${error}`;
      Logger.error(TAG, `reloadCharacters failed: ${msg}`);
      this.setCharacters([]);
      this.viewState = ViewState.EMPTY;
    }
  }

  /** 后台静默同步角色数据，完成后若仍是当前选中 tab 则刷新 UI */
  private syncCharactersInBackground(gameId: GameId, roleUid: string): void {
    if (this.allAccounts.length === 0) { return; }
    const account = this.allAccounts[this.selectedAccountIdx];
    const server = this.findServer(roleUid);
    const accountId = account.uid;
    this.syncCharacters(account, gameId, roleUid, server)
      .then(async () => {
        if (this.gameTabsInternal.length > 0 &&
            this.gameTabsInternal[this.selectedGameIdx].gameId === gameId &&
            this.gameTabsInternal[this.selectedGameIdx].roleUid === roleUid) {
          const rows = await CharactersDataLoader.loadCharacters(accountId, gameId, roleUid);
          this.setCharacters(rows);
          this.viewState = rows.length > 0 ? ViewState.DATA : ViewState.EMPTY;
        }
      })
      .catch((error: Error | object) => {
        const msg = error instanceof Error ? error.message : `${error}`;
        Logger.warn(TAG, `autoSyncCharacters failed for ${gameId}/${roleUid}: ${msg}`);
        if (this.viewState === ViewState.LOADING) {
          this.viewState = ViewState.EMPTY;
        }
      });
  }

  private setCharacters(rows: GameDataSummary[]): void {
    this.characters = rows;
    this.dataSource.setData(rows);
  }

  /**
   * 角色列表同步：把任务写入持久化队列，然后执行。
   */
  private async syncCharacters(
    account: AccountRow,
    gameId: GameId,
    roleUid: string,
    server: string
  ): Promise<void> {
    const roleRow = new GameRoleRow();
    roleRow.gameId = gameId;
    roleRow.roleId = roleUid;
    roleRow.server = server;
    const tasks = SyncQueueRunner.buildTasksForRoles(account.uid, [roleRow], account.cookie);
    await SyncQueueRunner.enqueue(tasks);
    await SyncQueueRunner.runTasks(tasks);
  }

  private findServer(roleUid: string): string {
    if (this.allRoles.length === 0 || this.selectedAccountIdx >= this.allRoles.length) {
      return '';
    }
    const roles = this.allRoles[this.selectedAccountIdx];
    for (let i = 0; i < roles.length; i++) {
      if (roles[i].roleId === roleUid) {
        return roles[i].server;
      }
    }
    return '';
  }

  static toSelectOptions(opts: AccountOption[]): SelectOption[] {
    return CharactersDataLoader.toSelectOptions(opts);
  }
}
