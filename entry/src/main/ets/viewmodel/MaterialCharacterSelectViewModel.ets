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
      this.viewState = ViewState.EMPTY;
      return;
    }

    // 取第一个角色的 UID
    this.roleUid = gameRoles[0].roleId;

    // 加载角色详情
    await this.loadCharacters(account, gameRoles[0]);
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
        characters[characters.length] = vm;
      }
    }

    this.characters = characters;
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
