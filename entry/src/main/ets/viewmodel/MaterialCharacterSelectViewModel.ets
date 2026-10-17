/**
 * MaterialCharacterSelectViewModel.ets — 角色选择页 ViewModel
 *
 * 加载指定游戏的角色列表，支持多选（最多 4 个）。
 * 选中的角色 ID 列表用于跳转到材料计算页。
 *
 * 数据维度：账号 × 游戏
 *   - accountOptions: 所有账号列表（用于账号切换器）
 *   - selectedAccountIdx: 当前选中账号下标
 *   - showAccountSwitcher: 是否显示账号切换按钮（多账号时为 true）
 */

import {
  CoreInitializer,
  AccountRow,
  GameRoleRow,
  GameId,
  Logger,
} from 'core';
import { ViewState } from '../constants/ViewStates';
import { gameIdToColor, gameIdToLogo, gameIdToName } from '../utils/GameIdUtil';
import { AccountOption } from '../models/AccountOption';
import { MaterialTargetConfigParam } from '../models/ToolsModels';
import { compareCharacter } from '../utils/CharacterSort';
import { MaterialComputeService, MaterialComputeResult } from '../utils/MaterialComputeService';

const TAG: string = 'MaterialCharacterSelectViewModel';
/** 角色 UI State */
@ObservedV2
export class SelectableCharacterVM {
  /** 角色 ID */
  avatarId: string = '';
  /** 角色名称 */
  name: string = '';
  /** 稀有度 */
  rarity: number = 4;
  /** 等级 */
  level: number = 1;
  /** 图标 URL */
  iconUrl: string = '';
  /** 元素 / 属性：原神、星铁为英文字符串（如 'Pyro' / 'fire'），绝区零为数字字符串（element_type） */
  element: string = '';
  /** 星铁命途（base_type）/ 绝区零特性（avatar_profession）；原神不使用 */
  pathOrProfession: number = 0;
  /** 武器（原神）/ 光锥（星铁）/ 音擎（绝区零）图标；没有装备时为空 */
  weaponIconUrl: string = '';
  /** 武器等级；没有装备时为 0 */
  weaponLevel: number = 0;
  /** 武器星级（绝区零 S = 5，A = 4，B = 3），用于图标背景色 */
  weaponRarity: number = 0;
  /** 是否选中 */
  @Trace isSelected: boolean = false;
}

/** 路由参数 */
export class MaterialCharacterSelectParam {
  accountId: string = '';
  roleUid: string = '';
  gameId: GameId = GameId.GENSHIN;
}

/** MaterialCharacterSelectViewModel @Monitor 路径常量类型 */
export class MaterialCharacterSelectViewModelKeys {
  static readonly characters: string = 'vm.characters';
  static readonly selectedCount: string = 'vm.selectedCount';
  static readonly canStart: string = 'vm.canStart';
  static readonly accountOptions: string = 'vm.accountOptions';
  static readonly selectedAccountIdx: string = 'vm.selectedAccountIdx';
  static readonly showAccountSwitcher: string = 'vm.showAccountSwitcher';
}

@ObservedV2
export class MaterialCharacterSelectViewModel {
  /** @Monitor 路径常量 */
  static readonly KEYS: MaterialCharacterSelectViewModelKeys = new MaterialCharacterSelectViewModelKeys();

  /** 游戏标识 */
  gameId: GameId = GameId.GENSHIN;

  /** 页面状态 */
  @Trace viewState: ViewState = ViewState.LOADING;

  /** 角色列表 */
  @Trace characters: SelectableCharacterVM[] = [];

  /** 账号选项列表（用于账号切换器） */
  @Trace accountOptions: AccountOption[] = [];

  /** 是否显示账号切换按钮（多账号时为 true） */
  @Trace showAccountSwitcher: boolean = false;

  /** 当前选中账号下标 */
  @Trace selectedAccountIdx: number = 0;

  /** 账号 UID */
  accountId: string = '';

  /** 角色 UID */
  roleUid: string = '';

  /** 选中数量（最多 4 个） */
  @Trace selectedCount: number = 0;

  /** 是否可以开始计算（至少选 1 个） */
  @Trace canStart: boolean = false;

  /** 是否正在计算 */
  @Trace isSyncing: boolean = false;

  /** DB 中已有计算结果的角色 ID（历史记录）；为空时不显示历史记录入口 */
  @Trace historyAvatarIds: string[] = [];


  /** 原始账号数据（切换账号时复用） */
  private allAccounts: AccountRow[] = [];

  /** 原始角色数据（按账号下标分组） */
  private allRoles: GameRoleRow[][] = [];

  // ─── 公开方法 ────────────────────────────────────────────────

  /**
   * 初始化：加载指定游戏的角色列表
   */
  async init(gameId: GameId): Promise<void> {
    this.gameId = gameId;
    this.viewState = ViewState.LOADING;
    this.selectedCount = 0;
    this.canStart = false;

    await CoreInitializer.waitForReady();

    try {
      // 加载所有账号
      this.allAccounts = await CoreInitializer.bbsRepository.getAllAccounts();
      this.allRoles = [];
      for (let i = 0; i < this.allAccounts.length; i++) {
        const roles = await CoreInitializer.bbsRepository.getGameRoles(this.allAccounts[i].uid);
        this.allRoles[this.allRoles.length] = roles;
      }

      if (this.allAccounts.length === 0) {
        this.showAccountSwitcher = false;
        this.viewState = ViewState.EMPTY;
        return;
      }

      // 构建账号选项列表
      this.accountOptions = this.buildAccountOptions(this.allAccounts);
      this.showAccountSwitcher = this.accountOptions.length > 1;

      // 确保 selectedAccountIdx 在有效范围内
      this.selectedAccountIdx = Math.min(this.selectedAccountIdx, this.allAccounts.length - 1);
      if (this.selectedAccountIdx < 0) { this.selectedAccountIdx = 0; }

      // 加载当前选中账号的角色列表
      await this.loadCurrentAccount();
    } catch (error) {
      const msg = error instanceof Error ? error.message : `${error}`;
      Logger.error(TAG, `init failed: ${msg}`);
      this.viewState = ViewState.EMPTY;
    }
  }

  /**
   * 切换账号
   */
  async selectAccount(idx: number): Promise<void> {
    if (idx === this.selectedAccountIdx || idx < 0 || idx >= this.allAccounts.length) {
      return;
    }
    this.selectedAccountIdx = idx;
    this.viewState = ViewState.LOADING;
    this.selectedCount = 0;
    this.canStart = false;
    this.characters = [];
    this.historyAvatarIds = [];
    await this.loadCurrentAccount();
  }

  /**
   * 切换角色选中状态
   * 如果已选 4 个且尝试选中新的，不做任何操作
   */
  toggleSelect(avatarId: string): void {
    for (let i = 0; i < this.characters.length; i++) {
      const char = this.characters[i];
      if (char.avatarId === avatarId) {
        if (char.isSelected) {
          // 取消选中
          char.isSelected = false;
          this.updateSelectedCount();
        } else if (this.selectedCount < 4) {
          // 选中（未超过上限）
          char.isSelected = true;
          this.updateSelectedCount();
        }
        return;
      }
    }
  }

  /**
   * 获取选中的角色 ID 列表
   */
  getSelectedAvatarIds(): string[] {
    const result: string[] = [];
    for (let i = 0; i < this.characters.length; i++) {
      if (this.characters[i].isSelected) {
        result[result.length] = this.characters[i].avatarId;
      }
    }
    return result;
  }

  /**
   * 读取 DB 中该账号 / 游戏 UID 已有的材料计算结果，得到历史记录的角色 ID。
   * 页面重新显示时（例如从配置页返回）也会调用，保证入口按钮状态与 DB 一致。
   */
  async loadHistory(): Promise<void> {
    if (this.accountId.length === 0 || this.roleUid.length === 0) {
      this.historyAvatarIds = [];
      return;
    }
    const ids: string[] = [];
    try {
      if (this.gameId === GameId.GENSHIN) {
        const rows = await CoreInitializer.genshinRepository.getAllComputeData(this.accountId, this.roleUid);
        for (let i = 0; i < rows.length; i++) {
          ids[ids.length] = rows[i].avatarId;
        }
      } else if (this.gameId === GameId.STARRAIL) {
        const rows = await CoreInitializer.starRailRepository.getAllComputeData(this.accountId, this.roleUid);
        for (let i = 0; i < rows.length; i++) {
          ids[ids.length] = rows[i].avatarId;
        }
      } else if (this.gameId === GameId.ZZZ) {
        const rows = await CoreInitializer.zzzRepository.getAllComputeData(this.accountId, this.roleUid);
        for (let i = 0; i < rows.length; i++) {
          ids[ids.length] = rows[i].avatarId;
        }
      }
    } catch (error) {
      Logger.error(TAG, `loadHistory failed: ${error instanceof Error ? error.message : `${error}`}`);
    }
    this.historyAvatarIds = ids;
    Logger.info('MaterialSelect', `loadHistory gameId=${this.gameId}, role=${this.roleUid}, avatarIds=${ids.join(',')}`);
  }

  /** 历史记录的路由参数：DB 中已有计算结果的全部角色 */
  buildHistoryParam(): MaterialTargetConfigParam {
    const param = new MaterialTargetConfigParam();
    param.accountId = this.accountId;
    param.roleUid = this.roleUid;
    param.gameId = this.gameId;
    param.avatarIds = this.historyAvatarIds.slice();
    return param;
  }

  /**
   * 构建路由参数（选中的账号 / 游戏 UID / 角色）。目标等级不放在参数里，每次计算都从 DB 读取。
   */
  buildSelectionParam(): MaterialTargetConfigParam {
    const param = new MaterialTargetConfigParam();
    param.accountId = this.accountId;
    param.roleUid = this.roleUid;
    param.gameId = this.gameId;
    param.avatarIds = this.getSelectedAvatarIds();
    return param;
  }

  /**
   * 当前账号 / 游戏 UID 是否已在 DB 中保存过养成目标配置。
   * 没有时页面应提示用户先去配置页设置，而不是用默认值计算。
   */
  async hasSavedConfig(): Promise<boolean> {
    try {
      return await MaterialComputeService.hasSavedConfig(this.gameId, this.accountId, this.roleUid);
    } catch (error) {
      Logger.error(TAG, `hasSavedConfig failed: ${error instanceof Error ? error.message : `${error}`}`);
      return false;
    }
  }

  /**
   * 开始计算：只计算选中角色（目标等级从 DB 读取，替换该游戏 UID 下旧的计算结果）
   */
  async startCompute(param: MaterialTargetConfigParam): Promise<MaterialComputeResult> {
    if (this.isSyncing) {
      return MaterialComputeResult.BUSY;
    }
    this.isSyncing = true;
    try {
      return await MaterialComputeService.compute(param);
    } finally {
      this.isSyncing = false;
    }
  }

  // ─── 私有方法 ────────────────────────────────────────────────

  /**
   * 加载当前选中账号的角色列表
   */
  private async loadCurrentAccount(): Promise<void> {
    if (this.allAccounts.length === 0) {
      this.viewState = ViewState.EMPTY;
      return;
    }

    const account = this.allAccounts[this.selectedAccountIdx];
    this.accountId = account.uid;

    // 获取该账号下指定游戏的角色列表
    const roles = this.allRoles[this.selectedAccountIdx];
    const gameRoles: GameRoleRow[] = [];
    for (let i = 0; i < roles.length; i++) {
      if (roles[i].gameId === this.gameId) {
        gameRoles[gameRoles.length] = roles[i];
      }
    }

    if (gameRoles.length === 0) {
      this.roleUid = '';
      this.historyAvatarIds = [];
      this.viewState = ViewState.EMPTY;
      return;
    }

    // 取第一个角色的 UID
    this.roleUid = gameRoles[0].roleId;

    // 加载角色详情 + 历史记录
    await this.loadCharacters(account, gameRoles[0]);
    await this.loadHistory();
    this.viewState = ViewState.DATA;
  }

  /**
   * 加载角色详情列表
   */
  private async loadCharacters(account: AccountRow, role: GameRoleRow): Promise<void> {
    const characters: SelectableCharacterVM[] = [];

    if (this.gameId === GameId.GENSHIN) {
      const list = await CoreInitializer.genshinRepository.getAvatarList(account.uid, role.roleId);
      for (let i = 0; i < list.length; i++) {
        const row = list[i];
        const vm = new SelectableCharacterVM();
        vm.avatarId = row.avatarId;
        vm.name = row.name ?? '';
        vm.rarity = row.rarity;
        vm.level = row.level;
        vm.iconUrl = row.icon ?? '';
        vm.element = row.element ?? '';
        vm.weaponIconUrl = row.weaponIconUrl ?? '';
        vm.weaponLevel = row.weaponLevel;
        vm.weaponRarity = row.weaponRarity;
        characters[characters.length] = vm;
      }
    } else if (this.gameId === GameId.STARRAIL) {
      const list = await CoreInitializer.starRailRepository.getAvatarList(account.uid, role.roleId);
      for (let i = 0; i < list.length; i++) {
        const row = list[i];
        const vm = new SelectableCharacterVM();
        vm.avatarId = row.avatarId;
        vm.name = row.name ?? '';
        vm.rarity = row.rarity;
        vm.level = row.level;
        vm.iconUrl = row.icon ?? '';
        vm.element = row.element ?? '';
        vm.pathOrProfession = row.baseType;
        vm.weaponIconUrl = row.equipIconUrl ?? '';
        vm.weaponLevel = row.equipLevel;
        vm.weaponRarity = row.equipRarity;
        characters[characters.length] = vm;
      }
    } else if (this.gameId === GameId.ZZZ) {
      const list = await CoreInitializer.zzzRepository.getAvatarList(account.uid, role.roleId);
      for (let i = 0; i < list.length; i++) {
        const row = list[i];
        const vm = new SelectableCharacterVM();
        vm.avatarId = row.avatarId;
        vm.name = row.nameMi18n ?? '';
        vm.rarity = row.rarity === 'S' ? 5 : 4;
        vm.level = row.level;
        vm.iconUrl = row.roleSquareUrl ?? '';
        vm.element = `${row.elementType}`;
        vm.pathOrProfession = row.avatarProfession;
        // 代理人列表没有音擎字段，从代理人详情（avatar/info 原始返回）的 weapon 读取；没有详情时不显示
        await MaterialCharacterSelectViewModel.fillZZZWeapon(vm, account.uid, role.roleId);
        characters[characters.length] = vm;
      }
    }

    // 星级从高到低，同星级按角色 ID 从大到小（与角色页一致）
    characters.sort((a: SelectableCharacterVM, b: SelectableCharacterVM) =>
      compareCharacter(a.rarity, a.avatarId, b.rarity, b.avatarId));
    this.characters = characters;
  }

  /** 绝区零：从代理人详情 rawJson 的 weapon 读取音擎图标 / 等级 / 稀有度 */
  private static async fillZZZWeapon(vm: SelectableCharacterVM, accountId: string, roleUid: string): Promise<void> {
    try {
      const detail = await CoreInitializer.zzzRepository.getAvatarDetail(accountId, roleUid, vm.avatarId);
      if (detail === null || detail.rawJson.length === 0) {
        return;
      }
      const raw = JSON.parse(detail.rawJson) as Record<string, Object>;
      const weapon = raw['weapon'] as Record<string, Object> | null | undefined;
      if (weapon === null || weapon === undefined) {
        return;
      }
      vm.weaponIconUrl = `${weapon['icon'] ?? ''}`;
      vm.weaponLevel = typeof weapon['level'] === 'number' ? weapon['level'] as number : detail.weaponLevel;
      const rarity = `${weapon['rarity'] ?? ''}`;
      vm.weaponRarity = rarity === 'S' ? 5 : rarity === 'A' ? 4 : 3;
    } catch (_) {
      // 解析失败时不显示音擎
    }
  }

  /**
   * 构建账号选项列表
   */
  private buildAccountOptions(accounts: AccountRow[]): AccountOption[] {
    const opts: AccountOption[] = [];
    for (let i = 0; i < accounts.length; i++) {
      const a = accounts[i];
      opts[opts.length] = new AccountOption(a.uid, a.username, a.nickname, a.avatarUrl, a.uid);
    }
    return opts;
  }

  /**
   * 更新选中数量和是否可以开始
   */
  private updateSelectedCount(): void {
    let count = 0;
    for (let i = 0; i < this.characters.length; i++) {
      if (this.characters[i].isSelected) {
        count++;
      }
    }
    this.selectedCount = count;
    this.canStart = count > 0;
  }
}
