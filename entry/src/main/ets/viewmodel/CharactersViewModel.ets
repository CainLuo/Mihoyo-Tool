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
  GenshinApiService,
  StarRailApiService,
  ZZZApiService
} from 'core';
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

// ─── 解析用本地 interface ────────────────────────────────────────

/** 原神角色列表 API 响应中的武器字段 */
interface GenshinWeaponItem {
  name: string;
  level: number;
  affix_level: number;
  rarity: number;
}

/** 原神角色列表 API 响应中的单个角色字段 */
interface GenshinCharacterItem {
  id: number;
  name: string;
  element: string;
  rarity: number;
  level: number;
  fetter: number;
  actived_constellation_num: number;
  icon: string;
  side_icon: string;
  weapon_type: number;
  weapon: GenshinWeaponItem | null;
}

/** 原神角色列表 API 响应 data 字段 */
interface GenshinCharacterListData {
  list: GenshinCharacterItem[];
}

/** 星穹铁道角色列表 API 响应中的装备字段 */
interface StarRailEquipItem {
  id: number;
  name: string;
  level: number;
  rank: number;
  rarity: number;
}

/** 星穹铁道角色列表 API 响应中的单个角色字段 */
interface StarRailAvatarItem {
  id: number;
  name: string;
  rarity: number;
  level: number;
  rank: number;
  base_type: number;
  element_id: number;
  icon: string;
  figure_path: string;
  equip: StarRailEquipItem | null;
}

/** 星穹铁道角色列表 API 响应 data 字段 */
interface StarRailAvatarListData {
  list: StarRailAvatarItem[];
}

/** 绝区零代理人列表 API 响应中的单个代理人字段 */
interface ZZZAvatarItem {
  id: number;
  name_mi18n: string;
  full_name_mi18n: string;
  rarity: string;
  level: number;
  rank: number;
  element_type: number;
  avatar_profession: number;
  hollow_icon_path: string;
  role_square_url: string;
}

/** 绝区零代理人列表 API 响应 data 字段 */
interface ZZZAvatarListData {
  avatar_list: ZZZAvatarItem[];
}

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
  private allAccounts: AccountRow[] = [];
  private allRoles: GameRoleRow[][] = [];

  // ─── 公开方法 ────────────────────────────────────────────────

  async loadData(): Promise<void> {
    await CoreInitializer.waitForReady();
    this.viewState = ViewState.LOADING;
    try {
      this.allAccounts = await CoreInitializer.bbsRepository.getAllAccounts();
      this.allRoles = [];
      for (let i = 0; i < this.allAccounts.length; i++) {
        const roles = await CoreInitializer.bbsRepository.getGameRoles(this.allAccounts[i].id);
        this.allRoles[this.allRoles.length] = roles;
      }
      if (this.allAccounts.length === 0) {
        this.viewState = ViewState.EMPTY;
        return;
      }
      this.accountOptions = CharactersViewModel.buildAccountOptions(this.allAccounts);
      this.selectedAccountIdx = 0;
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
    if (this.isRefreshing || this.gameTabs.length === 0) {
      return;
    }
    const tab = this.gameTabs[this.selectedGameIdx];
    // 检查冷却：使用 needsSync
    let inCooldown = false;
    try {
      const needed = await CharactersViewModel.needsCharacterSync(
        this.allAccounts[this.selectedAccountIdx].id, tab.roleUid, tab.gameId
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
      const account = this.allAccounts[this.selectedAccountIdx];
      await this.syncCharacters(account, tab.gameId, tab.roleUid, this.findServer(tab.roleUid));
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
    if (this.allAccounts.length === 0) {
      this.viewState = ViewState.EMPTY;
      return;
    }
    const roles = this.allRoles[this.selectedAccountIdx];
    const tabs: GameTabItem[] = [];

    if (roles.length > 0) {
      for (let i = 0; i < roles.length; i++) {
        const role = roles[i];
        tabs[tabs.length] = new GameTabItem(
          role.gameId,
          role.roleId,
          CharactersViewModel.gameNameResource(role.gameId)
        );
      }
    }

    this.gameTabs = tabs;
    if (tabs.length === 0) {
      this.setCharacters([]);
      this.viewState = ViewState.EMPTY;
      return;
    }
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
    const accountId = this.allAccounts[this.selectedAccountIdx].id;
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
    accountId: number,
    gameId: string,
    roleUid: string
  ): Promise<GameDataSummary[]> {
    if (gameId === GAME_GENSHIN) {
      const rows = await CoreInitializer.genshinRepository.getAvatarList(accountId, roleUid);
      return CharactersViewModel.genshinRowsToSummaries(rows, roleUid);
    }
    if (gameId === GAME_STARRAIL) {
      const rows = await CoreInitializer.starRailRepository.getAvatarList(accountId, roleUid);
      return CharactersViewModel.starRailRowsToSummaries(rows, roleUid);
    }
    if (gameId === GAME_ZZZ) {
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
      s.gameId = GAME_GENSHIN;
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
      s.gameId = GAME_STARRAIL;
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
      s.gameId = GAME_ZZZ;
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
      s.updateTime = r.updateTime;
      result[result.length] = s;
    }
    return result;
  }

  /** 后台静默同步角色数据，完成后若仍是当前选中 tab 则刷新 UI */
  private autoSyncCharacters(gameId: string, roleUid: string): void {
    if (this.allAccounts.length === 0) { return; }
    const account = this.allAccounts[this.selectedAccountIdx];
    const server = this.findServer(roleUid);
    const accountId = account.id;
    this.syncCharacters(account, gameId, roleUid, server)
      .then(async () => {
        if (this.gameTabs.length > 0 &&
            this.gameTabs[this.selectedGameIdx].gameId === gameId &&
            this.gameTabs[this.selectedGameIdx].roleUid === roleUid) {
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
   * 角色列表同步：根据 gameId 分发到对应 Repository，
   * 调用 ApiService 拉取数据后写入 DB。
   * 其他 gameId 静默跳过。
   */
  private async syncCharacters(
    account: AccountRow,
    gameId: string,
    roleUid: string,
    server: string
  ): Promise<void> {
    if (gameId === GAME_GENSHIN) {
      const repo = CoreInitializer.genshinRepository;
      await repo.markAvatarListSyncing(account.id, roleUid);
      try {
        const resp = await (repo.getService() as GenshinApiService).getCharacterList(
          roleUid, server, account.cookie
        );
        const rows = CharactersViewModel.parseGenshinCharacterList(account.id, roleUid, resp);
        await repo.upsertAvatarList(account.id, roleUid, rows);
      } catch (error) {
        const msg = error instanceof Error ? error.message : `${error}`;
        await repo.markAvatarListFailed(account.id, roleUid, msg);
        throw new Error(msg);
      }
    } else if (gameId === GAME_STARRAIL) {
      const repo = CoreInitializer.starRailRepository;
      await repo.markAvatarListSyncing(account.id, roleUid);
      try {
        const resp = await (repo.getService() as StarRailApiService).getAvatarBasic(
          roleUid, server, account.cookie
        );
        const rows = CharactersViewModel.parseStarRailAvatarBasic(account.id, roleUid, resp);
        await repo.upsertAvatarList(account.id, roleUid, rows);
      } catch (error) {
        const msg = error instanceof Error ? error.message : `${error}`;
        await repo.markAvatarListFailed(account.id, roleUid, msg);
        throw new Error(msg);
      }
    } else if (gameId === GAME_ZZZ) {
      const repo = CoreInitializer.zzzRepository;
      await repo.markAvatarListSyncing(account.id, roleUid);
      try {
        const resp = await (repo.getService() as ZZZApiService).getAvatarBasic(
          roleUid, server, account.cookie
        );
        const rows = CharactersViewModel.parseZZZAvatarBasic(account.id, roleUid, resp);
        await repo.upsertAvatarList(account.id, roleUid, rows);
      } catch (error) {
        const msg = error instanceof Error ? error.message : `${error}`;
        await repo.markAvatarListFailed(account.id, roleUid, msg);
        throw new Error(msg);
      }
    }
    // 其他 gameId 静默跳过
  }

  /**
   * 解析原神角色列表 API 响应，构建 GenshinCharacterListRow[]。
   * 响应结构：{ list: Array<{ id, name, element, rarity, level, fetter,
   *   actived_constellation_num, icon, side_icon, weapon_type, weapon: {...} }> }
   */
  private static parseGenshinCharacterList(
    accountId: number,
    roleUid: string,
    resp: object
  ): GenshinCharacterListRow[] {
    const result: GenshinCharacterListRow[] = [];
    try {
      const data = resp as GenshinCharacterListData;
      const list = data.list;
      if (!list || list.length === 0) {
        return result;
      }
      for (let i = 0; i < list.length; i++) {
        const item = list[i];
        const weapon = item.weapon;
        const row = new GenshinCharacterListRow();
        row.accountId = accountId;
        row.roleUid = roleUid;
        row.avatarId = `${item.id}`;
        row.name = item.name;
        row.element = item.element;
        row.rarity = item.rarity;
        row.level = item.level;
        row.fetter = item.fetter;
        row.activedConstellationNum = item.actived_constellation_num;
        row.icon = item.icon;
        row.sideIcon = item.side_icon;
        row.weaponType = item.weapon_type;
        row.weaponName = weapon ? weapon.name : '';
        row.weaponLevel = weapon ? weapon.level : 0;
        row.weaponAffixLevel = weapon ? weapon.affix_level : 0;
        row.weaponRarity = weapon ? weapon.rarity : 0;
        row.rawJson = JSON.stringify(item);
        row.updateTime = Math.floor(Date.now() / 1000);
        result[result.length] = row;
      }
    } catch (error) {
      Logger.warn(TAG, `parseGenshinCharacterList failed: ${error}`);
    }
    return result;
  }

  /**
   * 解析星穹铁道角色列表 API 响应，构建 StarRailAvatarBasicRow[]。
   * 响应结构：{ list: Array<{ id, name, rarity, level, rank, base_type,
   *   element_id, icon, figure_path, equip: {...} | null }> }
   */
  private static parseStarRailAvatarBasic(
    accountId: number,
    roleUid: string,
    resp: object
  ): StarRailAvatarBasicRow[] {
    const result: StarRailAvatarBasicRow[] = [];
    try {
      const data = resp as StarRailAvatarListData;
      const list = data.list;
      if (!list || list.length === 0) {
        return result;
      }
      for (let i = 0; i < list.length; i++) {
        const item = list[i];
        const equip = item.equip;
        const row = new StarRailAvatarBasicRow();
        row.accountId = accountId;
        row.roleUid = roleUid;
        row.avatarId = `${item.id}`;
        row.name = item.name;
        row.rarity = item.rarity;
        row.level = item.level;
        row.rank = item.rank;
        row.baseType = item.base_type;
        row.elementId = item.element_id;
        row.element = `${item.element_id}`;
        row.icon = item.icon;
        row.figurePath = item.figure_path;
        row.equipId = equip ? `${equip.id}` : '';
        row.equipName = equip ? equip.name : '';
        row.equipLevel = equip ? equip.level : 0;
        row.equipRank = equip ? equip.rank : 0;
        row.equipRarity = equip ? equip.rarity : 0;
        row.rawJson = JSON.stringify(item);
        row.updateTime = Math.floor(Date.now() / 1000);
        result[result.length] = row;
      }
    } catch (error) {
      Logger.warn(TAG, `parseStarRailAvatarBasic failed: ${error}`);
    }
    return result;
  }

  /**
   * 解析绝区零代理人列表 API 响应，构建 ZZZAvatarBasicRow[]。
   * 响应结构：{ avatar_list: Array<{ id, name_mi18n, full_name_mi18n, rarity,
   *   level, rank, element_type, avatar_profession, hollow_icon_path, role_square_url }> }
   */
  private static parseZZZAvatarBasic(
    accountId: number,
    roleUid: string,
    resp: object
  ): ZZZAvatarBasicRow[] {
    const result: ZZZAvatarBasicRow[] = [];
    try {
      const data = resp as ZZZAvatarListData;
      const list = data.avatar_list;
      if (!list || list.length === 0) {
        return result;
      }
      for (let i = 0; i < list.length; i++) {
        const item = list[i];
        const row = new ZZZAvatarBasicRow();
        row.accountId = accountId;
        row.roleUid = roleUid;
        row.avatarId = `${item.id}`;
        row.nameMi18n = item.name_mi18n;
        row.fullNameMi18n = item.full_name_mi18n;
        row.rarity = item.rarity;
        row.level = item.level;
        row.rank = item.rank;
        row.elementType = item.element_type;
        row.avatarProfession = item.avatar_profession;
        row.hollowIconPath = item.hollow_icon_path;
        row.roleSquareUrl = item.role_square_url;
        row.rawJson = JSON.stringify(item);
        row.updateTime = Math.floor(Date.now() / 1000);
        result[result.length] = row;
      }
    } catch (error) {
      Logger.warn(TAG, `parseZZZAvatarBasic failed: ${error}`);
    }
    return result;
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
  private static async needsCharacterSync(accountId: number, roleUid: string, gameId: string): Promise<boolean> {
    if (gameId === GAME_GENSHIN) {
      return CoreInitializer.genshinRepository.needsAvatarListSync(accountId, roleUid);
    }
    if (gameId === GAME_STARRAIL) {
      return CoreInitializer.starRailRepository.needsAvatarListSync(accountId, roleUid);
    }
    if (gameId === GAME_ZZZ) {
      return CoreInitializer.zzzRepository.needsAvatarListSync(accountId, roleUid);
    }
    return true;
  }

  private static buildAccountOptions(accounts: AccountRow[]): AccountOption[] {
    const opts: AccountOption[] = [];
    for (let i = 0; i < accounts.length; i++) {
      opts[opts.length] = new AccountOption(accounts[i].id, accounts[i].username);
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
