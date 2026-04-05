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
 *
 * 注意：网络同步部分（syncDailyNote / syncAllDailyNotes）暂时保留旧版调用，
 *       DB 读取部分已切换到 v2 Repository。
 */

import {
  GameRoleRow,
  DailyNoteRepository,
  GeetestService,
  GeetestCreateResult,
  GeetestVerifyInput,
  CoreInitializerV2,
  AccountRowV2,
  GameRoleRowV2
} from 'core';
import { GenshinDailyNoteParser } from 'core';
import { StarRailDailyNoteParser } from 'core';
import { ZZZDailyNoteParser } from 'core';
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
  refreshCoolingDown: string = 'vm.refreshCoolingDown';
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

  /** 手动刷新冷却信号（切换时触发 View 弹 Dialog） */
  @Trace refreshCoolingDown: boolean = false;

  private autoRefreshTimer: number = -1;

  // ─── 公开方法 ────────────────────────────────────────────────

  /**
   * 冷启动加载：读本地 DB → 切换状态，然后后台触发一次网络同步。
   * 同时启动 30 分钟自动刷新定时器。
   */
  async loadData(): Promise<void> {
    await CoreInitializerV2.waitForReady();
    this.viewState = ViewState.LOADING;
    try {
      const loaded = await this.fetchFromLocal();
      this.accounts = loaded;
      this.viewState = loaded.length > 0 ? ViewState.DATA : ViewState.EMPTY;
    } catch (error) {
      const msg = error instanceof Error ? error.message : `${error}`;
      Logger.error(TAG, `loadData failed: ${msg}`);
      this.viewState = ViewState.EMPTY;
    }

    const hasAccountsButNoCards = this.accounts.length > 0 &&
      this.accounts.every(a => a.roles.length === 0);

    if (hasAccountsButNoCards) {
      try {
        await this.syncAllDailyNotes();
        const refreshed = await this.fetchFromLocal();
        this.accounts = refreshed;
        this.viewState = refreshed.length > 0 ? ViewState.DATA : ViewState.EMPTY;
      } catch (e) {
        const msg = e instanceof Error ? e.message : `${e}`;
        Logger.error(TAG, `syncAllDailyNotes path failed: ${msg}`);
      }
    } else {
      this.syncIfNeeded().then(async () => {
        try {
          const refreshed = await this.fetchFromLocal();
          this.accounts = refreshed;
          this.viewState = refreshed.length > 0 ? ViewState.DATA : ViewState.EMPTY;
        } catch (_) {}
      }).catch((_: Error | object) => {});
    }
    this.startAutoRefresh();
  }

  /**
   * 手动刷新：触发网络同步，完成后重新读 DB。
   */
  async refresh(): Promise<void> {
    if (this.isRefreshing) {
      return;
    }
    const lastRefresh = AppStorage.get<number>('homeLastRefreshTime') ?? 0;
    const now = Math.floor(Date.now() / 1000);
    if (now - lastRefresh < AppConstants.AUTO_REFRESH_INTERVAL_MS / 1000) {
      this.refreshCoolingDown = !this.refreshCoolingDown;
      return;
    }
    this.isRefreshing = true;
    try {
      await this.syncAllDailyNotes();
      AppStorage.setOrCreate('homeLastRefreshTime', Math.floor(Date.now() / 1000));
      const loaded = await this.fetchFromLocal();
      this.accounts = loaded;
      this.viewState = loaded.length > 0 ? ViewState.DATA : ViewState.EMPTY;
    } finally {
      this.isRefreshing = false;
    }
  }

  /**
   * 强制刷新：跳过冷却检查，直接触发同步。
   */
  async forceRefresh(): Promise<void> {
    if (this.isRefreshing) {
      return;
    }
    this.isRefreshing = true;
    try {
      await this.syncAllDailyNotes();
      AppStorage.setOrCreate('homeLastRefreshTime', Math.floor(Date.now() / 1000));
      const loaded = await this.fetchFromLocal();
      this.accounts = loaded;
      this.viewState = loaded.length > 0 ? ViewState.DATA : ViewState.EMPTY;
    } finally {
      this.isRefreshing = false;
    }
  }

  /**
   * View 层 GeetestDialog 完成后调用此方法。
   */
  async onGeetestResult(result: GeetestVerifyInput | null): Promise<void> {
    const trigger = this.geetestTrigger;
    this.geetestTrigger = null;

    if (result === null || trigger === null) {
      return;
    }

    try {
      const newChallenge = await GeetestService.verifyVerification(result, trigger.cookie);
      await DailyNoteRepository.syncDailyNoteWithChallenge(
        trigger.gameId,
        trigger.roleId,
        trigger.server,
        trigger.cookie,
        newChallenge,
        result.geetest_validate,
        result.geetest_seccode
      );
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
   * 按需同步：遍历所有账号角色，只对需要同步的角色触发同步。
   * 暂时保留旧版 DailyNoteRepository 网络调用。
   */
  private async syncIfNeeded(): Promise<void> {
    const accounts = await CoreInitializerV2.bbsRepository.getAllAccounts();
    for (let ai = 0; ai < accounts.length; ai++) {
      const account = accounts[ai];
      const roles = await CoreInitializerV2.bbsRepository.getGameRoles(account.id);
      for (let ri = 0; ri < roles.length; ri++) {
        const role = roles[ri];
        let needed = false;
        try {
          needed = await HomeViewModel.needsDailyNoteSync(account.id, role.roleId, role.gameId);
        } catch (_) {
          needed = true;
        }
        if (!needed) {
          Logger.info(TAG, `skip sync (within 30min): ${role.gameId}/${role.roleId}`);
          continue;
        }
        try {
          // 暂时保留旧版网络同步调用
          await DailyNoteRepository.syncDailyNote(
            role.gameId,
            role.roleId,
            role.server,
            account.cookie
          );
        } catch (error) {
          const msg = error instanceof Error ? error.message : `${error}`;
          if (msg.indexOf(`retcode=${ApiErrorCodes.GEETEST_REQUIRED}`) !== -1) {
            Logger.info(TAG, `Geetest required for ${role.gameId}/${role.roleId}`);
            await this.handleGeetestV2(account.cookie, role);
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
   * 暂时保留旧版网络同步调用。
   */
  private async syncAllDailyNotes(): Promise<void> {
    const accounts = await CoreInitializerV2.bbsRepository.getAllAccounts();
    for (let ai = 0; ai < accounts.length; ai++) {
      const account = accounts[ai];
      const roles = await CoreInitializerV2.bbsRepository.getGameRoles(account.id);
      for (let ri = 0; ri < roles.length; ri++) {
        const role = roles[ri];
        try {
          // 暂时保留旧版网络同步调用
          await DailyNoteRepository.syncDailyNote(
            role.gameId,
            role.roleId,
            role.server,
            account.cookie
          );
        } catch (error) {
          const msg = error instanceof Error ? error.message : `${error}`;
          if (msg.indexOf(`retcode=${ApiErrorCodes.GEETEST_REQUIRED}`) !== -1) {
            Logger.info(TAG, `Geetest required for ${role.gameId}/${role.roleId}`);
            await this.handleGeetestV2(account.cookie, role);
          } else {
            Logger.warn(TAG, `syncDailyNote failed for ${role.gameId}/${role.roleId}: ${msg}`);
            this.networkErrorMsg = msg;
          }
        }
      }
    }
  }

  /**
   * 触发 Geetest 流程（v2 版本，使用 GameRoleRowV2）
   */
  private async handleGeetestV2(cookie: string, role: GameRoleRowV2): Promise<void> {
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

  /**
   * 检查指定游戏角色是否需要同步 daily_note（v2 版本）
   */
  private static async needsDailyNoteSync(accountId: number, roleUid: string, gameId: string): Promise<boolean> {
    if (gameId === GAME_GENSHIN) {
      return CoreInitializerV2.genshinRepository.needsDailyNoteSync(accountId, roleUid);
    }
    if (gameId === GAME_STARRAIL) {
      return CoreInitializerV2.starRailRepository.needsDailyNoteSync(accountId, roleUid);
    }
    if (gameId === GAME_ZZZ) {
      return CoreInitializerV2.zzzRepository.needsDailyNoteSync(accountId, roleUid);
    }
    return true;
  }

  /** 从本地 DB 读取账号 + 角色 + daily_note，组装 UI ViewModel（v2 版本） */
  private async fetchFromLocal(): Promise<MihoyoAccountVM[]> {
    const accounts = await CoreInitializerV2.bbsRepository.getAllAccounts();
    const result: MihoyoAccountVM[] = [];
    for (let ai = 0; ai < accounts.length; ai++) {
      const account = accounts[ai];
      const roles = await CoreInitializerV2.bbsRepository.getGameRoles(account.id);
      const cards = await this.buildRoleCardsV2(account, roles);
      result[result.length] = new MihoyoAccountVM(
        account.id, account.username, cards, account.nickname, account.avatarUrl
      );
    }
    return result;
  }

  /** 将 GameRoleRowV2[] 转换为 GameRoleCardVM[]，每个角色查一次 daily_note */
  private async buildRoleCardsV2(account: AccountRowV2, roles: GameRoleRowV2[]): Promise<GameRoleCardVM[]> {
    const cards: GameRoleCardVM[] = [];
    for (let ri = 0; ri < roles.length; ri++) {
      const role = roles[ri];
      const snapshot = await this.loadDailyNoteSnapshotV2(account.id, role.gameId, role.roleId);
      if (snapshot === null) {
        continue;
      }
      cards[cards.length] = new GameRoleCardVM(
        role.gameId,
        role.gameId,
        HomeViewModel.gameColor(role.gameId),
        role.roleId,
        role.nickname,
        serverDisplayName(role.server, role.gameId) ?? role.server,
        snapshot,
        'sync_just_now'
      );
    }
    return cards;
  }

  /**
   * 从 v2 DB 读取 daily_note，解析为 GameNoteSnapshotVM。
   */
  private async loadDailyNoteSnapshotV2(
    accountId: number,
    gameId: string,
    roleUid: string
  ): Promise<GameNoteSnapshotVM | null> {
    try {
      if (gameId === GAME_GENSHIN) {
        const row = await CoreInitializerV2.genshinRepository.getDailyNote(accountId, roleUid);
        if (row === null) {
          return null;
        }
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
        const row = await CoreInitializerV2.starRailRepository.getDailyNote(accountId, roleUid);
        if (row === null) {
          return null;
        }
        const data = StarRailDailyNoteParser.parse(row.rawJson);
        const stamina = data.currentStamina > 0 ? data.currentStamina : row.currentStamina;
        const maxStamina = data.maxStamina > 0 ? data.maxStamina : row.maxStamina;
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

      if (gameId === GAME_ZZZ) {
        const row = await CoreInitializerV2.zzzRepository.getDailyNote(accountId, roleUid);
        if (row === null) {
          return null;
        }
        const data = ZZZDailyNoteParser.parse(row.rawJson);
        const energy = data.currentEnergy > 0 ? data.currentEnergy : row.energyCurrent;
        const maxEnergy = data.maxEnergy > 0 ? data.maxEnergy : row.energyMax;
        const zzzisFull = energy >= maxEnergy && maxEnergy > 0;
        const zzzRecovery = zzzisFull ? '' : HomeViewModel.resinRecoveryDesc(data.energyRecoverTime);
        const snap = new GameNoteSnapshotVM(gameId, energy, maxEnergy, zzzRecovery, '', '', zzzisFull);
        snap.vitalityCurrent = data.currentVitality;
        snap.vitalityMax = data.maxVitality;
        snap.scratchCardDone = data.cardSign === 'CardSignDone';
        if (data.videoStoreState === 'SaleStateDone') {
          snap.videoStoreState = 'done';
        } else if (data.videoStoreState === 'SaleStateDoing') {
          snap.videoStoreState = 'open';
        } else {
          snap.videoStoreState = 'closed';
        }
        return snap;
      }

      return null;
    } catch (error) {
      const msg = error instanceof Error ? error.message : `${error}`;
      Logger.warn(TAG, `loadDailyNoteSnapshotV2 failed for ${gameId}/${roleUid}: ${msg}`);
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
