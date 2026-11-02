/**
 * HomeViewModel.ets
 *
 * 首页 ViewModel facade，遵循 MVVM 架构规范。
 *
 * 数据流：
 *   loadData()  → 读本地 DB → 渲染（有数据→'data'，无数据→'empty'）
 *                → 冷启动后立即触发一次后台同步
 *   refresh()   → 先网络同步所有角色的 daily_note → 再读 DB → 渲染
 *
 * 状态机：
 *   loading → data    有本地数据
 *   loading → empty   无本地数据
 *   （无 error 状态，网络失败通过 networkErrorMsg 通知 View 弹 Alert）
 *
 * 拆分说明（M8，2026-11-01）：
 *   数据读取   → HomeDataLoader
 *   同步编排   → HomeSyncCoordinator
 *   卡片展示   → HomeCardPresenter
 *   本文件保留原类名 / 导出符号 / 公开方法，作为 View 层与测试的稳定 facade。
 */

import { ColdStartCookieChecker, ColdStartRefreshResult, CoreInitializer, GameId, Logger } from 'core';
import {
  AppConstants,
  AppRoutes,
  GameRoleCardVM,
  MihoyoAccountVM,
  ViewState,
} from 'basic';
import { StaminaNotificationService } from 'notification';
import { GenshinDailyDetailParam, StarRailDailyDetailParam, ZZZDailyDetailParam } from 'dailynote';
import { HomeCardPresenter } from './HomeCardPresenter';
import { HomeDataLoader } from './HomeDataLoader';
import { HomeSyncCoordinator } from './HomeSyncCoordinator';

const TAG: string = 'HomeViewModel';

export type HomeViewState = ViewState;

/** 首页卡片点击路由结果 */
export class HomeCardTapRoute {
  /** 路由名称 */
  routeName: string = '';
  /** 路由参数 */
  param: GenshinDailyDetailParam | StarRailDailyDetailParam | ZZZDailyDetailParam = new GenshinDailyDetailParam();
}

@ObservedV2
export class HomeViewModel {

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

  /** 手动刷新冷却信号（切换时触发 View 弹 Dialog） */
  @Trace isRefreshCoolingDown: boolean = false;

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
      await this.reloadFromLocal();
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
        await this.reloadFromLocal();
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
          await this.reloadFromLocal();
        } catch (_) {}
      } else {
        this.syncIfNeeded().then(() => this.reloadFromLocal()).catch((_: Error | object) => {});
      }
    }
    this.startAutoRefresh();

    // 冷启动后推送 Widget 数据（无论是否同步，都推送最新数据）
    StaminaNotificationService.getInstance().onDailyNotesSynced().catch((_: Error | object) => {});

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
      this.isRefreshCoolingDown = !this.isRefreshCoolingDown;
      return;
    }
    await this.performRefresh();
  }

  /**
   * 强制刷新：跳过冷却检查，直接触发同步。
   */
  async forceRefresh(): Promise<void> {
    if (this.isRefreshing) {
      return;
    }
    await this.performRefresh();
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
    HomeSyncCoordinator.handleColdStartRefreshResult(
      result,
      () => this.syncIfNeeded().then(() => this.reloadFromLocal())
    );
  }

  // ─── 私有方法 ────────────────────────────────────────────────

  /** 重新读取本地 DB 并刷新页面状态 */
  private async reloadFromLocal(): Promise<void> {
    const loaded = await HomeDataLoader.fetchAccounts();
    this.accounts = loaded;
    this.viewState = loaded.length > 0 ? ViewState.DATA : ViewState.EMPTY;
  }

  /** 手动/强制刷新共用的同步 + 重载流程 */
  private async performRefresh(): Promise<void> {
    this.isAutoSync = false;
    this.isRefreshing = true;
    try {
      await this.syncAllDailyNotes();
      AppStorage.setOrCreate('homeLastRefreshTime', Math.floor(Date.now() / 1000));
      await this.reloadFromLocal();
      this.refreshResult = 'success';
    } catch (error) {
      const msg = error instanceof Error ? error.message : `${error}`;
      this.networkErrorMsg = msg;
      this.refreshResult = 'error';
    } finally {
      this.isRefreshing = false;
    }
  }

  /** 按需同步：委托 HomeSyncCoordinator，手动模式下上报错误 */
  private async syncIfNeeded(): Promise<void> {
    await HomeSyncCoordinator.syncIfNeeded(this.isAutoSync, (msg: string) => {
      this.networkErrorMsg = msg;
    });
  }

  /** 全量同步：委托 HomeSyncCoordinator，手动模式下上报错误 */
  private async syncAllDailyNotes(): Promise<void> {
    await HomeSyncCoordinator.syncAllDailyNotes(this.isAutoSync, (msg: string) => {
      this.networkErrorMsg = msg;
    });
  }

  private startAutoRefresh(): void {
    this.stopAutoRefresh();
    this.autoRefreshTimer = setInterval(() => {
      Logger.info(TAG, 'auto refresh triggered');
      this.syncIfNeeded().then(() => {
        this.reloadFromLocal().catch((e: Error) => {
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

  // ─── 静态展示辅助（保留原公开符号，内部委托 HomeCardPresenter） ───

  /** 根据 gameId 返回对应的游戏主题色资源引用 */
  static getGameColor(gameId: GameId): ResourceColor {
    return HomeCardPresenter.getGameColor(gameId);
  }

  /** 根据 gameId 返回对应的游戏 Logo 图标资源 */
  static getGameLogo(gameId: GameId): Resource {
    return HomeCardPresenter.getGameLogo(gameId);
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
    return HomeCardPresenter.syncDescKey(lastSyncTime);
  }

  /**
   * 根据体力比例和游戏类型计算主体力颜色。
   * 原神树脂满了 = danger（需要消耗），其他游戏体力满了 = primary（好事）。
   */
  static getPrimaryColor(gameId: GameId, current: number, max: number, isFull: boolean): ResourceColor {
    return HomeCardPresenter.getPrimaryColor(gameId, current, max, isFull);
  }
}
