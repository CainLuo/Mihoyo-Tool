/**
 * ToolsViewModel.ets — 工具页 ViewModel
 *
 * 工具页展示三个游戏的材料总汇入口，每个入口显示：
 * - 游戏名称和图标
 * - 角色数量
 * - 已计算角色数量
 *
 * 数据流：
 *   loadData() → 读本地 DB（账号 + 角色） → 按游戏汇总 → 渲染
 *
 * 状态机：
 *   LOADING → DATA    有账号有角色
 *   LOADING → EMPTY   无账号
 */

import {
  CoreInitializer,
  AccountRow,
  GameId,
  Logger,
  GenshinMaterialTargetConfigDao,
  StarRailMaterialTargetConfigDao,
  ZZZMaterialTargetConfigDao,
} from 'core';
import { ViewState } from '../constants/ViewStates';
import { GameEntryVM } from '../models/ToolsModels';
import { gameIdToColor, gameIdToLogo, gameIdToName } from '../utils/GameIdUtil';

const TAG: string = 'ToolsViewModel';

/** ToolsViewModel @Monitor 路径常量类型 */
export class ToolsViewModelKeys {
  // 当前无需监听特定字段
}

@ObservedV2
export class ToolsViewModel {
  /** @Monitor 路径常量 */
  static readonly KEYS: ToolsViewModelKeys = new ToolsViewModelKeys();

  @Trace viewState: ViewState = ViewState.LOADING;
  @Trace accountCount: number = 0;
  @Trace gameEntries: GameEntryVM[] = [];

  // ─── 公开方法 ────────────────────────────────────────────────

  /**
   * 冷启动加载：读本地 DB，组装游戏入口列表。
   */
  async loadData(): Promise<void> {
    await CoreInitializer.waitForReady();
    this.viewState = ViewState.LOADING;

    try {
      const accounts = await CoreInitializer.bbsRepository.getAllAccounts();
      this.accountCount = accounts.length;

      if (accounts.length === 0) {
        this.viewState = ViewState.EMPTY;
        this.gameEntries = [];
        return;
      }

      // 按游戏汇总角色数量和计算数量
      const entries = await this.buildGameEntries(accounts);
      this.gameEntries = entries;
      this.viewState = ViewState.DATA;
    } catch (error) {
      const msg = error instanceof Error ? error.message : `${error}`;
      Logger.error(TAG, `loadData failed: ${msg}`);
      this.viewState = ViewState.EMPTY;
    }
  }

  // ─── 私有方法 ────────────────────────────────────────────────

  /**
   * 构建游戏入口列表，每个游戏统计角色数量和计算数量。
   * 同时记录每个游戏的第一个角色 UID，用于跳转配置页时传递参数。
   */
  private async buildGameEntries(accounts: AccountRow[]): Promise<GameEntryVM[]> {
    const gameIds: GameId[] = [GameId.GENSHIN, GameId.STARRAIL, GameId.ZZZ];
    const entries: GameEntryVM[] = [];

    // 统计各游戏的角色数量
    const roleCounts: Map<GameId, number> = new Map();
    // 统计各游戏已计算的角色数量
    const computedCounts: Map<GameId, number> = new Map();
    // 首个账号 UID（用于填充 entry.accountId）
    let firstAccountUid: string = '';
    // 各游戏的第一个角色 UID（用于跳转配置页）
    const firstRoleUids: Map<GameId, string> = new Map();

    for (let i = 0; i < accounts.length; i++) {
      const account = accounts[i];
      if (firstAccountUid === '') {
        firstAccountUid = account.uid;
      }
      const roles = await CoreInitializer.bbsRepository.getGameRoles(account.uid);

      for (let j = 0; j < roles.length; j++) {
        const role = roles[j];
        const gameId = role.gameId;
        const current = roleCounts.get(gameId) ?? 0;
        roleCounts.set(gameId, current + 1);

        // 记录该游戏的第一个角色 UID
        if (!firstRoleUids.has(gameId)) {
          firstRoleUids.set(gameId, role.roleId);
        }

        // 统计已计算的角色数量（通过查询对应的 compute 表）
        const hasComputeData = await this.hasComputeData(gameId, account.uid, role.roleId);
        if (hasComputeData) {
          const computed = computedCounts.get(gameId) ?? 0;
          computedCounts.set(gameId, computed + 1);
        }
      }
    }

    // 构建游戏入口
    for (let i = 0; i < gameIds.length; i++) {
      const gameId = gameIds[i];
      const count = roleCounts.get(gameId) ?? 0;
      const computed = computedCounts.get(gameId) ?? 0;

      const entry = new GameEntryVM();
      entry.accountId = firstAccountUid;
      entry.roleUid = firstRoleUids.get(gameId) ?? '';
      entry.gameId = gameId;
      entry.gameName = gameIdToName(gameId);
      entry.gameIcon = gameIdToLogo(gameId);
      entry.gameColor = gameIdToColor(gameId);
      entry.characterCount = count;
      entry.computedCount = computed;
      entry.hasData = count > 0;

      entries[entries.length] = entry;
    }

    return entries;
  }

  /**
   * 检查指定角色是否有养成目标配置数据
   * 用户在配置页设置完目标等级后，config 表会有数据，此时应认为"已配置"
   */
  private async hasComputeData(gameId: GameId, accountUid: string, roleUid: string): Promise<boolean> {
    try {
      if (gameId === GameId.GENSHIN) {
        const dao = new GenshinMaterialTargetConfigDao();
        const config = await dao.findOne(accountUid, roleUid);
        return config !== null && config.configJson !== '';
      } else if (gameId === GameId.STARRAIL) {
        const dao = new StarRailMaterialTargetConfigDao();
        const config = await dao.findOne(accountUid, roleUid);
        return config !== null && config.configJson !== '';
      } else if (gameId === GameId.ZZZ) {
        const dao = new ZZZMaterialTargetConfigDao();
        const config = await dao.findOne(accountUid, roleUid);
        return config !== null && config.configJson !== '';
      }
      return false;
    } catch (error) {
      const msg = error instanceof Error ? error.message : `${error}`;
      Logger.error(TAG, `hasComputeData failed for ${gameId}: ${msg}`);
      return false;
    }
  }
}
