import { UIAbility, Want, AbilityConstant } from '@kit.AbilityKit';
import { window } from '@kit.ArkUI';
import { CoreInitializer, Logger } from 'core';
import { APP_ENV } from '../config/RuntimeConfig';
import { AppearanceManager } from '../utils/AppearanceManager';

const TAG: string = 'EntryAbility';

export default class EntryAbility extends UIAbility {
  onCreate(_want: Want, _launchParam: AbilityConstant.LaunchParam) {
    Logger.info(TAG, 'onCreate');

    // 尽早恢复用户选择的颜色模式，避免启动时闪烁
    AppearanceManager.restoreOnLaunch(this.context).catch((error: Error | object) => {
      Logger.warning(TAG, `restoreOnLaunch failed: ${JSON.stringify(error)}`);
    });

    // 初始化核心库，直接传递 AppEnv，无需任何转换
    CoreInitializer.initCore({ env: APP_ENV, context: this.context })
      .then(() => {
        Logger.info(TAG, `CoreV2 initialized. env=${APP_ENV}`);
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
      // 获取状态栏高度并存入 AppStorage，供各页面读取
      const topArea = win.getWindowAvoidArea(window.AvoidAreaType.TYPE_SYSTEM);
      const topPx = topArea.topRect.height;
      AppStorage.setOrCreate('topRectHeight', topPx);
      const bottomArea = win.getWindowAvoidArea(window.AvoidAreaType.TYPE_NAVIGATION_INDICATOR);
      const bottomPx = bottomArea.bottomRect.height;
      AppStorage.setOrCreate('bottomRectHeight', bottomPx);
      // 监听避让区域变化（折叠屏旋转等场景）
      win.on('avoidAreaChange', (data) => {
        if (data.type === window.AvoidAreaType.TYPE_SYSTEM) {
          AppStorage.setOrCreate('topRectHeight', data.area.topRect.height);
        } else if (data.type === window.AvoidAreaType.TYPE_NAVIGATION_INDICATOR) {
          AppStorage.setOrCreate('bottomRectHeight', data.area.bottomRect.height);
        }
      });
      // 存储窗口宽度（px），供响应式布局使用
      const size = win.getWindowProperties().windowRect;
      AppStorage.setOrCreate('windowWidthPx', size.width);
      win.on('windowSizeChange', (s) => {
        AppStorage.setOrCreate('windowWidthPx', s.width);
      });
    }).catch((err: Error | object) => {
      Logger.warning(TAG, `getMainWindow failed: ${JSON.stringify(err)}`);
    });
    windowStage.loadContent('pages/Index', (err, data) => {
      if (err.code) {
        Logger.warning(TAG, `Failed to load content: ${JSON.stringify(err)}`);
        return;
      }
      Logger.info(TAG, `Succeeded in loading content: ${JSON.stringify(data)}`);
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
