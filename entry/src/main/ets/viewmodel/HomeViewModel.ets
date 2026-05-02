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
  GeetestService,
  GeetestCreateResult,
  GeetestVerifyInput,
  CoreInitializer,
  AccountRow,
  GameRoleRow,
  ColdStartCookieChecker,
  ColdStartRefreshResult,
  FailedAccountInfo,
  AuthExpiredError,
  GameId,
  GenshinDailyNoteParser,
  StarRailDailyNoteParser,
  ZZZDailyNoteParser,
  Logger,
  ApiErrorCodes,
} from 'core';
import { GeetestTrigger } from '../models/GeetestTrigger';
import { serverDisplayName } from '../utils/ServerNameUtil';
import { CookieExpiredSignal } from '../utils/CookieExpiredSignal';
import {
  MihoyoAccountVM,
  GameRoleCardVM,
  GameNoteSnapshotVM,
  GameDataRowVM,
} from '../models/HomeModels';
import { ZZZVideoStoreState, ZZZCardSign } from 'core';
import { ViewState } from '../constants/ViewStates';
import { AppConstants } from '../constants/AppConstants';
import { StaminaNotificationService } from '../notification/StaminaNotificationService';
import { gameIdToColor, gameIdToLogo } from '../utils/GameIdUtil';
import { AppRoutes } from '../constants/AppRoutes';
import { GenshinDailyDetailParam } from '../pages/GenshinDailyDetail';
import { StarRailDailyDetailParam } from '../pages/StarRailDailyDetail';
import { ZZZDailyDetailParam } from '../pages/ZZZDailyDetail';

const TAG: string = 'HomeViewModel';

export type HomeViewState = ViewState;

/** 首页卡片点击路由结果 */
export class HomeCardTapRoute {
  /** 路由名称 */
  routeName: string = '';
  /** 路由参数 */
  param: GenshinDailyDetailParam | StarRailDailyDetailParam | ZZZDailyDetailParam = new GenshinDailyDetailParam();
}

/** HomeViewModel @Monitor 路径常量类型 */
export class HomeViewModelKeys {
  networkErrorMsg: string = 'vm.networkErrorMsg';
  geetestTrigger: string = 'vm.geetestTrigger';
  refreshCoolingDown: string = 'vm.refreshCoolingDown';
  refreshResult: string = 'vm.refreshResult';
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

  /**
   * 当前同步是否为自动触发（冷启动/30分钟定时器）。
   * true = 自动同步，错误静默处理（只记日志）
   * false = 用户手动触发，错误通过 Snackbar 提示
   */
  private isAutoSync: boolean = true;

  /** 非 null 时 View 弹 GeetestDialog */
  @Trace geetestTrigger: GeetestTrigger | null = null;

  /** 手动刷新冷却信号（切换时触发 View 弹 Dialog） */
  @Trace refreshCoolingDown: boolean = false;

  /** 手动刷新结果信号：'success' | 'error' | ''，View 层监听后调用 showFeedback */
  @Trace refreshResult: string = '';

  private autoRefreshTimer: number = -1;

  // ─── 公开方法 ────────────────────────────────────────────────

  /**
   * 根据点击的游戏卡片，返回对应便笺详情页的路由名称和参数。
   * View 层只负责调用 pushPath / replacePath，不做任何 gameId 判断。
   * 返回 null 表示该游戏暂不支持跳转。
   */
  buildCardTapRoute(accountId: string, card: GameRoleCardVM): HomeCardTapRoute | null {
    const route = new HomeCardTapRoute();
    if (card.gameId === GameId.GENSHIN) {
      const param = new GenshinDailyDetailParam();
      param.accountId = accountId;
      param.roleUid = card.roleUid;
      route.routeName = AppRoutes.GENSHIN_DAILY_DETAIL;
      route.param = param;
      return route;
    }
    if (card.gameId === GameId.STARRAIL) {
      const param = new StarRailDailyDetailParam();
      param.accountId = accountId;
      param.roleUid = card.roleUid;
      route.routeName = AppRoutes.STARRAIL_DAILY_DETAIL;
      route.param = param;
      return route;
    }
    if (card.gameId === GameId.ZZZ) {
      const param = new ZZZDailyDetailParam();
      param.accountId = accountId;
      param.roleUid = card.roleUid;
      route.routeName = AppRoutes.ZZZ_DAILY_DETAIL;
      route.param = param;
      return route;
    }
    return null;
  }

  /**
   * 冷启动加载：读本地 DB → 切换状态，然后后台触发一次网络同步。
   * 同时启动 30 分钟自动刷新定时器。
   */
  async loadData(): Promise<void> {
    await CoreInitializer.waitForReady();
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
      // 有角色数据：先渲染 DB 里的数据，再按需同步并刷新
      // 如果 DB 里没有任何 daily note 数据（首次登录），等待同步完成后再渲染
      const hasAnySnapshot = this.accounts.some(a =>
        a.roles.some((r: GameRoleCardVM) => r.snapshot !== null)
      );
      if (!hasAnySnapshot) {
        // 首次登录，DB 里没有 daily note，等待同步完成
        try {
          await this.syncIfNeeded();
          const refreshed = await this.fetchFromLocal();
          this.accounts = refreshed;
          this.viewState = refreshed.length > 0 ? ViewState.DATA : ViewState.EMPTY;
        } catch (_) {}
      } else {
        this.syncIfNeeded().then(async () => {
          try {
            const refreshed = await this.fetchFromLocal();
            this.accounts = refreshed;
            this.viewState = refreshed.length > 0 ? ViewState.DATA : ViewState.EMPTY;
          } catch (_) {}
        }).catch((_: Error | object) => {});
      }
    }
    this.startAutoRefresh();

    // 冷启动后推送 Widget 数据（无论是否同步，都推送最新数据）
    StaminaNotificationService.instance().onDailyNotesSynced().catch((_: Error | object) => {});

    // 冷启动 Cookie 检查：首屏渲染完成后异步触发，不阻塞 UI
    ColdStartCookieChecker.checkAndRefreshAll(CoreInitializer.bbsRepository)
      .then((result: ColdStartRefreshResult) => {
        this.handleColdStartRefreshResult(result);
      })
      .catch((_: Error | object) => {});
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
    this.isAutoSync = false;
    this.isRefreshing = true;
    try {
      await this.syncAllDailyNotes();
      AppStorage.setOrCreate('homeLastRefreshTime', Math.floor(Date.now() / 1000));
      const loaded = await this.fetchFromLocal();
      this.accounts = loaded;
      this.viewState = loaded.length > 0 ? ViewState.DATA : ViewState.EMPTY;
      this.refreshResult = 'success';
    } catch (error) {
      const msg = error instanceof Error ? error.message : `${error}`;
      this.networkErrorMsg = msg;
      this.refreshResult = 'error';
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
    this.isAutoSync = false;
    this.isRefreshing = true;
    try {
      await this.syncAllDailyNotes();
      AppStorage.setOrCreate('homeLastRefreshTime', Math.floor(Date.now() / 1000));
      const loaded = await this.fetchFromLocal();
      this.accounts = loaded;
      this.viewState = loaded.length > 0 ? ViewState.DATA : ViewState.EMPTY;
      this.refreshResult = 'success';
    } catch (error) {
      const msg = error instanceof Error ? error.message : `${error}`;
      this.networkErrorMsg = msg;
      this.refreshResult = 'error';
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
      const newChallenge = await GeetestService.verifyVerification(result, trigger.cookie, trigger.gameId);
      await this.syncDailyNoteWithChallenge(
        trigger.accountId,
        trigger.cookie,
        trigger.gameId,
        trigger.roleId,
        trigger.server,
        newChallenge,
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

  /**
   * 处理冷启动刷新结果：将 stoken 过期的失败账号写入全局 CookieExpiredSignal，
   * 若有成功刷新则重新触发数据同步。
   */
  handleColdStartRefreshResult(result: ColdStartRefreshResult): void {
    const signal = CookieExpiredSignal.instance();
    for (let i = 0; i < result.failedAccounts.length; i++) {
      const info = result.failedAccounts[i];
      if (!info.isNetworkError) {
        signal.push(info);
      }
    }
    if (result.successCount > 0) {
      this.syncIfNeeded().then(async () => {
        try {
          const refreshed = await this.fetchFromLocal();
          this.accounts = refreshed;
          this.viewState = refreshed.length > 0 ? ViewState.DATA : ViewState.EMPTY;
        } catch (_) {}
      }).catch((_: Error | object) => {});
    }
  }

  /**
   * 从队列取出第一个过期账号，弹出登录过期 Dialog。
   * @deprecated 已迁移到 Main.ets 通过 CookieExpiredSignal 统一处理
   */
  showNextCookieExpiredDialog(_context: UIContext): void {}

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
   * 单个角色的便笺同步：委托给对应游戏 Repository 完成 API 调用 + 写 DB。
   */
  private async syncDailyNote(account: AccountRow, role: GameRoleRow): Promise<void> {
    const gameId = role.gameId;
    try {
      if (gameId === GameId.GENSHIN) {
        await CoreInitializer.genshinRepository.syncDailyNote(
          account.uid, role.roleId, role.server, account.cookie
        );
      } else if (gameId === GameId.STARRAIL) {
        await CoreInitializer.starRailRepository.syncDailyNote(
          account.uid, role.roleId, role.server, account.cookie
        );
      } else if (gameId === GameId.ZZZ) {
        await CoreInitializer.zzzRepository.syncDailyNote(
          account.uid, role.roleId, role.server, account.cookie
        );
      }
    } catch (error) {
      const msg = error instanceof Error ? error.message : `${error}`;
      if (error instanceof AuthExpiredError) {
        // Cookie 失效（-100 / 10001）：推入过期队列，Main.ets 统一弹重新登录 Dialog
        const info = new FailedAccountInfo();
        info.username = account.username;
        info.nickname = account.nickname.length > 0 ? account.nickname : account.username;
        info.isNetworkError = false;
        CookieExpiredSignal.instance().push(info);
        Logger.warn(TAG, `Cookie expired for ${account.username}: ${msg}`);
      } else if (msg.indexOf(`retcode=${ApiErrorCodes.GEETEST_REQUIRED}`) !== -1 ||
          msg.indexOf(`retcode=${ApiErrorCodes.GEETEST_REQUIRED_GENERAL}`) !== -1) {
        await this.handleGeetest(account, role);
      } else {
        // 始终记录日志
        Logger.error(TAG, `syncDailyNote error for ${role.gameId}/${role.roleId}: ${msg}`);
        // 自动同步静默，手动刷新才触发 Snackbar
        if (!this.isAutoSync) {
          this.networkErrorMsg = msg;
        }
      }
    }
  }

  /** Geetest 验证后重新拉取便笺 */
  private async syncDailyNoteWithChallenge(
    accountId: string,
    cookie: string,
    gameId: GameId,
    roleId: string,
    server: string,
    geetestChallenge: string,
  ): Promise<void> {
    // 直接调用 Repository，只带 challenge（与 TeyvatGuide lunaReq.ts 一致）
    if (gameId === GameId.GENSHIN) {
      await CoreInitializer.genshinRepository.syncDailyNote(
        accountId, roleId, server, cookie, geetestChallenge
      );
    } else if (gameId === GameId.STARRAIL) {
      await CoreInitializer.starRailRepository.syncDailyNote(
        accountId, roleId, server, cookie, geetestChallenge
      );
    } else if (gameId === GameId.ZZZ) {
      await CoreInitializer.zzzRepository.syncDailyNote(
        accountId, roleId, server, cookie, geetestChallenge
      );
    }
  }

  /**
   * 按需同步：遍历所有账号角色，只对需要同步的角色触发同步。
   */
  private async syncIfNeeded(): Promise<void> {
    const accounts = await CoreInitializer.bbsRepository.getAllAccounts();
    for (let ai = 0; ai < accounts.length; ai++) {
      const account = accounts[ai];
      const roles = await CoreInitializer.bbsRepository.getGameRoles(account.uid);
      for (let ri = 0; ri < roles.length; ri++) {
        const role = roles[ri];
        let needed = false;
        try {
          needed = await HomeViewModel.needsDailyNoteSync(account.uid, role.roleId, role.gameId);
        } catch (_) {
          needed = true;
        }
        if (!needed) {
          Logger.info(TAG, `skip sync (within 30min): ${role.gameId}/${role.roleId}`);
          continue;
        }
        await this.syncDailyNote(account, role);
      }
    }
    // 同步完成后触发通知阈值检查和 Widget 数据推送
    StaminaNotificationService.instance().onDailyNotesSynced().catch((_: Error | object) => {});
  }

  /**
   * 遍历所有账号角色，逐一调用 syncDailyNote 进行全量同步。
   */
  private async syncAllDailyNotes(): Promise<void> {
    const accounts = await CoreInitializer.bbsRepository.getAllAccounts();
    for (let ai = 0; ai < accounts.length; ai++) {
      const account = accounts[ai];
      const roles = await CoreInitializer.bbsRepository.getGameRoles(account.uid);
      for (let ri = 0; ri < roles.length; ri++) {
        const role = roles[ri];
        await this.syncDailyNote(account, role);
      }
    }
    // 同步完成后触发通知阈值检查
    StaminaNotificationService.instance().onDailyNotesSynced().catch((_: Error | object) => {});
  }

  /**
   * 触发 Geetest 流程
   */
  private async handleGeetest(account: AccountRow, role: GameRoleRow): Promise<void> {
    // 已有 Geetest 弹窗等待用户操作时，跳过后续角色的 Geetest 触发
    if (this.geetestTrigger !== null) {
      Logger.warn(TAG, `Geetest already pending, skip for ${role.gameId}/${role.roleId}`);
      return;
    }
    try {
      const createResult = await GeetestService.createVerification(account.cookie, role.gameId);
      this.geetestTrigger = new GeetestTrigger(
        createResult,
        account.cookie,
        role.gameId,
        role.roleId,
        role.server,
        account.uid
      );
    } catch (error) {
      const msg = error instanceof Error ? error.message : `${error}`;
      Logger.error(TAG, `createVerification failed: ${msg}`);
      if (!this.isAutoSync) {
        this.networkErrorMsg = msg;
      }
    }
  }

  /**
   * 检查指定游戏角色是否需要同步 daily_note
   */
  private static async needsDailyNoteSync(accountId: string, roleUid: string, gameId: GameId): Promise<boolean> {
    if (gameId === GameId.GENSHIN) {
      return CoreInitializer.genshinRepository.needsDailyNoteSync(accountId, roleUid);
    }
    if (gameId === GameId.STARRAIL) {
      return CoreInitializer.starRailRepository.needsDailyNoteSync(accountId, roleUid);
    }
    if (gameId === GameId.ZZZ) {
      return CoreInitializer.zzzRepository.needsDailyNoteSync(accountId, roleUid);
    }
    return true;
  }

  /**
   * 获取指定游戏角色的 daily_note 上次同步时间（Unix 秒级时间戳）
   */
  private static async getDailyNoteLastSyncTime(accountId: string, roleUid: string, gameId: GameId): Promise<number> {
    if (gameId === GameId.GENSHIN) {
      return CoreInitializer.genshinRepository.getDailyNoteLastSyncTime(accountId, roleUid);
    }
    if (gameId === GameId.STARRAIL) {
      return CoreInitializer.starRailRepository.getDailyNoteLastSyncTime(accountId, roleUid);
    }
    if (gameId === GameId.ZZZ) {
      return CoreInitializer.zzzRepository.getDailyNoteLastSyncTime(accountId, roleUid);
    }
    return 0;
  }

  /** 从本地 DB 读取账号 + 角色 + daily_note，组装 UI ViewModel */
  private async fetchFromLocal(): Promise<MihoyoAccountVM[]> {
    const accounts = await CoreInitializer.bbsRepository.getAllAccounts();
    const result: MihoyoAccountVM[] = [];
    for (let ai = 0; ai < accounts.length; ai++) {
      const account = accounts[ai];
      const roles = await CoreInitializer.bbsRepository.getGameRoles(account.uid);
      const cards = await this.buildRoleCards(account, roles);
      result[result.length] = new MihoyoAccountVM(
        account.uid, account.username, cards, account.nickname, account.avatarUrl
      );
    }
    return result;
  }

  /** 将 GameRoleRow[] 转换为 GameRoleCardVM[]，每个角色查一次 daily_note */
  private async buildRoleCards(account: AccountRow, roles: GameRoleRow[]): Promise<GameRoleCardVM[]> {
    const cards: GameRoleCardVM[] = [];
    for (let ri = 0; ri < roles.length; ri++) {
      const role = roles[ri];
      const snapshot = await this.loadDailyNoteSnapshot(account.uid, role.gameId, role.roleId);
      if (snapshot === null) {
        continue;
      }
      // 从 sync_meta 读取真实的上次同步时间，计算描述
      let lastSyncTime = 0;
      try {
        lastSyncTime = await HomeViewModel.getDailyNoteLastSyncTime(account.uid, role.roleId, role.gameId);
      } catch (_) {}
      cards[cards.length] = new GameRoleCardVM(
        role.gameId,
        role.gameId,
        HomeViewModel.gameColor(role.gameId),
        role.roleId,
        role.nickname,
        serverDisplayName(role.server, role.gameId) ?? role.server,
        snapshot,
        HomeViewModel.syncDescKey(lastSyncTime),
        HomeViewModel.gameLogo(role.gameId)
      );
    }
    return cards;
  }

  /**
   * 从 DB 读取 daily_note，解析为 GameNoteSnapshotVM。
   */
  private async loadDailyNoteSnapshot(
    accountId: string,
    gameId: GameId,
    roleUid: string
  ): Promise<GameNoteSnapshotVM | null> {
    try {
      if (gameId === GameId.GENSHIN) {
        const row = await CoreInitializer.genshinRepository.getDailyNote(accountId, roleUid);
        if (row === null) {
          return null;
        }
        const data = GenshinDailyNoteParser.parse(row.rawJson);
        const isFull = data.currentResin >= data.maxResin && data.maxResin > 0;
        const recoverySec = isFull ? 0 : data.resinRecoveryTime;
        const snap = new GameNoteSnapshotVM(
          $r('app.string.daily_note_resin_title'), data.currentResin, data.maxResin, recoverySec, '', '', isFull
        );
        snap.expeditionCurrent = data.expeditions.length;
        snap.expeditionMax = data.maxExpeditionNum;
        snap.homeCoinCurrent = data.currentHomeCoin;
        snap.homeCoinMax = data.maxHomeCoin;
        snap.dailyTaskFinished = data.finishedTaskNum;
        snap.dailyTaskTotal = data.totalTaskNum;
        snap.dailyTaskAllReceived = data.isExtraTaskRewardReceived;

        // 数据行：由 VM 决定显示哪些行及颜色，View 层直接 ForEach
        const rows: GameDataRowVM[] = [];
        if (data.expeditions.length >= 0) {
          const expCur = data.expeditions.length;
          const expMax = data.maxExpeditionNum;
          rows[rows.length] = new GameDataRowVM(
            $r('app.string.daily_note_expedition_title'),
            `${expCur}/${expMax}`,
            expCur >= expMax ? $r('app.color.color_primary')
              : expCur === 0 ? $r('app.color.color_danger')
              : $r('app.color.color_warning')
          );
        }
        if (data.currentHomeCoin >= 0) {
          const coinCur = data.currentHomeCoin;
          const coinMax = data.maxHomeCoin;
          rows[rows.length] = new GameDataRowVM(
            $r('app.string.daily_note_home_coin_title'),
            `${coinCur}/${coinMax}`,
            coinMax > 0 && coinCur >= coinMax ? $r('app.color.color_danger')
              : coinMax > 0 && coinCur / coinMax >= 0.5 ? $r('app.color.color_warning')
              : $r('app.color.color_primary')
          );
        }
        if (data.finishedTaskNum >= 0) {
          rows[rows.length] = new GameDataRowVM(
            $r('app.string.daily_note_daily_task_title'),
            data.isExtraTaskRewardReceived
              ? $r('app.string.daily_note_task_all_received')
              : `${data.finishedTaskNum}/${data.totalTaskNum}`,
            data.isExtraTaskRewardReceived ? $r('app.color.color_primary')
              : data.finishedTaskNum === 0 ? $r('app.color.color_danger')
              : $r('app.color.color_warning')
          );
        }
        snap.dataRows = rows;
        snap.primaryColor = HomeViewModel.primaryColor(gameId, data.currentResin, data.maxResin, isFull);
        return snap;
      }

      if (gameId === GameId.STARRAIL) {
        const row = await CoreInitializer.starRailRepository.getDailyNote(accountId, roleUid);
        if (row === null) {
          return null;
        }
        const data = StarRailDailyNoteParser.parse(row.rawJson);
        const stamina = data.currentStamina > 0 ? data.currentStamina : row.currentStamina;
        const maxStamina = data.maxStamina > 0 ? data.maxStamina : row.maxStamina;
        const isFull = stamina >= maxStamina && maxStamina > 0;
        const recoverySec = isFull ? 0 : data.staminaRecoverTime;
        const snap = new GameNoteSnapshotVM(
          $r('app.string.starrail_stamina_title'), stamina, maxStamina, recoverySec, '', '', isFull
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

        // 数据行
        const srRows: GameDataRowVM[] = [];
        if (data.currentReserveStamina >= 0) {
          srRows[srRows.length] = new GameDataRowVM(
            $r('app.string.starrail_reserve_stamina_title'),
            `${data.currentReserveStamina}`,
            $r('app.color.color_text_secondary')
          );
        }
        if (data.currentTrainScore >= 0) {
          srRows[srRows.length] = new GameDataRowVM(
            $r('app.string.starrail_train_score_title'),
            `${data.currentTrainScore}/${data.maxTrainScore}`,
            data.currentTrainScore >= data.maxTrainScore ? $r('app.color.color_primary')
              : data.currentTrainScore === 0 ? $r('app.color.color_danger')
              : $r('app.color.color_warning')
          );
        }
        if (data.weeklyCocoonCnt >= 0) {
          srRows[srRows.length] = new GameDataRowVM(
            $r('app.string.starrail_cocoon_title'),
            `${data.weeklyCocoonCnt}/${data.weeklyCocoonLimit}`,
            data.weeklyCocoonCnt >= data.weeklyCocoonLimit ? $r('app.color.color_primary')
              : data.weeklyCocoonCnt === 0 ? $r('app.color.color_danger')
              : $r('app.color.color_warning')
          );
        }
        if (data.currentRogueScore >= 0) {
          srRows[srRows.length] = new GameDataRowVM(
            $r('app.string.starrail_rogue_score_title'),
            `${data.currentRogueScore}/${data.maxRogueScore}`,
            data.currentRogueScore >= data.maxRogueScore ? $r('app.color.color_primary')
              : data.currentRogueScore === 0 ? $r('app.color.color_danger')
              : $r('app.color.color_warning')
          );
        }
        if (data.rogueTournWeeklyCur >= 0) {
          srRows[srRows.length] = new GameDataRowVM(
            $r('app.string.starrail_tourn_score_title'),
            `${data.rogueTournWeeklyCur}/${data.rogueTournWeeklyMax}`,
            data.rogueTournWeeklyCur >= data.rogueTournWeeklyMax ? $r('app.color.color_primary')
              : data.rogueTournWeeklyCur === 0 ? $r('app.color.color_danger')
              : $r('app.color.color_warning')
          );
        }
        snap.dataRows = srRows;
        snap.primaryColor = HomeViewModel.primaryColor(gameId, stamina, maxStamina, isFull);
        return snap;
      }

      if (gameId === GameId.ZZZ) {
        const row = await CoreInitializer.zzzRepository.getDailyNote(accountId, roleUid);
        if (row === null) {
          return null;
        }
        const data = ZZZDailyNoteParser.parse(row.rawJson);
        const energy = data.currentEnergy > 0 ? data.currentEnergy : row.energyCurrent;
        const maxEnergy = data.maxEnergy > 0 ? data.maxEnergy : row.energyMax;
        const zzzisFull = energy >= maxEnergy && maxEnergy > 0;
        const zzzRecoverySec = zzzisFull ? 0 : data.energyRecoverTime;
        const snap = new GameNoteSnapshotVM($r('app.string.zzz_energy_title'), energy, maxEnergy, zzzRecoverySec, '', '', zzzisFull);
        snap.vitalityCurrent = data.currentVitality;
        snap.vitalityMax = data.maxVitality;
        snap.scratchCardSign = data.cardSign === 'CardSignDone' ? ZZZCardSign.DONE : ZZZCardSign.TODO;
        if (data.videoStoreState === 'SaleStateDone') {
          snap.videoStoreState = ZZZVideoStoreState.DONE;
        } else if (data.videoStoreState === 'SaleStateDoing') {
          snap.videoStoreState = ZZZVideoStoreState.OPEN;
        } else if (data.videoStoreState === 'SaleStateNo') {
          snap.videoStoreState = ZZZVideoStoreState.CLOSED;
        } else {
          snap.videoStoreState = ZZZVideoStoreState.UNKNOWN;
        }

        // 数据行
        const zzzRows: GameDataRowVM[] = [];
        if (data.currentVitality >= 0) {
          zzzRows[zzzRows.length] = new GameDataRowVM(
            $r('app.string.zzz_vitality_title'),
            `${data.currentVitality}/${data.maxVitality}`,
            data.currentVitality >= data.maxVitality ? $r('app.color.color_primary')
              : data.currentVitality === 0 ? $r('app.color.color_danger')
              : $r('app.color.color_warning')
          );
        }
        const cardSignDone = data.cardSign === 'CardSignDone';
        zzzRows[zzzRows.length] = new GameDataRowVM(
          $r('app.string.zzz_card_sign_title'),
          cardSignDone ? $r('app.string.zzz_card_sign_done') : $r('app.string.zzz_card_sign_todo'),
          cardSignDone ? $r('app.color.color_primary') : $r('app.color.color_danger')
        );
        if (data.videoStoreState !== '' && data.videoStoreState !== 'SaleStateUnknown') {
          let vhsValue: ResourceStr = $r('app.string.zzz_video_store_closed');
          let vhsColor: ResourceColor = $r('app.color.color_text_secondary');
          if (data.videoStoreState === 'SaleStateDone') {
            vhsValue = $r('app.string.zzz_video_store_done');
            vhsColor = $r('app.color.color_primary');
          } else if (data.videoStoreState === 'SaleStateDoing') {
            vhsValue = $r('app.string.zzz_video_store_open');
            vhsColor = $r('app.color.color_warning');
          }
          zzzRows[zzzRows.length] = new GameDataRowVM(
            $r('app.string.zzz_video_store_title'),
            vhsValue,
            vhsColor
          );
        }
        snap.dataRows = zzzRows;
        snap.primaryColor = HomeViewModel.primaryColor(gameId, energy, maxEnergy, zzzisFull);
        return snap;
      }

      return null;
    } catch (error) {
      const msg = error instanceof Error ? error.message : `${error}`;
      Logger.warn(TAG, `loadDailyNoteSnapshotV2 failed for ${gameId}/${roleUid}: ${msg}`);
      return null;
    }
  }

  /** 根据 gameId 返回对应的游戏主题色资源引用 */
  static gameColor(gameId: GameId): ResourceColor {
    return gameIdToColor(gameId);
  }

  /** 根据 gameId 返回对应的游戏 Logo 图标资源 */
  static gameLogo(gameId: GameId): Resource {
    return gameIdToLogo(gameId);
  }

  /**
   * 根据上次同步时间戳生成同步描述 key，供 GameToolCardHeader.syncDescResource 使用
   * 格式：
   *   'sync_not_synced'         — 从未同步
   *   'sync_just_now'           — 1 分钟内
   *   'sync_minutes_ago:{n}'    — n 分钟前（1 ≤ n < 60）
   *   'sync_hours_ago:{n}'      — n 小时前（1 ≤ n < 24）
   *   'sync_long_ago'           — 超过 24 小时
   */
  static syncDescKey(lastSyncTime: number): string {
    if (lastSyncTime === 0) {
      return 'sync_not_synced';
    }
    const now = Math.floor(Date.now() / 1000);
    const diffSec = now - lastSyncTime;
    if (diffSec < 60) {
      return 'sync_just_now';
    }
    const diffMin = Math.floor(diffSec / 60);
    if (diffMin < 60) {
      return `sync_minutes_ago:${diffMin}`;
    }
    const diffHour = Math.floor(diffMin / 60);
    if (diffHour < 24) {
      return `sync_hours_ago:${diffHour}`;
    }
    return 'sync_long_ago';
  }

  /**
   * 根据体力比例和游戏类型计算主体力颜色。
   * 原神树脂满了 = danger（需要消耗），其他游戏体力满了 = primary（好事）。
   */
  static primaryColor(gameId: GameId, current: number, max: number, isFull: boolean): ResourceColor {
    if (isFull) {
      return gameId === GameId.GENSHIN
        ? $r('app.color.color_danger')
        : $r('app.color.color_primary');
    }
    const ratio = max > 0 ? current / max : 0;
    if (ratio < 0.3) { return $r('app.color.color_danger'); }
    if (ratio < 0.7) { return $r('app.color.color_warning'); }
    return $r('app.color.color_primary');
  }
}
