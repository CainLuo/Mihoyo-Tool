/**
 * HomeViewModel.ets
 *
 * 首页 ViewModel，遵循 MVVM 架构规范（见 harmonyos-rules.md 第八节）。
 *
 * 数据流：
 *   loadData()  → 读本地 DB → 渲染
 *   refresh()   → 先网络同步所有角色的 daily_note → 再读 DB → 渲染
 *
 * 注意：
 *   gameName / primaryLabel 字段存 gameId，View 层负责映射 $r 资源字符串。
 *   lastSyncDesc 存资源 key（如 'sync_just_now'），View 层负责映射。
 */

import { AccountRepository, GameRoleRow, DailyNoteRepository, GameDataDao, DataType } from 'core';
import {
  MihoyoAccountVM,
  GameRoleCardVM,
  GameNoteSnapshotVM,
  GAME_GENSHIN,
  GAME_STARRAIL,
  GAME_ZZZ,
  GAME_HONKAI3
} from '../components/home/HomeModels';
import { Logger } from '../utils/Logger';

const TAG: string = 'HomeViewModel';

export type HomeViewState = 'loading' | 'empty' | 'data' | 'error';

@ObservedV2
export class HomeViewModel {
  @Trace viewState: HomeViewState = 'loading';
  @Trace accounts: MihoyoAccountVM[] = [];
  @Trace isRefreshing: boolean = false;
  @Trace errorMessage: string = '';

  /**
   * 冷启动加载：显示 Skeleton → 读本地 DB → 切换状态。
   */
  async loadData(): Promise<void> {
    this.viewState = 'loading';
    try {
      const loaded = await this.fetchFromLocal();
      this.accounts = loaded;
      this.viewState = loaded.length > 0 ? 'data' : 'empty';
    } catch (error) {
      const msg = error instanceof Error ? error.message : `${error}`;
      Logger.error(TAG, `loadData failed: ${msg}`);
      this.errorMessage = msg;
      this.viewState = 'error';
    }
  }

  /**
   * 手动刷新：先网络同步所有角色的 daily_note，再读 DB 更新 UI。
   * 不切换到 loading/skeleton，isRefreshing 驱动刷新按钮状态。
   */
  async refresh(): Promise<void> {
    if (this.isRefreshing) {
      return;
    }
    this.isRefreshing = true;
    try {
      await this.syncAllDailyNotes();
      const loaded = await this.fetchFromLocal();
      this.accounts = loaded;
      this.viewState = loaded.length > 0 ? 'data' : 'empty';
    } catch (error) {
      const msg = error instanceof Error ? error.message : `${error}`;
      Logger.error(TAG, `refresh failed: ${msg}`);
    } finally {
      this.isRefreshing = false;
    }
  }

  // ─── 私有方法 ────────────────────────────────────────────────

  /**
   * 遍历所有账号角色，逐一调用 DailyNoteRepository.syncDailyNote。
   * 单个角色失败不中断整体，只记录 warn 日志。
   */
  private async syncAllDailyNotes(): Promise<void> {
    const pairs = await AccountRepository.findAllAccountsWithRoles();
    for (const pair of pairs) {
      for (const role of pair.roles) {
        try {
          await DailyNoteRepository.syncDailyNote(
            role.gameId,
            role.roleId,
            role.server,
            pair.account.cookie
          );
        } catch (error) {
          const msg = error instanceof Error ? error.message : `${error}`;
          Logger.warn(TAG, `syncDailyNote failed for ${role.gameId}/${role.roleId}: ${msg}`);
        }
      }
    }
  }

  /** 从本地 DB 读取账号 + 角色 + daily_note，组装 UI ViewModel */
  private async fetchFromLocal(): Promise<MihoyoAccountVM[]> {
    const pairs = await AccountRepository.findAllAccountsWithRoles();
    const result: MihoyoAccountVM[] = [];
    for (const pair of pairs) {
      const cards = await this.buildRoleCards(pair.roles);
      result[result.length] = new MihoyoAccountVM(pair.account.id, pair.account.username, cards);
    }
    return result;
  }

  /** 将 GameRoleRow[] 转换为 GameRoleCardVM[]，每个角色查一次 daily_note */
  private async buildRoleCards(roles: GameRoleRow[]): Promise<GameRoleCardVM[]> {
    const cards: GameRoleCardVM[] = [];
    for (const role of roles) {
      const snapshot = await this.loadDailyNoteSnapshot(role.gameId, role.roleId);
      cards[cards.length] = new GameRoleCardVM(
        role.gameId,
        role.gameId,
        HomeViewModel.gameColor(role.gameId),
        role.roleId,
        role.nickname,
        role.server,
        snapshot,
        snapshot !== null ? 'sync_just_now' : 'sync_not_synced'
      );
    }
    return cards;
  }

  /**
   * 从 game_data 表读取 daily_note，解析为 GameNoteSnapshotVM。
   * 找不到数据时返回 null（UI 显示"未同步"状态）。
   */
  private async loadDailyNoteSnapshot(
    gameId: string,
    roleUid: string
  ): Promise<GameNoteSnapshotVM | null> {
    try {
      const row = await GameDataDao.findOne(gameId, roleUid, DataType.DAILY_NOTE, 'daily_note');
      if (row === null) {
        return null;
      }
      // extra_int1 = 当前树脂/开拓力，extra_int2 = 最大值
      const isFull = row.extraInt1 >= row.extraInt2 && row.extraInt2 > 0;
      return new GameNoteSnapshotVM(gameId, row.extraInt1, row.extraInt2, '', '', '', isFull);
    } catch (error) {
      const msg = error instanceof Error ? error.message : `${error}`;
      Logger.warn(TAG, `loadDailyNoteSnapshot failed for ${gameId}/${roleUid}: ${msg}`);
      return null;
    }
  }

  /** 根据 gameId 返回对应的游戏主题色资源引用 */
  private static gameColor(gameId: string): ResourceColor {
    if (gameId === GAME_GENSHIN) {
      return $r('app.color.game_color_genshin');
    }
    if (gameId === GAME_STARRAIL) {
      return $r('app.color.game_color_starrail');
    }
    if (gameId === GAME_ZZZ) {
      return $r('app.color.game_color_zzz');
    }
    if (gameId === GAME_HONKAI3) {
      return $r('app.color.game_color_honkai3');
    }
    return $r('app.color.color_accent');
  }
}
