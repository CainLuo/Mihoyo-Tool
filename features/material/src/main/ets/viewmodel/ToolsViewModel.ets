/**
 * ToolsViewModel.ets — 工具页 ViewModel
 *
 * 工具页展示三个游戏的材料总汇入口，每个入口显示：
 * - 游戏名称和图标
 * - 角色数量
 * - 已配置养成目标的角色数量
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
import { ViewState, getGameLogo, getGameName } from 'basic';
import { GameEntryVM } from '../model/ToolsModels';

const TAG: string = 'ToolsViewModel';
const SUPPORTED_GAMES: GameId[] = [GameId.GENSHIN, GameId.STARRAIL, GameId.ZZZ];

@ObservedV2
export class ToolsViewModel {
  @Trace viewState: ViewState = ViewState.LOADING;
  @Trace accountCount: number = 0;
  @Trace gameEntries: GameEntryVM[] = [];

  // DAO 无实例状态，复用同一实例即可，避免每个角色都 new 一次
  private readonly genshinConfigDao: GenshinMaterialTargetConfigDao = new GenshinMaterialTargetConfigDao();
  private readonly starRailConfigDao: StarRailMaterialTargetConfigDao = new StarRailMaterialTargetConfigDao();
  private readonly zzzConfigDao: ZZZMaterialTargetConfigDao = new ZZZMaterialTargetConfigDao();

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

      this.gameEntries = await this.buildGameEntries(accounts);
      this.viewState = ViewState.DATA;
    } catch (error) {
      const msg = error instanceof Error ? error.message : `${error}`;
      Logger.error(TAG, `loadData failed: ${msg}`);
      this.viewState = ViewState.EMPTY;
    }
  }

  // ─── 私有方法 ────────────────────────────────────────────────

  /**
   * 构建游戏入口列表，每个游戏统计角色数量和已配置目标的数量。
   * 同时记录每个游戏的第一个角色 UID，用于跳转角色选择页时传递参数。
   */
  private async buildGameEntries(accounts: AccountRow[]): Promise<GameEntryVM[]> {
    const roleCounts: Map<GameId, number> = new Map();
    const configuredCounts: Map<GameId, number> = new Map();
    const firstRoleUids: Map<GameId, string> = new Map();
    // 首个账号 UID（用于填充 entry.accountId）
    let firstAccountUid: string = '';

    for (const account of accounts) {
      if (firstAccountUid === '') {
        firstAccountUid = account.uid;
      }
      const roles = await CoreInitializer.bbsRepository.getGameRoles(account.uid);

      for (const role of roles) {
        const gameId = role.gameId;
        roleCounts.set(gameId, (roleCounts.get(gameId) ?? 0) + 1);

        if (!firstRoleUids.has(gameId)) {
          firstRoleUids.set(gameId, role.roleId);
        }

        if (await this.hasTargetConfig(gameId, account.uid, role.roleId)) {
          configuredCounts.set(gameId, (configuredCounts.get(gameId) ?? 0) + 1);
        }
      }
    }

    const entries: GameEntryVM[] = [];
    for (const gameId of SUPPORTED_GAMES) {
      const characterCount = roleCounts.get(gameId) ?? 0;
      const entry = new GameEntryVM();
      entry.accountId = firstAccountUid;
      entry.roleUid = firstRoleUids.get(gameId) ?? '';
      entry.gameId = gameId;
      entry.gameName = getGameName(gameId);
      entry.gameIcon = getGameLogo(gameId);
      entry.characterCount = characterCount;
      entry.computedCount = configuredCounts.get(gameId) ?? 0;
      entry.hasData = characterCount > 0;
      entries.push(entry);
    }
    return entries;
  }

  /**
   * 检查指定角色是否已保存养成目标配置。
   * 用户在配置页保存后 material_target_config 表会有记录，此时认为"已配置"。
   */
  private async hasTargetConfig(gameId: GameId, accountUid: string, roleUid: string): Promise<boolean> {
    try {
      if (gameId === GameId.GENSHIN) {
        const config = await this.genshinConfigDao.findOne(accountUid, roleUid);
        return config !== null && config.configJson !== '';
      } else if (gameId === GameId.STARRAIL) {
        const config = await this.starRailConfigDao.findOne(accountUid, roleUid);
        return config !== null && config.configJson !== '';
      } else if (gameId === GameId.ZZZ) {
        const config = await this.zzzConfigDao.findOne(accountUid, roleUid);
        return config !== null && config.configJson !== '';
      }
      return false;
    } catch (error) {
      const msg = error instanceof Error ? error.message : `${error}`;
      Logger.error(TAG, `hasTargetConfig failed for ${gameId}: ${msg}`);
      return false;
    }
  }
}
