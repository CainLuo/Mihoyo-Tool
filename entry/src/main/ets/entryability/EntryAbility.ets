import { UIAbility, Want, AbilityConstant, Configuration, common } from '@kit.AbilityKit';
import { window } from '@kit.ArkUI';
import { CoreInitializer, Logger, SyncQueueRunner } from 'core';
import { APP_ENV, TransparentColorCache, WidgetSyncHook } from 'basic';
import { AppearanceManager } from 'settings';
import { StaminaNotificationService } from 'notification';
import { WidgetDataStoreBuilder, WidgetDataStoreManager, WidgetSyncHandlerImpl } from 'widget';
import {
  WidgetEntryRoute,
  WIDGET_ENTRY_ACCOUNT_PARAM,
  WIDGET_ENTRY_FROM_PARAM,
  WIDGET_ENTRY_FROM_VALUE,
  WIDGET_ENTRY_GAME_PARAM,
  WIDGET_ENTRY_ROLE_PARAM,
  WIDGET_ENTRY_ROUTE_EVENT,
  WIDGET_ENTRY_ROUTE_STORAGE
} from '../widget/WidgetEntryRoute';

const TAG: string = 'EntryAbility';

export default class EntryAbility extends UIAbility {
  /**
   * 判断本次启动是否来自卡片点击。
   *
   * 卡片用 postCardAction({ action: 'router', params: { from: 'widget' } }) 打开应用，
   * params 会原样进入 want.parameters。
   */
  private static isFromWidget(want: Want): boolean {
    const params = want.parameters;
    if (params === undefined || params === null) {
      return false;
    }
    return `${params[WIDGET_ENTRY_FROM_PARAM] ?? ''}` === WIDGET_ENTRY_FROM_VALUE;
  }

  /**
   * 解析卡片直达详情页的路由参数。
   *
   * 1×2 卡片携带 gameId / accountId / roleUid；2×2 / 2×4 / 4×4 只带 from，
   * 返回 null 表示落在首页即可。
   */
  private static buildEntryRoute(want: Want): WidgetEntryRoute | null {
    if (!EntryAbility.isFromWidget(want)) {
      return null;
    }
    const params = want.parameters;
    if (params === undefined || params === null) {
      return null;
    }
    const route = new WidgetEntryRoute();
    route.gameId = `${params[WIDGET_ENTRY_GAME_PARAM] ?? ''}`;
    route.accountId = `${params[WIDGET_ENTRY_ACCOUNT_PARAM] ?? ''}`;
    route.roleUid = `${params[WIDGET_ENTRY_ROLE_PARAM] ?? ''}`;
    if (route.gameId.length === 0 || route.accountId.length === 0 || route.roleUid.length === 0) {
      return null;
    }
    return route;
  }

  /** 从卡片进入时刷新一次卡片数据（本地 DB → Preferences → 推送卡片） */
  private static async refreshWidgetData(context: common.UIAbilityContext): Promise<void> {
    try {
      await WidgetSyncHook.onDailyNotesSynced(context);
    } catch (e) {
      Logger.warning(TAG, `refreshWidgetData failed: ${JSON.stringify(e)}`);
    }
  }

  onCreate(want: Want, _launchParam: AbilityConstant.LaunchParam) {
    Logger.info(TAG, 'onCreate');

    // 冷启动来自卡片：先落到 AppStorage，MainPage 挂载时消费（LaunchPage 可能还没走完）
    const entryRoute = EntryAbility.buildEntryRoute(want);
    if (entryRoute !== null) {
      AppStorage.setOrCreate(WIDGET_ENTRY_ROUTE_STORAGE, entryRoute);
    }

    // 注册卡片推送实现（须早于 StaminaNotificationService.init）
    WidgetSyncHook.register(new WidgetSyncHandlerImpl());

    // 尽早恢复用户选择的颜色模式，避免启动时闪烁
    AppearanceManager.restoreOnLaunch(this.context).catch((error: Error | object) => {
      Logger.warning(TAG, `restoreOnLaunch failed: ${JSON.stringify(error)}`);
    });

    // 初始化透明色缓存（从 color.json 读取基础颜色并计算；restoreOnLaunch 已同步应用用户的颜色模式）
    TransparentColorCache.init(this.context);

    // Core 初始化成功后的附加初始化。走 registerReadyHook 而不是 initCore().then，
    // 这样启动页「初始化失败 → 重试」成功时同样会执行（否则重试后 Widget / 通知都不工作）。
    CoreInitializer.registerReadyHook(async () => {
      // 初始化 Widget 数据存储
      await WidgetDataStoreManager.init(this.context);
      // 立即构建并保存 Widget 数据（确保添加卡片时有数据可用）
      await WidgetDataStoreBuilder.initAndSave(this.context);
      // 注册同步完成回调：同步完成后刷新 Widget 数据
      SyncQueueRunner.registerOnComplete(async () => {
        Logger.info(TAG, 'SyncQueueRunner.onComplete: refreshing Widget data');
        await WidgetDataStoreBuilder.refreshAndSave(this.context);
      });
      // 核心库初始化完成后，初始化通知服务
      StaminaNotificationService.getInstance().init(this.context).catch((e: Error | object) => {
        Logger.warning(TAG, `StaminaNotificationService.init failed: ${JSON.stringify(e)}`);
      });
      // 从卡片点击进入：Core 与 Widget 存储就绪后刷新一次卡片数据
      if (EntryAbility.isFromWidget(want)) {
        await EntryAbility.refreshWidgetData(this.context);
      }
    });

    // 初始化核心库，直接传递 AppEnv，无需任何转换
    CoreInitializer.initCore({ env: APP_ENV, context: this.context })
      .then(() => {
        Logger.info(TAG, `CoreV2 initialized. env=${APP_ENV}`);
      })
      .catch((error: Error | object) => {
        // 启动页会收到 reject 并展示错误态 + 重试入口
        Logger.warning(TAG, `CoreInitializer.initCore failed: ${JSON.stringify(error)}`);
      });

    Logger.info(TAG, `env=${APP_ENV}`);
  }

  onDestroy() {
    Logger.info(TAG, 'onDestroy');
  }

  /**
   * UIAbility 已在后台运行时，收到新的 Want 时触发
   *
   * 处理场景：
   * - 其他应用拉起本应用
   */
  onNewWant(want: Want, _launchParam: AbilityConstant.LaunchParam): void {
    Logger.info(TAG, `onNewWant: action=${want.action} parameters=${JSON.stringify(want.parameters)}`);
    // 应用已在运行时从卡片点击进入：先通知 MainPage 跳转，再刷新卡片数据
    if (EntryAbility.isFromWidget(want)) {
      const entryRoute = EntryAbility.buildEntryRoute(want);
      if (entryRoute !== null) {
        try {
          this.context.eventHub.emit(WIDGET_ENTRY_ROUTE_EVENT, entryRoute);
        } catch (e) {
          Logger.warning(TAG, `emit widget entry route failed: ${JSON.stringify(e)}`);
        }
      }
      EntryAbility.refreshWidgetData(this.context);
    }
  }

  onWindowStageCreate(windowStage: window.WindowStage) {
    Logger.info(TAG, 'onWindowStageCreate');
    windowStage.getMainWindow().then((win) => {
      // 将 windowClass 存入 AppStorage，供 MainPage.ets 直接持有并注册监听
      AppStorage.setOrCreate('windowClass', win);
      // 获取底部导航条高度并存入 AppStorage，供弹窗类组件读取（Navigation 不自动处理弹窗）
      const bottomArea = win.getWindowAvoidArea(window.AvoidAreaType.TYPE_NAVIGATION_INDICATOR);
      const bottomPx = bottomArea.bottomRect.height;
      AppStorage.setOrCreate('bottomRectHeight', bottomPx);
      // 监听避让区域变化（折叠屏旋转等场景）
      win.on('avoidAreaChange', (data) => {
        if (data.type === window.AvoidAreaType.TYPE_NAVIGATION_INDICATOR) {
          AppStorage.setOrCreate('bottomRectHeight', data.area.bottomRect.height);
        }
      });
      // 存储窗口宽度（px），供响应式布局使用
      const size = win.getWindowProperties().windowRect;
      AppStorage.setOrCreate('windowWidthPx', size.width);
      win.on('windowSizeChange', (s) => {
        AppStorage.setOrCreate('windowWidthPx', s.width);
      });
      // 监听窗口状态变化（分屏模式检测）：windowStatusType=4 表示分屏
      win.on('windowStatusChange', (statusType: window.WindowStatusType) => {
        AppStorage.setOrCreate('windowStatusType', statusType as number);
      });
    }).catch((err: Error | object) => {
      Logger.warning(TAG, `getMainWindow failed: ${JSON.stringify(err)}`);
    });
    windowStage.loadContent('pages/Index', (err: Error | object) => {
      if ((err as Record<string, number>).code) {
        Logger.warning(TAG, `Failed to load content: ${JSON.stringify(err)}`);
        return;
      }
      Logger.info(TAG, 'Succeeded in loading content');
    });
  }

  onWindowStageDestroy() {
    Logger.info(TAG, 'onWindowStageDestroy');
  }

  onConfigurationUpdate(_newConfig: Configuration): void {
    // 深浅色切换（跟随系统或在外观设置中切换）后，color_primary 的取值会变，重算透明色缓存
    TransparentColorCache.init(this.context);
  }

  onForeground() {
    Logger.info(TAG, 'onForeground');
  }

  onBackground() {
    Logger.info(TAG, 'onBackground');
  }
}
