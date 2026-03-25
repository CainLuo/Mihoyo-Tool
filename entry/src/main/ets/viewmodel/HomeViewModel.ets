/**
 * HomeViewModel.ets
 *
 * 首页 ViewModel，遵循 MVVM 架构规范（见 harmonyos-rules.md 第八节）。
 *
 * 数据流：
 *   loadData()  → 读本地 DB → 渲染（有数据→'data'，无数据→'empty'）
 *                → 冷启动后立即触发一次后台 syncAllDailyNotes()
 *   refresh()   → 先网络同步所有角色的 daily_note → 再读 DB → 渲染
 *
 * 状态机：
 *   loading → data    有本地数据
 *   loading → empty   无本地数据
 *   （无 error 状态，网络失败通过 networkErrorMsg 通知 View 弹 Alert）
 *
 * Geetest 处理：
 *   syncDailyNote 抛出 retcode=10035 时，通过 needGeetest + geetestData 通知 View
 *   View 弹出 GeetestDialog，用户完成后调用 onGeetestResult()
 */

import {
  AccountRepository,
  GameRoleRow,
  DailyNoteRepository,
  GameDataDao,
  SyncMetaDao,
  DataType,
  GeetestService,
  GeetestCreateResult,
  GeetestVerifyInput,
  CoreInitializer
} from 'core';
import { GenshinDailyNoteParser } from 'core';
import { StarRailDailyNoteParser } from 'core';
import { serverDisplayName } from '../utils/ServerNameUtil';
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
import { ViewState } from '../constants/ViewStates';
import { ApiErrorCodes } from 'core';
import { AppConstants } from '../constants/AppConstants';

const TAG: string = 'HomeViewModel';

export type HomeViewState = ViewState;

/** Geetest 触发时传给 View 的数据 */
export class GeetestTrigger {
  createResult: GeetestCreateResult;
  cookie: string;
  gameId: string;
  roleId: string;
  server: string;

  constructor(
    createResult: GeetestCreateResult,
    cookie: string,
    gameId: string,
    roleId: string,
    server: string
  ) {
    this.createResult = createResult;
    this.cookie = cookie;
    this.gameId = gameId;
    this.roleId = roleId;
    this.server = server;
  }
}

/** HomeViewModel @Monitor 路径常量类型 */
export class HomeViewModelKeys {
  networkErrorMsg: string = 'vm.networkErrorMsg';
  geetestTrigger: string = 'vm.geetestTrigger';
}

@ObservedV2
export class HomeViewModel {
  /** @Monitor 路径常量，View 层必须通过此对象引用，禁止直接写字符串字面量 */
  static readonly KEYS: HomeViewModelKeys = new HomeViewModelKeys();

  @Trace viewState: ViewState = ViewState.LOADING;
  @Trace accounts: MihoyoAccountVM[] = [];
  @Trace isRefreshing: boolean = false;

  /** 非空时 View 弹系统 Alert，弹完后 View 应将其清空 */
  @Trace networkErrorMsg: string = '';

  /** 非 null 时 View 弹 GeetestDialog */
  @Trace geetestTrigger: GeetestTrigger | null = null;

  private autoRefreshTimer: number = -1;

  // ─── 公开方法 ────────────────────────────────────────────────

  /**
   * 冷启动加载：读本地 DB → 切换状态，然后后台触发一次网络同步。
   * 同时启动 30 分钟自动刷新定时器。
   */
  async loadData(): Promise<void> {
    // 等待 RDB 初始化完成（CoreInitializer.initCore 是异步的）
    await CoreInitializer.waitForReady();
    this.viewState = ViewState.LOADING;
    try {
      const loaded = await this.fetchFromLocal();
      this.accounts = loaded;
      this.viewState = loaded.length > 0 ? ViewState.DATA : ViewState.EMPTY;
    } catch (error) {
      const msg = error instanceof Error ? error.message : `${error}`;
      Logger.error(TAG, `loadData failed: ${msg}`);
      // DB 读取失败也显示 empty，不进入 error 状态
      this.viewState = ViewState.EMPTY;
    }

    // 冷启动后检查是否需要同步（距上次成功超过 30 分钟才触发）
    this.syncIfNeeded();

    // 启动 30 分钟自动刷新定时器
    this.startAutoRefresh();
  }

  /**
   * 手动刷新：触发网络同步，完成后重新读 DB。
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
      this.viewState = loaded.length > 0 ? ViewState.DATA : ViewState.EMPTY;
    } finally {
      this.isRefreshing = false;
    }
  }

  /**
   * View 层 GeetestDialog 完成后调用此方法。
   * result 为 null 表示用户取消，非 null 则继续重试同步。
   */
  async onGeetestResult(result: GeetestVerifyInput | null): Promise<void> {
    const trigger = this.geetestTrigger;
    this.geetestTrigger = null;

    if (result === null || trigger === null) {
      return;
    }

    // 提交验证结果换取新 challenge
    try {
      const newChallenge = await GeetestService.verifyVerification(result, trigger.cookie);
      // 用新 challenge 重试 syncDailyNote
      await DailyNoteRepository.syncDailyNoteWithChallenge(
        trigger.gameId,
        trigger.roleId,
        trigger.server,
        trigger.cookie,
        newChallenge,
        result.geetest_validate,
        result.geetest_seccode
      );
      // 重试成功后刷新 UI
      const loaded = await this.fetchFromLocal();
      this.accounts = loaded;
      this.viewState = loaded.length > 0 ? ViewState.DATA : ViewState.EMPTY;
    } catch (error) {
      const msg = error instanceof Error ? error.message : `${error}`;
      Logger.error(TAG, `onGeetestResult retry failed: ${msg}`);
      this.networkErrorMsg = msg;
    }
  }

  /** 释放定时器，在组件 aboutToDisappear 中调用 */
  dispose(): void {
    this.stopAutoRefresh();
  }

  // ─── 私有方法 ────────────────────────────────────────────────

  private startAutoRefresh(): void {
    this.stopAutoRefresh();
    this.autoRefreshTimer = setInterval(() => {
      Logger.info(TAG, 'auto refresh triggered');
      this.syncIfNeeded().then(() => {
        this.fetchFromLocal().then((loaded) => {
          this.accounts = loaded;
          this.viewState = loaded.length > 0 ? ViewState.DATA : ViewState.EMPTY;
        }).catch((e: Error) => {
          Logger.warn(TAG, `auto refresh fetchFromLocal failed: ${e.message}`);
        });
      }).catch((e: Error) => {
        Logger.warn(TAG, `auto refresh sync failed: ${e.message}`);
      });
    }, AppConstants.AUTO_REFRESH_INTERVAL_MS);
  }

  private stopAutoRefresh(): void {
    if (this.autoRefreshTimer !== -1) {
      clearInterval(this.autoRefreshTimer);
      this.autoRefreshTimer = -1;
    }
  }

  /**
   * 按需同步：遍历所有角色，只对距上次成功超过 30 分钟的角色触发同步。
   * 用于冷启动和定时器回调，避免每次都无条件请求网络。
   */
  private async syncIfNeeded(): Promise<void> {
    const pairs = await AccountRepository.findAllAccountsWithRoles();
    for (const pair of pairs) {
      for (const role of pair.roles) {
        let needed = false;
        try {
          needed = await SyncMetaDao.needsSync(role.gameId, role.roleId, DataType.DAILY_NOTE);
        } catch (_) {
          needed = true;
        }
        if (!needed) {
          Logger.info(TAG, `skip sync (within 30min): ${role.gameId}/${role.roleId}`);
          continue;
        }
        try {
          await DailyNoteRepository.syncDailyNote(
            role.gameId,
            role.roleId,
            role.server,
            pair.account.cookie
          );
        } catch (error) {
          const msg = error instanceof Error ? error.message : `${error}`;
          if (msg.indexOf(`retcode=${ApiErrorCodes.GEETEST_REQUIRED}`) !== -1) {
            Logger.info(TAG, `Geetest required for ${role.gameId}/${role.roleId}`);
            await this.handleGeetest(pair.account.cookie, role);
          } else {
            Logger.warn(TAG, `syncIfNeeded failed for ${role.gameId}/${role.roleId}: ${msg}`);
            this.networkErrorMsg = msg;
          }
        }
      }
    }
  }

  /**
   * 遍历所有账号角色，逐一调用 DailyNoteRepository.syncDailyNote。
   * 单个角色失败不中断整体：
   *   - retcode=10035 → 触发 Geetest 流程
   *   - 其他错误 → 通知 View 弹 Alert，保留旧数据
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
          if (msg.indexOf(`retcode=${ApiErrorCodes.GEETEST_REQUIRED}`) !== -1) {
            // 需要 Geetest 验证
            Logger.info(TAG, `Geetest required for ${role.gameId}/${role.roleId}`);
            await this.handleGeetest(pair.account.cookie, role);
          } else {
            Logger.warn(TAG, `syncDailyNote failed for ${role.gameId}/${role.roleId}: ${msg}`);
            this.networkErrorMsg = msg;
          }
        }
      }
    }
  }

  /**
   * 触发 Geetest 流程：先调 createVerification 拿到参数，再通知 View 弹窗。
   */
  private async handleGeetest(cookie: string, role: GameRoleRow): Promise<void> {
    try {
      const createResult = await GeetestService.createVerification(cookie);
      this.geetestTrigger = new GeetestTrigger(
        createResult,
        cookie,
        role.gameId,
        role.roleId,
        role.server
      );
    } catch (error) {
      const msg = error instanceof Error ? error.message : `${error}`;
      Logger.error(TAG, `createVerification failed: ${msg}`);
      this.networkErrorMsg = msg;
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
        serverDisplayName(role.server),
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

      if (gameId === GAME_GENSHIN) {
        // 原神：用 Parser 解析 raw_json，填充所有字段
        const data = GenshinDailyNoteParser.parse(row.rawJson);
        const isFull = data.currentResin >= data.maxResin && data.maxResin > 0;
        const recoveryDesc = isFull ? '' : HomeViewModel.resinRecoveryDesc(data.resinRecoveryTime);
        const snap = new GameNoteSnapshotVM(
          gameId, data.currentResin, data.maxResin, recoveryDesc, '', '', isFull
        );
        snap.expeditionCurrent = data.expeditions.length;
        snap.expeditionMax = data.maxExpeditionNum;
        snap.homeCoinCurrent = data.currentHomeCoin;
        snap.homeCoinMax = data.maxHomeCoin;
        snap.dailyTaskFinished = data.finishedTaskNum;
        snap.dailyTaskTotal = data.totalTaskNum;
        snap.dailyTaskAllReceived = data.isExtraTaskRewardReceived;
        return snap;
      }

      if (gameId === GAME_STARRAIL) {
        // 崩铁：用 Parser 解析 raw_json，填充所有字段
        const data = StarRailDailyNoteParser.parse(row.rawJson);
        const stamina = data.currentStamina > 0 ? data.currentStamina : row.extraInt1;
        const maxStamina = data.maxStamina > 0 ? data.maxStamina : row.extraInt2;
        const isFull = stamina >= maxStamina && maxStamina > 0;
        const recoveryDesc = isFull ? '' : HomeViewModel.resinRecoveryDesc(data.staminaRecoverTime);
        const snap = new GameNoteSnapshotVM(
          gameId, stamina, maxStamina, recoveryDesc, '', '', isFull
        );
        snap.reserveStamina = data.currentReserveStamina;
        snap.trainScoreCurrent = data.currentTrainScore;
        snap.trainScoreMax = data.maxTrainScore;
        snap.weeklyCocoonCnt = data.weeklyCocoonCnt;
        snap.weeklyCocoonLimit = data.weeklyCocoonLimit;
        snap.rogueScoreCurrent = data.currentRogueScore;
        snap.rogueScoreMax = data.maxRogueScore;
        snap.tournScoreCurrent = data.rogueTournWeeklyCur;
        snap.tournScoreMax = data.rogueTournWeeklyMax;
        return snap;
      }

      // 其他游戏：沿用旧逻辑（extraInt1/extraInt2）
      const isFull = row.extraInt1 >= row.extraInt2 && row.extraInt2 > 0;
      return new GameNoteSnapshotVM(gameId, row.extraInt1, row.extraInt2, '', '', '', isFull);
    } catch (error) {
      const msg = error instanceof Error ? error.message : `${error}`;
      Logger.warn(TAG, `loadDailyNoteSnapshot failed for ${gameId}/${roleUid}: ${msg}`);
      return null;
    }
  }

  /** 将剩余恢复秒数转为描述文字 */
  private static resinRecoveryDesc(seconds: number): string {
    if (!seconds || seconds <= 0) { return ''; }
    const h = Math.floor(seconds / 3600);
    const m = Math.floor((seconds % 3600) / 60);
    if (h > 0) { return `将于 ${h} 小时 ${m} 分钟后全部恢复`; }
    return `将于 ${m} 分钟后全部恢复`;
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
