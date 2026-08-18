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
  GenshinCharacterListRow,
  StarRailAvatarBasicRow,
  ZZZAvatarBasicRow,
  SyncQueueRunner,
  Logger,
  GameId,
} from 'core';
import { ViewState } from '../constants/ViewStates';
import { AppConstants } from '../constants/AppConstants';
import { CharacterDataSource } from '../components/characters/CharacterDataSource';
import { AccountOption } from '../models/AccountOption';
import { CharDetailRouterParam } from '../models/CharDetailModels';
import { SegmentedTabItem } from '../components/common/SegmentedTabBar';
import { AppRoutes } from '../constants/AppRoutes';

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

/** CharactersViewModel @Monitor 路径常量类型 */
export class CharactersViewModelKeys {
  networkErrorMsg: string = 'vm.networkErrorMsg';
  refreshCoolingDown: string = 'vm.refreshCoolingDown';
  refreshResult: string = 'vm.refreshResult';
}

@ObservedV2
export class CharactersViewModel {
  /** @Monitor 路径常量，View 层必须通过此对象引用，禁止直接写字符串字面量 */
  static readonly KEYS: CharactersViewModelKeys = new CharactersViewModelKeys();

  @Trace viewState: ViewState = ViewState.LOADING;
  @Trace accountOptions: AccountOption[] = [];
  /** 是否显示账号切换按钮（多账号时为 true） */
  @Trace showAccountSwitcher: boolean = false;
  /** 是否显示刷新按钮（有游戏数据时为 true） */
  @Trace showRefreshButton: boolean = false;
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
  @Trace refreshCoolingDown: boolean = false;
  /** 手动刷新结果信号：'success' | 'error' | ''，View 层监听后调用 showFeedback */
  @Trace refreshResult: string = '';

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
        this.showAccountSwitcher = false;
        this.showRefreshButton = false;
        this.viewState = ViewState.EMPTY;
        return;
      }
      this.accountOptions = CharactersViewModel.buildAccountOptions(this.allAccounts);
      this.showAccountSwitcher = this.accountOptions.length > 1;
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

  /** 手动刷新：强制同步当前游戏角色，30 分钟内重复触发时发出冷却信号 */
  async refresh(): Promise<void> {
    if (this.isRefreshing || this.gameTabsInternal.length === 0) {
      return;
    }
    const tab = this.gameTabsInternal[this.selectedGameIdx];
    // 检查冷却：使用 needsSync
    let inCooldown = false;
    try {
      const needed = await CharactersViewModel.needsCharacterSync(
        this.allAccounts[this.selectedAccountIdx].uid, tab.roleUid, tab.gameId
      );
      inCooldown = !needed;
    } catch (_) {
      inCooldown = false;
    }
    if (inCooldown) {
      this.refreshCoolingDown = !this.refreshCoolingDown;
      return;
    }
    this.isRefreshing = true;
    try {
      const account = this.allAccounts[this.selectedAccountIdx];
      const server = this.findServer(tab.roleUid);
      await this.syncCharacters(account, tab.gameId, tab.roleUid, server);
      await this.reloadCharacters();
      this.refreshResult = 'success';
    } catch (error) {
      const msg = error instanceof Error ? error.message : `${error}`;
      Logger.error(TAG, `refresh failed: ${msg}`);
      this.networkErrorMsg = msg;
      this.refreshResult = 'error';
    } finally {
      this.isRefreshing = false;
    }
  }

  /** 强制刷新：跳过冷却检查，由 View 层在用户确认冷却 Dialog 后调用 */
  async forceRefresh(): Promise<void> {
    if (this.isRefreshing || this.gameTabsInternal.length === 0) {
      return;
    }
    this.isRefreshing = true;
    try {
      const tab = this.gameTabsInternal[this.selectedGameIdx];
      const account = this.allAccounts[this.selectedAccountIdx];
      await this.syncCharacters(account, tab.gameId, tab.roleUid, this.findServer(tab.roleUid));
      await this.reloadCharacters();
      this.refreshResult = 'success';
    } catch (error) {
      const msg = error instanceof Error ? error.message : `${error}`;
      Logger.error(TAG, `forceRefresh failed: ${msg}`);
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
          CharactersViewModel.gameNameResource(role.gameId)
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
      this.showRefreshButton = false;
      this.viewState = ViewState.EMPTY;
      return;
    }
    // 记录当前选中游戏
    this.lastSelectedGameId = this.gameTabsInternal[this.selectedGameIdx].gameId;
    this.showRefreshButton = true;
    await this.reloadCharacters();
  }

  /** 从 DB 加载当前选中游戏的角色列表，若为空则自动触发一次后台同步 */
  private async reloadCharacters(): Promise<void> {
    if (this.gameTabsInternal.length === 0) {
      this.setCharacters([]);
      this.viewState = ViewState.EMPTY;
      return;
    }
    const tab = this.gameTabsInternal[this.selectedGameIdx];
    const accountId = this.allAccounts[this.selectedAccountIdx].uid;
    try {
      const rows = await CharactersViewModel.loadCharacters(accountId, tab.gameId, tab.roleUid);
      if (rows.length > 0) {
        this.setCharacters(rows);
        this.viewState = ViewState.DATA;
      } else {
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

  /** 从 Repository 读取角色数据并转换为 GameDataSummary */
  private static async loadCharacters(
    accountId: string,
    gameId: GameId,
    roleUid: string
  ): Promise<GameDataSummary[]> {
    if (gameId === GameId.GENSHIN) {
      const rows = await CoreInitializer.genshinRepository.getAvatarList(accountId, roleUid);
      return CharactersViewModel.genshinRowsToSummaries(rows, roleUid);
    }
    if (gameId === GameId.STARRAIL) {
      const rows = await CoreInitializer.starRailRepository.getAvatarList(accountId, roleUid);
      return CharactersViewModel.starRailRowsToSummaries(rows, roleUid);
    }
    if (gameId === GameId.ZZZ) {
      const rows = await CoreInitializer.zzzRepository.getAvatarList(accountId, roleUid);
      return CharactersViewModel.zzzRowsToSummaries(rows, roleUid);
    }
    return [];
  }

  /** 将 GenshinCharacterListRow[] 转换为 GameDataSummary[] */
  private static genshinRowsToSummaries(rows: GenshinCharacterListRow[], roleUid: string): GameDataSummary[] {
    const result: GameDataSummary[] = [];
    for (let i = 0; i < rows.length; i++) {
      const r = rows[i];
      const s = new GameDataSummary();
      s.gameId = GameId.GENSHIN;
      s.roleUid = roleUid;
      s.entityId = r.avatarId;
      s.name = r.name;
      s.rarity = r.rarity;
      s.level = r.level;
      s.extraInt1 = r.activedConstellationNum;
      s.extraInt2 = r.fetter;
      s.extraText1 = r.element;
      s.extraText2 = `${r.weaponType}`;
      s.iconUrl = r.icon;
      s.squareIconUrl = r.sideIcon;
      s.weaponName = r.weaponName;
      s.weaponLevel = r.weaponLevel;
      s.weaponAffix = r.weaponAffixLevel;
      s.weaponRarity = r.weaponRarity;
      s.weaponIconUrl = r.weaponIconUrl;
      s.hasWeaponSlot = true;
      s.updateTime = r.updateTime;
      result[result.length] = s;
    }
    return result;
  }

  /** 将 StarRailAvatarBasicRow[] 转换为 GameDataSummary[] */
  private static starRailRowsToSummaries(rows: StarRailAvatarBasicRow[], roleUid: string): GameDataSummary[] {
    const result: GameDataSummary[] = [];
    for (let i = 0; i < rows.length; i++) {
      const r = rows[i];
      const s = new GameDataSummary();
      s.gameId = GameId.STARRAIL;
      s.roleUid = roleUid;
      s.entityId = r.avatarId;
      s.name = r.name;
      s.rarity = r.rarity;
      s.level = r.level;
      s.extraInt1 = r.rank;
      s.extraInt2 = 0;
      s.extraText1 = r.element;
      s.extraText2 = `${r.baseType}`;
      s.iconUrl = r.icon;
      s.squareIconUrl = r.figurePath;
      s.weaponName = r.equipName;
      s.weaponLevel = r.equipLevel;
      s.weaponAffix = r.equipRank;
      s.weaponRarity = r.equipRarity;
      s.weaponIconUrl = r.equipIconUrl;
      s.hasWeaponSlot = true;
      s.updateTime = r.updateTime;
      result[result.length] = s;
    }
    return result;
  }

  /** 将 ZZZAvatarBasicRow[] 转换为 GameDataSummary[] */
  private static zzzRowsToSummaries(rows: ZZZAvatarBasicRow[], roleUid: string): GameDataSummary[] {
    const result: GameDataSummary[] = [];
    for (let i = 0; i < rows.length; i++) {
      const r = rows[i];
      const s = new GameDataSummary();
      s.gameId = GameId.ZZZ;
      s.roleUid = roleUid;
      s.entityId = r.avatarId;
      s.name = r.nameMi18n;
      s.fullName = r.fullNameMi18n;
      s.rarity = r.rarity === 'S' ? 5 : 4;
      s.level = r.level;
      s.extraInt1 = r.rank;
      s.extraInt2 = 0;
      s.extraText1 = `${r.elementType}`;
      s.extraText2 = `${r.avatarProfession}`;
      s.iconUrl = r.hollowIconPath;
      s.squareIconUrl = r.roleSquareUrl;
      s.groupIconUrl = r.groupIconPath;
      s.updateTime = r.updateTime;
      result[result.length] = s;
    }
    return result;
  }

  /** 后台静默同步角色数据，完成后若仍是当前选中 tab 则刷新 UI */
  private autoSyncCharacters(gameId: GameId, roleUid: string): void {
    if (this.allAccounts.length === 0) { return; }
    const account = this.allAccounts[this.selectedAccountIdx];
    const server = this.findServer(roleUid);
    const accountId = account.uid;
    this.syncCharacters(account, gameId, roleUid, server)
      .then(async () => {
        if (this.gameTabsInternal.length > 0 &&
            this.gameTabsInternal[this.selectedGameIdx].gameId === gameId &&
            this.gameTabsInternal[this.selectedGameIdx].roleUid === roleUid) {
          const rows = await CharactersViewModel.loadCharacters(accountId, gameId, roleUid);
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

  /** 检查指定游戏角色是否需要同步角色数据 */
  private static async needsCharacterSync(accountId: string, roleUid: string, gameId: GameId): Promise<boolean> {
    if (gameId === GameId.GENSHIN) {
      return CoreInitializer.genshinRepository.needsAvatarListSync(accountId, roleUid);
    }
    if (gameId === GameId.STARRAIL) {
      return CoreInitializer.starRailRepository.needsAvatarListSync(accountId, roleUid);
    }
    if (gameId === GameId.ZZZ) {
      return CoreInitializer.zzzRepository.needsAvatarListSync(accountId, roleUid);
    }
    return true;
  }

  private static buildAccountOptions(accounts: AccountRow[]): AccountOption[] {
    const opts: AccountOption[] = [];
    for (let i = 0; i < accounts.length; i++) {
      const a = accounts[i];
      opts[opts.length] = new AccountOption(a.uid, a.username, a.nickname, a.avatarUrl, a.uid);
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

  private static gameNameResource(gameId: GameId): Resource {
    if (gameId === GameId.GENSHIN) {
      return $r('app.string.game_name_genshin');
    }
    if (gameId === GameId.STARRAIL) {
      return $r('app.string.game_name_starrail');
    }
    if (gameId === GameId.ZZZ) {
      return $r('app.string.game_name_zzz');
    }
    if (gameId === GameId.HONKAI3) {
      return $r('app.string.game_name_honkai3');
    }
    return $r('app.string.game_name_genshin');
  }
}
