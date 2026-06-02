import { UIAbility, Want, AbilityConstant } from '@kit.AbilityKit';
import { window } from '@kit.ArkUI';
import { CoreInitializer, Logger, SyncQueueRunner } from 'core';
import { APP_ENV } from '../config/RuntimeConfig';
import { AppearanceManager } from '../utils/AppearanceManager';
import { StaminaNotificationService } from '../notification/StaminaNotificationService';
import { WidgetDataStoreBuilder } from '../widget/utils/WidgetDataStoreBuilder';
import { WidgetDataStoreManager } from '../widget/utils/WidgetDataStoreManager';
import { TransparentColorCache } from '../utils/ColorUtil';

const TAG: string = 'EntryAbility';

export default class EntryAbility extends UIAbility {
  onCreate(_want: Want, _launchParam: AbilityConstant.LaunchParam) {
    Logger.info(TAG, 'onCreate');

    // 尽早恢复用户选择的颜色模式，避免启动时闪烁
    AppearanceManager.restoreOnLaunch(this.context).catch((error: Error | object) => {
      Logger.warning(TAG, `restoreOnLaunch failed: ${JSON.stringify(error)}`);
    });

    // 初始化透明色缓存（从 color.json 读取基础颜色并计算）
    TransparentColorCache.init(this.context);

    // 初始化核心库，直接传递 AppEnv，无需任何转换
    CoreInitializer.initCore({ env: APP_ENV, context: this.context })
      .then(async () => {
        Logger.info(TAG, `CoreV2 initialized. env=${APP_ENV}`);
        // 初始化 Widget 数据存储
        await WidgetDataStoreManager.init(this.context);
        // 立即构建并保存 Widget 数据（确保添加卡片时有数据可用）
        await WidgetDataStoreBuilder.initAndSave();
        // 注册同步完成回调：同步完成后刷新 Widget 数据
        SyncQueueRunner.registerOnComplete(async () => {
          Logger.info(TAG, 'SyncQueueRunner.onComplete: refreshing Widget data');
          await WidgetDataStoreBuilder.refreshAndSave();
        });
        // 核心库初始化完成后，初始化通知服务
        StaminaNotificationService.instance().init(this.context).catch((e: Error | object) => {
          Logger.warning(TAG, `StaminaNotificationService.init failed: ${JSON.stringify(e)}`);
        });
      })
      .catch((error: Error | object) => {
        Logger.warning(TAG, `CoreInitializer.initCore failed: ${JSON.stringify(error)}`);
      });

    Logger.info(TAG, `env=${APP_ENV}`);
  }

  onDestroy() {
    Logger.info(TAG, 'onDestroy');
  }

  onWindowStageCreate(windowStage: window.WindowStage) {
    Logger.info(TAG, 'onWindowStageCreate');
    windowStage.getMainWindow().then((win) => {
      // 将 windowClass 存入 AppStorage，供 Main.ets 直接持有并注册监听
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

  onForeground() {
    Logger.info(TAG, 'onForeground');
  }

  onBackground() {
    Logger.info(TAG, 'onBackground');
  }
}
